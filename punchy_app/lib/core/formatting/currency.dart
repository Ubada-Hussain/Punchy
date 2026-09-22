class Currency {
  const Currency._();

  static const _symbols = <String, String>{
    'PKR': '₨',
    'USD': r'$',
    'AED': 'د.إ',
    'SAR': 'ر.س',
    'QAR': 'ر.ق',
    'KWD': 'د.ك',
    'BHD': 'د.ب',
    'OMR': 'ر.ع.',
    'INR': '₹',
    'GBP': '£',
    'EUR': '€',
    'JPY': '¥',
    'CNY': '¥',
    'KRW': '₩',
    'TRY': '₺',
    'THB': '฿',
    'BDT': '৳',
    'IDR': 'Rp',
    'MYR': 'RM',
    'SGD': r'S$',
    'AUD': r'A$',
    'CAD': r'C$',
    'NZD': r'NZ$',
    'ZAR': 'R',
    'NGN': '₦',
    'EGP': 'E£',
    'BRL': r'R$',
    'MXN': r'M$',
    'CHF': 'CHF',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'PLN': 'zł',
    'RUB': '₽',
    'PHP': '₱',
    'VND': '₫',
  };

  static String symbol(dynamic code) {
    final normalized = code?.toString().toUpperCase() ?? 'PKR';
    return _symbols[normalized] ?? normalized;
  }

  static String price(dynamic code, dynamic amount) =>
      '${symbol(code)} ${amount ?? 'Not set'}';
}
