import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget de relógio em tempo real com atualização a cada segundo.
class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Timer _timer;
  DateTime _horaAtual = DateTime.now();

  static const _days = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo'
  ];
  static const _months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro'
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _horaAtual = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('HH:mm:ss');
    final shortDateFormat = DateFormat('dd/MM/yyyy');
    final dayName = _days[_horaAtual.weekday - 1];
    final monthName = _months[_horaAtual.month - 1];
    final dateString =
        '$dayName, ${_horaAtual.day} de $monthName de ${_horaAtual.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
            tokens.cardBackground,
            tokens.backgroundSection,
          ],
        ),
        borderRadius: BorderRadius.circular(tokens.cardRadius + 2),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.34 : 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.shadowColor.withValues(alpha: isDark ? 0.14 : 0.06),
            blurRadius: isDark ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ClockPill(
                icon: Icons.schedule_rounded,
                label: 'Relógio oficial',
                color: AppColors.primary,
              ),
              _ClockPill(
                icon: Icons.bolt_rounded,
                label: 'Atualização ao vivo',
                color: AppColors.success,
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingMD),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              timeFormat.format(_horaAtual),
              style: AppTextStyles.h1.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 1.4,
              ),
            ),
          ),
          SizedBox(height: Dimensions.spacingXS),
          Text(
            dateString,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          SizedBox(height: Dimensions.spacingMD),
          Row(
            children: [
              Expanded(
                child: _ClockMetricTile(
                  label: 'Data',
                  value: shortDateFormat.format(_horaAtual),
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: _ClockMetricTile(
                  label: 'Dia',
                  value: dayName,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClockPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ClockPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppStyles.softTile(
        context: context,
        tint: color,
        radius: 999,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ClockMetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSM,
        vertical: Dimensions.paddingSM,
      ),
      decoration: AppStyles.softTile(
        context: context,
        tint: color,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
