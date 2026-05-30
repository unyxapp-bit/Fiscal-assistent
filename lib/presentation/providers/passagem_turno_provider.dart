import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';
import '../../data/services/operation_audit_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class PassagemTurno {
  final String id;
  final String resumo;
  final String pendencias;
  final String recados;
  final String? turno; // 'manha' | 'tarde' | 'noite' | null (legado)
  final DateTime registradaEm;

  const PassagemTurno({
    required this.id,
    required this.resumo,
    required this.pendencias,
    required this.recados,
    this.turno,
    required this.registradaEm,
  });

  String get turnoLabel {
    switch (turno) {
      case 'manha':
        return 'Manhã';
      case 'tarde':
        return 'Tarde';
      case 'noite':
        return 'Noite';
      default:
        return '';
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

class PassagemTurnoProvider with ChangeNotifier {
  static const _table = 'passagens_turno';

  final List<PassagemTurno> _passagens = [];

  List<PassagemTurno> get historico => _passagens;

  PassagemTurno? get ultima => _passagens.isEmpty ? null : _passagens.first;

  List<PassagemTurno> get historicoHoje {
    final hoje = DateTime.now();
    return _passagens.where((p) {
      return p.registradaEm.year == hoje.year &&
          p.registradaEm.month == hoje.month &&
          p.registradaEm.day == hoje.day;
    }).toList();
  }

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  Future<void> load() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_table)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('registrada_em', ascending: false)
          .limit(30);

      _passagens.clear();
      _passagens.addAll(rows.map(_fromMap));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PassagemTurnoProvider] Erro ao carregar: $e');
      }
    }
  }

  void registrar({
    required String resumo,
    required String pendencias,
    required String recados,
    String? turno,
  }) {
    final passagem = PassagemTurno(
      id: const Uuid().v4(),
      resumo: resumo,
      pendencias: pendencias,
      recados: recados,
      turno: turno,
      registradaEm: DateTime.now(),
    );
    _passagens.insert(0, passagem);
    notifyListeners();
    _upsert(passagem);
    unawaited(OperationAuditService.log(
      fiscalId: _fiscalId,
      area: 'passagem_turno',
      action: 'created',
      entityType: 'passagem_turno',
      entityId: passagem.id,
      title: 'Passagem de turno registrada',
      description: passagem.resumo,
      metadata: {
        'turno': passagem.turno,
        'tem_pendencias': passagem.pendencias.isNotEmpty,
        'tem_recados': passagem.recados.isNotEmpty,
      },
    ));
    if (passagem.pendencias.isNotEmpty) {
      unawaited(OperationAuditService.queueNotification(
        fiscalId: _fiscalId,
        area: 'passagem_turno',
        entityType: 'passagem_turno',
        entityId: passagem.id,
        priority: 'high',
        title: 'Pendencia na passagem de turno',
        message: passagem.pendencias,
        actionPayload: {
          'route': 'passagem_turno',
          'id': passagem.id,
        },
      ));
    }
  }

  void deletar(String id) {
    final removida = _passagens.where((p) => p.id == id).firstOrNull;
    _passagens.removeWhere((p) => p.id == id);
    notifyListeners();
    SupabaseClientManager.client
        .from(_table)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) {
        debugPrint('[PassagemTurnoProvider] Erro ao deletar: $e');
      }
    });
    unawaited(OperationAuditService.log(
      fiscalId: _fiscalId,
      area: 'passagem_turno',
      action: 'deleted',
      entityType: 'passagem_turno',
      entityId: id,
      severity: 'warning',
      title: 'Passagem de turno removida',
      description: removida?.resumo,
    ));
  }

  void _upsert(PassagemTurno p) {
    SupabaseClientManager.client
        .from(_table)
        .upsert({
          'id': p.id,
          'fiscal_id': _fiscalId,
          'resumo': p.resumo,
          'pendencias': p.pendencias,
          'recados': p.recados,
          'turno': p.turno,
          'registrada_em': p.registradaEm.toIso8601String(),
        })
        .then((_) {})
        .catchError((e) {
          if (kDebugMode) {
            debugPrint('[PassagemTurnoProvider] Erro ao sync: $e');
          }
        });
  }

  PassagemTurno _fromMap(Map<String, dynamic> m) => PassagemTurno(
        id: m['id'] as String,
        resumo: m['resumo'] as String? ?? '',
        pendencias: m['pendencias'] as String? ?? '',
        recados: m['recados'] as String? ?? '',
        turno: m['turno'] as String?,
        registradaEm: DateTime.parse(m['registrada_em'] as String),
      );
}
