import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';

class ExploreBusinessDetailScreen extends StatelessWidget {
  const ExploreBusinessDetailScreen({
    super.key,
    required this.business,
    required this.card,
  });

  final Map<String, dynamic> business;
  final Map<String, dynamic>? card;

  String get _address {
    final locations = business['locations'];
    return locations is List && locations.isNotEmpty && locations.first is Map
        ? locations.first['address']?.toString() ?? ''
        : '';
  }

  String get _phone => business['user'] is Map
      ? business['user']['phone']?.toString() ?? ''
      : '';
  String get _currency =>
      card?['currency']?.toString() ??
      business['currencyCode']?.toString() ??
      'USD';
  String get _symbol =>
      const {
        'PKR': 'Rs',
        'GBP': '£',
        'AED': 'AED',
        'USD': r'$',
        'EUR': '€',
        'INR': '₹',
        'SAR': '﷼',
        'CAD': r'C$',
        'AUD': r'A$',
      }[_currency] ??
      _currency;

  Future<void> _join(BuildContext context) async {
    if (card == null) return;
    try {
      await ApiClient().post('/customer/cards/join', {'cardId': card!['id']});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card added to your wallet.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add this card.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = card?['pricePerPunch'];
    final priceText = price == null ? 'Not set' : '$_symbol $price';
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          'Business details',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            business['name']?.toString() ?? 'Business',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            business['category']?.toString() ?? '',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.tealDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((business['description']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              business['description'].toString(),
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.inkSoft,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _section('Loyalty card', [
            _row(
              Icons.style_outlined,
              'Card',
              card?['title']?.toString() ?? 'No active loyalty card',
            ),
            _row(
              Icons.touch_app_outlined,
              'Punches needed',
              '${card?['punchesRequired'] ?? 0}',
            ),
            _row(
              Icons.card_giftcard_outlined,
              'Reward',
              card?['rewardDescription']?.toString() ?? 'Not set',
            ),
            _row(Icons.payments_outlined, 'Price per punch', priceText),
          ]),
          const SizedBox(height: 14),
          _section('Contact & location', [
            if (_phone.isNotEmpty)
              InkWell(
                onTap: () => launchUrl(Uri.parse('tel:$_phone')),
                child: _row(Icons.phone_outlined, 'Phone', _phone),
              ),
            if (_address.isNotEmpty)
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(_address)}',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                child: _row(Icons.location_on_outlined, 'Address', _address),
              ),
            if ((business['website']?.toString() ?? '').isNotEmpty)
              _row(
                Icons.language_outlined,
                'Website',
                business['website'].toString(),
              ),
          ]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: card == null ? null : () => _join(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text('Join loyalty card'),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
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
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.tealDark),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label\n$value',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    ),
  );
}
