import 'package:flutter/material.dart';

import '../../core/loyalty/card_palette.dart';
import '../../core/loyalty/loyalty_card_surface.dart';
import '../../core/loyalty/loyalty_punch_token.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/loyalty/card_color.dart';
import 'color_picker/card_color_swatches.dart';

class CreateCardScreen extends StatefulWidget {
  final String? cardId;
  final Map<String, dynamic>? initialData;
  final ApiClient? apiClient;

  const CreateCardScreen({
    super.key,
    this.cardId,
    this.initialData,
    this.apiClient,
  });

  @override
  State<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends State<CreateCardScreen> {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  final _nameController = TextEditingController();
  final _rewardController = TextEditingController();
  final _priceController = TextEditingController(text: '350');

  int _punchesRequired = 10;
  Color _selectedColor = CardColor.parse(CardColor.presets['coral']);
  String _selectedCurrency = 'PKR';
  final List<String> _currencies = ['PKR', 'USD', 'AED', 'EUR', 'GBP'];

  bool _useQR = true;
  bool _useNFC = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isLoadingBusinessCurrency = true;
  String? _currencyError;
  DateTime _validUntil = DateTime.now().add(const Duration(days: 365));

  String get _currencySymbol =>
      const {
        'PKR': 'Rs',
        'GBP': '£',
        'AED': 'AED',
        'USD': r'$',
        'EUR': '€',
        'INR': '₹',
        'SAR': '﷼',
        'CAD': r'C$',
        'AUD': r'A$',
      }[_selectedCurrency] ??
      _selectedCurrency;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _nameController.text = data['title'] ?? 'Coffee Lovers Card';
      _rewardController.text = data['rewardDescription'] ?? '1 Free Coffee';
      _punchesRequired = data['punchesRequired'] as int? ?? 10;

      _selectedColor = CardColor.fromCard(data);

      if (data['validUntil'] != null) {
        try {
          _validUntil = DateTime.parse(data['validUntil'].toString());
        } catch (_) {}
      }

      if (data['pricePerPunch'] != null) {
        final p = data['pricePerPunch'];
        if (p is num) {
          _priceController.text = (p % 1 == 0)
              ? p.toInt().toString()
              : p.toString();
        } else {
          _priceController.text = p.toString();
        }
      }

      if (data['currency'] != null && data['currency'].toString().isNotEmpty) {
        final c = data['currency'].toString().toUpperCase();
        if (_currencies.contains(c)) {
          _selectedCurrency = c;
        } else {
          _currencies.insert(0, c);
          _selectedCurrency = c;
        }
      }
    } else {
      _nameController.text = 'Coffee Lovers Card';
      _rewardController.text = '1 Free Coffee';
    }
    _loadBusinessCurrency();
  }

  Future<void> _loadBusinessCurrency() async {
    try {
      final profile = await _api.get('/business/profile');
      String? currency;
      String? countryCode;
      if (profile is Map && profile['business'] is Map) {
        countryCode = profile['business']['countryCode']
            ?.toString()
            .toUpperCase();
        currency = profile['business']['currencyCode']
            ?.toString()
            .toUpperCase();
      }
      if (currency != null &&
          currency.isNotEmpty &&
          countryCode != null &&
          countryCode.length == 2 &&
          mounted) {
        final selectedCurrency = currency;
        setState(() {
          if (!_currencies.contains(selectedCurrency)) {
            _currencies.add(selectedCurrency);
          }
          _selectedCurrency = selectedCurrency;
          _currencyError = null;
          _isLoadingBusinessCurrency = false;
        });
      }
    } catch (_) {}
    if (mounted && _isLoadingBusinessCurrency) {
      setState(() {
        _isLoadingBusinessCurrency = false;
        _currencyError =
            'Select a valid business country before saving this card.';
      });
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil.isAfter(DateTime.now())
          ? _validUntil
          : DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _validUntil = picked);
    }
  }

  void _applyPresetDuration(int days) {
    setState(() {
      _validUntil = DateTime.now().add(Duration(days: days));
    });
  }

  void _adjustPrice(int delta) {
    int current = int.tryParse(_priceController.text.trim()) ?? 350;
    current = (current + delta).clamp(0, 100000);
    setState(() {
      _priceController.text = current.toString();
    });
  }

  Future<void> _saveCard() async {
    if (_isLoadingBusinessCurrency || _currencyError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_currencyError ?? 'Checking your business country…'),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    final priceVal = double.tryParse(_priceController.text.trim()) ?? 350.0;

    final body = {
      'title': _nameController.text.trim().isEmpty
          ? 'Coffee Lovers Card'
          : _nameController.text.trim(),
      'punchesRequired': _punchesRequired,
      'rewardDescription': _rewardController.text.trim().isEmpty
          ? '1 Free Coffee'
          : _rewardController.text.trim(),
      'validUntil': _validUntil.toIso8601String(),
      'pricePerPunch': priceVal,
      'currency': _selectedCurrency,
      'visualStyle': {
        if (widget.initialData?['visualStyle'] is Map)
          ...Map<String, dynamic>.from(
            widget.initialData!['visualStyle'] as Map,
          ),
        'primaryColor': CardColor.format(_selectedColor),
        'icon': widget.initialData?['visualStyle'] is Map
            ? (widget.initialData!['visualStyle']['icon'] ?? '☕')
            : '☕',
      },
      if (widget.cardId == null) ...{'enableQR': _useQR, 'enableNFC': _useNFC},
    };

    try {
      if (widget.cardId != null) {
        await _api.put('/business/cards/${widget.cardId}', body);
      } else {
        await _api.post('/business/cards', body);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              widget.cardId != null
                  ? '✅ Loyalty Card Updated!'
                  : '🎉 Loyalty Card Saved & Activated!',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        String msg = 'Failed to save card.';
        if (e is ApiException) {
          msg = e.message;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.coralDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              msg,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteCard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Loyalty Card?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this loyalty card? Customers will no longer be able to earn punches for it. Deleting will allow you to create a brand new card.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.inkSoft,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete Card',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && widget.cardId != null) {
      setState(() => _isDeleting = true);
      try {
        await _api.delete('/business/cards/${widget.cardId}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.ink,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(
                '🗑️ Loyalty Card deleted successfully.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
          context.pop();
        }
      } catch (err) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.coralDark,
              content: Text(
                'Failed to delete card: $err',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CardPalette.fromColor(_selectedColor);
    final isEditing = widget.cardId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar matching Reference Image 1
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 26,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Edit Loyalty Card'
                              : 'Create Loyalty Card',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Set up your card and start rewarding your customers.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEditing)
                    GestureDetector(
                      onTap: _isDeleting ? null : _deleteCard,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.coralDark.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.coralDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Scrollable Form & Live Preview
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                children: [
                  // Live Preview Card (Image 1)
                  _buildLivePreviewCard(palette),
                  const SizedBox(height: 18),

                  // 1. Card Name
                  _buildFieldLabel('Card name'),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line, width: 1.2),
                    ),
                    child: TextFormField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Coffee Lovers Card',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Card validity (Valid till)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFieldLabel('Card validity (Valid till)'),
                      Text(
                        _formatDate(_validUntil),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.tealDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line, width: 1.2),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _selectDate,
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: AppColors.tealDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Set Expiry Date: ${_formatDate(_validUntil)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.inkFaint,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.line),
                        const SizedBox(height: 10),
                        // Quick Presets
                        Row(
                          children: [
                            Expanded(
                              child: _buildDurationChip(
                                '3 Months',
                                () => _applyPresetDuration(90),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDurationChip(
                                '6 Months',
                                () => _applyPresetDuration(180),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDurationChip(
                                '1 Year',
                                () => _applyPresetDuration(365),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Punches required
                  _buildFieldLabel('Punches required'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line, width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_punchesRequired > 2) {
                              setState(() => _punchesRequired--);
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                '−',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '$_punchesRequired',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_punchesRequired < 20) {
                              setState(() => _punchesRequired++);
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Reward description
                  _buildFieldLabel('Reward description'),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line, width: 1.2),
                    ),
                    child: TextFormField(
                      controller: _rewardController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: '1 Free Coffee',
                        prefixIcon: Icon(
                          Icons.card_giftcard_rounded,
                          color: AppColors.inkSoft,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Card color theme
                  _buildFieldLabel('Card color theme'),
                  const SizedBox(height: 8),
                  CardColorSwatches(
                    color: _selectedColor,
                    cardTitle: _nameController.text.trim().isEmpty
                        ? 'Coffee Lovers Card'
                        : _nameController.text.trim(),
                    onChanged: (color) =>
                        setState(() => _selectedColor = color),
                  ),
                  const SizedBox(height: 16),

                  // 6. Punch method
                  _buildFieldLabel('Punch method'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _useQR = !_useQR),
                        child: _buildChip('QR Code', _useQR),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(() => _useNFC = !_useNFC),
                        child: _buildChip('NFC Tap', _useNFC),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 7. NEW FIELD: Price setting (per punch)
                  _buildFieldLabel('Price setting (per punch)'),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        // Currency is determined by the business signup country.
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_currencySymbol ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                _selectedCurrency,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32, color: AppColors.line),
                        const SizedBox(width: 12),

                        // Numeric Input
                        Expanded(
                          child: TextFormField(
                            key: const Key('price_setting_input'),
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                        // Up/Down Stepper Arrows
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                key: const Key('price_stepper_up'),
                                onTap: () => _adjustPrice(50),
                                behavior: HitTestBehavior.opaque,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    size: 18,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                key: const Key('price_stepper_down'),
                                onTap: () => _adjustPrice(-50),
                                behavior: HitTestBehavior.opaque,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Helper/info text box
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5F1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFCCE8DF),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.tealDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Customers will get a punch when they spend more than this amount.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tealDark,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save & Activate Button matching Image 1
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.tealDark,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tealDark.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSaving ? null : _saveCard,
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.edit_note_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEditing
                                          ? 'Save Changes'
                                          : 'Save & Activate',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.inkSoft,
      ),
    );
  }

  Widget _buildLivePreviewCard(CardPalette palette) {
    final title = _nameController.text.trim().isEmpty
        ? 'Coffee Lovers Card'
        : _nameController.text.trim();
    final count = _punchesRequired.clamp(1, 10);
    return LoyaltyCardSurface(
      key: const Key('business_card_live_preview'),
      palette: palette,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.overlay,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.coffee_rounded,
                  color: palette.text,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                    ),
                    Text(
                      'Live preview',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: palette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: palette.overlay,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Valid till ${_formatDate(_validUntil)}',
              style: TextStyle(
                fontSize: 11,
                color: palette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: palette.emptyToken),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              count,
              (i) => LoyaltyPunchToken(
                palette: palette,
                size: 28,
                filled: i == 0,
                number: i + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.tealDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isOn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isOn ? AppColors.tealDark : const Color(0xFFEFF4F1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isOn ? AppColors.tealDark : AppColors.line),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: isOn ? Colors.white : AppColors.inkSoft,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rewardController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
