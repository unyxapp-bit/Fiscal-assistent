import 'package:flutter/material.dart';
import 'colors.dart';

class AppStyles {
  static BoxDecoration softCard({
    Color? tint,
    double radius = 16,
    bool elevated = true,
  }) {
    final borderBase = tint ?? AppColors.cardBorder;
    return BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderBase.withValues(alpha: tint != null ? 0.16 : 0.72),
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ]
          : const [],
    );
  }

  static BoxDecoration softTile({
    Color? tint,
    double radius = 12,
  }) {
    final tileTint = tint ?? AppColors.primary;
    return BoxDecoration(
      color: tileTint.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: tileTint.withValues(alpha: 0.16),
      ),
    );
  }
}
