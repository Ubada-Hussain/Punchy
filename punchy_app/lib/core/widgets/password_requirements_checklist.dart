import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../validation/password_policy.dart';

class PasswordRequirementsChecklist extends StatelessWidget {
  const PasswordRequirementsChecklist({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, passwordValue, _) => Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password must include:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 5),
              for (final requirement in PasswordPolicy.requirements)
                _PasswordRequirementRow(
                  requirement: requirement,
                  isSatisfied: requirement.isSatisfiedBy(passwordValue.text),
                ),
            ],
          ),
        ),
      );
}

class _PasswordRequirementRow extends StatelessWidget {
  const _PasswordRequirementRow({
    required this.requirement,
    required this.isSatisfied,
  });

  final PasswordRequirement requirement;
  final bool isSatisfied;

  @override
  Widget build(BuildContext context) {
    final color = isSatisfied ? AppColors.tealDark : AppColors.inkSoft;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Text(
                isSatisfied ? '✓' : '•',
                key: ValueKey(isSatisfied),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isSatisfied ? 13 : 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSatisfied ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(requirement.label),
            ),
          ),
        ],
      ),
    );
  }
}
