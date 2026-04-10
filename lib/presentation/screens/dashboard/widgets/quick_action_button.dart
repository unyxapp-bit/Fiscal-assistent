import 'package:flutter/material.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/theme/app_theme.dart';

/// Quick action button on dashboard
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final String? subtitle;

  /// Number shown as red badge at icon corner
  final String? badge;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingMD,
            vertical: Dimensions.paddingMD,
          ),
          decoration: AppStyles.softCard(
            context: context,
            tint: color,
            radius: tokens.cardRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(tokens.inputRadius),
                          color: color.withValues(alpha: 0.10),
                          border:
                              Border.all(color: color.withValues(alpha: 0.16)),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      if (badge != null)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: tokens.cardBackground, width: 1.5),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: AppStyles.softTile(
                      context: context,
                      tint: color,
                      radius: 999,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: color,
                      size: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Dimensions.spacingSM),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
