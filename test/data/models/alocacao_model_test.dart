import 'package:flutter_test/flutter_test.dart';
import 'package:fiscal_assistant/data/models/alocacao_model.dart';

void main() {
  group('AlocacaoModel.fromJson', () {
    test('preserva horario local ao ler timestamps com offset UTC', () {
      final model = AlocacaoModel.fromJson(const {
        'id': 'aloc-1',
        'colaborador_id': 'colab-1',
        'caixa_id': 'caixa-1',
        'alocado_em': '2026-04-07T07:40:00+00:00',
        'created_at': '2026-04-07T07:40:00+00:00',
        'status': 'ativo',
      });

      expect(model.alocadoEm.isUtc, isFalse);
      expect(model.alocadoEm.hour, 7);
      expect(model.alocadoEm.minute, 40);
      expect(model.createdAt.hour, 7);
      expect(model.createdAt.minute, 40);
    });

    test('mantem horarios locais sem offset inalterados', () {
      final model = AlocacaoModel.fromJson(const {
        'id': 'aloc-2',
        'colaborador_id': 'colab-2',
        'caixa_id': 'caixa-2',
        'alocado_em': '2026-04-07T08:15:00',
        'created_at': '2026-04-07T08:15:00',
        'status': 'ativo',
      });

      expect(model.alocadoEm.isUtc, isFalse);
      expect(model.alocadoEm.hour, 8);
      expect(model.alocadoEm.minute, 15);
    });
  });
}
