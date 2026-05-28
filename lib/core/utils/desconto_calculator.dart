class DescontoResultado {
  final int etiquetaCentavos;
  final int sistemaCentavos;
  final int quantidade;

  const DescontoResultado({
    required this.etiquetaCentavos,
    required this.sistemaCentavos,
    required this.quantidade,
  });

  int get maiorValorCentavos =>
      etiquetaCentavos > sistemaCentavos ? etiquetaCentavos : sistemaCentavos;

  int get menorValorCentavos =>
      etiquetaCentavos < sistemaCentavos ? etiquetaCentavos : sistemaCentavos;

  int get descontoUnitarioCentavos =>
      (etiquetaCentavos - sistemaCentavos).abs();

  int get descontoTotalCentavos => descontoUnitarioCentavos * quantidade;

  int get valorFinalTotalCentavos => menorValorCentavos * quantidade;

  bool get valoresIguais => descontoUnitarioCentavos == 0;

  bool get etiquetaMaior => etiquetaCentavos > sistemaCentavos;

  bool get sistemaMaior => sistemaCentavos > etiquetaCentavos;

  double get percentualDesconto {
    if (maiorValorCentavos <= 0) return 0;
    return (descontoUnitarioCentavos / maiorValorCentavos) * 100;
  }
}

class DescontoCalculator {
  const DescontoCalculator._();

  static DescontoResultado calcular({
    required int etiquetaCentavos,
    required int sistemaCentavos,
    int quantidade = 1,
  }) {
    return DescontoResultado(
      etiquetaCentavos: etiquetaCentavos,
      sistemaCentavos: sistemaCentavos,
      quantidade: quantidade < 1 ? 1 : quantidade,
    );
  }

  static DescontoResultado calcularPorPercentual({
    required int precoBaseCentavos,
    required double percentual,
    int quantidade = 1,
  }) {
    final pct = percentual.isNaN || percentual.isInfinite ? 0.0 : percentual;
    final fator = 1 - (pct.clamp(0.0, 100.0) / 100);
    final precoFinal = (precoBaseCentavos * fator).round();
    return calcular(
      etiquetaCentavos: precoBaseCentavos,
      sistemaCentavos: precoFinal,
      quantidade: quantidade,
    );
  }

  static DescontoResultado calcularLevePague({
    required int precoUnitarioCentavos,
    required int leve,
    required int pague,
    int quantidade = 1,
  }) {
    final leveValido = leve < 1 ? 1 : leve;
    final pagueValido = pague < 0 ? 0 : pague.clamp(0, leveValido);
    return calcular(
      etiquetaCentavos: precoUnitarioCentavos * leveValido,
      sistemaCentavos: precoUnitarioCentavos * pagueValido,
      quantidade: quantidade,
    );
  }

  static int? parseMoneyToCents(String input) {
    var value = input.trim();
    if (value.isEmpty) return null;

    value = value
        .replaceAll(RegExp(r'[Rr]\$'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^0-9,.\-]'), '');

    if (value.isEmpty || value == '-' || value == ',' || value == '.') {
      return null;
    }

    final negative = value.startsWith('-');
    value = value.replaceAll('-', '');
    if (value.isEmpty) return null;

    final lastComma = value.lastIndexOf(',');
    final lastDot = value.lastIndexOf('.');
    final decimalIndex = lastComma > lastDot ? lastComma : lastDot;

    String reaisPart;
    String centsPart;

    if (decimalIndex >= 0) {
      reaisPart = value.substring(0, decimalIndex);
      centsPart = value.substring(decimalIndex + 1);
    } else {
      reaisPart = value;
      centsPart = '0';
    }

    reaisPart = reaisPart.replaceAll(RegExp(r'[^0-9]'), '');
    centsPart = centsPart.replaceAll(RegExp(r'[^0-9]'), '');

    if (reaisPart.isEmpty && centsPart.isEmpty) return null;

    final reais = int.tryParse(reaisPart.isEmpty ? '0' : reaisPart);
    if (reais == null) return null;

    final centsText = centsPart.padRight(2, '0');
    final cents = int.tryParse(centsText.substring(0, 2)) ?? 0;
    final result = reais * 100 + cents;

    return negative ? -result : result;
  }

  static int parseQuantidade(String input) {
    final parsed = int.tryParse(input.trim());
    if (parsed == null || parsed < 1) return 1;
    return parsed;
  }

  static double? parsePercent(String input) {
    var value = input.trim();
    if (value.isEmpty) return null;

    value = value
        .replaceAll('%', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^0-9,.\-]'), '');

    if (value.isEmpty || value == '-' || value == ',' || value == '.') {
      return null;
    }

    value = value.replaceAll(',', '.');
    return double.tryParse(value);
  }

  static String formatMoney(int cents) {
    final negative = cents < 0;
    final absolute = cents.abs();
    final reais = absolute ~/ 100;
    final centavos = absolute % 100;
    final reaisFormatados = _formatThousands(reais);
    final centavosFormatados = centavos.toString().padLeft(2, '0');
    final sign = negative ? '-' : '';

    return '${sign}R\$ $reaisFormatados,$centavosFormatados';
  }

  static String formatPercent(double percent) {
    return '${percent.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  static String _formatThousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}
