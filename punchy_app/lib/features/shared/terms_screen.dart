import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    'Terms & Conditions',
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

            // Scrollable Terms Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Punchy Terms of Service',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated: August 2026',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkFaint,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.line),
                        const SizedBox(height: 16),

                        _buildSection(
                          title: '1. Overview & Acceptance',
                          body: 'Welcome to Punchy. By downloading, accessing, or using our mobile application, digital loyalty cards, QR/NFC readers, or web services, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the service.',
                        ),

                        _buildSection(
                          title: '2. Customer Loyalty & Punches',
                          body: 'Customers can join loyalty cards offered by participating businesses and collect digital punches via authorized QR code scanning or NFC tap interactions. Punches hold no independent monetary cash value and cannot be transferred, sold, or redeemed outside the terms specified by each merchant.',
                        ),

                        _buildSection(
                          title: '3. Reward Redemptions',
                          body: 'Once the required number of punches is reached on a loyalty card, the customer may present the completed card to the merchant for reward redemption. Merchants reserve the right to verify card validity and confirm redemption through their merchant portal.',
                        ),

                        _buildSection(
                          title: '4. Business & Merchant Responsibilities',
                          body: 'Businesses using Punchy agree to honor advertised rewards in good faith, maintain accurate business profile information, and refrain from fraudulent punch issuance or deceptive promotions.',
                        ),

                        _buildSection(
                          title: '5. Account Security & Privacy',
                          body: 'Users are responsible for safeguarding their login credentials. Punchy complies with applicable privacy regulations and does not sell personal user data to unauthorized third parties.',
                        ),

                        _buildSection(
                          title: '6. Modifications & Termination',
                          body: 'Punchy reserves the right to modify these terms or suspend accounts violating platform rules or engaging in fraudulent activity at any time.',
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'Questions about our Terms? Contact us at support@punchy.app.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tealDark,
                          ),
                        ),
                      ],
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

  Widget _buildSection({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
