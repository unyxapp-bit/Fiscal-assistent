import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../../../core/errors/exceptions.dart';

/// Fonte de dados remota para colaboradores em Outro Setor (Supabase)
class OutroSetorRemoteDataSource {
  final SupabaseClient _client = SupabaseClientManager.client;

  String _hoje() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Busca registros de hoje para o fiscal
  Future<List<Map<String, dynamic>>> getOutroSetorHoje(String fiscalId) async {
    try {
      final response = await _client
          .from('outro_setor')
          .select()
          .eq('fiscal_id', fiscalId)
          .eq('data', _hoje())
          .order('criado_em', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw ServerException('Erro ao buscar outro setor: $e');
    }
  }

  /// Registra colaborador em outro setor
  Future<Map<String, dynamic>> addOutroSetor(
    String fiscalId,
    String colaboradorId,
    String setor,
  ) async {
    try {
      final response = await _client
          .from('outro_setor')
          .insert({
            'fiscal_id': fiscalId,
            'colaborador_id': colaboradorId,
            'setor': setor,
            'data': _hoje(),
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw ServerException('Erro ao registrar em outro setor: $e');
    }
  }

  /// Remove o registro
  Future<void> removeOutroSetor(String id) async {
    try {
      await _client.from('outro_setor').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Erro ao remover: $e');
    }
  }
}
