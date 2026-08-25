import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class HardwareScannerService {
  /// Check if running on mobile device with native hardware capabilities
  static bool get isMobileDevice => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Requests camera permission and shows a design-consistent explanation if denied
  static Future<bool> requestCameraPermission(BuildContext context) async {
    if (kIsWeb) return true; // Browser handles its own media stream permission

    final status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          title: 'Camera Permission Needed',
          message: 'Punchy requires camera access to scan QR loyalty codes in-store. Please enable it in Settings.',
          onOpenSettings: () => openAppSettings(),
        );
      }
      return false;
    }
    return false;
  }

  /// Checks if NFC hardware is available on the device
  static Future<bool> isNfcAvailable() async {
    if (kIsWeb) return false;
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Starts listening for real NFC tags on supported mobile devices
  static Future<void> startNfcSession({
    required Function(String tagIdentifier) onTagDiscovered,
    required Function(String error) onError,
  }) async {
    if (kIsWeb) return;
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        onError('NFC is not supported or disabled on this device.');
        return;
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final data = tag.data;
          // Extract identifier payload
          final identifier = data['nfca']?['identifier']?.toString() ??
              data['mifare']?['identifier']?.toString() ??
              data['isodep']?['identifier']?.toString() ??
              'nfc_tag_${DateTime.now().millisecondsSinceEpoch}';

          onTagDiscovered(identifier);
        },
      );
    } catch (e) {
      onError('NFC session error: $e');
    }
  }

  /// Stops active NFC session
  static Future<void> stopNfcSession() async {
    if (kIsWeb) return;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  static void _showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onOpenSettings,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.coralDark, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.inkSoft, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(color: AppColors.inkSoft, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onOpenSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                      child: Text(
                        'Settings',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
