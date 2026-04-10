import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppStyles {
  static BoxDecoration softCard({
    BuildContext? context,
    Color? tint,
    double? radius,
    bool elevated = true,
  }) {
    final tokens = context != null ? context.appTheme : AppThemes.activeTokens;
    final borderBase = tint ?? tokens.cardBorder;
    final backgroundColor = tokens.cardBackground;
    final shadowBase = tokens.shadowColor;
    final resolvedRadius = radius ?? tokens.cardRadius;
    final hasGlow = tokens.cardElevation > 0;
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(resolvedRadius),
      border: Border.all(
        color: borderBase.withValues(alpha: tint != null ? 0.16 : 0.72),
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: shadowBase.withValues(
                  alpha: hasGlow ? 0.14 : 0.04,
                ),
                blurRadius: hasGlow ? 18 : 10,
                offset: Offset(0, hasGlow ? 6 : 3),
              ),
            ]
          : const [],
    );
  }

  static BoxDecoration softTile({
    BuildContext? context,
    Color? tint,
    double? radius,
  }) {
    final tokens = context != null ? context.appTheme : AppThemes.activeTokens;
    final tileTint = tint ?? tokens.primary;
    final resolvedRadius = radius ?? tokens.inputRadius;
    final hasGlow = tokens.cardElevation > 0;
    return BoxDecoration(
      color: tileTint.withValues(
        alpha: hasGlow ? 0.08 : 0.03,
      ),
      borderRadius: BorderRadius.circular(resolvedRadius),
      border: Border.all(
        color: tileTint.withValues(
          alpha: hasGlow ? 0.28 : 0.16,
        ),
      ),
    );
  }
}
