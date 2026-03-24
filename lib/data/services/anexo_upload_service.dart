import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/remote/supabase_client.dart';

class AnexoSelecionado {
  final String nomeArquivo;
  final Uint8List bytes;
  final bool isImagem;

  const AnexoSelecionado({
    required this.nomeArquivo,
    required this.bytes,
    required this.isImagem,
  });
}

class AnexoUploadService {
  static const _bucket = 'anexos';

  Future<AnexoSelecionado?> selecionarFoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    return AnexoSelecionado(
      nomeArquivo: file.name,
      bytes: bytes,
      isImagem: true,
    );
  }

  Future<AnexoSelecionado?> selecionarArquivo() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    return AnexoSelecionado(
      nomeArquivo: file.name,
      bytes: bytes,
      isImagem: false,
    );
  }

  Future<String> upload({
    required AnexoSelecionado anexo,
    required String fiscalId,
    required String modulo,
    required String entidadeId,
  }) async {
    final nome = _sanitizarNome(anexo.nomeArquivo);
    final path =
        '$fiscalId/$modulo/$entidadeId/${DateTime.now().millisecondsSinceEpoch}_$nome';
    final contentType = _contentType(anexo.nomeArquivo, anexo.isImagem);

    await SupabaseClientManager.client.storage.from(_bucket).uploadBinary(
          path,
          anexo.bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );

    return SupabaseClientManager.client.storage
        .from(_bucket)
        .getPublicUrl(path);
  }

  String _sanitizarNome(String nome) {
    final semEspacos = nome.replaceAll(RegExp(r'\s+'), '_');
    return semEspacos.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');
  }

  String _contentType(String nomeArquivo, bool isImagem) {
    final lower = nomeArquivo.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.csv')) return 'text/csv';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    return isImagem ? 'image/jpeg' : 'application/octet-stream';
  }
}
