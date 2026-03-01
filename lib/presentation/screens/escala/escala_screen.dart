import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/datasources/remote/supabase_client.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/escala_provider.dart';
import 'escala_dia_screen.dart';

class EscalaScreen extends StatefulWidget {
  const EscalaScreen({super.key});

  @override
  State<EscalaScreen> createState() => _EscalaScreenState();
}

class _EscalaScreenState extends State<EscalaScreen> {
  DateTime _semanaBase = DateTime.now();

  // ── Semana ───────────────────────────────────────────────────────────────

  DateTime get _segunda {
    final d = _semanaBase;
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  List<DateTime> get _diasDaSemana =>
      List.generate(7, (i) => _segunda.add(Duration(days: i)));

  bool _ehHoje(DateTime d) {
    final h = DateTime.now();
    return d.year == h.year && d.month == h.month && d.day == h.day;
  }

  bool get _ehSemanaAtual {
    final h = DateTime.now();
    final seg = _segunda;
    final dom = seg.add(const Duration(days: 6));
    return !h.isBefore(seg) && !h.isAfter(dom);
  }

  void _semanaAnterior() =>
      setState(() => _semanaBase = _semanaBase.subtract(const Duration(days: 7)));

  void _semanaSeguinte() =>
      setState(() => _semanaBase = _semanaBase.add(const Duration(days: 7)));

  void _semanaAtual() => setState(() => _semanaBase = DateTime.now());

  // ── Colaboradores: garante carregamento ──────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colaboradorProvider =
        context.read<ColaboradorProvider>();
    final authUserId =
        SupabaseClientManager.currentUserId ?? '';
    if (colaboradorProvider.todosColaboradores.isEmpty &&
        authUserId.isNotEmpty) {
      colaboradorProvider.loadColaboradores(authUserId);
    }
  }

  // ── Geração automática ───────────────────────────────────────────────────

