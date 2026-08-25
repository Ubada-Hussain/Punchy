import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFFF5F9F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF5F0);
  static const Color ink = Color(0xFF142420);
  static const Color inkSoft = Color(0xFF63736C);
  static const Color inkFaint = Color(0xFF9AA8A2);
  static const Color line = Color(0xFFE2EBE5);

  static const Color teal = Color(0xFF0EA893);
  static const Color tealDark = Color(0xFF076B5D);
  static const Color coral = Color(0xFFFF6B57);
  static const Color coralDark = Color(0xFFE4503D);
  static const Color gold = Color(0xFFFFC145);
  static const Color purple = Color(0xFF7C6FF0);
  static const Color darkNav = Color(0xFF0C1210);

  // Gradients
  static const LinearGradient gradTeal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14C1A6), Color(0xFF076B5D)],
  );

  static const LinearGradient gradCoral = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9166), Color(0xFFE4503D)],
  );

  static const LinearGradient gradPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9A8CFF), Color(0xFF5B4FD6)],
  );

  static const LinearGradient gradGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD166), Color(0xFFF2994A)],
  );
}
