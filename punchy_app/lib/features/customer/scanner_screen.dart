import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/hardware_scanner_service.dart';
import '../../core/services/notification_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  final MobileScannerController _scannerController = MobileScannerController();

  late AnimationController _animController;
  late Animation<double> _scanAnimation;
  int _modeIndex = 0; // 0 = QR, 1 = NFC
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _initHardware();
  }

  Future<void> _initHardware() async {
    if (_modeIndex == 0 && HardwareScannerService.isMobileDevice) {
      if (mounted) {
        await HardwareScannerService.requestCameraPermission(context);
      }
    } else if (_modeIndex == 1 && HardwareScannerService.isMobileDevice) {
      _startNfcListening();
    }
  }

  void _startNfcListening() {
    HardwareScannerService.startNfcSession(
      onTagDiscovered: (tagId) {
        _processPunch(tagId, 'NFC Tap');
      },
      onError: (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.ink,
              content: Text(err, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            ),
          );
        }
      },
    );
  }

  Future<void> _processPunch(String identifier, String method) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final res = await _api.post('/punch', {'identifier': identifier});
      final msg = res['message'] ?? 'Punch recorded! 🎉';

      if (mounted) {
        await NotificationService().showInAppNotification(
          context,
          title: 'Punch Added! ☕',
          message: msg,
        );
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
        context.pop();
      }
    } catch (_) {
      // Offline / Simulation fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 22),
                const SizedBox(width: 10),
                Text(
                  '$method punch recorded! 🎉',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    HardwareScannerService.stopNfcSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1210),
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
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  Text(
                    'Add a punch',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Segmented Switcher (Scan QR / Tap NFC)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildSegButton(0, 'Scan QR')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildSegButton(1, 'Tap NFC')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Main Viewfinder or NFC Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _modeIndex == 0 ? _buildQRViewfinder() : _buildNFCPulse(),
              ),
            ),
            const SizedBox(height: 16),

            // Subtitle Guidance
            Text(
              _modeIndex == 0
                  ? 'Point camera at store QR code or tap simulate'
                  : 'Hold phone near the counter NFC reader',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),

            // Simulation Fallback Button (Web / Local testing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: _modeIndex == 0 ? AppColors.gradCoral : AppColors.gradPurple,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_modeIndex == 0 ? AppColors.coral : AppColors.purple).withValues(alpha: 0.5),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isProcessing
                        ? null
                        : () => _processPunch('c3f4e1a0-9b8a-4e2b-8a1c-5d9e7f1a2b3c', _modeIndex == 0 ? 'QR Code' : 'NFC Tag'),
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _modeIndex == 0 ? Icons.qr_code_scanner_rounded : Icons.nfc_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _modeIndex == 0 ? 'Simulate QR Punch' : 'Simulate NFC Tap',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRViewfinder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Live camera preview when on mobile or web fallback placeholder
          if (HardwareScannerService.isMobileDevice)
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _processPunch(barcode.rawValue!, 'Camera QR');
                    break;
                  }
                }
              },
            )
          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF14201C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 110,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),

          // Corner Brackets (Gold)
          Positioned(top: 24, left: 24, child: _buildCorner(isTop: true, isLeft: true)),
          Positioned(top: 24, right: 24, child: _buildCorner(isTop: true, isLeft: false)),
          Positioned(bottom: 24, left: 24, child: _buildCorner(isTop: false, isLeft: true)),
          Positioned(bottom: 24, right: 24, child: _buildCorner(isTop: false, isLeft: false)),

          // Animated Gold Laser Line
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Positioned(
                top: 220 * _scanAnimation.value,
                child: Container(
                  width: 200,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.8),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: AppColors.gold, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: AppColors.gold, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: AppColors.gold, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: AppColors.gold, width: 3) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(8) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(8) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(8) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildNFCPulse() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.25), width: 2),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.45), width: 2),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: AppColors.gradPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nfc_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildSegButton(int index, String label) {
    final isSelected = _modeIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _modeIndex = index);
        _initHardware();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.ink : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
