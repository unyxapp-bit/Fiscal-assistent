import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../../models/registro_ponto_model.dart';
import '../../../core/errors/exceptions.dart';

/// Fonte de dados remota para Registros de Ponto (Supabase)
class RegistroPontoRemoteDataSource {
  final SupabaseClient _client = SupabaseClientManager.client;

  /// Busca todos os registros de ponto de um colaborador
  Future<List<RegistroPontoModel>> getRegistrosPorColaborador(
      String colaboradorId) async {
    try {
      final response = await _client
          .from('registros_ponto')
          .select()
          .eq('colaborador_id', colaboradorId)
          .order('data', ascending: false);

      return (response as List)
          .map((json) =>
              RegistroPontoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Erro ao buscar registros de ponto: $e');
    }
  }

  /// Cria novo registro de ponto
  Future<RegistroPontoModel> createRegistroPonto(
      RegistroPontoModel model) async {
    try {
      final json = model.toJson();
      json.remove('id'); // Supabase gera o ID
      final response =
          await _client.from('registros_ponto').insert(json).select().single();

      return RegistroPontoModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao criar registro de ponto: $e');
    }
  }

  /// Atualiza registro de ponto existente
  Future<RegistroPontoModel> updateRegistroPonto(
      RegistroPontoModel model) async {
    try {
      final response = await _client
          .from('registros_ponto')
          .update(model.toJson())
          .eq('id', model.id)
          .select()
          .single();

      return RegistroPontoModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao atualizar registro de ponto: $e');
    }
  }

  /// Deleta registro de ponto
  Future<void> deleteRegistroPonto(String id) async {
    try {
      await _client.from('registros_ponto').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Erro ao deletar registro de ponto: $e');
    }
  }

  /// Insere múltiplos registros em lote (sem retorno individual)
  Future<void> createBatchRegistros(
      List<Map<String, dynamic>> registros) async {
    try {
      await _client.from('registros_ponto').insert(registros);
    } catch (e) {
      throw ServerException('Erro ao importar registros em lote: $e');
    }
  }
}
