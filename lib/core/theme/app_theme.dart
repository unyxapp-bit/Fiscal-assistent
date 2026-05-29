import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

enum AppThemeVariant { bento, gamer }

class AppThemeController extends ChangeNotifier {
  AppThemeController({AppThemeVariant initialVariant = AppThemeVariant.bento})
      : _variant = initialVariant {
    AppThemes.setActiveVariant(initialVariant);
  }

  AppThemeVariant _variant;

  AppThemeVariant get variant => _variant;
  bool get isGamer => _variant == AppThemeVariant.gamer;
  ThemeMode get themeMode => isGamer ? ThemeMode.dark : ThemeMode.light;

  void setVariant(AppThemeVariant variant) {
    if (_variant == variant) return;
    _variant = variant;
    AppThemes.setActiveVariant(variant);
    notifyListeners();
  }

  void useBento() => setVariant(AppThemeVariant.bento);
  void useGamer() => setVariant(AppThemeVariant.gamer);
  void toggle() =>
      setVariant(isGamer ? AppThemeVariant.bento : AppThemeVariant.gamer);
}

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final Color background;
  final Color backgroundSection;
  final Color cardBackground;
  final Color cardBorder;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnColor;
  final Color primary;
  final Color secondary;
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;
  final Color alertCritical;
  final Color alertWarning;
  final Color alertInfo;
  final Color alertSuccess;
  final Color shadowColor;
  final double cardRadius;
  final double inputRadius;
  final double buttonRadius;
  final double sheetRadius;
  final double cardElevation;

  const AppThemeTokens({
    required this.background,
    required this.backgroundSection,
    required this.cardBackground,
    required this.cardBorder,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnColor,
    required this.primary,
    required this.secondary,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.alertCritical,
    required this.alertWarning,
    required this.alertInfo,
    required this.alertSuccess,
    required this.shadowColor,
    required this.cardRadius,
    required this.inputRadius,
    required this.buttonRadius,
    required this.sheetRadius,
    required this.cardElevation,
  });

  static const AppThemeTokens bento = AppThemeTokens(
    background: Color(0xFFF4F6F8),
    backgroundSection: Color(0xFFE9EEF4),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFD8DEE8),
    divider: Color(0xFFC8D1DC),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF526071),
    textOnColor: Color(0xFFFFFFFF),
    primary: Color(0xFF0F766E),
    secondary: Color(0xFFE7F7F4),
    success: Color(0xFF15803D),
    danger: Color(0xFFB91C1C),
    warning: Color(0xFFB45309),
    info: Color(0xFF2563EB),
    alertCritical: Color(0xFFFFE4E6),
    alertWarning: Color(0xFFFFF1D6),
    alertInfo: Color(0xFFE7F0FF),
    alertSuccess: Color(0xFFE8F7EE),
    shadowColor: Color(0xFF0F172A),
    cardRadius: 8,
    inputRadius: 8,
    buttonRadius: 8,
    sheetRadius: 14,
    cardElevation: 0,
  );

  static const AppThemeTokens gamer = AppThemeTokens(
    background: Color(0xFF0B0F14),
    backgroundSection: Color(0xFF111821),
    cardBackground: Color(0xFF151C25),
    cardBorder: Color(0xFF263241),
    divider: Color(0xFF2B3746),
    textPrimary: Color(0xFFE7EDF4),
    textSecondary: Color(0xFF9AA7B7),
    textOnColor: Color(0xFF041816),
    primary: Color(0xFF2DD4BF),
    secondary: Color(0xFF0D2C2A),
    success: Color(0xFF4ADE80),
    danger: Color(0xFFFB7185),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    alertCritical: Color(0xFF341821),
    alertWarning: Color(0xFF2D230D),
    alertInfo: Color(0xFF10243F),
    alertSuccess: Color(0xFF102B1C),
    shadowColor: Color(0xFF020617),
    cardRadius: 8,
    inputRadius: 8,
    buttonRadius: 8,
    sheetRadius: 14,
    cardElevation: 2,
  );

  @override
  AppThemeTokens copyWith({
    Color? background,
    Color? backgroundSection,
    Color? cardBackground,
    Color? cardBorder,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textOnColor,
    Color? primary,
    Color? secondary,
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    Color? alertCritical,
    Color? alertWarning,
    Color? alertInfo,
    Color? alertSuccess,
    Color? shadowColor,
    double? cardRadius,
    double? inputRadius,
    double? buttonRadius,
    double? sheetRadius,
    double? cardElevation,
  }) {
    return AppThemeTokens(
      background: background ?? this.background,
      backgroundSection: backgroundSection ?? this.backgroundSection,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textOnColor: textOnColor ?? this.textOnColor,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      alertCritical: alertCritical ?? this.alertCritical,
      alertWarning: alertWarning ?? this.alertWarning,
      alertInfo: alertInfo ?? this.alertInfo,
      alertSuccess: alertSuccess ?? this.alertSuccess,
      shadowColor: shadowColor ?? this.shadowColor,
      cardRadius: cardRadius ?? this.cardRadius,
      inputRadius: inputRadius ?? this.inputRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      sheetRadius: sheetRadius ?? this.sheetRadius,
      cardElevation: cardElevation ?? this.cardElevation,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      background: Color.lerp(background, other.background, t) ?? background,
      backgroundSection: Color.lerp(
            backgroundSection,
            other.backgroundSection,
            t,
          ) ??
          backgroundSection,
      cardBackground:
          Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t) ?? cardBorder,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textOnColor: Color.lerp(textOnColor, other.textOnColor, t) ?? textOnColor,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      success: Color.lerp(success, other.success, t) ?? success,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      alertCritical:
          Color.lerp(alertCritical, other.alertCritical, t) ?? alertCritical,
      alertWarning:
          Color.lerp(alertWarning, other.alertWarning, t) ?? alertWarning,
      alertInfo: Color.lerp(alertInfo, other.alertInfo, t) ?? alertInfo,
      alertSuccess:
          Color.lerp(alertSuccess, other.alertSuccess, t) ?? alertSuccess,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t) ?? shadowColor,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t) ?? cardRadius,
      inputRadius: lerpDouble(inputRadius, other.inputRadius, t) ?? inputRadius,
      buttonRadius:
          lerpDouble(buttonRadius, other.buttonRadius, t) ?? buttonRadius,
      sheetRadius: lerpDouble(sheetRadius, other.sheetRadius, t) ?? sheetRadius,
      cardElevation:
          lerpDouble(cardElevation, other.cardElevation, t) ?? cardElevation,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get appTheme =>
      Theme.of(this).extension<AppThemeTokens>() ?? AppThemes.activeTokens;
}

