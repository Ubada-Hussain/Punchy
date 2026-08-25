import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Brew & Co. Artisanal Coffee');
  final _descController = TextEditingController(text: 'Specialty coffee roastery, handcrafted drinks, and bakery.');
  final _websiteController = TextEditingController(text: 'https://brewandco.coffee');
  final _addressController = TextEditingController(text: '142 Market Street, Downtown');

  String _selectedCategory = 'Cafe & Bakery';
  bool _enableQR = true;
  bool _enableNFC = true;
  bool _isSaving = false;

  final List<String> _categories = [
    'Cafe & Bakery',
    'Salon & Spa',
    'Fitness & Gym',
    'Restaurant & Dining',
    'Retail & Boutique',
    'Auto & Car Care',
  ];

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await _api.post('/business/setup', {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'description': _descController.text.trim(),
        'website': _websiteController.text.trim(),
        'address': _addressController.text.trim(),
        'enableQR': _enableQR,
        'enableNFC': _enableNFC,
      });
    } catch (_) {}

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Business Profile Setup Completed! 🎉',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      context.go('/business');
    }
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
                    'Business Setup',
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

            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  children: [
                    // Logo Picker
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.line, width: 2),
                            ),
                            child: const Center(
                              child: Text('☕', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: AppColors.teal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Business Name
                    Text(
                      'Business Name',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v == null || v.isEmpty ? 'Business name is required' : null,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(hintText: 'e.g. Brew & Co.'),
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    Text(
                      'Business Category',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.inkSoft),
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Short Description',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(hintText: 'What makes your business special?'),
                    ),
                    const SizedBox(height: 16),

                    // Address / Location
                    Text(
                      'Store Address / Location',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressController,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 142 Market Street',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 18, color: AppColors.inkFaint),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Punch Method Hardware Setup
                    Text(
                      'Punch Hardware & Verification',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            title: Text(
                              'Counter QR Code Display',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                            subtitle: Text(
                              'Auto-generates print-ready counter QR standee',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.inkSoft),
                            ),
                            value: _enableQR,
                            activeTrackColor: AppColors.teal,
                            activeThumbColor: Colors.white,
                            onChanged: (v) => setState(() => _enableQR = v),
                          ),
                          const Divider(height: 1, color: AppColors.line),
                          SwitchListTile.adaptive(
                            title: Text(
                              'NFC Tap Tag Integration',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                            subtitle: Text(
                              'Enable fast phone-tap punches via NFC tags',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.inkSoft),
                            ),
                            value: _enableNFC,
                            activeTrackColor: AppColors.teal,
                            activeThumbColor: Colors.white,
                            onChanged: (v) => setState(() => _enableNFC = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Continue Button
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSaving ? null : _handleSave,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Save & Continue to Dashboard',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
