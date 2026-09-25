import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _data;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.get('/subscriptions/business/current');
      if (mounted) setState(() => _data = Map<String, dynamic>.from(data));
    } catch (_) {
      if (mounted) setState(() => _data = {});
    }
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? '—'
        : '${date.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final subscription = _data?['subscription'] as Map?;
    final pricing = _data?['pricing'] as Map?;
    final trial = subscription?['status'] == 'TRIALING';
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: AppColors.bg,
      ),
      body: _data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (trial)
                  _card(
                    '🎉 2-Month Free Trial',
                    'Trial ends: ${_date(subscription?['trialEnd'] ?? subscription?['endDate'])}',
                  ),
                if (!trial)
                  _card(
                    'Subscription',
                    'Status: ${subscription?['status'] ?? 'PAYMENT_PENDING'}\nEnds: ${_date(subscription?['endDate'])}',
                  ),
                const SizedBox(height: 18),
                Text(
                  'Plans for your business country',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _card(
                  'Monthly',
                  pricing == null
                      ? 'Pricing is not available yet.'
                      : '${pricing['currencyCode']} ${pricing['monthlyPrice']} / month',
                ),
                const SizedBox(height: 10),
                _card(
                  'Yearly',
                  pricing == null
                      ? 'Pricing is not available yet.'
                      : '${pricing['currencyCode']} ${pricing['yearlyPrice']} / year',
                ),
              ],
            ),
    );
  }

  Widget _card(String title, String body) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
