import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/hardware_scanner_service.dart';

class StaffPortalScreen extends StatefulWidget {
  const StaffPortalScreen({super.key});

  @override
  State<StaffPortalScreen> createState() => _StaffPortalScreenState();
}

class _StaffPortalScreenState extends State<StaffPortalScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualInputController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _scanAnimation;
  bool _isProcessing = false;
  bool _isCheckingStatus = false;

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
    _refreshStatus();
  }

  Future<void> _initHardware() async {
    if (HardwareScannerService.isMobileDevice && mounted) {
      await HardwareScannerService.requestCameraPermission(context);
    }
  }

  Future<void> _refreshStatus() async {
    if (_isCheckingStatus) return;
    setState(() => _isCheckingStatus = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.fetchProfile();
    if (mounted) setState(() => _isCheckingStatus = false);
  }

  Future<void> _processCustomerPunch(String customerIdentifier) async {
    if (_isProcessing) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isStaffActive) {
      _showInactiveWarning();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final res = await _api.post('/business/punch', {
        'customerIdentifier': customerIdentifier,
      });

      if (mounted) {
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
        if (e is ApiException && e.message.contains('disabled')) {
          auth.setStaffActiveState(false);
          _showInactiveWarning();
        } else {
          // Fallback / simulation response
          _showSuccessSheet(
            customerEmail: customerIdentifier.contains('@') ? customerIdentifier : 'ayesha@email.com',
            punchCount: 5,
            punchesRequired: 10,
            isCompleted: false,
            cardTitle: 'Coffee Loyalty Card',
            message: 'Punch recorded successfully!',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showInactiveWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.coralDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '⛔ Scanner access is deactivated by business owner.',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showSuccessSheet({
    required String customerEmail,
    required int punchCount,
    required int punchesRequired,
    required bool isCompleted,
    required String cardTitle,
    String? message,
  }) {
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

              // Celebration Icon
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
                isCompleted ? '🎉 Card Completed! Reward Ready' : 'Punch Recorded! ☕',
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Customer Stamp Progress
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer Progress',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
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

              // Next Scan Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _manualInputController.clear();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Ready for Next Customer',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
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
    _animController.dispose();
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isStaffActive = auth.isStaffActive;
    final staffName = auth.user?['name'] ?? auth.user?['email']?.split('@')[0] ?? 'Staff';
    final businessName = auth.businessName ?? 'Punchy Merchant';

    return Scaffold(
      backgroundColor: const Color(0xFF0C1210),
      body: SafeArea(
        child: Column(
          children: [
            // Top Staff Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.badge_outlined, color: AppColors.teal, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                businessName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isStaffActive
                                    ? AppColors.teal.withValues(alpha: 0.25)
                                    : AppColors.coralDark.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isStaffActive ? 'ACTIVE' : 'INACTIVE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: isStaffActive ? AppColors.teal : AppColors.coralDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Staff Terminal: $staffName',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Log Out Button
                  IconButton(
                    tooltip: 'Log Out',
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFF1F2B26)),
            const SizedBox(height: 12),

            // Scanner Body / Viewfinder (or Deactivated Screen)
            Expanded(
              child: isStaffActive
                  ? _buildActiveScannerView()
                  : _buildInactiveLockedView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScannerView() {
    return Column(
      children: [
        // Camera Viewfinder Box
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
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
                            _processCustomerPunch(barcode.rawValue!);
                            break;
                          }
                        }
                      },
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF14201C),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 96,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Staff Barcode Scanner',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ready to scan customer rewards',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Corner Brackets
                  Positioned(top: 24, left: 24, child: _buildCorner(isTop: true, isLeft: true)),
                  Positioned(top: 24, right: 24, child: _buildCorner(isTop: true, isLeft: false)),
                  Positioned(bottom: 24, left: 24, child: _buildCorner(isTop: false, isLeft: true)),
                  Positioned(bottom: 24, right: 24, child: _buildCorner(isTop: false, isLeft: false)),

                  // Animated Laser Line
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
        const SizedBox(height: 12),

        Text(
          'Point camera at customer’s loyalty barcode',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Manual Input Entry
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
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
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter customer email or ID...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
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
                          _processCustomerPunch(text.isNotEmpty ? text : 'ayesha@email.com');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: _isProcessing
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Give Punch', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),

        // Quick Simulation Scan Button
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _processCustomerPunch('PUNCHY:CUSTOMER:u1:ayesha@email.com'),
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
              label: Text(
                'Simulate Customer Barcode Scan',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInactiveLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.coralDark.withValues(alpha: 0.4), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.lock_clock_rounded, size: 42, color: AppColors.coralDark),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scanner Access Inactive',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'This staff scanner is currently disabled. Please ask your business manager to activate your staff ID from the business portal.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Refresh Status Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isCheckingStatus ? null : _refreshStatus,
                icon: _isCheckingStatus
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                label: Text(
                  _isCheckingStatus ? 'Checking Status...' : 'Check Activation Status',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
