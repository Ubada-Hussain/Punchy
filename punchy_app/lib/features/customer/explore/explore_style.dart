import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const exploreInk = Color(0xFF14201F);
const exploreMuted = Color(0xFF4F5B5A);
const exploreTeal = Color(0xFF0B6B63);
const exploreCoral = Color(0xFFC93F2A);
const exploreLine = Color(0xFFE4E7E6);
const exploreTrack = Color(0xFFF1F3F2);
const exploreTints = [Color(0xFFF8C5B8), Color(0xFFBFE6DD), Color(0xFFF4DC95)];
const exploreCurve = Cubic(.2, .8, .2, 1);

TextStyle exploreDisplay(
  double size, {
  Color color = exploreInk,
  FontWeight weight = FontWeight.w900,
  double height = 1,
}) => GoogleFonts.bigShouldersDisplay(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);
TextStyle exploreBody(
  double size, {
  Color color = exploreInk,
  FontWeight weight = FontWeight.w700,
}) => GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color);

// Presentation helpers for the existing raw API response; no new data model.
Map<String, dynamic>? exploreCard(Map<String, dynamic> business) {
  final cards = business['loyaltyCards'];
  return cards is List && cards.isNotEmpty && cards.first is Map
      ? Map<String, dynamic>.from(cards.first as Map)
      : null;
}

String exploreName(Map business) => (business['name'] ?? 'Business').toString();
String exploreCategory(Map business) => (business['category'] ?? '').toString();
int explorePunches(Map? card) =>
    (card?['punchesRequired'] as num?)?.toInt() ?? 0;
String explorePunchText(Map? card) =>
    explorePunches(card) > 0 ? '${explorePunches(card)}' : '—';
String explorePrice(Map business, Map? card) {
  final value = card?['pricePerPunch'];
  if (value == null) return 'Not set';
  final currency = card?['currency'] ?? business['currencyCode'];
  final amount = value is num && value % 1 == 0 ? value.toInt() : value;
  return '${currency == null ? '' : '$currency '}$amount';
}

String exploreAddress(Map business) {
  final locations = business['locations'];
  return locations is List && locations.isNotEmpty && locations.first is Map
      ? (locations.first['address'] ?? '').toString()
      : (business['address'] ?? '').toString();
}

String exploreInitials(Map business) =>
    exploreName(business)
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.characters.first)
        .join()
        .toUpperCase();
bool matchesExploreSearch(Map business, String query) =>
    '${exploreName(business)} ${exploreCategory(business)}'
        .toLowerCase()
        .contains(query.trim().toLowerCase());
