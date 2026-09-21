enum CurrencyCode { ghs, usd }

CurrencyCode currencyCodeFromApi(String? raw) {
  if (raw == 'USD') return CurrencyCode.usd;
  return CurrencyCode.ghs;
}

String currencySymbol(CurrencyCode currency) {
  return currency == CurrencyCode.usd ? '\$' : 'GH₵';
}

String formatMoneyMajor(double major, CurrencyCode currency) {
  final fixed = major.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) {
      buf.write(',');
    }
    buf.write(intPart[i]);
  }
  return '${currencySymbol(currency)}${buf}.${parts[1]}';
}
