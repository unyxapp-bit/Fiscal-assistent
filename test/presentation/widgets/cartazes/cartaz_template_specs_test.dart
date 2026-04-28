import 'dart:io';

import 'package:fiscal_assistant/presentation/widgets/cartazes/cartaz_template_specs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
