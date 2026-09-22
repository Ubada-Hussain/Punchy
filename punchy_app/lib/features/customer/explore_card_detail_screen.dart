import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/formatting/currency.dart';
import '../../core/theme/app_colors.dart';

class ExploreCardDetailScreen extends StatelessWidget {
  const ExploreCardDetailScreen({
    super.key,
    required this.business,
    required this.card,
  });

  final Map<String, dynamic> business;
  final Map<String, dynamic>? card;

  Future<void> _join(BuildContext context) async {
    if (card?['id'] == null) return;
    try {
      final result = await ApiClient().post('/customer/cards/join', {
        'cardId': card!['id'],
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['message'] ?? 'Card added to your wallet.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not add card: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locations = business['locations'] is List
        ? business['locations'] as List
        : const [];
    final address = locations.isNotEmpty && locations.first is Map
        ? (locations.first['address'] ?? '').toString()
        : '';
    final title =
        card?['title']?.toString() ??
        '${business['name'] ?? 'Business'} loyalty card';
    final currency = card?['currency'];
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          'Card details',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.gradTeal,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business['name']?.toString() ?? 'Business',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${card?['punchesRequired'] ?? 0} punches • Reward: ${card?['rewardDescription'] ?? 'Not set'}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: .9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            'About',
            business['description']?.toString().trim().isNotEmpty == true
                ? business['description'].toString()
                : 'No business description has been added.',
          ),
          _section('Category', business['category']?.toString() ?? 'Business'),
          _section(
            'Price per punch',
            Currency.price(currency, card?['pricePerPunch']),
          ),
          if (address.isNotEmpty) _section('Address', address),
          _section(
            'Valid until',
            card?['validUntil']?.toString().split('T').first ?? 'No expiry',
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: card == null ? null : () => _join(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add to wallet'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
