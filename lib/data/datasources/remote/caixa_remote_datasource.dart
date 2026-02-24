import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../../models/caixa_model.dart';
import '../../../core/errors/exceptions.dart';

/// Fonte de dados remota para Caixas (Supabase)
class CaixaRemoteDataSource {
  final SupabaseClient _client = SupabaseClientManager.client;

  Future<List<CaixaModel>> getCaixas(String fiscalId) async {
    try {
      final response = await _client
          .from('caixas')
          .select()
          .eq('fiscal_id', fiscalId)
          .order('numero');
      return response.map((j) => CaixaModel.fromJson(j)).toList();
    } catch (e) {
      throw ServerException('Erro ao buscar caixas: $e');
    }
  }

  Future<CaixaModel?> getCaixaById(String id) async {
    try {
      final response =
          await _client.from('caixas').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return CaixaModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao buscar caixa: $e');
    }
  }

  Future<void> upsertCaixa(CaixaModel caixa) async {
    try {
      await _client.from('caixas').upsert(caixa.toJson());
    } catch (e) {
      throw ServerException('Erro ao salvar caixa: $e');
    }
  }

  Future<void> deleteCaixa(String id) async {
    try {
      await _client.from('caixas').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Erro ao deletar caixa: $e');
    }
  }

  /// Retorna IDs de caixas usados pelo colaborador hoje
  Future<List<String>> getCaixasUsadosHoje(String colaboradorId) async {
    try {
      final hoje = DateTime.now();
      final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
      final response = await _client
          .from('alocacoes')
          .select('caixa_id')
          .eq('colaborador_id', colaboradorId)
          .gte('alocado_em', inicioDia.toIso8601String());
      return response.map<String>((r) => r['caixa_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<CaixaModel>> watchCaixas(String fiscalId) {
    return _client
        .from('caixas')
        .stream(primaryKey: ['id'])
        .eq('fiscal_id', fiscalId)
        .order('numero')
        .map((data) => data.map((j) => CaixaModel.fromJson(j)).toList());
  }
}
