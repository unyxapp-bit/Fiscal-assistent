import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';

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
    final timeFormat = DateFormat('HH:mm:ss');
    final dayName = _days[_horaAtual.weekday - 1];
    final monthName = _months[_horaAtual.month - 1];
    final dateString =
        '$dayName, ${_horaAtual.day} de $monthName de ${_horaAtual.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingLG),
      decoration: AppStyles.softCard(
        tint: AppColors.primary,
        radius: Dimensions.borderRadius,
      ),
      child: Column(
        children: [
          Text(
            timeFormat.format(_horaAtual),
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            dateString,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
