import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/punchy_empty_state.dart';

class BusinessStaffScreen extends StatefulWidget {
  const BusinessStaffScreen({super.key});

  @override
  State<BusinessStaffScreen> createState() => _BusinessStaffScreenState();
}

class _BusinessStaffScreenState extends State<BusinessStaffScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _staffList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/business/staff');
      if (res is List && mounted) {
        setState(() {
          _staffList = res;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback if offline
    if (mounted) {
      setState(() {
        _staffList = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStaffActive(String staffId, int index) async {
    final currentStatus = _staffList[index]['isStaffActive'] == true;
    setState(() {
      _staffList[index]['isStaffActive'] = !currentStatus;
    });

    try {
      final res = await _api.patch('/business/staff/$staffId/toggle-active', {});
      if (res != null && res['staff'] != null && mounted) {
        setState(() {
          _staffList[index] = res['staff'];
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              !currentStatus
                  ? '✅ Staff scanner activated!'
                  : '🔒 Staff scanner paused & deactivated.',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (_) {
      // Revert if error
      if (mounted) {
        setState(() {
          _staffList[index]['isStaffActive'] = currentStatus;
        });
      }
    }
  }

  Future<void> _deleteStaff(String staffId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Staff Account?',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        content: Text(
          'This staff member will be removed permanently and won’t be able to scan barcodes.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.inkSoft, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.delete('/business/staff/$staffId');
        await _fetchStaff();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.ink,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Text(
                'Staff account removed.',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
      } catch (_) {}
    }
  }

  void _showAddStaffModal() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'Staff1234!');
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.tealDark, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Add Staff Scanner Account',
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Name
                        Text('Staff Name', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nameCtrl,
                          validator: (v) => v == null || v.trim().length < 2 ? 'Please enter a name' : null,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.ink),
                          decoration: const InputDecoration(hintText: 'e.g. Sarah Connor'),
                        ),
                        const SizedBox(height: 14),

                        // Email
                        Text('Staff Login Email', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: emailCtrl,
                          validator: (v) => v == null || !v.contains('@') ? 'Please enter a valid email' : null,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.ink),
                          decoration: const InputDecoration(hintText: 'e.g. sarah@mycafe.com'),
                        ),
                        const SizedBox(height: 14),

                        // Password
                        Text('Initial Password', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: passCtrl,
                          validator: (v) => v == null || v.length < 6 ? 'Password must be 6+ chars' : null,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.ink),
                          decoration: const InputDecoration(hintText: 'Min 6 characters'),
                        ),
                        const SizedBox(height: 14),

                        // Phone
                        Text('Phone (Optional)', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: phoneCtrl,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.ink),
                          decoration: const InputDecoration(hintText: '+1 234 567 8900'),
                        ),
                        const SizedBox(height: 22),

                        // Submit
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      setModalState(() => isSubmitting = true);
                                      try {
                                        await _api.post('/business/staff', {
                                          'name': nameCtrl.text.trim(),
                                          'email': emailCtrl.text.trim(),
                                          'password': passCtrl.text,
                                          if (phoneCtrl.text.isNotEmpty) 'phone': phoneCtrl.text.trim(),
                                        });
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        await _fetchStaff();
                                      } catch (err) {
                                        setModalState(() => isSubmitting = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: AppColors.coralDark,
                                              content: Text('Failed: $err', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text('Create Staff Account', style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'Staff & Terminals',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  GestureDetector(
                    onTap: _showAddStaffModal,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Explainer Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.tealDark, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Staff accounts only have access to the scanner. Toggle the switch to instantly enable or disable their scanning permissions.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Staff List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : _staffList.isEmpty
                      ? Center(
                          child: PunchyEmptyState(
                            icon: Icons.badge_outlined,
                            heading: 'No Staff Accounts Yet',
                            subtext: 'Add staff members to let your employees scan customer barcodes on their phones.',
                            actionLabel: '+ Add First Staff Member',
                            onAction: _showAddStaffModal,
                            iconColor: AppColors.tealDark,
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.teal,
                          onRefresh: _fetchStaff,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            itemCount: _staffList.length,
                            itemBuilder: (context, index) {
                              final staff = _staffList[index];
                              final isActive = staff['isStaffActive'] == true;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.line),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.teal.withValues(alpha: 0.12)
                                            : Colors.grey.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          (staff['name'] ?? 'S')[0].toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: isActive ? AppColors.tealDark : AppColors.inkFaint,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  staff['name'] ?? 'Staff Member',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.ink,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? AppColors.teal.withValues(alpha: 0.15)
                                                      : AppColors.coralDark.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isActive ? 'SCANNER ACTIVE' : 'SCANNER LOCKED',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: isActive ? AppColors.tealDark : AppColors.coralDark,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            staff['email'] ?? '',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.inkSoft,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Switch Toggle
                                    Switch.adaptive(
                                      value: isActive,
                                      activeThumbColor: AppColors.teal,
                                      onChanged: (val) => _toggleStaffActive(staff['id'], index),
                                    ),

                                    // Delete Button
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coralDark, size: 18),
                                      onPressed: () => _deleteStaff(staff['id']),
                                      tooltip: 'Delete Staff',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
