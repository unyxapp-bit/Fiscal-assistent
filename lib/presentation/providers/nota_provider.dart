import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/nota.dart';
import '../../domain/enums/tipo_lembrete.dart';
import '../../data/datasources/remote/supabase_client.dart';
import '../../data/services/notification_service.dart';

enum OrdenacaoNota { importancia, dataCriacao, dataVencimento, tipo }

class NotaProvider with ChangeNotifier {
  static const _table = 'notas';

  final List<Nota> _notas = [];
  TipoLembrete? _filtroTipo;
  bool _mostrarApenasPendentes = false;
  String _searchQuery = '';
  OrdenacaoNota _ordenacao = OrdenacaoNota.importancia;

  // ─── Getters filtrados ────────────────────────────────────────────────────

  List<Nota> get notas {
    var result = List<Nota>.from(_notas);

    if (_filtroTipo != null) {
      result = result.where((n) => n.tipo == _filtroTipo).toList();
    }

    if (_mostrarApenasPendentes) {
      result = result.where((n) => !n.concluida).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((n) {
        final q = _searchQuery;
        return n.titulo.toLowerCase().contains(q) ||
            n.conteudo.toLowerCase().contains(q);
      }).toList();
    }

    result.sort((a, b) {
      switch (_ordenacao) {
        case OrdenacaoNota.importancia:
          if (a.importante && !b.importante) return -1;
          if (!a.importante && b.importante) return 1;
          return b.createdAt.compareTo(a.createdAt);
        case OrdenacaoNota.dataCriacao:
          return b.createdAt.compareTo(a.createdAt);
        case OrdenacaoNota.dataVencimento:
          if (a.dataLembrete == null && b.dataLembrete == null) return 0;
          if (a.dataLembrete == null) return 1;
          if (b.dataLembrete == null) return -1;
          return a.dataLembrete!.compareTo(b.dataLembrete!);
        case OrdenacaoNota.tipo:
          return a.tipo.index.compareTo(b.tipo.index);
      }
    });

    return result;
  }

  List<Nota> get anotacoes =>
      _notas.where((n) => n.tipo == TipoLembrete.anotacao).toList();
  List<Nota> get tarefas =>
      _notas.where((n) => n.tipo == TipoLembrete.tarefa).toList();
  List<Nota> get lembretes =>
      _notas.where((n) => n.tipo == TipoLembrete.lembrete).toList();

  List<Nota> get tarefasPendentes =>
      tarefas.where((t) => !t.concluida).toList();
  List<Nota> get tarefasConcluidas =>
      tarefas.where((t) => t.concluida).toList();

  List<Nota> get lembretesAtivos =>
      lembretes.where((l) => l.lembreteAtivo).toList();

  List<Nota> get importantes =>
      _notas.where((n) => n.importante && !n.concluida).toList();

  int get totalNotas => _notas.length;
  int get totalTarefasPendentes => tarefasPendentes.length;
  int get totalLembretesAtivos => lembretesAtivos.length;
  int get totalLembretesVencidos =>
      _notas.where((n) => n.tipo == TipoLembrete.lembrete && n.isVencido).length;

  TipoLembrete? get filtroTipo => _filtroTipo;
  bool get mostrarApenasPendentes => _mostrarApenasPendentes;
  OrdenacaoNota get ordenacao => _ordenacao;
  String get searchQuery => _searchQuery;

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  // ─── Filtros ──────────────────────────────────────────────────────────────

  void setFiltroTipo(TipoLembrete? tipo) {
    _filtroTipo = tipo;
    notifyListeners();
  }