class AppThemes {
  static AppThemeVariant _activeVariant = AppThemeVariant.bento;

  static AppThemeVariant get activeVariant => _activeVariant;

  static AppThemeTokens get activeTokens => tokensFor(_activeVariant);

  static void setActiveVariant(AppThemeVariant variant) {
    _activeVariant = variant;
  }

  static AppThemeTokens tokensFor(AppThemeVariant variant) {
    return variant == AppThemeVariant.gamer
        ? AppThemeTokens.gamer
        : AppThemeTokens.bento;
  }

  static ThemeData themeFor(AppThemeVariant variant) {
    return variant == AppThemeVariant.gamer ? gamerTheme : bentoTheme;
  }

  static final ThemeData bentoTheme = _buildTheme(
    tokens: AppThemeTokens.bento,
    brightness: Brightness.light,
    textTheme: _bentoTextTheme(AppThemeTokens.bento),
  );

  static final ThemeData gamerTheme = _buildTheme(
    tokens: AppThemeTokens.gamer,
    brightness: Brightness.dark,
    textTheme: _gamerTextTheme(AppThemeTokens.gamer),
  );

  static ThemeData _buildTheme({
    required AppThemeTokens tokens,
    required Brightness brightness,
    required TextTheme textTheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: tokens.primary,
            onPrimary: tokens.textOnColor,
            secondary: tokens.info,
            onSecondary: tokens.textOnColor,
            error: tokens.danger,
            onError: tokens.textOnColor,
            surface: tokens.cardBackground,
            onSurface: tokens.textPrimary,
          )
        : ColorScheme.light(
            primary: tokens.primary,
            onPrimary: tokens.textOnColor,
            secondary: tokens.info,
            onSecondary: tokens.textOnColor,
            error: tokens.danger,
            onError: tokens.textOnColor,
            surface: tokens.cardBackground,
            onSurface: tokens.textPrimary,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: tokens.background,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: tokens.textPrimary,
        displayColor: tokens.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.cardBackground,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: tokens.cardBackground,
        elevation: tokens.cardElevation,
        shadowColor: tokens.shadowColor.withValues(alpha: isDark ? 0.18 : 0.06),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerColor: tokens.divider,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        labelStyle:
            textTheme.labelMedium?.copyWith(color: tokens.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.inputRadius),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.inputRadius),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.inputRadius),
          borderSide: BorderSide(color: tokens.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
          backgroundColor: WidgetStatePropertyAll(tokens.primary),
          foregroundColor: WidgetStatePropertyAll(tokens.textOnColor),
          elevation: WidgetStatePropertyAll(tokens.cardElevation),
          shadowColor: WidgetStatePropertyAll(
            tokens.shadowColor.withValues(alpha: isDark ? 0.24 : 0.10),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
            ),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
          foregroundColor: WidgetStatePropertyAll(tokens.primary),
          side: WidgetStatePropertyAll(
            BorderSide(color: tokens.cardBorder),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
            ),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(tokens.primary),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.backgroundSection,
        disabledColor: tokens.backgroundSection,
        selectedColor: tokens.secondary,
        secondarySelectedColor: tokens.secondary,
        side: BorderSide(color: tokens.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.inputRadius),
        ),
        labelStyle: textTheme.bodySmall ?? const TextStyle(),
        secondaryLabelStyle:
            (textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: tokens.primary,
        ),
        brightness: brightness,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.textSecondary,
        textColor: tokens.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.textOnColor,
        elevation: isDark ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius + 4),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.sheetRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(tokens.sheetRadius)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? tokens.cardBackground : tokens.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? tokens.textPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.inputRadius),
          side: isDark ? BorderSide(color: tokens.cardBorder) : BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: tokens.cardBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tokens.secondary,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? tokens.primary
                : tokens.textSecondary,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => (textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: states.contains(WidgetState.selected)
                ? tokens.primary
                : tokens.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: tokens.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: tokens.primary,
        unselectedLabelColor: tokens.textSecondary,
        dividerColor: tokens.cardBorder,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }

  static TextTheme _bentoTextTheme(AppThemeTokens tokens) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: tokens.textPrimary,
        height: 1.15,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
        height: 1.2,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
        height: 1.3,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
        height: 1.35,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
        height: 1.45,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
        height: 1.45,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: tokens.textSecondary,
        height: 1.3,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: tokens.textOnColor,
        height: 1.2,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: tokens.textSecondary,
        height: 1.35,
        letterSpacing: 0,
      ),
    );
  }

  static TextTheme _gamerTextTheme(AppThemeTokens tokens) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: tokens.primary,
        height: 1.15,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: tokens.textPrimary,
        height: 1.2,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: tokens.primary,
        height: 1.3,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
        height: 1.35,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
        height: 1.45,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
        height: 1.45,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: tokens.textSecondary,
        height: 1.3,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: tokens.textOnColor,
        height: 1.2,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: tokens.primary,
        height: 1.35,
        letterSpacing: 0,
      ),
    );
  }
}
