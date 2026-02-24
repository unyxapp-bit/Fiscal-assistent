import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';

/// Widget que mostra quando não há dados
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone grande
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary,
            ),

            const SizedBox(height: Dimensions.spacingLG),

            // Título
            Text(
              title,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: Dimensions.spacingSM),

            // Mensagem
            Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Botão opcional
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: Dimensions.spacingLG),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingMD,
                    vertical: Dimensions.paddingSM,
                  ),
                ),
                child: Text(
                  buttonLabel!,
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
