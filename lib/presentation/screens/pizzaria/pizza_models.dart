// lib/modules/pizza/pizza_models.dart

import 'package:supabase_flutter/supabase_flutter.dart';

final _db = Supabase.instance.client;

// ============================================================
// MODELS
// ============================================================

class Pizza {
  final String id;
  final String nome;
  final String tamanho; // 'grande' | 'media'
  final String? ingredientes;
  final bool ativa;

  Pizza(
      {required this.id,
      required this.nome,
      required this.tamanho,
      this.ingredientes,
      this.ativa = true});

  factory Pizza.fromMap(Map<String, dynamic> m) => Pizza(
        id: m['id'],
        nome: m['nome'],
        tamanho: m['tamanho'],
        ingredientes: m['ingredientes'],
        ativa: m['ativa'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'tamanho': tamanho,
        'ingredientes': ingredientes,
        'ativa': ativa,
      };

  String get tamanhoLabel => tamanho == 'grande' ? 'Grande' : 'Média';
}

// ------------------------------------------------------------

class ItemPedido {
  final String pizzaId;
  final String pizzaNome;
  final String pizzaTamanho;
  final String? pizza2Id;
  final String? pizza2Nome;
  final int quantidade;
  final bool ehMeioAMeio;

  ItemPedido({
    required this.pizzaId,
    required this.pizzaNome,
    required this.pizzaTamanho,
    this.pizza2Id,
    this.pizza2Nome,
    this.quantidade = 1,
    this.ehMeioAMeio = false,
  });

  String get descricao {
    if (ehMeioAMeio) return '$pizzaNome / ${pizza2Nome ?? ''}';
    return pizzaNome;
  }

  String get tamanhoLabel => pizzaTamanho == 'grande' ? 'Grande' : 'Média';
}

// ------------------------------------------------------------

class PedidoPizza {
  final String? id;
  final String? nomeCliente;
  final String? codigoEntrega;
  final String? endereco;
  final String? bairro;
  final String? telefone;
  final String? referencia;
  final DateTime dataPedido;
  final String horarioPedido; // "HH:mm"
  final String? observacoes;
  String status; // 'aberto' | 'pronto' | 'entregue'
  final List<ItemPedido> itens;

  PedidoPizza({
    this.id,
    this.nomeCliente,
    this.codigoEntrega,
    this.endereco,
    this.bairro,
    this.telefone,
    this.referencia,
    required this.dataPedido,
    required this.horarioPedido,
    this.observacoes,
    this.status = 'aberto',
    this.itens = const [],
  });

  factory PedidoPizza.fromMap(Map<String, dynamic> m, List<ItemPedido> itens) {
    return PedidoPizza(
      id: m['id'],
      nomeCliente: m['nome_cliente'] as String?,
      codigoEntrega: m['codigo_entrega'] as String?,
      endereco: m['endereco'] as String?,
      bairro: m['bairro'] as String?,
      telefone: m['telefone'] as String?,
      referencia: m['referencia'] as String?,
      dataPedido: DateTime.parse(m['data_pedido']),
      horarioPedido: (m['horario_pedido'] as String).substring(0, 5),
      observacoes: m['observacoes'] as String?,
      status: m['status'],
      itens: itens,
    );
  }
}

// ============================================================
// SERVICE
// ============================================================

class PizzaService {
  static String _textoObrigatorio(String? valor) => (valor ?? '').trim();

