import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppColors {
  static AppThemeTokens get _tokens => AppThemes.activeTokens;
  static bool get _isGamer => AppThemes.activeVariant == AppThemeVariant.gamer;

  // Backgrounds
  static Color get background => _tokens.background;
  static Color get backgroundSection => _tokens.backgroundSection;

  // Surfaces
  static Color get cardBackground => _tokens.cardBackground;
  static Color get cardBorder => _tokens.cardBorder;
  static Color get divider => _tokens.divider;

  // Text
  static Color get textPrimary => _tokens.textPrimary;
  static Color get textSecondary => _tokens.textSecondary;
  static Color get textOnColor => _tokens.textOnColor;

  // Status
  static Color get statusAtivo => _tokens.success;
  static Color get statusInativo =>
      _isGamer ? const Color(0xFFFF6B8A) : const Color(0xFFEF4444);
  static Color get statusAtencao => _tokens.warning;
  static Color get statusInfo => _tokens.info;
  static Color get statusCafe =>
      _isGamer ? const Color(0xFFFFB86B) : const Color(0xFFC2410C);
  static Color get statusIntervalo =>
      _isGamer ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static Color get statusSelf =>
      _isGamer ? const Color(0xFF22D3EE) : const Color(0xFF0891B2);
  static Color get inactive =>
      _isGamer ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // Actions
  static Color get primary => _tokens.primary;
  static Color get success => _tokens.success;
  static Color get danger => _tokens.danger;
  static Color get secondary => _tokens.secondary;

  // Alerts
  static Color get alertCritical => _tokens.alertCritical;
  static Color get alertWarning => _tokens.alertWarning;
  static Color get alertInfo => _tokens.alertInfo;
  static Color get alertSuccess => _tokens.alertSuccess;

  // Extra status
  static Color get statusSaida =>
      _isGamer ? const Color(0xFFFF8A5B) : const Color(0xFFEA580C);
  static Color get statusFolga => inactive;

  // Dashboard module colors
  static Color get coffee =>
      _isGamer ? const Color(0xFFFF9E57) : const Color(0xFF9A3412);
  static Color get teal =>
      _isGamer ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
  static Color get cyan =>
      _isGamer ? const Color(0xFF22D3EE) : const Color(0xFF0E7490);
  static Color get pink =>
      _isGamer ? const Color(0xFFFF4FD8) : const Color(0xFFDB2777);
  static Color get blueGrey =>
      _isGamer ? const Color(0xFF7C8EA6) : const Color(0xFF475569);
  static Color get indigo =>
      _isGamer ? const Color(0xFF7DD3FC) : const Color(0xFF1D4ED8);
  static Color get deepPurple =>
      _isGamer ? const Color(0xFF38BDF8) : const Color(0xFF0B3B8A);
  static Color get brown =>
      _isGamer ? const Color(0xFFA1887F) : const Color(0xFF795548);
  static Color get outro =>
      _isGamer ? const Color(0xFF9FA8DA) : const Color(0xFF5C6BC0);

  // Aliases
  static Color get info => statusInfo;
  static Color get warning => statusAtencao;
  static Color get border => cardBorder;
}
