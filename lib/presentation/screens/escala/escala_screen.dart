import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/escala_provider.dart';
import 'escala_dia_screen.dart';

class EscalaScreen extends StatefulWidget {
  const EscalaScreen({super.key});

  @override
  State<EscalaScreen> createState() => _EscalaScreenState();
}

class _EscalaScreenState extends State<EscalaScreen> {
  DateTime _semanaBase = DateTime.now();

  /// Segunda-feira da semana atual
  DateTime get _segunda {
    final d = _semanaBase;
    return d.subtract(Duration(days: d.weekday - 1));
  }

  List<DateTime> get _diasDaSemana =>
      List.generate(7, (i) => _segunda.add(Duration(days: i)));

  bool _ehHoje(DateTime d) {
    final h = DateTime.now();
    return d.year == h.year && d.month == h.month && d.day == h.day;
  }

  void _semanaAnterior() =>
      setState(() => _semanaBase = _semanaBase.subtract(const Duration(days: 7)));

  void _semanaSeguinte() =>
      setState(() => _semanaBase = _semanaBase.add(const Duration(days: 7)));

  void _semanaAtual() => setState(() => _semanaBase = DateTime.now());

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EscalaProvider>(context);
    final diasSemana = _diasDaSemana;
    final mesAno = DateFormat('MMMM yyyy', 'pt_BR').format(_segunda);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Escala Semanal'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _semanaAtual,
            child: const Text('Hoje'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Navegação de semana
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingMD, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _semanaAnterior,
                ),
                Text(
                  mesAno,
                  style: AppTextStyles.h4,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _semanaSeguinte,
                ),
              ],
            ),
          ),

          // Lista de dias
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              itemCount: 7,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: Dimensions.spacingSM),
              itemBuilder: (context, index) {
                final dia = diasSemana[index];
                final turnos = provider.getTurnosByData(dia);
                final trabalhando =
                    turnos.where((t) => t.trabalhando).length;
                final folgas =
                    turnos.where((t) => t.folga || t.feriado).length;
                final hoje = _ehHoje(dia);

                final nomeDia = DateFormat('EEEE', 'pt_BR').format(dia);

                return Card(
                  color: hoje
                      ? AppColors.primary.withValues(alpha: 0.07)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.borderRadius),
                    side: hoje
                        ? const BorderSide(
                            color: AppColors.primary, width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: hoje
                            ? AppColors.primary
                            : AppColors.backgroundSection,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dia.day.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: hoje
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            DateFormat('MMM', 'pt_BR')
                                .format(dia)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: hoje
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      _capitalizar(nomeDia),
                      style: AppTextStyles.h4.copyWith(
                        color: hoje
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: turnos.isEmpty
                        ? Text(
                            'Sem escala cadastrada',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          )
                        : Text(
                            '$trabalhando trabalhando'
                            '${folgas > 0 ? " • $folgas folga(s)" : ""}',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (turnos.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${turnos.length}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textSecondary),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EscalaDiaScreen(data: dia),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
