import 'dart:async';

import 'package:fiscal_assistant/data/repositories/alocacao_repository.dart';
import 'package:fiscal_assistant/data/repositories/caixa_repository.dart';
import 'package:fiscal_assistant/data/repositories/colaborador_repository.dart';
import 'package:fiscal_assistant/domain/entities/alocacao.dart';
import 'package:fiscal_assistant/domain/usecases/alocar_colaborador.dart';
import 'package:fiscal_assistant/domain/usecases/get_alocacoes_ativas.dart';
import 'package:fiscal_assistant/domain/usecases/liberar_alocacao.dart';
import 'package:fiscal_assistant/presentation/providers/alocacao_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlocacaoProvider.watchAlocacoes', () {
    test('reaproveita a assinatura ao observar o mesmo fiscal', () async {
      final repository = _WatchAlocacaoRepository();
      final provider = _buildProvider(repository);
      addTearDown(() async {
        provider.dispose();
        await repository.close();
      });

      provider.watchAlocacoes('fiscal-1');
      provider.watchAlocacoes('fiscal-1');

      expect(repository.watchCalls, ['fiscal-1']);
    });

    test('cancela a assinatura ao trocar fiscal e ao descartar provider',
        () async {
      final repository = _WatchAlocacaoRepository();
      final provider = _buildProvider(repository);
      addTearDown(repository.close);

      provider.watchAlocacoes('fiscal-1');
      provider.watchAlocacoes('fiscal-2');
      await Future<void>.delayed(Duration.zero);

      expect(repository.watchCalls, ['fiscal-1', 'fiscal-2']);
      expect(repository.cancelledFiscalIds, contains('fiscal-1'));

      provider.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(repository.cancelledFiscalIds, contains('fiscal-2'));
    });
  });
}

AlocacaoProvider _buildProvider(_WatchAlocacaoRepository repository) {
  return AlocacaoProvider(
    alocarColaboradorUseCase: AlocarColaborador(
      alocacaoRepository: repository,
      colaboradorRepository: _UnusedColaboradorRepository(),
      caixaRepository: _UnusedCaixaRepository(),
    ),
    liberarAlocacaoUseCase: LiberarAlocacao(alocacaoRepository: repository),
    getAlocacoesAtivasUseCase:
        GetAlocacoesAtivas(alocacaoRepository: repository),
    repository: repository,
  );
}

class _WatchAlocacaoRepository implements AlocacaoRepository {
  final List<String> watchCalls = [];
  final List<String> cancelledFiscalIds = [];
  final Map<String, StreamController<List<Alocacao>>> _controllers = {};

  @override
  Stream<List<Alocacao>> watchAlocacoesAtivas(String fiscalId) {
    watchCalls.add(fiscalId);
    return _controllers
        .putIfAbsent(
          fiscalId,
          () => StreamController<List<Alocacao>>(
            onCancel: () => cancelledFiscalIds.add(fiscalId),
          ),
        )
        .stream;
  }

  Future<void> close() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedColaboradorRepository implements ColaboradorRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedCaixaRepository implements CaixaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