  void setMostrarApenasPendentes(bool valor) {
    _mostrarApenasPendentes = valor;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  void setOrdenacao(OrdenacaoNota o) {
    _ordenacao = o;
    notifyListeners();
  }

  void limparFiltros() {
    _filtroTipo = null;
    _mostrarApenasPendentes = false;
    _searchQuery = '';
    _ordenacao = OrdenacaoNota.importancia;
    notifyListeners();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> load() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_table)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('created_at', ascending: false);
      _notas
        ..clear()
        ..addAll(
            (rows as List).map((r) => _fromMap(r as Map<String, dynamic>)));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[NotaProvider] Erro ao carregar: $e');
    }
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  void adicionarNota(
    String titulo,
    String conteudo,
    TipoLembrete tipo, {
    DateTime? dataLembrete,
    bool importante = false,
    bool lembreteAtivo = true,
  }) {
    final nota = Nota(
      id: const Uuid().v4(),
      titulo: titulo,
      conteudo: conteudo,
      tipo: tipo,
      importante: importante,
      dataLembrete: dataLembrete,
      lembreteAtivo: lembreteAtivo,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _notas.add(nota);
    notifyListeners();
    _upsert(nota);
    _agendarNotificacao(nota);
  }

  void atualizarNota(Nota nota) {
    final index = _notas.indexWhere((n) => n.id == nota.id);
    if (index != -1) {
      final atualizada = nota.copyWith(updatedAt: DateTime.now());
      _notas[index] = atualizada;
      notifyListeners();
      _upsert(atualizada);
      // Cancela a notificação anterior e reagenda se necessário
      NotificationService.instance.cancel(_notifId(nota.id));
      _agendarNotificacao(atualizada);
    }
  }

  void toggleConcluida(String id) {
    final index = _notas.indexWhere((n) => n.id == id);
    if (index != -1) {
      final atualizada = _notas[index].copyWith(
        concluida: !_notas[index].concluida,
        updatedAt: DateTime.now(),
      );
      _notas[index] = atualizada;
      notifyListeners();
      _upsert(atualizada);
    }
  }

  void toggleImportante(String id) {
    final index = _notas.indexWhere((n) => n.id == id);
    if (index != -1) {
      final atualizada = _notas[index].copyWith(
        importante: !_notas[index].importante,
        updatedAt: DateTime.now(),
      );
      _notas[index] = atualizada;
      notifyListeners();
      _upsert(atualizada);
    }
  }

  void toggleLembreteAtivo(String id) {
    final index = _notas.indexWhere((n) => n.id == id);
    if (index != -1) {
      final atualizada = _notas[index].copyWith(
        lembreteAtivo: !_notas[index].lembreteAtivo,
        updatedAt: DateTime.now(),
      );
      _notas[index] = atualizada;
      notifyListeners();
      _upsert(atualizada);
      if (atualizada.lembreteAtivo) {
        _agendarNotificacao(atualizada);
      } else {
        NotificationService.instance.cancel(_notifId(id));
      }
    }
  }

  void deletarNota(String id) {
    NotificationService.instance.cancel(_notifId(id));
    _notas.removeWhere((n) => n.id == id);
    notifyListeners();
    SupabaseClientManager.client
        .from(_table)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) debugPrint('[NotaProvider] Erro ao remover: $e');
    });
  }

  // ─── Notificações ────────────────────────────────────────────────────────

  /// ID estável: primeiros 7 hex chars do UUID → int.
  int _notifId(String notaId) =>
      int.parse(notaId.replaceAll('-', '').substring(0, 7), radix: 16);

  void _agendarNotificacao(Nota nota) {
    if (nota.tipo != TipoLembrete.lembrete) return;
    if (nota.dataLembrete == null) return;
    if (nota.dataLembrete!.isBefore(DateTime.now())) return;
    if (!nota.lembreteAtivo) return;

    NotificationService.instance
        .scheduleAlert(
          id: _notifId(nota.id),
          title: nota.titulo,
          body: nota.conteudo.isNotEmpty ? nota.conteudo : 'Toque para abrir',
          scheduledAt: nota.dataLembrete!,
        )
        .catchError(
            (e) => debugPrint('[NotaProvider] Erro ao agendar notif: $e'));
  }

  // ─── Sync / Parse ────────────────────────────────────────────────────────

  void _upsert(Nota nota) {
    SupabaseClientManager.client
        .from(_table)
        .upsert(_toMap(nota))
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) debugPrint('[NotaProvider] Erro ao sincronizar: $e');
    });
  }

  Nota _fromMap(Map<String, dynamic> m) => Nota(
        id: m['id'] as String,
        titulo: m['titulo'] as String,
        conteudo: m['conteudo'] as String? ?? '',
        tipo: _parseTipo(m['tipo'] as String? ?? 'anotacao'),
        concluida: m['concluida'] as bool? ?? false,
        importante: m['importante'] as bool? ?? false,
        lembreteAtivo: m['lembrete_ativo'] as bool? ?? true,
        dataLembrete: m['data_lembrete'] != null
            ? DateTime.parse(m['data_lembrete'] as String)
            : null,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  Map<String, dynamic> _toMap(Nota n) => {
        'id': n.id,
        'fiscal_id': _fiscalId,
        'titulo': n.titulo,
        'conteudo': n.conteudo,
        'tipo': n.tipo.name,
        'concluida': n.concluida,
        'importante': n.importante,
        'lembrete_ativo': n.lembreteAtivo,
        'data_lembrete': n.dataLembrete?.toIso8601String(),
        'created_at': n.createdAt.toIso8601String(),
        'updated_at': n.updatedAt.toIso8601String(),
      };

  TipoLembrete _parseTipo(String s) {
    switch (s) {
      case 'tarefa':
        return TipoLembrete.tarefa;
      case 'lembrete':
        return TipoLembrete.lembrete;
      default:
        return TipoLembrete.anotacao;
    }
  }
}
