import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class CreateCardScreen extends StatefulWidget {
  const CreateCardScreen({super.key});

  @override
  State<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends State<CreateCardScreen> {
  final _nameController = TextEditingController(text: 'Coffee Lovers Card');
  final _rewardController = TextEditingController(text: '1 Free Coffee');
  int _punchesRequired = 10;
  int _selectedColorIndex = 0; // 0=Coral, 1=Teal, 2=Purple, 3=Gold
  bool _useQR = true;
  bool _useNFC = true;

  final List<LinearGradient> _gradients = [
    AppColors.gradCoral,
    AppColors.gradTeal,
    AppColors.gradPurple,
    AppColors.gradGold,
  ];

  void _saveCard() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '🎉 Card Activated! Ready for customers.',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentGradient = _gradients[_selectedColorIndex];

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
                    'Design your card',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),

            // Scrollable Form & Live Preview
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                children: [
                  // Live Preview Card
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      gradient: currentGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: currentGradient.colors.last.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('☕', style: TextStyle(fontSize: 15)),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isEmpty ? 'Your Card' : _nameController.text,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Live preview',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Tear Line
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bg),
                            ),
                            Expanded(
                              child: Container(
                                height: 1.5,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bg),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Stamps
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(_punchesRequired > 10 ? 10 : _punchesRequired, (i) {
                            final isFirst = i == 0;
                            return Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFirst ? Colors.white : Colors.transparent,
                                border: isFirst ? null : Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
                              ),
                              child: Center(
                                child: isFirst
                                    ? Icon(Icons.check_rounded, color: currentGradient.colors.last, size: 14)
                                    : Text(
                                        '${i + 1}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                      ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Card Name
                  Text(
                    'Card name',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(hintText: 'e.g. Coffee Lovers Card'),
                  ),
                  const SizedBox(height: 16),

                  // Punches Required Stepper
                  Text(
                    'Punches required',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_punchesRequired > 3) setState(() => _punchesRequired--);
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Center(child: Text('−', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                          ),
                        ),
                        Text(
                          '$_punchesRequired',
                          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_punchesRequired < 20) setState(() => _punchesRequired++);
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Center(child: Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reward Input
                  Text(
                    'Reward',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _rewardController,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: '1 Free Coffee',
                      prefixIcon: Icon(Icons.card_giftcard_rounded, color: AppColors.inkFaint, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card Color Swatches
                  Text(
                    'Card color',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(_gradients.length, (index) {
                      final isSelected = _selectedColorIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorIndex = index),
                        child: Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            gradient: _gradients[index],
                            borderRadius: BorderRadius.circular(11),
                            border: isSelected ? Border.all(color: AppColors.ink, width: 2.5) : null,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Punch Method Chips
                  Text(
                    'Punch method',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _useQR = !_useQR),
                        child: _buildChip('QR Code', _useQR),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _useNFC = !_useNFC),
                        child: _buildChip('NFC Tap', _useNFC),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Save & Activate Button
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.coral.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _saveCard,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Text(
                            'Save & Activate',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
    );
  }

  Widget _buildChip(String label, bool isOn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isOn ? AppColors.teal : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isOn ? AppColors.teal : AppColors.line, width: 1.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isOn ? Colors.white : AppColors.inkSoft,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rewardController.dispose();
    super.dispose();
  }
}
