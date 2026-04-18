import 'package:flutter/material.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/theme/app_theme.dart';

/// Card de estatistica com icone e valor.
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: AppStyles.softCard(
        context: context,
        tint: color,
        radius: tokens.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(tokens.inputRadius),
              border: Border.all(
                color: color.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          SizedBox(height: Dimensions.spacingSM),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
