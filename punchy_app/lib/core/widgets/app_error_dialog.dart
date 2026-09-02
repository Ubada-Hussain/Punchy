import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

String readableError(Object error) {
  final raw = error.toString();
  try { final v = jsonDecode(raw); if (v is Map && v['error'] != null) return v['error'].toString(); } catch (_) {}
  return raw.replaceFirst(RegExp(r'^ApiException:\s*\d+\s*-\s*'), '');
}

Future<void> showAppError(BuildContext context, Object error) => showDialog(
  context: context,
  barrierDismissible: true,
  builder: (_) => AlertDialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    title: Row(children: [const Icon(Icons.error_outline_rounded, color: AppColors.coralDark), const SizedBox(width: 10), Text('Something went wrong', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 17))]),
    content: Text(readableError(error), style: GoogleFonts.plusJakartaSans(color: AppColors.inkSoft, height: 1.4)),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: GoogleFonts.plusJakartaSans(color: AppColors.tealDark, fontWeight: FontWeight.w800)))],
  ),
);
