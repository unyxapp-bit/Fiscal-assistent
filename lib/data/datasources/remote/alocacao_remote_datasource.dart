import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../../models/alocacao_model.dart';
import '../../../core/errors/exceptions.dart';

/// Fonte de dados remota para Alocações (Supabase)
class AlocacaoRemoteDataSource {
  final SupabaseClient _client = SupabaseClientManager.client;

  /// Busca alocações ativas
  Future<List<AlocacaoModel>> getAlocacoesAtivas(String fiscalId) async {
    try {
      final response = await _client
          .from('alocacoes')
          .select()
          .eq('fiscal_id', fiscalId)
          .eq('status', 'ativo')
          .order('horario_inicio', ascending: true);

      return (response as List)
          .map((json) => AlocacaoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Erro ao buscar alocações: $e');
    }
  }

  /// Busca alocação ativa de um colaborador
  Future<AlocacaoModel?> getAlocacaoAtivaColaborador(
    String colaboradorId,
  ) async {
    try {
      final response = await _client
          .from('alocacoes')
          .select()
          .eq('colaborador_id', colaboradorId)
          .eq('status', 'ativo')
          .order('horario_inicio', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return AlocacaoModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao buscar alocação: $e');
    }
  }

  /// Verifica se colaborador já usou caixa hoje
  Future<bool> jaUsouCaixaHoje(String colaboradorId, String caixaId) async {
    try {
      final hoje = DateTime.now();
      final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
      final fimDia = inicioDia.add(const Duration(days: 1));

      final response = await _client
          .from('alocacoes')
          .select('id')
          .eq('colaborador_id', colaboradorId)
          .eq('caixa_id', caixaId)
          .gte('horario_inicio', inicioDia.toIso8601String())
          .lt('horario_inicio', fimDia.toIso8601String())
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      throw ServerException('Erro ao verificar caixa usado: $e');
    }
  }

  /// Cria nova alocação
  Future<AlocacaoModel> createAlocacao(AlocacaoModel alocacao) async {
    try {
      final json = alocacao.toJson();
      // Garante fiscal_id para que o RLS funcione corretamente
      final fiscalId = _client.auth.currentUser?.id;
      if (fiscalId != null) json['fiscal_id'] = fiscalId;

      final response = await _client
          .from('alocacoes')
          .insert(json)
          .select()
          .single();

      return AlocacaoModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao criar alocação: $e');
    }
  }

  /// Libera alocação (marca como liberada)
  Future<AlocacaoModel> liberarAlocacao(
    String id,
    DateTime liberadoEm,
    String motivo,
  ) async {
    try {
      final response = await _client
          .from('alocacoes')
          .update({
            'liberado_em': liberadoEm.toIso8601String(),
            'horario_fim': liberadoEm.toIso8601String(),
            'status': 'finalizado',
            'motivo_liberacao': motivo,
          })
          .eq('id', id)
          .select()
          .single();

      return AlocacaoModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao liberar alocação: $e');
    }
  }

  /// Marca intervalo como feito para uma alocação específica
  Future<void> marcarIntervaloFeito(String alocacaoId) async {
    try {
      await _client
          .from('alocacoes')
          .update({'intervalo_marcado_feito': true}).eq('id', alocacaoId);
    } catch (e) {
      throw ServerException('Erro ao marcar intervalo feito: $e');
    }
  }

  /// Busca histórico de alocações
  Future<List<AlocacaoModel>> getHistorico(String fiscalId) async {
    try {
      final response = await _client
          .from('alocacoes')
          .select()
          .eq('fiscal_id', fiscalId)
          .order('horario_inicio', ascending: false)
          .limit(100);

      return (response as List)
          .map((json) => AlocacaoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Erro ao buscar histórico: $e');
    }
  }

  /// Stream de alocações ativas (Realtime)
  Stream<List<AlocacaoModel>> watchAlocacoesAtivas(String fiscalId) {
    return _client
        .from('alocacoes')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data
              .map((json) => AlocacaoModel.fromJson(json))
              .where((alocacao) => alocacao.liberadoEm == null)
              .toList()
              ..sort((a, b) => a.alocadoEm.compareTo(b.alocadoEm)),
        );
  }
}
