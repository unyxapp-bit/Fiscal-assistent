import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../../../core/errors/exceptions.dart';

/// Fonte de dados remota para Plantão de Empacotadores (Supabase)
class PacotePlantaoRemoteDataSource {
  final SupabaseClient _client = SupabaseClientManager.client;

  /// Busca plantão de hoje para o fiscal
  Future<List<Map<String, dynamic>>> getPlantaoHoje(String fiscalId) async {
    try {
      final hoje = DateTime.now();
      final dataStr =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

      final response = await _client
          .from('pacote_plantao')
          .select()
          .eq('fiscal_id', fiscalId)
          .eq('data', dataStr)
          .order('criado_em', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw ServerException('Erro ao buscar plantão: $e');
    }
  }

  /// Adiciona empacotador ao plantão de hoje
  Future<Map<String, dynamic>> addPlantao(
    String fiscalId,
    String colaboradorId,
  ) async {
    try {
      final hoje = DateTime.now();
      final dataStr =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

      final response = await _client
          .from('pacote_plantao')
          .insert({
            'fiscal_id': fiscalId,
            'colaborador_id': colaboradorId,
            'data': dataStr,
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw ServerException('Erro ao adicionar ao plantão: $e');
    }
  }

  /// Remove empacotador do plantão
  Future<void> removePlantao(String id) async {
    try {
      await _client.from('pacote_plantao').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Erro ao remover do plantão: $e');
    }
  }
}
