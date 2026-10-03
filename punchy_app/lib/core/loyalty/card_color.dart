import 'package:flutter/material.dart';

/// The first stop of each original Create Card swatch gradient. All legacy
/// readers now use this one mapping, including numeric swatch indices.
abstract final class CardColor {
  static const defaultHex = '#0B6B63';
  static const presets = <String, String>{
    'coral': '#FF8368',
    'teal': '#14B8A6',
    'purple': '#8B7FF5',
    'gold': '#FFC658',
  };

  static String? parseHex(String input) {
    final value = input.trim().toUpperCase();
    return RegExp(r'^#?[0-9A-F]{6}$').hasMatch(value)
        ? (value.startsWith('#') ? value : '#$value')
        : null;
  }

  static String normalize(dynamic value) {
    if (value is String) {
      final hex = parseHex(value);
      if (hex != null) return hex;
      final legacy = value.trim().toLowerCase();
      if (presets.containsKey(legacy)) return presets[legacy]!;
      final index = int.tryParse(legacy);
      if (index != null && index >= 0 && index < presets.length) {
        return presets.values.elementAt(index);
      }
    } else if (value is int && value >= 0 && value < presets.length) {
      return presets.values.elementAt(value);
    }
    return defaultHex;
  }

  static Color parse(dynamic value) =>
      Color(int.parse(normalize(value).substring(1), radix: 16) | 0xFF000000);

  static String format(Color value) =>
      '#${(value.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// Accept either the business card or a customer's joined-card response.
  static Color fromCard(dynamic value) {
    if (value is! Map) return parse(null);
    final card = value['card'] is Map ? value['card'] as Map : value;
    final style = card['visualStyle'];
    return parse(
      style is Map
          ? (style['primaryColor'] ?? card['cardColor'] ?? style['theme'])
          : (card['cardColor'] ?? style),
    );
  }
}
