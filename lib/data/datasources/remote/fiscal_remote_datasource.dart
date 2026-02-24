import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../../models/fiscal_model.dart';
import '../../../core/errors/exceptions.dart';

/// Fonte de dados remota para Fiscal (Supabase)
class FiscalRemoteDataSource {
  final SupabaseClient _client = SupabaseClientManager.client;

  /// Busca fiscal pelo userId (auth)
  Future<FiscalModel?> getFiscalByUserId(String userId) async {
    try {
      if (kDebugMode) {
        print('[FiscalRemoteDataSource] Buscando fiscal para userId: $userId');
      }
      // Na tabela fiscais, o id É o user_id (PRIMARY KEY REFERENCES auth.users)
      final response = await _client
          .from('fiscais')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) {
          print('[FiscalRemoteDataSource] Nenhum fiscal encontrado para userId: $userId');
        }
        return null;
      }

      if (kDebugMode) {
        print('[FiscalRemoteDataSource] Fiscal encontrado: ${response['id']}');
      }
      return FiscalModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('[FiscalRemoteDataSource] Erro: $e');
      }
      throw ServerException('Erro ao buscar fiscal: $e');
    }
  }

  /// Busca fiscal pelo ID
  Future<FiscalModel?> getFiscalById(String id) async {
    try {
      final response = await _client
          .from('fiscais')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return FiscalModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao buscar fiscal: $e');
    }
  }

  /// Cria novo fiscal
  Future<FiscalModel> createFiscal(FiscalModel fiscal) async {
    try {
      final response = await _client
          .from('fiscais')
          .insert(fiscal.toJson())
          .select()
          .single();

      return FiscalModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao criar fiscal: $e');
    }
  }

  /// Atualiza fiscal
  Future<FiscalModel> updateFiscal(FiscalModel fiscal) async {
    try {
      final response = await _client
          .from('fiscais')
          .update(fiscal.toJson())
          .eq('id', fiscal.id)
          .select()
          .single();

      return FiscalModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erro ao atualizar fiscal: $e');
    }
  }

  /// Deleta fiscal
  Future<void> deleteFiscal(String id) async {
    try {
      await _client.from('fiscais').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Erro ao deletar fiscal: $e');
    }
  }

  /// Stream de mudanças no fiscal (Realtime)
  Stream<FiscalModel?> watchFiscal(String userId) {
    return _client
        .from('fiscais')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          if (data.isEmpty) return null;
          return FiscalModel.fromJson(data.first);
        });
  }
}