  Future<void> _gerarEscala(BuildContext context) async {
    final colaboradorProvider =
        context.read<ColaboradorProvider>();
    final escalaProvider = context.read<EscalaProvider>();
    final colaboradores = colaboradorProvider.todosColaboradores;

    if (colaboradores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Nenhum colaborador cadastrado. Cadastre colaboradores primeiro.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Verifica se já existe algum turno na semana
    final diasDaSemana = _diasDaSemana;
    final temEscalaExistente = diasDaSemana.any((dia) =>
        escalaProvider.getTurnosByData(dia).isNotEmpty);

    bool substituir = false;

    if (temEscalaExistente) {
      final resposta = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gerar Escala Automática'),
          content: const Text(
            'Esta semana já possui turnos cadastrados.\n'
            'Deseja substituir os existentes ou apenas preencher os dias vazios?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancelar'),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'preencher'),
              child: const Text('Só dias vazios'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'substituir'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('Substituir tudo'),
            ),
          ],
        ),
      );

      if (resposta == null || resposta == 'cancelar') return;
      substituir = resposta == 'substituir';
    } else {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gerar Escala Automática'),
          content: Text(
            'Preencher a escala da semana de '
            '${DateFormat("dd/MM", "pt_BR").format(_segunda)} a '
            '${DateFormat("dd/MM", "pt_BR").format(_segunda.add(const Duration(days: 6)))} '
            'com base nos registros de ponto?\n\n'
            '${colaboradores.where((c) => c.ativo).length} colaboradores ativos serão incluídos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('Gerar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    final resultado = await escalaProvider.gerarEscalaDaSemana(
      colaboradores: colaboradores,
      segunda: _segunda,
      substituirExistentes: substituir,
    );

    if (!context.mounted) return;

    final criados = resultado['criados'] ?? 0;
    final semRegistro = resultado['semRegistro'] ?? 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          criados > 0
              ? '$criados turno(s) gerado(s) com sucesso.'
                  '${semRegistro > 0 ? " $semRegistro dia(s) sem registro de ponto." : ""}'
              : 'Nenhum registro de ponto encontrado para a semana.',
        ),
        backgroundColor:
            criados > 0 ? AppColors.success : AppColors.statusAtencao,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EscalaProvider>(context);
    final diasSemana = _diasDaSemana;
    final mesAno = DateFormat('MMMM yyyy', 'pt_BR').format(_segunda);

    // Totais da semana
    int totalSemana = 0;
    int folgasSemana = 0;
    int diasComEscala = 0;
    for (final dia in diasSemana) {
      final turnos = provider.getTurnosByData(dia);
      if (turnos.isNotEmpty) diasComEscala++;
      totalSemana += turnos.where((t) => t.trabalhando).length;
      folgasSemana += turnos.where((t) => t.folga || t.feriado).length;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Escala Semanal'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (!_ehSemanaAtual)
            TextButton(
              onPressed: _semanaAtual,
              child: const Text('Hoje'),
            ),
          IconButton(
            icon: provider.gerando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.auto_awesome),
            tooltip: 'Gerar escala automática',
            onPressed: provider.gerando ? null : () => _gerarEscala(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Navegação de semana ──────────────────────────────────────────
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
                Column(
                  children: [
                    Text(
                      _capitalizar(mesAno),
                      style: AppTextStyles.h4,
                    ),
                    Text(
                      '${DateFormat("dd/MM", "pt_BR").format(_segunda)}'
                      ' – '
                      '${DateFormat("dd/MM", "pt_BR").format(_segunda.add(const Duration(days: 6)))}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _semanaSeguinte,
                ),
              ],
            ),
          ),

          // ── Resumo da semana ─────────────────────────────────────────────
          if (diasComEscala > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingMD, vertical: 4),
              child: Row(
                children: [
                  _StatChip(
                    icon: Icons.people,
                    label: '$totalSemana trabalhando',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.beach_access,
                    label: '$folgasSemana folga(s)',
                    color: AppColors.inactive,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.calendar_month,
                    label: '$diasComEscala/7 dias',
                    color: AppColors.primary,
                  ),
                ],
              ),
            )
          else if (!provider.gerando)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingMD, vertical: 8),
              child: InkWell(
                onTap: () => _gerarEscala(context),
                borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(Dimensions.borderRadius),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Toque para gerar a escala automaticamente',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Loading overlay ──────────────────────────────────────────────
          if (provider.gerando)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Gerando escala...'),
                ],
              ),
            ),

          // ── Lista de dias ────────────────────────────────────────────────
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
                    turnos.where((t) => t.trabalhando).toList();
                final folgas =
                    turnos.where((t) => t.folga || t.feriado).length;
                final hoje = _ehHoje(dia);
                final nomeDia =
                    DateFormat('EEEE', 'pt_BR').format(dia);

                // Breakdown por departamento
                final nCaixa = trabalhando
                    .where((t) =>
                        t.departamento == DepartamentoTipo.caixa ||
                        t.departamento == DepartamentoTipo.self)
                    .length;
                final nFiscal = trabalhando
                    .where(
                        (t) => t.departamento == DepartamentoTipo.fiscal)
                    .length;
                final nPacote = trabalhando
                    .where(
                        (t) => t.departamento == DepartamentoTipo.pacote)
                    .length;
                final nOutros = trabalhando.length - nCaixa - nFiscal - nPacote;

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
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${trabalhando.length} trabalhando'
                                '${folgas > 0 ? " • $folgas folga(s)" : ""}',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                              if (trabalhando.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    if (nCaixa > 0)
                                      _DeptBadge(
                                          label: 'Caixa $nCaixa',
                                          color: AppColors.primary),
                                    if (nFiscal > 0)
                                      _DeptBadge(
                                          label: 'Fiscal $nFiscal',
                                          color: AppColors.statusAtencao),
                                    if (nPacote > 0)
                                      _DeptBadge(
                                          label: 'Pacote $nPacote',
                                          color: AppColors.success),
                                    if (nOutros > 0)
                                      _DeptBadge(
                                          label: 'Outros $nOutros',
                                          color: AppColors.inactive),
                                  ],
                                ),
                              ],
                            ],
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (turnos.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.success.withValues(alpha: 0.1),
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

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeptBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DeptBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
