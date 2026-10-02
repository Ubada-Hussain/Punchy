import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/notification_count_badge.dart';
import 'card_detail_screen.dart';
import 'widgets/loyalty_card_deck.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen>
    with WidgetsBindingObserver {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _cards = [];
  String? _loadError;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService().inboxRevision.addListener(_handleInboxChanged);
    _loadCards();
    _loadUnreadNotifications();
  }

  void _handleInboxChanged() => _loadUnreadNotifications();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadUnreadNotifications();
  }

  @override
  void dispose() {
    NotificationService().inboxRevision.removeListener(_handleInboxChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    await Future.wait([_loadCards(), _loadUnreadNotifications()]);
  }

  Future<void> _loadCards() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/customer/cards');
      if (res != null && res is List) {
        if (mounted) {
          setState(() {
            _cards = res;
            _isLoading = false;
            _loadError = null;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadError = "Couldn't load your cards";
      });
    }
  }

  Future<void> _confirmRemoveCard(Map<String, dynamic> cardData) async {
    final cardInfo = cardData['card'] ?? {};
    final biz = cardInfo['business'] ?? {};
    final bizName = biz['name'] ?? cardInfo['title'] ?? 'this loyalty card';
    final cardId = cardData['id'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(
              Icons.remove_circle_outline_rounded,
              color: AppColors.coralDark,
            ),
            const SizedBox(width: 10),
            Text(
              'Remove Card',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "$bizName" from your wallet? Your punch progress on this card will be deleted.',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.inkSoft,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || cardId == null || !mounted) return;

    try {
      await _api.delete('/customer/cards/$cardId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              'Card removed from your wallet.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        _loadCards();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              'Could not remove card. Please try again.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openCard(Map<String, dynamic> card) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CardDetailScreen(cardData: card)));
    if (mounted) await _loadCards();
  }

  Future<void> _cardOptions(Map<String, dynamic> card) async {
    final remove = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: deckCream,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  LoyaltyDeckData(card).name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: deckInk,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: AppColors.coralDark,
                ),
                title: const Text('Remove card'),
                subtitle: const Text('You will be asked to confirm'),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (remove == true && mounted) await _confirmRemoveCard(card);
  }

  Future<void> _explore() async {
    await context.push('/explore');
    if (mounted) await _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName =
        (auth.user?['name'] ?? auth.user?['email']?.split('@')[0] ?? 'there')
            .toString();
    final cards = _cards
        .whereType<Map>()
        .map((card) => Map<String, dynamic>.from(card))
        .toList();
    return Scaffold(
      backgroundColor: deckCream,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(.05, -.95),
            radius: 1.05,
            colors: [Color(0xFFD5EEE7), deckCream],
            stops: [0, .85],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardHeight = (constraints.maxWidth * 1.18).clamp(
                      440.0,
                      570.0,
                    );
                    return RefreshIndicator(
                      onRefresh: () => Future.wait([
                        _loadCards(),
                        _loadUnreadNotifications(),
                      ]),
                      color: deckTeal,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 22, bottom: 28),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hi $userName',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 27,
                                          height: 1.15,
                                          letterSpacing: -.8,
                                          fontWeight: FontWeight.w800,
                                          color: deckInk,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _isLoading && cards.isEmpty
                                            ? 'Your deck'
                                            : 'Your deck · ${cards.length} ${cards.length == 1 ? 'card' : 'cards'}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF596663),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _headerButton(
                                  Icons.search_rounded,
                                  'Search businesses',
                                  _explore,
                                ),
                                const SizedBox(width: 10),
                                _headerButton(
                                  Icons.notifications_none_rounded,
                                  'Open alerts',
                                  _openNotifications,
                                  badge: _unreadNotificationsCount,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 34),
                          if (_isLoading && cards.isEmpty)
                            LoadingDeckState(height: cardHeight)
                          else if (_loadError != null && cards.isEmpty)
                            _statePanel(
                              Icons.cloud_off_rounded,
                              "Couldn't load your cards",
                              'Please check your connection and try again.',
                              'Try again',
                              _loadCards,
                            )
                          else if (cards.isEmpty)
                            _statePanel(
                              Icons.credit_card_rounded,
                              'Your deck is empty',
                              'Discover businesses and join a loyalty card to start collecting punches.',
                              'Explore rewards',
                              _explore,
                            )
                          else ...[
                            if (_loadError != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: TextButton.icon(
                                  onPressed: _loadCards,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text(
                                    'Could not refresh · try again',
                                  ),
                                ),
                              ),
                            LoyaltyCardDeck(
                              cards: cards,
                              cardHeight: cardHeight,
                              onOpen: _openCard,
                              onLongPress: _cardOptions,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              _bottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    int badge = 0,
  }) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: deckInk.withValues(alpha: .06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          tooltip: label,
          onPressed: onTap,
          icon: Icon(icon, color: deckInk, size: 23),
        ),
      ),
      if (badge > 0)
        Positioned(
          top: -5,
          right: -5,
          child: NotificationCountBadge(count: badge),
        ),
    ],
  );

  Widget _statePanel(
    IconData icon,
    String title,
    String body,
    String action,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 60, 28, 60),
    child: Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFE5EFE8),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, size: 40, color: deckTeal),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: deckInk,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 1.6,
            color: const Color(0xFF596663),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: deckTeal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          ),
          child: Text(action),
        ),
      ],
    ),
  );

  Widget _bottomNav() => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFEAE3D8))),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 78,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.credit_card_outlined, 'Cards', () {}, active: true),
            _navItem(Icons.explore_outlined, 'Explore', _explore),
            Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: deckCream, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.coral.withValues(alpha: .25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: IconButton.filled(
                  tooltip: 'Open your QR scanner pass',
                  onPressed: () => context.push('/barcode'),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF5654F),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
                ),
              ),
            ),
            _navItem(
              Icons.notifications_none_rounded,
              'Alerts',
              _openNotifications,
              badge: _unreadNotificationsCount,
            ),
            _navItem(Icons.person_outline_rounded, 'Profile', () async {
              await context.push('/profile');
              if (mounted) await _loadCards();
            }),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
    int badge = 0,
  }) => Semantics(
    selected: active,
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 58,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 25,
                  color: active ? deckTeal : const Color(0xFF677370),
                ),
                if (badge > 0)
                  Positioned(
                    top: -7,
                    right: -10,
                    child: NotificationCountBadge(count: badge),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: active ? deckTeal : const Color(0xFF677370),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class LoadingDeckState extends StatelessWidget {
  final double height;
  const LoadingDeckState({super.key, required this.height});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: MediaQuery.sizeOf(context).width * .77,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEE7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _block(54, 54, radius: 18),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _block(double.infinity, 17),
                      const SizedBox(height: 10),
                      _block(80, 12),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            _block(130, 64),
            const SizedBox(height: 12),
            _block(145, 14),
            const Spacer(),
            Row(
              children: List.generate(
                5,
                (_) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _block(
                        double.infinity,
                        double.infinity,
                        radius: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _block(double.infinity, 14),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _block(double.infinity, 32, radius: 20)),
                const SizedBox(width: 16),
                _block(44, 44, radius: 30),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _block(double width, double height, {double radius = 8}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFDBE3DC),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
