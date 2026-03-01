import 'package:flutter/foundation.dart';
import '../../data/services/claude_parser_service.dart';
import 'ocorrencia_provider.dart';
import 'nota_provider.dart';
import '../../domain/enums/tipo_lembrete.dart';

export '../../data/services/claude_parser_service.dart'
    show EventoImportado, TipoEventoImportado, TipoEventoImportadoExt;

// ── Mapeamento de eventos para módulos existentes ─────────────────────────────

String _tipoOcorrencia(TipoEventoImportado tipo) {
  switch (tipo) {
    case TipoEventoImportado.discrepanciaValor:
      return 'Erro de Caixa';
    case TipoEventoImportado.atestado:
    case TipoEventoImportado.ausencia:
      return 'Ausência';
    case TipoEventoImportado.reclamacao:
      return 'Reclamação';
    default:
      return 'Outro';
  }
}

GravidadeOcorrencia _gravidade(TipoEventoImportado tipo) {
  switch (tipo) {
    case TipoEventoImportado.discrepanciaValor:
      return GravidadeOcorrencia.alta;
    case TipoEventoImportado.reclamacao:
    case TipoEventoImportado.atestado:
    case TipoEventoImportado.ausencia:
      return GravidadeOcorrencia.media;
    default:
      return GravidadeOcorrencia.baixa;
  }
}

TipoLembrete _tipoNota(TipoEventoImportado tipo) =>
    tipo == TipoEventoImportado.tarefa
        ? TipoLembrete.tarefa
        : TipoLembrete.anotacao;

// ── Provider ──────────────────────────────────────────────────────────────────

class ImportacaoProvider with ChangeNotifier {
  final _parser = ClaudeParserService();

  List<EventoImportado> eventos = [];
  bool carregando = false;
  String? erro;

  bool get configurado => _parser.configurado;

  // ── Analisar ────────────────────────────────────────────────────────────────

  Future<void> analisar(String conversa) async {
    carregando = true;
    erro = null;
    eventos = [];
    notifyListeners();

    try {
      eventos = await _parser.analisar(conversa);
      if (eventos.isEmpty) {
        erro = 'Nenhum evento operacional encontrado. '
            'Tente colar uma conversa com ocorrências, faltas ou tarefas.';
      }
    } catch (e) {
      erro = e.toString();
      if (kDebugMode) debugPrint('[ImportacaoProvider] $e');
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // ── Edição da lista ─────────────────────────────────────────────────────────

  void remover(int index) {
    if (index >= 0 && index < eventos.length) {
      eventos.removeAt(index);
      notifyListeners();
    }
  }

  void limpar() {
    eventos = [];
    erro = null;
    notifyListeners();
  }

  // ── Salvar ──────────────────────────────────────────────────────────────────

  /// Cria Ocorrências ou Notas para cada evento detectado.
  /// Retorna quantos foram salvos.
  Future<int> salvar(
    OcorrenciaProvider ocorrenciaProvider,
    NotaProvider notaProvider,
  ) async {
    int salvos = 0;

    for (final ev in eventos) {
      final colaborador =
          ev.nomeColaborador != null ? ' (${ev.nomeColaborador})' : '';
      final valorStr = ev.valor != null
          ? ' — R\$ ${ev.valor!.toStringAsFixed(2)}'
          : '';

      if (ev.tipo.vaiParaOcorrencia) {
        ocorrenciaProvider.registrar(
          tipo: _tipoOcorrencia(ev.tipo),
          descricao: '${ev.descricao}$colaborador$valorStr',
          gravidade: _gravidade(ev.tipo),
        );
      } else {
        notaProvider.adicionarNota(
          ev.descricao,
          ev.nomeColaborador != null
              ? 'Colaborador: ${ev.nomeColaborador}'
              : '',
          _tipoNota(ev.tipo),
        );
      }
      salvos++;
    }

    eventos = [];
    notifyListeners();
    return salvos;
  }
}
