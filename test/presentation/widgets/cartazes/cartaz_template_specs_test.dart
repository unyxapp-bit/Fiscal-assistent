import 'dart:io';

import 'package:fiscal_assistant/data/models/cartaz_form_data.dart';
import 'package:fiscal_assistant/presentation/widgets/cartazes/cartaz_price_text.dart';
import 'package:fiscal_assistant/presentation/widgets/cartazes/cartaz_template_specs.dart';
import 'package:fiscal_assistant/presentation/widgets/cartazes/poster_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('todos os tipos de cartaz ativos possuem especificacao', () {
    final tiposComSpec = cartazTemplateSpecs.map((spec) => spec.tipo).toSet();

    expect(tiposComSpec, containsAll(CartazTemplateTipo.values));
    expect(tiposComSpec.length, cartazTemplateSpecs.length);
  });

  test('templates ativos apontam para assets existentes', () {
    for (final spec in cartazTemplateSpecs) {
      expect(spec.title.trim(), isNotEmpty);
      expect(spec.description.trim(), isNotEmpty);
      expect(
        File(spec.asset.path).existsSync(),
        isTrue,
        reason: 'Asset ausente para ${spec.title}: ${spec.asset.path}',
      );
    }
  });

  testWidgets('super oferta renderiza com textos do formulario',
      (tester) async {
    const data = CartazFormData(
      tipo: CartazTemplateTipo.superOferta,
      tamanho: CartazTamanho.a6,
      tituloLinha1: 'Arroz Tio Joao',
      tituloLinha2: 'Tipo 1',
      subtitulo: '5KG',
      detalhe: 'Cada unidade',
      preco: 'R\$ 19,99',
      unidade: 'UNID',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: buildPosterWidget(data),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('ARROZ TIO JOAO'), findsOneWidget);
    expect(find.text('19,99'), findsWidgets);

    final currencyRect = tester.getRect(find.text('R\$').first);
    final priceRect = tester.getRect(find.text('19,99').first);
    expect(currencyRect.right, lessThan(priceRect.left));
  });

  testWidgets('centavos menores ocupam a metade superior do preco',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: CartazPriceText(
            text: '19,99',
            centavosMenores: true,
            style: TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );

    final reaisRect = tester.getRect(find.text('19'));
    final centavosRect = tester.getRect(find.text(',99'));

    expect(centavosRect.top, closeTo(reaisRect.top, 0.5));
    expect(centavosRect.bottom, lessThanOrEqualTo(reaisRect.center.dy));
  });
}
