import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppTextStyles {
  static TextTheme get _textTheme =>
      AppThemes.themeFor(AppThemes.activeVariant).textTheme;

  // Headers
  static TextStyle get h1 => _textTheme.displayLarge ?? const TextStyle();
  static TextStyle get h2 => _textTheme.displayMedium ?? const TextStyle();
  static TextStyle get h3 => _textTheme.titleLarge ?? const TextStyle();
  static TextStyle get h4 => _textTheme.titleMedium ?? const TextStyle();

  // Body
  static TextStyle get body => _textTheme.bodyMedium ?? const TextStyle();
  static TextStyle get label => _textTheme.labelMedium ?? const TextStyle();
  static TextStyle get caption => _textTheme.bodySmall ?? const TextStyle();

  // Button
  static TextStyle get button => _textTheme.labelLarge ?? const TextStyle();

  // Aliases for compatibility
  static TextStyle get title => h2;
  static TextStyle get subtitle => label;
  static TextStyle get headingLarge => h1;
  static TextStyle get headingMedium => h2;
  static TextStyle get bodyLarge => body;
  static TextStyle get bodyMedium => body;
  static TextStyle get bodySmall => caption;
}
