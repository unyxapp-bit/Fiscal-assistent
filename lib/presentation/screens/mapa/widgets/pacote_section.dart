import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/enums/departamento_tipo.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cafe_provider.dart';
import '../../../providers/colaborador_provider.dart';
import '../../../providers/escala_provider.dart';
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

    final plantao = plantaoProvider.plantao;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: const BorderSide(color: _kPacoteColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                const Icon(Icons.shopping_bag, color: _kPacoteColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pacotes',
                  style: AppTextStyles.subtitle.copyWith(
                    color: _kPacoteColor,
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

                  return InputChip(
                    avatar: CircleAvatar(
                      backgroundColor: _kPacoteColor,
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
                      nome.split(' ').first,
                      style: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    deleteIconColor: Colors.red,
                    onDeleted: () => plantaoProvider.remover(p.id),
                    onPressed: () => _showDetalhesEmpacotador(
                      context,
                      colaborador,
                      p.id,
                    ),
                    backgroundColor: _kPacoteColor.withValues(alpha: 0.1),
                    side: BorderSide(
                        color: _kPacoteColor.withValues(alpha: 0.4)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EmpacotadorPickerSheet(
        fiscalId: fiscalId,
        plantaoProvider: plantaoProvider,
        colaboradorProvider: colaboradorProvider,
      ),
    );
  }
}

// ── Picker de empacotadores ────────────────────────────────────────────────────

class _EmpacotadorPickerSheet extends StatelessWidget {
  final String fiscalId;
  final PacotePlantaoProvider plantaoProvider;
  final ColaboradorProvider colaboradorProvider;

  const _EmpacotadorPickerSheet({
    required this.fiscalId,
    required this.plantaoProvider,
    required this.colaboradorProvider,
  });

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
                    subtitle: Text(colaborador.departamento.nome),
                    onTap: () async {
                      Navigator.pop(context);
                      await plantaoProvider.adicionar(
                          fiscalId, colaborador.id);
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
