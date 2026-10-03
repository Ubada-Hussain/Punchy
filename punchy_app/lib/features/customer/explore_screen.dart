import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api/api_client.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/notification_count_badge.dart';
import 'explore_business_detail_screen.dart';
import 'explore/explore_style.dart';
import 'explore/explore_header.dart';
import 'explore/explore_filters.dart';
import 'explore/explore_tile.dart';
import 'explore/explore_transition.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.apiClient, this.positionLoader});

  final ApiClient? apiClient;
  final Future<Position?> Function()? positionLoader;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with WidgetsBindingObserver {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _businesses = [];
  bool _isLoading = true;
  bool _locationUnavailable = false;
  bool _loadFailed = false;
  bool _locationChecked = false;
  bool _locationResolutionAttempted = false;
  Position? _cachedPosition;
  Future<Position?>? _positionFuture;
  Map<String, dynamic>? _resolvedLocation;
  int _requestId = 0;
  String? _activeFiltersKey;
  String? _lastSuccessfulFiltersKey;
  String _selectedCategory = 'All';
  String _selectedLocationScope = 'city';
  int _unreadNotificationsCount = 0;

  final List<String> _categories = [
    'All',
    'Cafe',
    'Salon',
    'Fitness',
    'Restaurant',
    'Other',
  ];
  final Map<String, Map<String, dynamic>> _wallet = {};
  final Map<String, GlobalKey> _tileKeys = {};
  bool _showSearch = false;
  bool _dismissedLocationNotice = false;
  Timer? _searchDebounce;
  late final Future<void> _walletReady;
  int _entryRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService().inboxRevision.addListener(_handleInboxChanged);
    _walletReady = _loadWallet();
    _fetchBusinesses();
    _loadUnreadNotifications();
  }

  void _handleInboxChanged() => _loadUnreadNotifications();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadUnreadNotifications();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final res = await _api.get('/notifications/unread-count');
      if (mounted && res is Map<String, dynamic>) {
        setState(() {
          _unreadNotificationsCount =
              int.tryParse(res['unreadCount']?.toString() ?? '') ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await context.push('/notifications');
    await _loadUnreadNotifications();
  }

  Future<void> _fetchBusinesses({bool force = false}) async {
    final filtersKey =
        '$_selectedLocationScope|$_selectedCategory|${_searchController.text.trim()}';
    if (!force &&
        (_activeFiltersKey == filtersKey ||
            (!_isLoading && _lastSuccessfulFiltersKey == filtersKey))) {
      return;
    }
    final requestId = ++_requestId;
    _activeFiltersKey = filtersKey;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }
    final startedAt = DateTime.now();
    try {
      final categoryParam = _selectedCategory == 'All'
          ? ''
          : _selectedCategory.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      var position = _cachedPosition;
      if (!_locationChecked && _resolvedLocation == null) {
        position = await (_positionFuture ??= _loadPositionOnce());
      }
      if (mounted && requestId == _requestId) {
        setState(
          () => _locationUnavailable =
              position == null && _resolvedLocation == null,
        );
      }
      final params = <String, String>{
        'search': _searchController.text.trim(),
        'category': categoryParam,
        'scope': _selectedLocationScope,
        if (position != null && !_locationResolutionAttempted)
          'lat': position.latitude.toString(),
        if (position != null && !_locationResolutionAttempted)
          'lng': position.longitude.toString(),
        if (_resolvedLocation?['countryCode'] != null)
          'currentCountryCode': _resolvedLocation!['countryCode'].toString(),
        if (_resolvedLocation?['city'] != null)
          'currentCity': _resolvedLocation!['city'].toString(),
      };
      final query = '?${Uri(queryParameters: params).query}';

      final res = await _api.get('/customer/explore$query');
      if (res is Map &&
          res['businesses'] is List &&
          mounted &&
          requestId == _requestId) {
        final location = res['location'];
        setState(() {
          _businesses = res['businesses'] as List;
          _locationUnavailable = res['locationAvailable'] != true;
          if (location is Map) {
            _resolvedLocation = Map<String, dynamic>.from(location);
          }
          _locationResolutionAttempted = true;
          _isLoading = false;
          _loadFailed = false;
          _lastSuccessfulFiltersKey = filtersKey;
        });
        if (_activeFiltersKey == filtersKey) _activeFiltersKey = null;
        debugPrint(
          'Explore load: ${DateTime.now().difference(startedAt).inMilliseconds} ms (location + API + filtering)',
        );
        return;
      }
    } catch (error) {
      debugPrint(
        'Explore load failed after ${DateTime.now().difference(startedAt).inMilliseconds} ms: $error',
      );
      if (mounted && requestId == _requestId) {
        setState(() => _loadFailed = true);
      }
    }

    if (mounted && requestId == _requestId) {
      setState(() {
        if (_businesses.isEmpty) _businesses = [];
        _isLoading = false;
      });
      if (_activeFiltersKey == filtersKey) _activeFiltersKey = null;
    }
  }

  Future<Position?> _loadPositionOnce() async {
    try {
      if (widget.positionLoader != null) {
        return _cachedPosition = await widget.positionLoader!();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          !await Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      return _cachedPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      return null;
    } finally {
      _locationChecked = true;
    }
  }

  Future<void> _refreshExplore() async {
    // A user-requested refresh also gets a fresh GPS fix in case they moved.
    _cachedPosition = null;
    _positionFuture = null;
    _locationChecked = false;
    _resolvedLocation = null;
    _locationResolutionAttempted = false;
    _lastSuccessfulFiltersKey = null;
    await _fetchBusinesses(force: true);
  }

  Future<bool> _addCardToWallet(String cardId, String businessName) async {
    try {
      final res = await _api.post('/customer/cards/join', {'cardId': cardId});
      if (res is Map && res['customerCard'] is Map && mounted) {
        setState(
          () =>
              _wallet[cardId] = Map<String, dynamic>.from(res['customerCard']),
        );
      }
      final msg =
          res?['message'] ?? 'Added card from $businessName to your wallet! 🎉';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: exploreInk,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: exploreTeal,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadWallet() async {
    try {
      final result = await _api.get('/customer/cards');
      if (result is List && mounted) {
        setState(() {
          _wallet.clear();
          for (final row in result.whereType<Map>()) {
            final id =
                row['cardId'] ??
                (row['card'] is Map ? row['card']['id'] : null);
            if (id != null) {
              _wallet[id.toString()] = Map<String, dynamic>.from(row);
            }
          }
        });
      }
    } catch (_) {
      // Joining remains idempotent on the existing backend if wallet refresh fails.
    }
  }

  void _searchChanged(String _) {
    _searchDebounce?.cancel();
    setState(() => _entryRevision++);
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _fetchBusinesses(),
    );
  }

  Future<void> _openTile(
    Map<String, dynamic> business,
    int index,
    GlobalKey key,
  ) async {
    await _walletReady;
    if (!mounted) return;
    final card = exploreCard(business);
    final id = card?['id']?.toString();
    final initialBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (initialBox == null || !initialBox.hasSize) return;
    final fallback = initialBox.localToGlobal(Offset.zero) & initialBox.size;
    Rect rect() {
      final box = key.currentContext?.findRenderObject();
      return box is RenderBox && box.attached && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : fallback;
    }

    final color = exploreCardColor(business, index);
    await Navigator.of(context).push(
      ExploreDetailRoute(
        sourceRect: rect,
        color: color,
        business: business,
        added: () => _wallet.containsKey(id),
        reducedMotion: MediaQuery.disableAnimationsOf(context),
        detail: ExploreBusinessDetailScreen(
          business: business,
          card: card,
          color: color,
          customerCard: _wallet[id],
          onJoin: () async {
            if (id == null) return false;
            final success = await _addCardToWallet(id, exploreName(business));
            if (success && mounted && !_wallet.containsKey(id)) {
              await _loadWallet();
            }
            return success;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _businesses
        .whereType<Map>()
        .map((b) => Map<String, dynamic>.from(b))
        .where((b) => matchesExploreSearch(b, _searchController.text))
        .toList();
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: exploreTeal,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: exploreInk,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: exploreTeal,
            onRefresh: () async {
              await Future.wait([_refreshExplore(), _loadWallet()]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 18, bottom: 40),
              children: [
                if (_locationUnavailable && !_dismissedLocationNotice)
                  Container(
                    color: exploreTrack,
                    padding: const EdgeInsets.only(left: 22, right: 6),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Location unavailable — showing all businesses. Enable location for city or country results.',
                            style: exploreBody(
                              11,
                              color: exploreMuted,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Dismiss location notice',
                          onPressed: () =>
                              setState(() => _dismissedLocationNotice = true),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: exploreMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ExploreHeader(
                  onSearch: () => setState(() => _showSearch = !_showSearch),
                  onRefresh: () async {
                    await Future.wait([_refreshExplore(), _loadWallet()]);
                  },
                  onProfile: () => context.push('/profile'),
                  loading: _isLoading,
                ),
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: _searchChanged,
                        onSubmitted: (_) {
                          _searchDebounce?.cancel();
                          _fetchBusinesses();
                        },
                        style: exploreBody(15, weight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Search cafes, salons, fitness…',
                          hintStyle: exploreBody(
                            15,
                            color: exploreMuted,
                            weight: FontWeight.w500,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(color: exploreLine),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(color: exploreTeal),
                          ),
                        ),
                      ),
                    ),
                  ),
                ExploreFilters(
                  scope: _selectedLocationScope,
                  category: _selectedCategory,
                  categories: _categories,
                  onScope: (scope) {
                    if (_selectedLocationScope == scope) return;
                    setState(() {
                      _selectedLocationScope = scope;
                      _entryRevision++;
                    });
                    _fetchBusinesses();
                  },
                  onCategory: (category) {
                    if (_selectedCategory == category) return;
                    setState(() {
                      _selectedCategory = category;
                      _entryRevision++;
                    });
                    _fetchBusinesses();
                  },
                ),
                const SizedBox(height: 22),
                if (_isLoading)
                  const ExploreSkeletonTiles()
                else if (_loadFailed)
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Text(
                          'Couldn’t load cards. Please try again.',
                          style: exploreBody(14, color: exploreMuted),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _fetchBusinesses(force: true),
                          child: Text(
                            'Try again',
                            style: exploreBody(14, color: exploreTeal),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (visible.isEmpty)
                  const ExploreEmptyState()
                else
                  SizedBox(
                    height:
                        (exploreTileHeightFor(context) - 24) *
                            (visible.length - 1) +
                        exploreTileHeightFor(context),
                    child: Stack(
                      children: [
                        for (var i = 0; i < visible.length; i++)
                          Positioned(
                            top: i * (exploreTileHeightFor(context) - 24),
                            left: 0,
                            right: 0,
                            height: exploreTileHeightFor(context),
                            child: ExploreTileEntry(
                              key: ValueKey(
                                '$_entryRevision|${visible[i]['id']}',
                              ),
                              index: i,
                              child: SizedBox(
                                key: _tileKeys.putIfAbsent(
                                  visible[i]['id'].toString(),
                                  GlobalKey.new,
                                ),
                                child: ExploreTile(
                                  business: visible[i],
                                  color: exploreCardColor(visible[i], i),
                                  added: _wallet.containsKey(
                                    exploreCard(visible[i])?['id']?.toString(),
                                  ),
                                  onTap: () => _openTile(
                                    visible[i],
                                    i,
                                    _tileKeys[visible[i]['id'].toString()]!,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                Icons.wallet_rounded,
                'Wallet',
                false,
                onTap: () => context.go('/'),
              ),
              _buildNavItem(
                Icons.explore_rounded,
                'Explore',
                true,
                onTap: () {},
              ),
              // Floating Loyalty Barcode Pass FAB
              GestureDetector(
                onTap: () => context.push('/barcode'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              _buildNavItem(
                Icons.notifications_none_rounded,
                'Alerts',
                false,
                badgeCount: _unreadNotificationsCount,
                onTap: _openNotifications,
              ),
              _buildNavItem(
                Icons.person_outline_rounded,
                'Profile',
                false,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool active, {
    VoidCallback? onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 22,
                color: active ? AppColors.tealDark : AppColors.inkFaint,
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -9,
                  right: -12,
                  child: NotificationCountBadge(count: badgeCount),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? AppColors.tealDark : AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    NotificationService().inboxRevision.removeListener(_handleInboxChanged);
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
