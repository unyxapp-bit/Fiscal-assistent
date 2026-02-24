import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Model para notificação
class Notificacao {
  final String id;
  final String titulo;
  final String mensagem;
  final String tipo; // intervalo, cafe, saida, alerta
  final DateTime criadoEm;
  final bool lida;

  Notificacao({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.criadoEm,
    this.lida = false,
  });

  Notificacao copyWith({
    String? id,
    String? titulo,
    String? mensagem,
    String? tipo,
    DateTime? criadoEm,
    bool? lida,
  }) {
    return Notificacao(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensagem: mensagem ?? this.mensagem,
      tipo: tipo ?? this.tipo,
      criadoEm: criadoEm ?? this.criadoEm,
      lida: lida ?? this.lida,
    );
  }
}

/// Provider para gerenciar notificações
class NotificacaoProvider with ChangeNotifier {
  final List<Notificacao> _notificacoes = [];

  List<Notificacao> get notificacoes => _notificacoes;
  List<Notificacao> get naoLidas =>
      _notificacoes.where((n) => !n.lida).toList();
  int get totalNaoLidas => naoLidas.length;

  /// Adiciona nova notificação
  void adicionarNotificacao({
    required String titulo,
    required String mensagem,
    required String tipo,
  }) {
    _notificacoes.insert(
      0,
      Notificacao(
        id: const Uuid().v4(),
        titulo: titulo,
        mensagem: mensagem,
        tipo: tipo,
        criadoEm: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Marca como lida
  void marcarComoLida(String id) {
    final index = _notificacoes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notificacoes[index] = _notificacoes[index].copyWith(lida: true);
      notifyListeners();
    }
  }

  /// Marca todas como lidas
  void marcarTodasComoLidas() {
    for (int i = 0; i < _notificacoes.length; i++) {
      if (!_notificacoes[i].lida) {
        _notificacoes[i] = _notificacoes[i].copyWith(lida: true);
      }
    }
    notifyListeners();
  }

  /// Remove notificação
  void removerNotificacao(String id) {
    _notificacoes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// Limpa todas
  void limparNotificacoes() {
    _notificacoes.clear();
    notifyListeners();
  }
}
