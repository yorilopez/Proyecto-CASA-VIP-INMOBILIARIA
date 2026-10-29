/// Cálculo en céntimos enteros, equivalente al cálculo decimal del servidor.
class FinancialTerms {
  final int priceCents, initialCents, count;
  const FinancialTerms(this.priceCents, this.initialCents, this.count);
  static int? cents(String text) {
    final value = text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(value)) return null;
    final parts = value.split('.');
    final whole = int.tryParse(parts[0]);
    if (whole == null || whole > 999999999999) return null;
    return whole * 100 +
        int.parse(parts.length == 1 ? '00' : parts[1].padRight(2, '0'));
  }

  static FinancialTerms? parse(String price, String initial, String count) {
    final p = cents(price), i = cents(initial), n = int.tryParse(count);
    if (p == null ||
        i == null ||
        n == null ||
        p <= 0 ||
        i <= 0 ||
        i > p ||
        n < 1 ||
        n > 600)
      return null;
    return FinancialTerms(p, i, n);
  }

  int get monthlyCents => (priceCents - initialCents) ~/ count;
  int get lastCents => priceCents - initialCents - monthlyCents * (count - 1);
  num get monthly => monthlyCents / 100;
  num get last => lastCents / 100;
}
