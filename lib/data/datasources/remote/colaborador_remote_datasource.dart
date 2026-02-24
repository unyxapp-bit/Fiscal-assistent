import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../../models/colaborador_model.dart';
import '../../../core/errors/exceptions.dart';

/// Fonte de dados remota para Colaboradores (Supabase)
class ColaboradorRemoteDataSource {
  final SupabaseClient _client = SupabaseClientManager.client;

  /// Busca todos os colaboradores de um fiscal
  Future<List<ColaboradorModel>> getColaboradores(String fiscalId) async {
    try {
      if (kDebugMode) {
        print('[ColaboradorRemoteDataSource] Buscando colaboradores para fiscalId: $fiscalId');
      }
      final response = await _client
          .from('colaboradores')
          .select()
          .or('fiscal_id.eq.$fiscalId,fiscal_id.is.null')
          .order('nome');

      if (kDebugMode) {
        print('[ColaboradorRemoteDataSource] ${(response as List).length} colaboradores retornados');
      }

      // Filtrar apenas ativos e associar fiscal_id ao usuário atual nos registros sem dono
      final list = (response as List)
          .map((json) => ColaboradorModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Atualizar em background os registros órfãos (fiscal_id null)
      _adotarRegistrosOrfaos(fiscalId, list);

      return list;
    } catch (e) {
      if (kDebugMode) {
        print('[ColaboradorRemoteDataSource] Erro: $e');
      }
      throw ServerException('Erro ao buscar colaboradores: $e');
    }
  }

  /// Busca colaboradores por departamento
  Future<List<ColaboradorModel>> getColaboradoresByDepartamento(
    String fiscalId,
    String departamento,
  ) async {
    try {
      final response = await _client
          .from('colaboradores')
          .select()
          .eq('fiscal_id', fiscalId)
          .eq('departamento', departamento)
          .eq('ativo', true)
          .order('nome');

      return (response as List)
          .map((json) => ColaboradorModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Erro ao buscar colaboradores: $e');
    }
  }

  /// Busca colaborador pelo ID
  Future<ColaboradorModel?> getColaboradorById(String id) async {
    try {
      final response = await _client
          .from('colaboradores')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return ColaboradorModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao buscar colaborador: $e');
    }
  }

  /// Cria novo colaborador
  Future<ColaboradorModel> createColaborador(ColaboradorModel colaborador) async {
    try {
      final response = await _client
          .from('colaboradores')
          .insert(colaborador.toJson())
          .select()
          .single();

      return ColaboradorModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao criar colaborador: $e');
    }
  }

  /// Atualiza colaborador
  Future<ColaboradorModel> updateColaborador(ColaboradorModel colaborador) async {
    try {
      final response = await _client
          .from('colaboradores')
          .update(colaborador.toJson())
          .eq('id', colaborador.id)
          .select()
          .single();

      return ColaboradorModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao atualizar colaborador: $e');
    }
  }

  /// Deleta colaborador
  Future<void> deleteColaborador(String id) async {
    try {
      await _client.from('colaboradores').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Erro ao deletar colaborador: $e');
    }
  }

  /// Associa colaboradores sem fiscal_id ao fiscal atual (migração única).
  void _adotarRegistrosOrfaos(
      String fiscalId, List<ColaboradorModel> lista) {
    final orfaos = lista.where((c) => c.fiscalId.isEmpty).map((c) => c.id).toList();
    if (orfaos.isEmpty) return;

    _client
        .from('colaboradores')
        .update({'fiscal_id': fiscalId})
        .inFilter('id', orfaos)
        .then((_) {
          if (kDebugMode) {
            print('[ColaboradorRemoteDataSource] ${orfaos.length} colaboradores associados ao fiscal $fiscalId');
          }
        })
        .catchError((e) {
          if (kDebugMode) {
            print('[ColaboradorRemoteDataSource] Erro ao adotar órfãos: $e');
          }
        });
  }

  /// Stream de mudanças nos colaboradores (Realtime)
  Stream<List<ColaboradorModel>> watchColaboradores(String fiscalId) {
    // Supabase stream não suporta .or(), então filtra no client após receber
    return _client
        .from('colaboradores')
        .stream(primaryKey: ['id'])
        .order('nome')
        .map((data) => data
            .where((row) =>
                row['fiscal_id'] == fiscalId || row['fiscal_id'] == null)
            .map((json) => ColaboradorModel.fromJson(json))
            .toList());
  }
}
