import '../datasources/remote/supabase_client.dart';

class DashboardQuickNote {
  final String id;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DashboardQuickNote({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DashboardQuickNote.fromMap(Map<String, dynamic> map) {
    return DashboardQuickNote(
      id: (map['id'] as String?) ?? '',
      text: (map['content'] as String?) ?? '',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((map['updated_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class DashboardQuickNoteService {
  static const _table = 'dashboard_quick_notes';

  static String get _fiscalId {
    final id = SupabaseClientManager.currentUserId;
    if (id == null || id.isEmpty) {
      throw Exception('Usuario nao autenticado para salvar nota rapida.');
    }
    return id;
  }

  static Future<List<DashboardQuickNote>> listar({int limit = 24}) async {
    final rows = await SupabaseClientManager.client
        .from(_table)
        .select()
        .eq('fiscal_id', _fiscalId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((row) => DashboardQuickNote.fromMap(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
  }

  static Future<DashboardQuickNote> salvar(String text) async {
    final value = text.trim();
    if (value.isEmpty) {
      throw Exception('Escreva uma nota antes de salvar.');
    }

    final row = await SupabaseClientManager.client
        .from(_table)
        .insert({
          'fiscal_id': _fiscalId,
          'content': value,
        })
        .select()
        .single();

    return DashboardQuickNote.fromMap(Map<String, dynamic>.from(row as Map));
  }

  static Future<void> excluir(String id) async {
    await SupabaseClientManager.client
        .from(_table)
        .delete()
        .eq('fiscal_id', _fiscalId)
        .eq('id', id);
  }
}
