import '../../core/utils/desconto_calculator.dart';
import '../datasources/remote/supabase_client.dart';

class DescontoHistoricoItem {
  final String id;
  final String modo;
  final String produtoCodigo;
  final String produtoNome;
  final int etiquetaCentavos;
  final int sistemaCentavos;
  final double? percentual;
  final int quantidade;
  final int? leve;
  final int? pague;
  final int descontoUnitarioCentavos;
  final int descontoTotalCentavos;
  final int valorFinalTotalCentavos;
  final String mensagemCopiada;
  final DateTime createdAt;

  const DescontoHistoricoItem({
    required this.id,
    required this.modo,
    required this.produtoCodigo,
    required this.produtoNome,
    required this.etiquetaCentavos,
    required this.sistemaCentavos,
    required this.percentual,
    required this.quantidade,
    required this.leve,
    required this.pague,
    required this.descontoUnitarioCentavos,
    required this.descontoTotalCentavos,
    required this.valorFinalTotalCentavos,
    required this.mensagemCopiada,
    required this.createdAt,
  });

  factory DescontoHistoricoItem.fromMap(Map<String, dynamic> map) {
    return DescontoHistoricoItem(
      id: map['id'] as String,
      modo: (map['modo'] as String?) ?? 'comparacao',
      produtoCodigo: (map['produto_codigo'] as String?) ?? '',
      produtoNome: (map['produto_nome'] as String?) ?? '',
      etiquetaCentavos: (map['etiqueta_centavos'] as num?)?.toInt() ?? 0,
      sistemaCentavos: (map['sistema_centavos'] as num?)?.toInt() ?? 0,
      percentual: (map['percentual'] as num?)?.toDouble(),
      quantidade: (map['quantidade'] as num?)?.toInt() ?? 1,
      leve: (map['leve'] as num?)?.toInt(),
      pague: (map['pague'] as num?)?.toInt(),
      descontoUnitarioCentavos:
          (map['desconto_unitario_centavos'] as num?)?.toInt() ?? 0,
      descontoTotalCentavos:
          (map['desconto_total_centavos'] as num?)?.toInt() ?? 0,
      valorFinalTotalCentavos:
          (map['valor_final_total_centavos'] as num?)?.toInt() ?? 0,
      mensagemCopiada: (map['mensagem_copiada'] as String?) ?? '',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class DescontoHistoricoInput {
  final String modo;
  final String produtoCodigo;
  final String produtoNome;
  final double? percentual;
  final int? leve;
  final int? pague;
  final String mensagemCopiada;
  final DescontoResultado resultado;

  const DescontoHistoricoInput({
    required this.modo,
    required this.produtoCodigo,
    required this.produtoNome,
    required this.resultado,
    required this.mensagemCopiada,
    this.percentual,
    this.leve,
    this.pague,
  });

  Map<String, dynamic> toMap(String fiscalId) => {
        'fiscal_id': fiscalId,
        'modo': modo,
        'produto_codigo': produtoCodigo.trim(),
        'produto_nome': produtoNome.trim(),
        'etiqueta_centavos': resultado.etiquetaCentavos,
        'sistema_centavos': resultado.sistemaCentavos,
        'percentual': percentual,
        'quantidade': resultado.quantidade,
        'leve': leve,
        'pague': pague,
        'desconto_unitario_centavos': resultado.descontoUnitarioCentavos,
        'desconto_total_centavos': resultado.descontoTotalCentavos,
        'valor_final_total_centavos': resultado.valorFinalTotalCentavos,
        'mensagem_copiada': mensagemCopiada,
      };
}

class DescontoHistoricoService {
  static const _table = 'desconto_calculos';

  static String get _fiscalId {
    final id = SupabaseClientManager.currentUserId;
    if (id == null || id.isEmpty) {
      throw Exception('Usuario nao autenticado para registrar desconto.');
    }
    return id;
  }

  static Future<List<DescontoHistoricoItem>> listar({int limit = 12}) async {
    final rows = await SupabaseClientManager.client
        .from(_table)
        .select()
        .eq('fiscal_id', _fiscalId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((row) => DescontoHistoricoItem.fromMap(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
  }

  static Future<void> salvar(DescontoHistoricoInput input) async {
    await SupabaseClientManager.client
        .from(_table)
        .insert(input.toMap(_fiscalId));
  }
}
