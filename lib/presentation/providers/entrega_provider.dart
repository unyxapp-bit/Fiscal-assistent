import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';
import '../../data/services/operation_audit_service.dart';

/// Model para Entrega
class Entrega {
  final String id;
  final String numeroNota;
  final String clienteNome;
  final String bairro;
  final String cidade;
  final String endereco;
  final String? telefone;
  final String status; // separada, em_rota, entregue, cancelada
  final DateTime separadoEm;
  final DateTime? horarioMarcado;
  final DateTime? saiuParaEntregaEm;
  final DateTime? entregueEm;
  final String? observacoes;

  Entrega({
    required this.id,
    required this.numeroNota,
    required this.clienteNome,
    required this.bairro,
    required this.cidade,
    required this.endereco,
    this.telefone,
    this.status = 'separada',
    required this.separadoEm,
    this.horarioMarcado,
    this.saiuParaEntregaEm,
    this.entregueEm,
    this.observacoes,
  });

  factory Entrega.fromMap(Map<String, dynamic> m) => Entrega(
        id: m['id'] as String,
        numeroNota: m['numero_nota'] as String,
        clienteNome: m['cliente_nome'] as String,
        bairro: m['bairro'] as String? ?? '',
        cidade: m['cidade'] as String? ?? '',
        endereco: m['endereco'] as String? ?? '',
        telefone: m['telefone'] as String?,
        status: m['status'] as String? ?? 'separada',
        separadoEm: m['separado_em'] != null
            ? DateTime.parse(m['separado_em'] as String)
            : DateTime.now(),
        horarioMarcado: m['horario_marcado'] != null
            ? DateTime.parse(m['horario_marcado'] as String)
            : null,
        saiuParaEntregaEm: m['saiu_para_entrega_em'] != null
            ? DateTime.parse(m['saiu_para_entrega_em'] as String)
            : null,
        entregueEm: m['entregue_em'] != null
            ? DateTime.parse(m['entregue_em'] as String)
            : null,
        observacoes: m['observacoes'] as String?,
      );

  Map<String, dynamic> toMap(String fiscalId) => {
        'id': id,
        'fiscal_id': fiscalId,
        'numero_nota': numeroNota,
        'cliente_nome': clienteNome,
        'bairro': bairro,
        'cidade': cidade,
        'endereco': endereco,
        'telefone': telefone,
        'status': status,
        'separado_em': separadoEm.toIso8601String(),
        'horario_marcado': horarioMarcado?.toIso8601String(),
        'saiu_para_entrega_em': saiuParaEntregaEm?.toIso8601String(),
        'entregue_em': entregueEm?.toIso8601String(),
        'observacoes': observacoes,
        'updated_at': DateTime.now().toIso8601String(),
      };

