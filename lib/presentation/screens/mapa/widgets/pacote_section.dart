import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/enums/departamento_tipo.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../../domain/entities/evento_turno.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cafe_provider.dart';
import '../../../providers/colaborador_provider.dart';
import '../../../providers/escala_provider.dart';
import '../../../providers/evento_turno_provider.dart';
import '../../../providers/pacote_plantao_provider.dart';
import 'pacote_detalhes_sheet.dart';

const Color _kPacoteColor = Color(0xFF795548); // marrom

/// Seção de plantão de empacotadores no Mapa
class PacoteSection extends StatelessWidget {
  const PacoteSection({super.key});

  @override
  Widget build(BuildContext context) {
    final plantaoProvider = Provider.of<PacotePlantaoProvider>(context);
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(context, listen: false);
    final escalaProvider = Provider.of<EscalaProvider>(context, listen: false);
    // listen: true — CafeProvider notifica a cada segundo via Timer.periodic,
    // fazendo o countdown de intervalo atualizar automaticamente.
    final cafeProvider = Provider.of<CafeProvider>(context);

    // Função local: positivo = minutos atrasado, negativo = minutos restantes
    int? calcMinIntervalo(TurnoLocal? turno) {
      if (turno?.intervalo == null) return null;
      final parts = turno!.intervalo!.split(':');
      if (parts.length < 2) return null;
      final agora = DateTime.now();
      final agoraMin = agora.hour * 60 + agora.minute;
      final intervaloMin =
          (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      return agoraMin - intervaloMin;
    }

    final plantao = plantaoProvider.plantao;

    // Verifica se algum empacotador está em atenção (15+ min atrasado)
    final hayAtencao = plantao.any((p) {
      final turno = escalaProvider.turnosHoje
          .where((t) => t.colaboradorId == p.colaboradorId)
          .firstOrNull;
      final pausa = cafeProvider.getPausaAtiva(p.colaboradorId);
      if (pausa != null) return false;
      final min = calcMinIntervalo(turno);
      return min != null && min >= 15;
    });

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: BorderSide(
          color: hayAtencao ? AppColors.danger : _kPacoteColor,
          width: hayAtencao ? 2.5 : 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(
                  Icons.shopping_bag,
                  color: hayAtencao ? AppColors.danger : _kPacoteColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pacotes',
                  style: AppTextStyles.subtitle.copyWith(
                    color: hayAtencao ? AppColors.danger : _kPacoteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: plantao.isNotEmpty
                        ? _kPacoteColor.withValues(alpha: 0.15)
                        : AppColors.backgroundSection,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${plantao.length} hoje',
                    style: AppTextStyles.caption.copyWith(
                      color: plantao.isNotEmpty
                          ? _kPacoteColor
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: Dimensions.spacingMD),

            // Chips de empacotadores + botão adicionar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Chips dos empacotadores no plantão
                ...plantao.map((p) {
                  final colaborador = colaboradorProvider.colaboradores
                      .cast<Colaborador?>()
                      .firstWhere(
                        (c) => c?.id == p.colaboradorId,
                        orElse: () => null,
                      );
                  final nome = colaborador?.nome ?? 'Empacotador';
                  final iniciais = colaborador?.iniciais ??
                      nome.substring(0, 1).toUpperCase();

                  // Estado de intervalo
                  final turno = escalaProvider.turnosHoje
                      .where((t) => t.colaboradorId == p.colaboradorId)
                      .firstOrNull;
                  final pausaAtiva = cafeProvider.getPausaAtiva(p.colaboradorId);
                  final isEmPausa = pausaAtiva != null;
                  final minIntervalo =
                      isEmPausa ? null : calcMinIntervalo(turno);
                  final emAtencao = minIntervalo != null && minIntervalo >= 15;

                  // Cor e label dinâmicos
                  final Color chipColor;
                  final String chipLabel;
                  final IconData chipAvatarIcon;

                  if (isEmPausa) {
                    final isCafe = pausaAtiva.duracaoMinutos <= 15;
                    chipColor = Colors.orange;
                    chipLabel =
                        '${nome.split(' ').first} · ${pausaAtiva.minutosDecorridos}min';
                    chipAvatarIcon = isCafe ? Icons.coffee : Icons.restaurant;
                  } else if (emAtencao) {
                    chipColor = AppColors.danger;
                    chipLabel =
                        '${nome.split(' ').first} · ${minIntervalo}min';
                    chipAvatarIcon = Icons.warning_amber_rounded;
                  } else if (minIntervalo != null && minIntervalo >= 0) {
                    // Atraso leve (0–14 min)
                    chipColor = Colors.amber.shade700;
                    chipLabel =
                        '${nome.split(' ').first} · ${minIntervalo}min';
                    chipAvatarIcon = Icons.schedule;
                  } else if (minIntervalo != null && minIntervalo > -60) {
                    // Countdown (1–59 min antes)
                    chipColor = Colors.orange.shade600;
                    chipLabel =
                        '${nome.split(' ').first} · ${-minIntervalo}min';
                    chipAvatarIcon = Icons.schedule;
                  } else {
                    chipColor = _kPacoteColor;
                    chipLabel = nome.split(' ').first;
                    chipAvatarIcon = Icons.person;
                  }

                  final bool showIcon =
                      isEmPausa || emAtencao || (minIntervalo != null);

                  return InputChip(
                    avatar: showIcon
                        ? CircleAvatar(
                            backgroundColor: chipColor,
                            child: Icon(
                              chipAvatarIcon,
                              size: 11,
                              color: Colors.white,
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: chipColor,
                            child: Text(
                              iniciais,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    label: Text(
                      chipLabel,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: chipColor,
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    deleteIconColor: Colors.red,
                    onDeleted: () {
                      eventoProvider.registrar(
                        fiscalId: authProvider.user?.id ?? '',
                        tipo: TipoEvento.empacotadorRemovido,
                        colaboradorNome: nome,
                      );
                      plantaoProvider.remover(p.id);
                    },
                    onPressed: () => _showDetalhesEmpacotador(
                      context,
                      colaborador,
                      p.id,
                    ),
                    backgroundColor: chipColor.withValues(alpha: 0.1),
                    side: BorderSide(color: chipColor.withValues(alpha: 0.4)),
                  );
                }),

                // Botão adicionar
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: _kPacoteColor),
                  label: Text(
                    '+ Empacotador',
                    style: AppTextStyles.caption.copyWith(color: _kPacoteColor),
                  ),
                  backgroundColor: _kPacoteColor.withValues(alpha: 0.05),
                  side: BorderSide(
                      color: _kPacoteColor.withValues(alpha: 0.3),
                      style: BorderStyle.solid),
                  onPressed: () => _abrirPicker(
                    context,
                    authProvider.user?.id ?? '',
                    plantaoProvider,
                    colaboradorProvider,
                  ),
                ),
              ],
            ),

            // Banner de atenção — aparece quando há atraso ≥ 15 min
            if (hayAtencao) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 14, color: AppColors.danger),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Empacotador(es) em atraso para o intervalo',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetalhesEmpacotador(
    BuildContext context,
    Colaborador? colaborador,
    String plantaoId,
  ) {
    if (colaborador == null) return;
    final escalaProvider = Provider.of<EscalaProvider>(context, listen: false);
    final cafeProvider = Provider.of<CafeProvider>(context, listen: false);

    final turno = escalaProvider.turnosHoje
        .where((t) => t.colaboradorId == colaborador.id)
        .firstOrNull;
    final pausa = cafeProvider.getPausaAtiva(colaborador.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => PacoteDetalhesSheet(
        colaborador: colaborador,
        plantaoId: plantaoId,
        turno: turno,
        pausa: pausa,
        providerContext: context,
      ),
    );
  }

  void _abrirPicker(
    BuildContext context,
    String fiscalId,
    PacotePlantaoProvider plantaoProvider,
    ColaboradorProvider colaboradorProvider,
  ) {
    final escalaProvider =
        Provider.of<EscalaProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => _EmpacotadorPickerSheet(
        fiscalId: fiscalId,
        plantaoProvider: plantaoProvider,
        colaboradorProvider: colaboradorProvider,
        escalaProvider: escalaProvider,
      ),
    );
  }
}

// ── Picker de empacotadores ────────────────────────────────────────────────────

class _EmpacotadorPickerSheet extends StatelessWidget {
  final String fiscalId;
  final PacotePlantaoProvider plantaoProvider;
  final ColaboradorProvider colaboradorProvider;
  final EscalaProvider escalaProvider;

  const _EmpacotadorPickerSheet({
    required this.fiscalId,
    required this.plantaoProvider,
    required this.colaboradorProvider,
    required this.escalaProvider,
  });

  String _horarios(TurnoLocal? turno) {
    if (turno == null) return 'Sem escala hoje';
    final partes = <String>[];
    if (turno.entrada != null && turno.saida != null) {
      partes.add('${turno.entrada}–${turno.saida}');
    }
    if (turno.intervalo != null) {
      partes.add('Intervalo: ${turno.intervalo}');
    }
    return partes.isEmpty ? 'Sem horário' : partes.join('  •  ');
  }

  @override
  Widget build(BuildContext context) {
    // Apenas empacotadores ativos que ainda não estão na lista hoje
    final disponiveis = colaboradorProvider.colaboradores
        .where((c) =>
            c.ativo &&
            c.departamento == DepartamentoTipo.pacote &&
            !plantaoProvider.isNaLista(c.id))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Adicionar empacotador',
                style: AppTextStyles.subtitle
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (disponiveis.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Todos os empacotadores já estão na lista'),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: disponiveis.length,
                itemBuilder: (_, i) {
                  final colaborador = disponiveis[i];
                  final turno = escalaProvider.turnosHoje
                      .where((t) => t.colaboradorId == colaborador.id)
                      .firstOrNull;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _kPacoteColor,
                      child: Text(
                        colaborador.iniciais,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(colaborador.nome),
                    subtitle: Text(
                      _horarios(turno),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    onTap: () async {
                      final eventoProviderPicker =
                          Provider.of<EventoTurnoProvider>(context,
                              listen: false);
                      Navigator.pop(context);
                      await plantaoProvider.adicionar(fiscalId, colaborador.id);
                      eventoProviderPicker.registrar(
                        fiscalId: fiscalId,
                        tipo: TipoEvento.empacotadorAdicionado,
                        colaboradorNome: colaborador.nome,
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
