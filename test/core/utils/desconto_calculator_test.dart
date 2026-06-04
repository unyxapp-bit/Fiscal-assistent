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

    test('calcula desconto por percentual', () {
      final resultado = DescontoCalculator.calcularPorPercentual(
        precoBaseCentavos: 2000,
        percentual: 15,
        quantidade: 2,
      );

      expect(resultado.sistemaCentavos, 1700);
      expect(resultado.descontoUnitarioCentavos, 300);
      expect(resultado.descontoTotalCentavos, 600);
      expect(resultado.valorFinalTotalCentavos, 3400);
    });

    test('calcula promocao leve e pague', () {
      final resultado = DescontoCalculator.calcularLevePague(
        precoUnitarioCentavos: 1000,
        leve: 3,
        pague: 2,
      );

      expect(resultado.etiquetaCentavos, 3000);
      expect(resultado.sistemaCentavos, 2000);
      expect(resultado.descontoUnitarioCentavos, 1000);
    });

    test('aceita percentual com virgula e simbolo', () {
      expect(DescontoCalculator.parsePercent('12,5%'), 12.5);
      expect(DescontoCalculator.parsePercent('7.25'), 7.25);
      expect(DescontoCalculator.parsePercent('abc'), isNull);
    });

    test('calcula troca de moedas por valor em cada denominacao', () {
      final resultado = DescontoCalculator.calcularTrocaMoedas(
        valor005Centavos: DescontoCalculator.parseMoneyToCents('14,05')!,
        valor010Centavos: DescontoCalculator.parseMoneyToCents('0,00')!,
        valor025Centavos: DescontoCalculator.parseMoneyToCents('12.50')!,
        valor050Centavos: DescontoCalculator.parseMoneyToCents('0,00')!,
      );

      expect(resultado.valorGrupo10Centavos, 1405);
      expect(resultado.bonusGrupo10Centavos, 141);
      expect(resultado.valorGrupo5Centavos, 1250);
      expect(resultado.bonusGrupo5Centavos, 63);
      expect(resultado.valorTotalMoedasCentavos, 2655);
      expect(resultado.totalPorcentagensCentavos, 204);
      expect(resultado.totalComPorcentagemCentavos, 2859);

      final historico = resultado.toDescontoResultado();
      expect(historico.etiquetaCentavos, 2655);
      expect(historico.sistemaCentavos, 2859);
      expect(historico.descontoTotalCentavos, 204);
      expect(historico.valorFinalTotalCentavos, 2859);
    });
  });
}
