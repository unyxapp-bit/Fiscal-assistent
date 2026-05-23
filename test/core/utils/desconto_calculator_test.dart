import 'package:fiscal_assistant/core/utils/desconto_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DescontoCalculator', () {
    test('calcula o desconto do exemplo 16,99 para 14,99', () {
      final resultado = DescontoCalculator.calcular(
        etiquetaCentavos: DescontoCalculator.parseMoneyToCents('16,99')!,
        sistemaCentavos: DescontoCalculator.parseMoneyToCents('14,99')!,
      );

      expect(resultado.descontoUnitarioCentavos, 200);
      expect(resultado.descontoTotalCentavos, 200);
      expect(resultado.valorFinalTotalCentavos, 1499);
      expect(resultado.percentualDesconto, closeTo(11.77, 0.01));
      expect(DescontoCalculator.formatMoney(resultado.descontoUnitarioCentavos),
          'R\$ 2,00');
    });

    test('multiplica o desconto pela quantidade', () {
      final resultado = DescontoCalculator.calcular(
        etiquetaCentavos: 1699,
        sistemaCentavos: 1499,
        quantidade: 3,
      );

      expect(resultado.descontoUnitarioCentavos, 200);
      expect(resultado.descontoTotalCentavos, 600);
      expect(resultado.valorFinalTotalCentavos, 4497);
    });

    test('aceita dinheiro com virgula, ponto e milhar', () {
      expect(DescontoCalculator.parseMoneyToCents('16,99'), 1699);
      expect(DescontoCalculator.parseMoneyToCents('16.99'), 1699);
      expect(DescontoCalculator.parseMoneyToCents('R\$ 1.234,56'), 123456);
    });
  });
}
