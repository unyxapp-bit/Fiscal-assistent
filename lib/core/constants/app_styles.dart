import 'package:flutter/material.dart';
import 'colors.dart';

class AppStyles {
  static BoxDecoration softCard({
    Color? tint,
    double radius = 16,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (tint ?? AppColors.cardBorder).withValues(alpha: 0.35),
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: (tint ?? AppColors.textPrimary).withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ]
          : const [],
    );
  }

  static BoxDecoration softTile({
    Color? tint,
    double radius = 12,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          (tint ?? AppColors.primary).withValues(alpha: 0.04),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (tint ?? AppColors.cardBorder).withValues(alpha: 0.28),
      ),
    );
  }
}
