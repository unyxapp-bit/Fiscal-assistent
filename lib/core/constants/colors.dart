import 'package:flutter/material.dart';

class AppColors {
  // Fundos
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSection = Color(0xFFF5F5F5);

  // Cards
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFBDBDBD);

  // Texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnColor = Color(0xFFFFFFFF);

  // Status
  static const Color statusAtivo = Color(0xFF4CAF50); // Verde
  static const Color statusInativo = Color(0xFFF44336); // Vermelho
  static const Color statusAtencao = Color(0xFFFFC107); // Amarelo
  static const Color statusInfo = Color(0xFF2196F3); // Azul
  static const Color statusCafe = Color(0xFFFF9800); // Laranja
  static const Color statusIntervalo = Color(0xFF795548); // Marrom
  static const Color statusSelf = Color(0xFF9C27B0); // Roxo
  static const Color inactive = Color(0xFF9E9E9E); // Cinza

  // Botões e Ações
  static const Color primary = Color(0xFF2196F3); // Azul
  static const Color success = Color(0xFF4CAF50); // Verde
  static const Color danger = Color(0xFFF44336); // Vermelho
  static const Color secondary = Color(0xFFF5F5F5); // Cinza claro

  // Alertas
  static const Color alertCritical = Color(0xFFFFEBEE); // Vermelho claro
  static const Color alertWarning = Color(0xFFFFF9C4); // Amarelo claro
  static const Color alertInfo = Color(0xFFE3F2FD); // Azul claro
  static const Color alertSuccess = Color(0xFFE8F5E9); // Verde claro

  // Status adicionais
  static const Color statusSaida = Color(0xFFFF5722); // Laranja saída
  static const Color statusFolga = Color(0xFF9E9E9E); // Cinza folga

  // Cores de módulo (botões do Dashboard)
  static const Color coffee     = Color(0xFF8D6E63); // Café/pausa
  static const Color teal       = Color(0xFF009688); // Modo Folga
  static const Color cyan       = Color(0xFF0097A7); // Relatório
  static const Color pink       = Color(0xFFE91E63); // Escala
  static const Color blueGrey   = Color(0xFF607D8B); // Guia Rápido
  static const Color indigo     = Color(0xFF3F51B5); // Formulários
  static const Color deepPurple = Color(0xFF673AB7); // Procedimentos

  // Aliases adicionais
  static const Color info = statusInfo;
  static const Color warning = statusAtencao;
  static const Color border = cardBorder;
}
