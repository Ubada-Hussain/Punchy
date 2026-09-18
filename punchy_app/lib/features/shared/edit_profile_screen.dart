import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: auth.user?['name'] ?? '');
    _phoneController = TextEditingController(text: auth.user?['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.updateProfile(
      name: name,
      phone: phone.isNotEmpty ? phone : null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Profile updated successfully! ✨',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              auth.errorMessage ?? 'Failed to update profile. Please try again.',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isBusiness = auth.user?['role'] == 'BUSINESS';

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
                    'Edit Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),

            // Form
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full name',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.inkFaint),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.inkSoft, size: 18),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            isBusiness ? 'Business Phone Number *' : 'Phone number',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (val) {
                              final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{8,20}$');
                              if (isBusiness) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Business phone number is required';
                                }
                                if (!phoneRegex.hasMatch(val.trim())) {
                                  return 'Please enter a valid phone number';
                                }
                              } else if (val != null && val.trim().isNotEmpty) {
                                if (!phoneRegex.hasMatch(val.trim())) {
                                  return 'Please enter a valid phone number';
                                }
                              }
                              return null;
                            },
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: '+1 234 567 8900',
                              hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.inkFaint),
                              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.inkSoft, size: 18),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
