import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/punchy_skeleton.dart';

typedef _JsonMap = Map<String, dynamic>;

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _data;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.get('/subscriptions/business/current');
      if (mounted) {
        setState(() {
          _data = Map<String, dynamic>.from(data);
          _loadError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _data = {};
          _loadError = error is ApiException
              ? error.message
              : error is NetworkException
              ? error.message
              : 'Unable to load subscription details.';
        });
      }
    }
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? '—'
        : '${date.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';
  }

  String _money(dynamic value) {
    if (value == null) return '—';
    final number = value is num ? value : num.tryParse(value.toString());
    return number == null
        ? value.toString()
        : number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }

  Future<void> _makePayment(List<_JsonMap> methods, _JsonMap? pricing) async {
    if (methods.isEmpty || pricing == null) return;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) =>
          _PaymentFlow(api: _api, methods: methods, pricing: pricing),
    );
    if (submitted == true && mounted) {
      unawaited(_load());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment submitted successfully. Our team will verify your payment and activate your subscription.',
          ),
        ),
      );
    }
  }

  Future<void> _contact(String email) async {
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Punchy support contact is not available right now.'),
        ),
      );
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Alternative subscription payment'},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email app is available on this device.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = _data?['subscription'] as Map?;
    final pricing = _data?['pricing'] as Map?;
    final methods = ((_data?['paymentMethods'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final payments = ((_data?['paymentSubmissions'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final supportEmail = _data?['supportEmail']?.toString() ?? '';
    final trial = subscription?['status'] == 'TRIALING';
    final hasPricing = pricing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Subscription & Billing'),
        backgroundColor: AppColors.bg,
      ),
      body: _data == null
          ? const PunchySkeleton(rows: 3)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  if (_loadError != null)
                    _NoticeCard(message: _loadError!, onRetry: _load),
                  _statusCard(subscription, trial),
                  const SizedBox(height: 22),
                  _sectionTitle(
                    'Choose your plan',
                    'Prices use your business country and currency.',
                  ),
                  const SizedBox(height: 12),
                  if (!hasPricing)
                    _infoCard(
                      'Pricing unavailable',
                      'Ask the Punchy team to configure subscription pricing for your business country.',
                    )
                  else ...[
                    _planCard(
                      'Monthly',
                      '${pricing['currencyCode']} ${_money(pricing['monthlyPrice'])}',
                      'Billed every month',
                      Icons.calendar_month_rounded,
                    ),
                    const SizedBox(height: 10),
                    _planCard(
                      'Yearly',
                      '${pricing['currencyCode']} ${_money(pricing['yearlyPrice'])}',
                      'Billed once per year',
                      Icons.auto_awesome_rounded,
                      highlight: true,
                    ),
                  ],
                  const SizedBox(height: 22),
                  _sectionTitle(
                    'Payment methods',
                    'Choose a method to see its current payment details.',
                  ),
                  const SizedBox(height: 12),
                  if (methods.isEmpty)
                    _infoCard(
                      'Payment methods coming soon',
                      'The Punchy team has not enabled a payment method yet.',
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: methods
                          .map((method) => _PaymentMethodPill(method: method))
                          .toList(),
                    ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pay using one of the available payment methods below. International businesses can contact the Punchy team for alternative payment options.',
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      key: const Key('make_payment_button'),
                      onPressed: methods.isNotEmpty && hasPricing
                          ? () => _makePayment(
                              methods,
                              Map<String, dynamic>.from(pricing),
                            )
                          : null,
                      icon: const Icon(Icons.lock_rounded, size: 18),
                      label: const Text('Make Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'International Business?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'If these payment methods are not available in your country, contact the Punchy team for an alternative payment method.',
                          style: TextStyle(
                            color: AppColors.inkSoft,
                            height: 1.5,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _contact(supportEmail),
                          icon: const Icon(
                            Icons.mail_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Contact Punchy Team'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.tealDark,
                            side: const BorderSide(color: AppColors.line),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (payments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle(
                      'Payment history',
                      'Your recent subscription payment submissions.',
                    ),
                    const SizedBox(height: 10),
                    ...payments.map((payment) => _paymentHistoryCard(payment)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _statusCard(Map? subscription, bool trial) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      gradient: trial ? AppColors.gradTeal : AppColors.gradPurple,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.teal.withValues(alpha: .14),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            trial ? Icons.celebration_rounded : Icons.workspace_premium_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trial ? 'Your free trial' : 'Subscription status',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                trial
                    ? 'Trial ends ${_date(subscription?['trialEnd'] ?? subscription?['endDate'])}'
                    : '${subscription?['status'] ?? 'PAYMENT_PENDING'} · Ends ${_date(subscription?['endDate'])}',
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.4,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
      ),
    ],
  );

  Widget _planCard(
    String title,
    String price,
    String detail,
    IconData icon, {
    bool highlight = false,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: highlight ? AppColors.teal : AppColors.line,
        width: highlight ? 1.4 : 1,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: highlight ? AppColors.surfaceAlt : const Color(0xFFF2F2FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: highlight ? AppColors.tealDark : AppColors.purpleDark,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );

  Widget _infoCard(String title, String message) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          style: const TextStyle(
            color: AppColors.inkSoft,
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ],
    ),
  );

  Widget _paymentHistoryCard(_JsonMap payment) {
    final status = payment['status']?.toString() ?? 'PENDING';
    final color = status == 'APPROVED'
        ? AppColors.tealDark
        : status == 'REJECTED'
        ? AppColors.coralDark
        : AppColors.goldDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: AppColors.tealDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment['plan'] == 'YEARLY' ? 'Yearly' : 'Monthly'} · ${payment['currency']} ${_money(payment['amount'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  '${payment['paymentMethodName']} · Transaction ${payment['transactionId']}',
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.coralDark, fontSize: 12.5),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _PaymentMethodPill extends StatelessWidget {
  const _PaymentMethodPill({required this.method});
  final _JsonMap method;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PaymentLogo(url: method['logoUrl']?.toString(), size: 25),
        const SizedBox(width: 8),
        Text(
          method['name']?.toString() ?? '',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );
}

class _PaymentLogo extends StatelessWidget {
  const _PaymentLogo({required this.url, this.size = 42});
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(size * .28),
    ),
    child: url == null || url!.isEmpty
        ? Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.tealDark,
            size: size * .62,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(size * .2),
            child: Image.network(
              url!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.tealDark,
                size: size * .62,
              ),
            ),
          ),
  );
}

class _PaymentFlow extends StatefulWidget {
  const _PaymentFlow({
    required this.api,
    required this.methods,
    required this.pricing,
  });
  final ApiClient api;
  final List<_JsonMap> methods;
  final _JsonMap pricing;
  @override
  State<_PaymentFlow> createState() => _PaymentFlowState();
}

class _PaymentFlowState extends State<_PaymentFlow> {
  static final Random _random = Random.secure();
  late final String _clientRequestId =
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
  final _transactionController = TextEditingController();
  _JsonMap? _method;
  String _plan = 'MONTHLY';
  String? _transactionError;
  String? _requestError;
  bool _sending = false;

  String _money(dynamic value) {
    final number = value is num ? value : num.tryParse(value?.toString() ?? '');
    return number == null
        ? value?.toString() ?? '—'
        : number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }

  Future<void> _copy(String label, String? value) async {
    if (value == null || value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label copied.')));
    }
  }

  Future<void> _submit() async {
    if (_sending) return;
    final transactionId = _transactionController.text.trim();
    if (transactionId.isEmpty) {
      setState(() {
        _transactionError = 'Enter the transaction ID.';
        _requestError = null;
      });
      return;
    }
    final method = _method;
    if (method == null) return;
    setState(() {
      _sending = true;
      _transactionError = null;
      _requestError = null;
    });

    try {
      await widget.api.post('/subscriptions/payments', {
        'paymentMethodId': method['id'],
        'plan': _plan,
        'transactionId': transactionId,
        'clientRequestId': _clientRequestId,
      });
      if (!mounted) return;
      _transactionController.clear();
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _requestError = switch (error) {
          ApiException() => error.message,
          NetworkException() => error.message,
          _ => 'Could not submit your payment. Please try again.',
        };
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _method == null
                          ? 'Choose payment method'
                          : 'Payment details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (_method == null) ...[
                const Text(
                  'Select one of the currently active methods.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                ),
                const SizedBox(height: 14),
                ...widget.methods.map(
                  (method) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: InkWell(
                      onTap: () => setState(() {
                        _method = method;
                        _requestError = null;
                      }),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            _PaymentLogo(url: method['logoUrl']?.toString()),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                method['name']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
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
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    _PaymentLogo(url: _method!['logoUrl']?.toString()),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        _method!['name']?.toString() ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _sending
                          ? null
                          : () => setState(() {
                              _method = null;
                              _transactionError = null;
                              _requestError = null;
                            }),
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _PaymentDetail(
                  label: 'Account name',
                  value: _method!['accountName']?.toString(),
                ),
                _PaymentDetail(
                  label: 'Account / mobile number',
                  value: _method!['accountNumber']?.toString(),
                  copy: () => _copy(
                    'Account number',
                    _method!['accountNumber']?.toString(),
                  ),
                ),
                _PaymentDetail(
                  label: 'Bank name',
                  value: _method!['bankName']?.toString(),
                ),
                _PaymentDetail(
                  label: 'IBAN',
                  value: _method!['iban']?.toString(),
                  copy: () => _copy('IBAN', _method!['iban']?.toString()),
                ),
                if ((_method!['instructions']?.toString() ?? '').isNotEmpty)
                  _PaymentDetail(
                    label: 'Instructions',
                    value: _method!['instructions']?.toString(),
                  ),
                const SizedBox(height: 18),
                Text(
                  'Select your plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PlanChoice(
                        title: 'Monthly',
                        amount: widget.pricing['monthlyPrice'],
                        currency: widget.pricing['currencyCode'].toString(),
                        selected: _plan == 'MONTHLY',
                        money: _money,
                        onTap: () => setState(() => _plan = 'MONTHLY'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _PlanChoice(
                        title: 'Yearly',
                        amount: widget.pricing['yearlyPrice'],
                        currency: widget.pricing['currencyCode'].toString(),
                        selected: _plan == 'YEARLY',
                        money: _money,
                        onTap: () => setState(() => _plan = 'YEARLY'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _transactionController,
                  enabled: !_sending,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_transactionError != null) {
                      setState(() => _transactionError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Transaction ID',
                    hintText: 'Enter the transaction ID you received after making the payment.',
                    errorText: _transactionError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
                if (_requestError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _requestError!,
                      style: const TextStyle(
                        color: AppColors.coralDark,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _sending
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 9),
                              Text('Processing…'),
                            ],
                          )
                        : const Text('Submit Payment'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  const _PaymentDetail({required this.label, this.value, this.copy});
  final String label;
  final String? value;
  final VoidCallback? copy;
  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SelectableText(
                    value!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            if (copy != null)
              IconButton(
                tooltip: 'Copy $label',
                visualDensity: VisualDensity.compact,
                onPressed: copy,
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 17,
                  color: AppColors.tealDark,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanChoice extends StatelessWidget {
  const _PlanChoice({
    required this.title,
    required this.amount,
    required this.currency,
    required this.selected,
    required this.money,
    required this.onTap,
  });
  final String title;
  final dynamic amount;
  final String currency;
  final bool selected;
  final String Function(dynamic) money;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceAlt : AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: selected ? AppColors.teal : AppColors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.tealDark : AppColors.inkFaint,
                size: 17,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$currency ${money(amount)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    ),
  );
}
