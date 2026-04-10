import 'package:flutter/material.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';

/// Shown when a list has no data.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Container(
          decoration: AppStyles.softCard(tint: AppColors.inactive, radius: 20),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingLG,
            vertical: Dimensions.paddingXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(icon, size: 34, color: AppColors.primary),
              ),
              SizedBox(height: Dimensions.spacingLG),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.spacingSM),
              Text(
                message,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (buttonLabel != null && onButtonPressed != null) ...[
                SizedBox(height: Dimensions.spacingLG),
                ElevatedButton.icon(
                  onPressed: onButtonPressed,
                  icon: Icon(Icons.arrow_forward, size: 18),
                  label: Text(buttonLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