  static String? _textoOpcional(String? valor) {
    final t = valor?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  static bool _erroColunaInexistente(Object erro) {
    final msg = erro.toString().toLowerCase();
    return msg.contains('column') && msg.contains('does not exist');
  }

  static Map<String, dynamic> _payloadPedido(
    PedidoPizza pedido, {
    bool incluirCamposNovos = true,
  }) {
    final payload = <String, dynamic>{
      'nome_cliente': _textoObrigatorio(pedido.nomeCliente),
      'codigo_entrega': _textoObrigatorio(pedido.codigoEntrega),
      'data_pedido': pedido.dataPedido.toIso8601String().substring(0, 10),
      'horario_pedido': pedido.horarioPedido,
      'observacoes': _textoOpcional(pedido.observacoes),
      'status': pedido.status,
    };

    if (incluirCamposNovos) {
      payload.addAll({
        'endereco': _textoOpcional(pedido.endereco),
        'bairro': _textoOpcional(pedido.bairro),
        'telefone': _textoOpcional(pedido.telefone),
        'referencia': _textoOpcional(pedido.referencia),
      });
    }

    return payload;
  }

  // ---------- PIZZAS ----------

  static Future<List<Pizza>> listarPizzas({bool somenteAtivas = true}) async {
    var query = _db.from('pizzas').select().order('tamanho').order('nome');
    if (somenteAtivas) {
      query = _db
          .from('pizzas')
          .select()
          .eq('ativa', true)
          .order('tamanho')
          .order('nome');
    }
    final data = await query;
    return (data as List).map((e) => Pizza.fromMap(e)).toList();
  }

  static Future<void> salvarPizza(Pizza pizza) async {
    await _db.from('pizzas').insert(pizza.toMap());
  }

  static Future<void> atualizarPizza(String id, Pizza pizza) async {
    await _db.from('pizzas').update(pizza.toMap()).eq('id', id);
  }

  static Future<void> toggleAtivaPizza(String id, bool ativa) async {
    await _db.from('pizzas').update({'ativa': ativa}).eq('id', id);
  }

  static Future<void> deletarPizza(String id) async {
    await _db.from('pizzas').delete().eq('id', id);
  }

  // ---------- PEDIDOS ----------

  static Future<List<PedidoPizza>> listarPedidos() async {
    final data = await _db
        .from('pedidos_pizza')
        .select()
        .order('created_at', ascending: false);

    final pedidos = <PedidoPizza>[];
    for (final row in data as List) {
      final itens = await _buscarItens(row['id']);
      pedidos.add(PedidoPizza.fromMap(row, itens));
    }
    return pedidos;
  }

  static Future<List<ItemPedido>> _buscarItens(String pedidoId) async {
    final data =
        await _db.from('itens_pedido').select().eq('pedido_id', pedidoId);

    final pizzas = await listarPizzas(somenteAtivas: false);
    final pizzaMap = {for (var p in pizzas) p.id: p};

    return (data as List).map((row) {
      final p1 = pizzaMap[row['pizza_id']]!;
      final p2 = row['pizza2_id'] != null ? pizzaMap[row['pizza2_id']] : null;
      return ItemPedido(
        pizzaId: p1.id,
        pizzaNome: p1.nome,
        pizzaTamanho: p1.tamanho,
        pizza2Id: p2?.id,
        pizza2Nome: p2?.nome,
        quantidade: row['quantidade'],
        ehMeioAMeio: row['eh_meio_a_meio'],
      );
    }).toList();
  }

  static Future<String> criarPedido(PedidoPizza pedido) async {
    dynamic result;
    try {
      result = await _db
          .from('pedidos_pizza')
          .insert(_payloadPedido(pedido))
          .select()
          .single();
    } catch (e) {
      if (!_erroColunaInexistente(e)) rethrow;
      result = await _db
          .from('pedidos_pizza')
          .insert(_payloadPedido(pedido, incluirCamposNovos: false))
          .select()
          .single();
    }

    final pedidoId = result['id'] as String;

    for (final item in pedido.itens) {
      await _db.from('itens_pedido').insert({
        'pedido_id': pedidoId,
        'pizza_id': item.pizzaId,
        'pizza2_id': item.pizza2Id,
        'quantidade': item.quantidade,
        'eh_meio_a_meio': item.ehMeioAMeio,
      });
    }

    return pedidoId;
  }

  static Future<void> atualizarPedido(PedidoPizza pedido) async {
    if (pedido.id == null || pedido.id!.isEmpty) {
      throw Exception('Pedido sem ID para atualizar.');
    }

    final pedidoId = pedido.id!;

    try {
      await _db
          .from('pedidos_pizza')
          .update(_payloadPedido(pedido))
          .eq('id', pedidoId);
    } catch (e) {
      if (!_erroColunaInexistente(e)) rethrow;
      await _db
          .from('pedidos_pizza')
          .update(_payloadPedido(pedido, incluirCamposNovos: false))
          .eq('id', pedidoId);
    }

    await _db.from('itens_pedido').delete().eq('pedido_id', pedidoId);

    if (pedido.itens.isNotEmpty) {
      final itens = pedido.itens
          .map((item) => {
                'pedido_id': pedidoId,
                'pizza_id': item.pizzaId,
                'pizza2_id': item.pizza2Id,
                'quantidade': item.quantidade,
                'eh_meio_a_meio': item.ehMeioAMeio,
              })
          .toList();
      await _db.from('itens_pedido').insert(itens);
    }
  }

  static Future<void> atualizarStatus(String id, String status) async {
    await _db.from('pedidos_pizza').update({'status': status}).eq('id', id);
  }

  static Future<void> excluirPedido(String id) async {
    await _db.from('pedidos_pizza').delete().eq('id', id);
  }
}
