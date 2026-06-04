import 'package:flutter_test/flutter_test.dart';
import 'package:fiscal_assistant/data/services/entrega_cupom_ai_service.dart';

void main() {
  group('EntregaCupomDraft', () {
    test('normaliza payload da IA para rascunho de entrega', () {
      final draft = EntregaCupomDraft.fromMap({
        'numero_nota': '320939',
        'cliente_nome': 'YASMIN CRISTINA DA SILVA',
        'telefone': '(35) 99973-4860',
        'endereco': 'CORONEL VICENTE SEIXAS, 1698',
        'bairro': 'PALMEIRA',
        'cidade': 'BAEPENDI',
        'horario_marcado': '14:30',
        'observacoes': 'Manuscrito: 1 fria',
        'confidence': '0,82',
      });

      expect(draft.canCreate, isTrue);
      expect(draft.cidade, 'Baependi');
      expect(draft.horarioMarcado?.hour, 14);
      expect(draft.horarioMarcado?.minute, 30);
      expect(draft.confidence, 0.82);
      expect(draft.observacoesParaSalvar(), contains('Manuscrito: 1 fria'));
    });

    test('informa campos obrigatorios pendentes', () {
      final draft = EntregaCupomDraft.fromMap({
        'cliente_nome': 'Cliente Teste',
        'cidade': 'Baependi',
      });

      expect(draft.canCreate, isFalse);
      expect(
        draft.requiredMissingFields,
        containsAll(['numero da nota', 'endereco', 'bairro']),
      );
    });
  });
}
