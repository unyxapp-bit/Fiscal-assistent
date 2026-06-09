import 'dart:async';

import 'package:fiscal_assistant/data/repositories/alocacao_repository.dart';
import 'package:fiscal_assistant/data/repositories/caixa_repository.dart';
import 'package:fiscal_assistant/data/repositories/colaborador_repository.dart';
import 'package:fiscal_assistant/domain/entities/alocacao.dart';
import 'package:fiscal_assistant/domain/enums/departamento_tipo.dart';
import 'package:fiscal_assistant/domain/usecases/alocar_colaborador.dart';
import 'package:fiscal_assistant/domain/usecases/get_alocacoes_ativas.dart';
import 'package:fiscal_assistant/domain/usecases/liberar_alocacao.dart';
import 'package:fiscal_assistant/presentation/providers/alocacao_provider.dart';
import 'package:fiscal_assistant/presentation/providers/escala_provider.dart';
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

    test('ignora alocacao ativa de outro dia ao carregar', () async {
      final repository = _WatchAlocacaoRepository();
      final provider = _buildProvider(repository);
      addTearDown(() async {
        provider.dispose();
        await repository.close();
      });

      final agora = DateTime.now();
      final antiga = _alocacao(
        id: 'old',
        colaboradorId: 'col-old',
        caixaId: 'caixa-old',
        alocadoEm: agora.subtract(const Duration(days: 1)),
      );
      final atual = _alocacao(
        id: 'today',
        colaboradorId: 'col-today',
        caixaId: 'caixa-today',
        alocadoEm: agora,
      );
      repository.activeResult = [antiga, atual];

      await provider.loadAlocacoes('fiscal-1');

      expect(provider.quantidadeAtivasAgora, 1);
      expect(provider.getAlocacaoColaborador('col-old'), isNull);
      expect(provider.getAlocacaoCaixa('caixa-old'), isNull);
      expect(provider.getAlocacoesAtivas(), [atual]);
    });

    test('ignora alocacao ativa de outro dia no realtime', () async {
      final repository = _WatchAlocacaoRepository();
      final provider = _buildProvider(repository);
      addTearDown(() async {
        provider.dispose();
        await repository.close();
      });

      final agora = DateTime.now();
      final antiga = _alocacao(
        id: 'old',
        colaboradorId: 'col-old',
        caixaId: 'caixa-old',
        alocadoEm: agora.subtract(const Duration(days: 1)),
      );
      final atual = _alocacao(
        id: 'today',
        colaboradorId: 'col-today',
        caixaId: 'caixa-today',
        alocadoEm: agora,
      );

      provider.watchAlocacoes('fiscal-1');
      repository.emit('fiscal-1', [antiga, atual]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.quantidadeAtivasAgora, 1);
      expect(provider.getAlocacoesAtivas(), [atual]);
    });

    test('libera automaticamente ao passar horario de saida', () async {
      final repository = _WatchAlocacaoRepository();
      final provider = _buildProvider(repository);
      addTearDown(() async {
        provider.dispose();
        await repository.close();
      });

      final agora = DateTime.now();
      final alocacao = _alocacao(
        id: 'allocation-1',
        colaboradorId: 'colaborador-1',
        caixaId: 'caixa-1',
        alocadoEm: agora.subtract(const Duration(hours: 1)),
      );
      repository.activeResult = [alocacao];
      await provider.loadAlocacoes('fiscal-1');

      final saida = agora.subtract(const Duration(minutes: 1));
      final escala = EscalaProvider(
        turnosIniciais: [
          TurnoLocal(
            id: 'turno-1',
            colaboradorId: 'colaborador-1',
            colaboradorNome: 'Maria',
            departamento: DepartamentoTipo.caixa,
            data: DateTime(agora.year, agora.month, agora.day),
            entrada: '08:00',
            saida:
                '${saida.hour.toString().padLeft(2, '0')}:${saida.minute.toString().padLeft(2, '0')}',
          ),
        ],
      );

      provider.vincularEscala(escala);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repository.releasedIds, ['allocation-1']);
      expect(provider.quantidadeAtivasAgora, 0);
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

Alocacao _alocacao({
  required String id,
  required String colaboradorId,
  required String caixaId,
  required DateTime alocadoEm,
  DateTime? liberadoEm,
}) {
  return Alocacao(
    id: id,
    colaboradorId: colaboradorId,
    caixaId: caixaId,
    alocadoEm: alocadoEm,
    liberadoEm: liberadoEm,
    createdAt: alocadoEm,
  );
}

class _WatchAlocacaoRepository implements AlocacaoRepository {
  final List<String> watchCalls = [];
  final List<String> cancelledFiscalIds = [];
  final List<String> releasedIds = [];
  List<Alocacao> activeResult = [];
  final Map<String, StreamController<List<Alocacao>>> _controllers = {};

  @override
  Future<List<Alocacao>> getAlocacoesAtivas(String fiscalId) async {
    return activeResult;
  }

  @override
  Future<Alocacao> liberarAlocacao(
    String id,
    DateTime liberadoEm,
    String motivo,
  ) async {
    releasedIds.add(id);
    final alocacao = activeResult.firstWhere((a) => a.id == id);
    final liberada = alocacao.copyWith(
      liberadoEm: liberadoEm,
      motivoLiberacao: motivo,
    );
    activeResult = [
      for (final atual in activeResult)
        if (atual.id == id) liberada else atual,
    ];
    return liberada;
  }

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

  void emit(String fiscalId, List<Alocacao> alocacoes) {
    _controllers[fiscalId]?.add(alocacoes);
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
