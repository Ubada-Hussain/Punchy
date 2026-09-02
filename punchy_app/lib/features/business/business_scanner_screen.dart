import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'dart:async';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/hardware_scanner_service.dart';

class BusinessScannerScreen extends StatefulWidget {
  const BusinessScannerScreen({super.key});

  @override
  State<BusinessScannerScreen> createState() => _BusinessScannerScreenState();
}

class _BusinessScannerScreenState extends State<BusinessScannerScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  final MobileScannerController _scannerController = MobileScannerController(autoStart: false);
  final TextEditingController _manualInputController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _scanAnimation;
  bool _isProcessing = false;
  final ValueNotifier<int> _cooldownRemaining = ValueNotifier<int>(0);
  Timer? _cooldownTimer;

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
    if (HardwareScannerService.isMobileDevice && mounted) {
      final granted = await HardwareScannerService.requestCameraPermission(context);
      if (granted && mounted) {
        await _scannerController.start();
      }
    }
  }

  Future<void> _processCustomerPunch(String customerIdentifier) async {
    if (_isProcessing) return;
    await _scannerController.stop();
    setState(() => _isProcessing = true);

    try {
      final res = await _api.post('/business/punch', {
        'customerIdentifier': _normalizeCustomerIdentifier(customerIdentifier),
      });

      if (mounted) {
        await _scannerController.stop();
        _showSuccessSheet(
          customerEmail: res['customerEmail'] ?? customerIdentifier,
          punchCount: res['punchCount'] as int? ?? 1,
          punchesRequired: res['punchesRequired'] as int? ?? 10,
          isCompleted: res['isCompleted'] == true,
          cardTitle: res['cardTitle'] ?? 'Loyalty Card',
          message: res['message'],
        );
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.statusCode == 429) {
          final seconds = (e.details?['remainingSeconds'] as num?)?.toInt() ?? 180;
          _showCooldown(seconds);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Could not record punch.')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showCooldown(int initialSeconds) {
    showDialog<void>(context: context, builder: (dialogContext) {
      var remaining = initialSeconds;
      Timer? timer;
      return StatefulBuilder(builder: (context, setState) {
        timer ??= Timer.periodic(const Duration(seconds: 1), (_) { if (remaining > 0) setState(() => remaining--); else { timer?.cancel(); Navigator.of(dialogContext).pop(); } });
        final m = remaining ~/ 60, s = remaining % 60;
        return AlertDialog(title: const Text('Punch cooldown'), content: Text('This customer already punched this card. Try again in $m:${s.toString().padLeft(2, '0')}'), actions: [TextButton(onPressed: () { timer?.cancel(); Navigator.of(dialogContext).pop(); }, child: const Text('OK'))]);
      });
    });
  }

  String _normalizeCustomerIdentifier(String value) {
    final text = value.trim();
    if (text.startsWith('{')) {
      try {
        final json = jsonDecode(text);
        for (final key in ['customerId', 'userId', 'id', 'email']) {
          if (json[key] is String && (json[key] as String).trim().isNotEmpty) return (json[key] as String).trim();
        }
      } catch (_) {}
    }
    return text;
  }

  Future<void> _processScan(String value) async {
    await _scannerController.stop();
    _processCustomerPunch(value);
  }

  void _showSuccessSheet({
    required String customerEmail,
    required int punchCount,
    required int punchesRequired,
    required bool isCompleted,
    required String cardTitle,
    String? message,
  }) {
    _cooldownTimer?.cancel();
    _cooldownRemaining.value = 180;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_cooldownRemaining.value > 0) _cooldownRemaining.value--;
    });
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Success Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (isCompleted ? AppColors.coral : AppColors.teal).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isCompleted ? Icons.celebration_rounded : Icons.check_circle_rounded,
                    color: isCompleted ? AppColors.coralDark : AppColors.tealDark,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                message ?? (isCompleted ? '🎉 Card Completed — reward ready' : 'Punch Added Successfully! ☕'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$customerEmail • $cardTitle',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),

              ValueListenableBuilder<int>(
                valueListenable: _cooldownRemaining,
                builder: (_, seconds, __) => Text(
                  'Next punch available in ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.coralDark),
                ),
              ),
              const SizedBox(height: 12),

              // Punch Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer Progress',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                    ),
                    Text(
                      isCompleted ? 'COMPLETE ($punchCount/$punchesRequired)' : '$punchCount of $punchesRequired punches',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isCompleted ? AppColors.coralDark : AppColors.tealDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Done / Next Scan Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Done / Back to Dashboard',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _cooldownRemaining.dispose();
    _animController.dispose();
    _scannerController.dispose();
    _manualInputController.dispose();
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
                    'Scan Customer Barcode',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Viewfinder Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (HardwareScannerService.isMobileDevice)
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              if (barcode.rawValue != null) {
                                _processScan(barcode.rawValue!);
                                break;
                              }
                            }
                          },
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF14201C),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 100,
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Merchant Barcode Scanner',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Corner Gold Brackets
                      Positioned(top: 24, left: 24, child: _buildCorner(isTop: true, isLeft: true)),
                      Positioned(top: 24, right: 24, child: _buildCorner(isTop: true, isLeft: false)),
                      Positioned(bottom: 24, left: 24, child: _buildCorner(isTop: false, isLeft: true)),
                      Positioned(bottom: 24, right: 24, child: _buildCorner(isTop: false, isLeft: false)),

                      // Gold Laser Line
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 240 * _scanAnimation.value,
                            child: Container(
                              width: 220,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: AppColors.teal,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.teal.withValues(alpha: 0.9),
                                    blurRadius: 14,
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
                ),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'Align the customer’s phone barcode inside the box',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),

            // Quick Simulate / Manual Customer Email Entry for Testing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualInputController,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 13),
                        cursorColor: AppColors.teal,
                        decoration: InputDecoration(
                          hintText: 'Or enter customer email...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.ink.withValues(alpha: 0.45), fontSize: 12.5),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              final text = _manualInputController.text.trim();
                              if (text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the customer email or ID first.'))); return; }
                              _processScan(text);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: _isProcessing
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Add Punch', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

            // Simulate Scan Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () {
                    final text = _manualInputController.text.trim();
                    if (text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the customer email or ID first.'))); return; }
                    _processScan(text);
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                  label: Text('Simulate Customer Barcode Scan', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: AppColors.teal, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: AppColors.teal, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: AppColors.teal, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: AppColors.teal, width: 3) : BorderSide.none,
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
}
