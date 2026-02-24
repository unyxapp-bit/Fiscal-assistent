import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/fiscal_provider.dart';

/// Tela exibida quando o fiscal está de folga
class FolgaScreen extends StatelessWidget {
  const FolgaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<FiscalProvider>(
          builder: (context, fiscalProvider, _) {
            // final fiscal = fiscalProvider.fiscal; // Pode ser usado no futuro
            final now = DateTime.now();
            final proximoTurno = _calcularProximoTurno(now);

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingLG),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ícone de folga
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.beach_access,
                        size: 60,
                        color: AppColors.success,
                      ),
                    ),

                    const SizedBox(height: Dimensions.spacingLG),

                    // Relógio atual
                    Text(
                      DateFormat('HH:mm:ss').format(now),
                      style: AppTextStyles.headingLarge.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: Dimensions.spacingSM),

                    // Data atual
                    Text(
                      DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'pt_BR')
                          .format(now),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: Dimensions.spacingXL),

                    // Status de folga
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingLG,
                        vertical: Dimensions.paddingMD,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusMD),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.sentiment_satisfied_alt,
                                color: AppColors.success,
                                size: 28,
                              ),
                              const SizedBox(width: Dimensions.spacingSM),
                              Text(
                                'VOCÊ ESTÁ DE FOLGA',
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.spacingSM),
                          Text(
                            'Aproveite seu dia de descanso!',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: Dimensions.spacingXL),

                    // Próximo turno
                    if (proximoTurno != null) ...[
                      Container(
                        padding: const EdgeInsets.all(Dimensions.paddingLG),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSection,
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusMD),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.work_outline,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: Dimensions.spacingSM),
                                Text(
                                  'Próximo turno',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Dimensions.spacingMD),
                            Text(
                              DateFormat('EEEE, dd/MM', 'pt_BR')
                                  .format(proximoTurno),
                              style: AppTextStyles.headingMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: Dimensions.spacingXS),
                            Text(
                              'às ${DateFormat('HH:mm').format(proximoTurno)}',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: Dimensions.spacingXL),

                    // Ações rápidas
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/escala');
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Ver Escala Semanal'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingMD,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusMD,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: Dimensions.spacingMD),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/configuracoes');
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Configurações'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingMD,
                              ),
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusMD,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: Dimensions.spacingXL),

                    // Informações adicionais
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingMD),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSM),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_off,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: Dimensions.spacingSM),
                          Expanded(
                            child: Text(
                              'Notificações silenciadas durante a folga',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Calcula o próximo turno baseado na data atual
  /// TODO: Integrar com a escala real do colaborador
  DateTime? _calcularProximoTurno(DateTime now) {
    // Se for sexta-feira, próximo turno é segunda
    if (now.weekday == DateTime.friday) {
      return DateTime(now.year, now.month, now.day + 3, 7, 40);
    }
    // Se for sábado, próximo turno é segunda
    if (now.weekday == DateTime.saturday) {
      return DateTime(now.year, now.month, now.day + 2, 7, 40);
    }
    // Se for domingo, próximo turno é segunda
    if (now.weekday == DateTime.sunday) {
      return DateTime(now.year, now.month, now.day + 1, 7, 40);
    }
    // Qualquer outro dia, próximo turno é amanhã
    return DateTime(now.year, now.month, now.day + 1, 7, 40);
  }
}
