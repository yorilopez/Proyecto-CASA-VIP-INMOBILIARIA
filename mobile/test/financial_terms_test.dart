import 'package:flutter_test/flutter_test.dart';
import 'package:casa_vip/financial_terms.dart';

void main() {
  test('Las cuotas y el ajuste final suman exactamente el saldo', () {
    final terms = FinancialTerms.parse('21000', '5000', '31')!;
    expect(terms.monthly, 516.12);
    expect(terms.monthlyCents * 30 + terms.lastCents, 1600000);
  });
  test('El cálculo evita errores binarios de un céntimo', () {
    final terms = FinancialTerms.parse('100.10', '33.33', '1')!;
    expect(terms.monthlyCents, 6677);
    expect(terms.lastCents, 6677);
  });
  test('Se rechazan decimales excesivos y plazos fuera de rango', () {
    expect(FinancialTerms.parse('21000', '5000.001', '24'), isNull);
    expect(FinancialTerms.parse('21000', '5000', '601'), isNull);
    expect(FinancialTerms.parse('21000', '22000', '24'), isNull);
    expect(FinancialTerms.parse('100,10', '33,33', '2')!.lastCents, 3339);
  });
}
