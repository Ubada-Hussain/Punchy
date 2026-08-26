import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _statsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/admin/stats');
      if (res is Map<String, dynamic> && mounted) {
        setState(() {
          _statsData = res;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback stats
    if (mounted) {
      setState(() {
        _statsData = {
          'stats': {
            'totalBusinesses': 0,
            'totalCustomers': 0,
            'totalPunches': 0,
            'totalRedemptions': 0,
          },
          'recentActivity': [],
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statsData?['stats'] ?? {'totalBusinesses': 0, 'totalCustomers': 0, 'totalPunches': 0, 'totalRedemptions': 0};
    final recent = (_statsData?['recentActivity'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/'),
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
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Platform Admin',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Overview & Management',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.inkSoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'ADMIN ROLE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.coralDark,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      children: [
                        // Platform Stat Grid
                        Row(
                          children: [
                            Expanded(child: _buildAdminStatCard('Businesses', '${stats['totalBusinesses']}', Icons.storefront_rounded, AppColors.tealDark)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildAdminStatCard('Customers', '${stats['totalCustomers']}', Icons.people_outline_rounded, AppColors.coralDark)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildAdminStatCard('Total Punches', '${stats['totalPunches']}', Icons.qr_code_2_rounded, AppColors.purpleDark)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildAdminStatCard('Redeemed', '${stats['totalRedemptions']}', Icons.card_giftcard_rounded, AppColors.goldDark)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Growth Analytics Chart Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Platform Growth',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    '+24% this month',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.tealDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 130,
                                child: LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: const FlTitlesData(show: false),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: const [
                                          FlSpot(0, 42),
                                          FlSpot(1, 88),
                                          FlSpot(2, 145),
                                          FlSpot(3, 210),
                                          FlSpot(4, 290),
                                          FlSpot(5, 380),
                                        ],
                                        isCurved: true,
                                        color: AppColors.teal,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: AppColors.teal.withValues(alpha: 0.15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Admin Navigation Section
                        Text(
                          'Management Sections',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _buildNavTile(
                          icon: Icons.storefront_rounded,
                          title: 'Business Management',
                          subtitle: 'Approve, suspend, and inspect business profiles',
                          onTap: () => context.push('/admin/businesses'),
                        ),
                        const SizedBox(height: 8),

                        _buildNavTile(
                          icon: Icons.manage_accounts_rounded,
                          title: 'Customer Management',
                          subtitle: 'View user wallets, punch history & block accounts',
                          onTap: () => context.push('/admin/customers'),
                        ),
                        const SizedBox(height: 8),

                        _buildNavTile(
                          icon: Icons.campaign_rounded,
                          title: 'Platform Announcements',
                          subtitle: 'Broadcast alerts to businesses and customers',
                          onTap: () => context.push('/admin/notifications'),
                        ),
                        const SizedBox(height: 20),

                        // Recent Platform Activity
                        Text(
                          'Recent Platform Activity',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            children: recent.map((a) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceAlt,
                                            borderRadius: BorderRadius.circular(9),
                                          ),
                                          child: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.tealDark),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                a['userEmail'] ?? 'User action',
                                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                                              ),
                                              Text(
                                                (a['action'] ?? '').toString().replaceAll('_', ' '),
                                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.inkSoft),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: AppColors.line),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.inkSoft, letterSpacing: 0.4),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: AppColors.tealDark, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