  Entrega copyWith({
    String? id,
    String? numeroNota,
    String? clienteNome,
    String? bairro,
    String? cidade,
    String? endereco,
    String? telefone,
    String? status,
    DateTime? separadoEm,
    DateTime? horarioMarcado,
    DateTime? saiuParaEntregaEm,
    DateTime? entregueEm,
    String? observacoes,
  }) {
    return Entrega(
      id: id ?? this.id,
      numeroNota: numeroNota ?? this.numeroNota,
      clienteNome: clienteNome ?? this.clienteNome,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      endereco: endereco ?? this.endereco,
      telefone: telefone ?? this.telefone,
      status: status ?? this.status,
      separadoEm: separadoEm ?? this.separadoEm,
      horarioMarcado: horarioMarcado ?? this.horarioMarcado,
      saiuParaEntregaEm: saiuParaEntregaEm ?? this.saiuParaEntregaEm,
      entregueEm: entregueEm ?? this.entregueEm,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}

/// Provider para gerenciar entregas com persistência no Supabase
class EntregaProvider with ChangeNotifier {
  static const _table = 'entregas';
  final List<Entrega> _entregas = [];

  List<Entrega> get entregas => _entregas;
  List<Entrega> get separadas =>
      _entregas.where((e) => e.status == 'separada').toList();
  List<Entrega> get emRota =>
      _entregas.where((e) => e.status == 'em_rota').toList();
  List<Entrega> get entregues =>
      _entregas.where((e) => e.status == 'entregue').toList();

  int get totalSeparadas => separadas.length;
  int get totalEmRota => emRota.length;
  int get totalEntregues => entregues.length;

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  /// Carrega entregas do Supabase. Chamar após login.
  Future<void> load() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_table)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('separado_em', ascending: false);
      _entregas
        ..clear()
        ..addAll((rows as List)
            .map((r) => Entrega.fromMap(r as Map<String, dynamic>)));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[EntregaProvider] Erro ao carregar: $e');
    }
  }

  /// Adiciona entrega (optimistic update)
  void adicionarEntrega({
    required String numeroNota,
    required String clienteNome,
    required String bairro,
    required String cidade,
    required String endereco,
    String? telefone,
    String? observacoes,
    DateTime? horarioMarcado,
  }) {
    final entrega = Entrega(
      id: const Uuid().v4(),
      numeroNota: numeroNota,
      clienteNome: clienteNome,
      bairro: bairro,
      cidade: cidade,
      endereco: endereco,
      telefone: telefone,
      separadoEm: DateTime.now(),
      horarioMarcado: horarioMarcado,
      observacoes: observacoes,
    );
    _entregas.insert(0, entrega);
    notifyListeners();
    _upsert(entrega);
    unawaited(OperationAuditService.log(
      fiscalId: _fiscalId,
      area: 'entregas',
      action: 'created',
      entityType: 'entrega',
      entityId: entrega.id,
      title: 'Entrega cadastrada',
      description: 'Nota ${entrega.numeroNota} para ${entrega.clienteNome}',
      metadata: {
        'status': entrega.status,
        'cidade': entrega.cidade,
        'bairro': entrega.bairro,
        'horario_marcado': entrega.horarioMarcado?.toIso8601String(),
      },
    ));
  }

  /// Atualiza entrega existente
  void atualizarEntrega({
    required String id,
    required String numeroNota,
    required String clienteNome,
    required String bairro,
    required String cidade,
    required String endereco,
    String? telefone,
    String? observacoes,
    DateTime? horarioMarcado,
  }) {
    final index = _entregas.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final atualizada = _entregas[index].copyWith(
      numeroNota: numeroNota,
      clienteNome: clienteNome,
      bairro: bairro,
      cidade: cidade,
      endereco: endereco,
      telefone: telefone,
      observacoes: observacoes,
      horarioMarcado: horarioMarcado,
    );
    _entregas[index] = atualizada;
    notifyListeners();
    _upsert(atualizada);
    unawaited(OperationAuditService.log(
      fiscalId: _fiscalId,
      area: 'entregas',
      action: 'updated',
      entityType: 'entrega',
      entityId: atualizada.id,
      title: 'Entrega atualizada',
      description: 'Nota ${atualizada.numeroNota}',
      metadata: {
        'status': atualizada.status,
        'cidade': atualizada.cidade,
        'bairro': atualizada.bairro,
      },
    ));
  }

  /// Atualiza status
  void atualizarStatus(String id, String novoStatus) {
    final index = _entregas.indexWhere((e) => e.id == id);
    if (index == -1) return;
    var entrega = _entregas[index];
    final statusAnterior = entrega.status;
    DateTime? saiuEm = entrega.saiuParaEntregaEm;
    DateTime? entregueEm = entrega.entregueEm;

    if (novoStatus == 'em_rota' && saiuEm == null) {
      saiuEm = DateTime.now();
    } else if (novoStatus == 'entregue' && entregueEm == null) {
      entregueEm = DateTime.now();
    }

    final atualizada = entrega.copyWith(
      status: novoStatus,
      saiuParaEntregaEm: saiuEm,
      entregueEm: entregueEm,
    );
    _entregas[index] = atualizada;
    notifyListeners();
    _upsert(atualizada);
    unawaited(OperationAuditService.log(
      fiscalId: _fiscalId,
      area: 'entregas',
      action: 'status_changed',
      entityType: 'entrega',
      entityId: atualizada.id,
      severity: novoStatus == 'cancelada' ? 'warning' : 'info',
      title: 'Status de entrega alterado',
      description: '${atualizada.numeroNota}: $statusAnterior -> $novoStatus',
      metadata: {
        'status_anterior': statusAnterior,
        'status_novo': novoStatus,
        'numero_nota': atualizada.numeroNota,
        'cliente': atualizada.clienteNome,
      },
    ));
    if (novoStatus == 'em_rota' ||
        novoStatus == 'entregue' ||
        novoStatus == 'cancelada') {
      unawaited(OperationAuditService.queueNotification(
        fiscalId: _fiscalId,
        area: 'entregas',
        entityType: 'entrega',
        entityId: atualizada.id,
        priority: novoStatus == 'cancelada' ? 'high' : 'normal',
        title: 'Entrega ${_statusLabel(novoStatus)}',
        message: 'Nota ${atualizada.numeroNota} - ${atualizada.clienteNome}',
        actionPayload: {
          'route': 'entregas',
          'status': novoStatus,
          'id': atualizada.id,
        },
      ));
    }
  }

  /// Remove entrega
  void removerEntrega(String id) {
    final removida = _entregas.where((e) => e.id == id).firstOrNull;
    _entregas.removeWhere((e) => e.id == id);
    notifyListeners();
    SupabaseClientManager.client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('fiscal_id', _fiscalId)
        .then((_) {
      // ok
    }).catchError((e) {
      if (kDebugMode) debugPrint('[EntregaProvider] Erro ao remover: $e');
    });
    unawaited(OperationAuditService.log(
      fiscalId: _fiscalId,
      area: 'entregas',
      action: 'deleted',
      entityType: 'entrega',
      entityId: id,
      severity: 'warning',
      title: 'Entrega removida',
      description: removida?.numeroNota,
    ));
  }

  /// Remove todas as entregas concluidas do fiscal atual.
  void removerEntregasConcluidas() {
    final removidas = entregues;
    if (removidas.isEmpty) return;

    final ids = removidas.map((e) => e.id).toList();
    _entregas.removeWhere((e) => e.status == 'entregue');
    notifyListeners();

    unawaited(_removerEntregasRemotas(ids));
    unawaited(OperationAuditService.log(
      fiscalId: _fiscalId,
      area: 'entregas',
      action: 'completed_deleted_bulk',
      entityType: 'entrega',
      severity: 'warning',
      title: 'Entregas concluidas removidas',
      description: '${ids.length} entrega(s) concluidas removidas',
      metadata: {
        'total': ids.length,
        'notas': removidas.map((e) => e.numeroNota).toList(),
      },
    ));
  }

  Future<void> _removerEntregasRemotas(List<String> ids) async {
    try {
      for (final id in ids) {
        await SupabaseClientManager.client
            .from(_table)
            .delete()
            .eq('id', id)
            .eq('fiscal_id', _fiscalId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EntregaProvider] Erro ao remover em lote: $e');
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'em_rota':
        return 'em rota';
      case 'entregue':
        return 'entregue';
      case 'cancelada':
        return 'cancelada';
      default:
        return status;
    }
  }

  void _upsert(Entrega entrega) {
    SupabaseClientManager.client
        .from(_table)
        .upsert(entrega.toMap(_fiscalId))
        .then((_) {
      // ok
    }).catchError((e) {
      if (kDebugMode) debugPrint('[EntregaProvider] Erro ao sincronizar: $e');
    });
  }
}
