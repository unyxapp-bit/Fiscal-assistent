import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/notificacao_provider.dart';

/// Helper global para exibir notificações.
///
/// Sempre limpa SnackBars anteriores antes de mostrar um novo,
/// evitando filas presas. Também adiciona o evento na tela de
/// Notificações via [NotificacaoProvider].
class AppNotif {
  AppNotif._();

  static void show(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    String tipo = 'alerta',
    Color? cor,
    SnackBarAction? acao,
    Duration duracao = const Duration(seconds: 2),
  }) {
    // Registra na tela de Notificações
    try {
      Provider.of<NotificacaoProvider>(context, listen: false)
          .adicionarNotificacao(titulo: titulo, mensagem: mensagem, tipo: tipo);
    } catch (_) {}

    // Exibe SnackBar (limpa fila primeiro para evitar travamento)
    final sm = ScaffoldMessenger.of(context);
    sm.clearSnackBars();
    sm.showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: cor,
      duration: duracao,
      action: acao,
    ));
  }
}
