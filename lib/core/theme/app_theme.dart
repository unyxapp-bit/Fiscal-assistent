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
    background: Color(0xFFF8FAFC),
    backgroundSection: Color(0xFFF1F5F9),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE2E8F0),
    divider: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textOnColor: Color(0xFFFFFFFF),
    primary: Color(0xFF2563EB),
    secondary: Color(0xFFEFF6FF),
    success: Color(0xFF10B981),
    danger: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF2563EB),
    alertCritical: Color(0xFFFEF2F2),
    alertWarning: Color(0xFFFFF7ED),
    alertInfo: Color(0xFFEFF6FF),
    alertSuccess: Color(0xFFECFDF5),
    shadowColor: Color(0xFF0F172A),
    cardRadius: 24,
    inputRadius: 18,
    buttonRadius: 18,
    sheetRadius: 24,
    cardElevation: 0,
  );

  static const AppThemeTokens gamer = AppThemeTokens(
    background: Color(0xFF030712),
    backgroundSection: Color(0xFF0B1220),
    cardBackground: Color(0xFF111827),
    cardBorder: Color(0xFF134E4A),
    divider: Color(0xFF1F2937),
    textPrimary: Color(0xFFE6FFFB),
    textSecondary: Color(0xFF94A3B8),
    textOnColor: Color(0xFF03120F),
    primary: Color(0xFF5EEAD4),
    secondary: Color(0xFF0F2F2D),
    success: Color(0xFF4ADE80),
    danger: Color(0xFFFB7185),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF22D3EE),
    alertCritical: Color(0xFF2A1020),
    alertWarning: Color(0xFF261B05),
    alertInfo: Color(0xFF07212B),
    alertSuccess: Color(0xFF062417),
    shadowColor: Color(0xFF5EEAD4),
    cardRadius: 12,
    inputRadius: 12,
    buttonRadius: 12,
    sheetRadius: 18,
    cardElevation: 8,
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
      scaffoldBackgroundColor: tokens.background,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: tokens.textPrimary,
        displayColor: tokens.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: tokens.cardBackground,
        elevation: tokens.cardElevation,
        shadowColor: tokens.shadowColor.withValues(alpha: isDark ? 0.22 : 0.10),
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
          vertical: 14,
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
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
          backgroundColor: WidgetStatePropertyAll(tokens.primary),
          foregroundColor: WidgetStatePropertyAll(tokens.textOnColor),
          elevation: WidgetStatePropertyAll(tokens.cardElevation),
          shadowColor: WidgetStatePropertyAll(
            tokens.shadowColor.withValues(alpha: isDark ? 0.24 : 0.10),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
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
          borderRadius: BorderRadius.circular(isDark ? 10 : 14),
        ),
        labelStyle: textTheme.bodySmall ?? TextStyle(),
        secondaryLabelStyle: (textTheme.bodySmall ?? TextStyle()).copyWith(
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
        elevation: isDark ? 6 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius + 10),
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
        backgroundColor: tokens.cardBackground.withValues(alpha: 0.94),
        indicatorColor: tokens.secondary,
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: tokens.textSecondary),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          (textTheme.bodySmall ?? TextStyle()).copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: tokens.primary,
        indicatorSize: TabBarIndicatorSize.label,
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
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: tokens.textPrimary,
        height: 1.15,
        letterSpacing: -0.6,
      ),
      displayMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
        height: 1.2,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: tokens.textSecondary,
        height: 1.3,
        letterSpacing: 0.2,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: tokens.textOnColor,
        height: 1.2,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: tokens.textSecondary,
        height: 1.35,
        letterSpacing: 0.2,
      ),
    );
  }

  static TextTheme _gamerTextTheme(AppThemeTokens tokens) {
    const monoFallback = <String>['Courier New', 'monospace'];
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: tokens.primary,
        height: 1.1,
        letterSpacing: 0.8,
      ),
      displayMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: tokens.textPrimary,
        height: 1.15,
        letterSpacing: 0.6,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: tokens.primary,
        height: 1.25,
        letterSpacing: 0.8,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
        height: 1.3,
        letterSpacing: 0.5,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
        height: 1.45,
        fontFamilyFallback: monoFallback,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
        height: 1.45,
        fontFamilyFallback: monoFallback,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: tokens.textSecondary,
        height: 1.3,
        letterSpacing: 0.3,
        fontFamilyFallback: monoFallback,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: tokens.textOnColor,
        height: 1.2,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: tokens.primary,
        height: 1.35,
        letterSpacing: 0.4,
      ),
    );
  }
}
