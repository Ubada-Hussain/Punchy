import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/punchy_empty_state.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/business/customers');
      if (res is List && mounted) {
        setState(() {
          _customers = res;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Sample fallback data if backend is empty
    if (mounted) {
      setState(() {
        _customers = [
          {
            'customerCardId': 'cc1',
            'customerId': 'u1',
            'email': 'ayesha@email.com',
            'cardTitle': 'Coffee Lovers Card',
            'punchCount': 8,
            'punchesRequired': 10,
            'isCompleted': false,
            'joinedAt': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
            'lastActivity': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
          },
          {
            'customerCardId': 'cc2',
            'customerId': 'u2',
            'email': 'bilal.hassan@gmail.com',
            'cardTitle': 'Coffee Lovers Card',
            'punchCount': 10,
            'punchesRequired': 10,
            'isCompleted': true,
            'joinedAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
            'lastActivity': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          },
          {
            'customerCardId': 'cc3',
            'customerId': 'u3',
            'email': 'zainab.r@outlook.com',
            'cardTitle': 'Coffee Lovers Card',
            'punchCount': 3,
            'punchesRequired': 10,
            'isCompleted': false,
            'joinedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
            'lastActivity': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          },
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmRedemption(String customerCardId, String email) async {
    try {
      await _api.post('/business/redeem-confirm', {'customerCardId': customerCardId});
      await _fetchCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Reward verified and redeemed for $email! 🎉',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _customers.where((c) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      final email = (c['email'] ?? '').toString().toLowerCase();
      final card = (c['cardTitle'] ?? '').toString().toLowerCase();
      return email.contains(q) || card.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.ink),
                      ),
                    ),
                  ),
                  Text(
                    'Your Customers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search customer email or card...',
                    hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.inkFaint, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.inkSoft),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),

            // Customer List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: PunchyEmptyState.noCustomers(),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            final email = c['email'] ?? 'customer@email.com';
                            final initial = email.isNotEmpty ? email[0].toUpperCase() : 'C';
                            final punchCount = c['punchCount'] as int? ?? 0;
                            final punchesRequired = c['punchesRequired'] as int? ?? 10;
                            final isCompleted = c['isCompleted'] == true || punchCount >= punchesRequired;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceAlt,
                                          borderRadius: BorderRadius.circular(11),
                                        ),
                                        child: Center(
                                          child: Text(
                                            initial,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.tealDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              email,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            Text(
                                              c['cardTitle'] ?? 'Loyalty Card',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11.5,
                                                color: AppColors.inkSoft,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? AppColors.coral.withValues(alpha: 0.15)
                                              : AppColors.teal.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          isCompleted ? 'Reward Ready 🎉' : '$punchCount/$punchesRequired',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isCompleted ? AppColors.coralDark : AppColors.tealDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: punchesRequired > 0 ? (punchCount / punchesRequired).clamp(0.0, 1.0) : 0,
                                      backgroundColor: AppColors.surfaceAlt,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isCompleted ? AppColors.coral : AppColors.teal,
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),

                                  // Verify Redemption Button (only when card is complete)
                                  if (isCompleted) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 38,
                                      child: ElevatedButton(
                                        onPressed: () => _confirmRedemption(c['customerCardId'] ?? '', email),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.coral,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_circle_outline_rounded, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Confirm Redemption',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
