import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/alocacao.dart';
import '../../../../domain/entities/caixa.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../providers/alocacao_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cafe_provider.dart';
import '../../../providers/colaborador_provider.dart';
import '../../../providers/escala_provider.dart';
import 'colaborador_detalhes_sheet.dart';
import '../../../../core/utils/app_notif.dart';
import '../../../widgets/excecao_dialog.dart';

const Color _kBalcaoColor = Color(0xFF009688);

/// Card de balcão exibindo fiscais alocados (sem limite fixo)
class BalcaoListItem extends StatelessWidget {
  final Caixa balcao;
  final List<Alocacao> alocacoes;

  const BalcaoListItem({
    super.key,
    required this.balcao,
    required this.alocacoes,
  });

  void _abrirPickerFiscal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => _ColaboradorPickerSheet(balcao: balcao),
    );
  }

  void _liberarSlot(BuildContext context, Alocacao alocacao) async {
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Liberar fiscal'),
        content: Text('Deseja liberar este fiscal do balcão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Liberar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await alocacaoProvider.liberarAlocacao(
          alocacao.id, 'Liberado pelo fiscal');
    }
  }

  void _showDetalhes(
    BuildContext context,
    Alocacao alocacao,
    Colaborador? colaborador,
  ) {
    final escalaProvider = Provider.of<EscalaProvider>(context, listen: false);
    final cafeProvider = Provider.of<CafeProvider>(context, listen: false);
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);

    final turno = colaborador != null
        ? escalaProvider.turnosHoje
            .where((t) => t.colaboradorId == colaborador.id)
            .firstOrNull
        : null;
    final pausa =
        colaborador != null ? cafeProvider.getPausaAtiva(colaborador.id) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => ColaboradorDetalhesSheet(
        caixa: balcao,
        colaborador: colaborador,
        alocacao: alocacao,
        turno: turno,
        pausa: pausa,
        alocacaoProvider: alocacaoProvider,
        providerContext: context,
        liberarLabel: 'Liberar Balcão',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ocupados = alocacoes.length;
    final podeAdicionar = balcao.ativo && !balcao.emManutencao;

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: BorderSide(color: _kBalcaoColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(Icons.support_agent, color: _kBalcaoColor, size: 20),
                SizedBox(width: 8),
                Text(
                  balcao.nomeExibicao,
                  style: AppTextStyles.subtitle.copyWith(
                      color: _kBalcaoColor, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ocupados > 0
                        ? _kBalcaoColor.withValues(alpha: 0.10)
                        : AppColors.backgroundSection,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ocupados == 0
                        ? 'Vazio'
                        : '$ocupados fiscal${ocupados > 1 ? 'is' : ''}',
                    style: AppTextStyles.caption.copyWith(
                      color: ocupados > 0
                          ? _kBalcaoColor
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: Dimensions.spacingMD),

            // Slots: um por alocação ativa + botão de adicionar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...alocacoes.map((alocacao) {
                  final col =
                      Provider.of<ColaboradorProvider>(context, listen: false)
                          .colaboradores
                          .cast<Colaborador?>()
                          .firstWhere(
                            (c) => c?.id == alocacao.colaboradorId,
                            orElse: () => null,
                          );
                  return SizedBox(
                    width: 90,
                    child: _OcupadoSlot(
                      alocacao: alocacao,
                      onLiberar: () => _liberarSlot(context, alocacao),
                      onTap: () => _showDetalhes(context, alocacao, col),
                    ),
                  );
                }),
                if (podeAdicionar)
                  SizedBox(
                    width: 90,
                    child: _VazioSlot(
                      onAdicionar: () => _abrirPickerFiscal(context),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Slots â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OcupadoSlot extends StatelessWidget {
  final Alocacao alocacao;
  final VoidCallback onLiberar;
  final VoidCallback? onTap;

  const _OcupadoSlot({
    required this.alocacao,
    required this.onLiberar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);
    final colaborador = colaboradorProvider.colaboradores
        .cast<Colaborador?>()
        .firstWhere((c) => c?.id == alocacao.colaboradorId, orElse: () => null);
    final nome = colaborador?.nome ?? 'Fiscal';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: _kBalcaoColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBalcaoColor.withValues(alpha: 0.28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _kBalcaoColor,
              child: Text(
                colaborador?.iniciais ?? nome.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              nome.split(' ').first,
              style:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            GestureDetector(
              onTap: onLiberar,
              child: Icon(Icons.logout, size: 16, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _VazioSlot extends StatelessWidget {
  final VoidCallback onAdicionar;

  const _VazioSlot({required this.onAdicionar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdicionar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: _kBalcaoColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _kBalcaoColor.withValues(alpha: 0.22),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 28,
              color: _kBalcaoColor.withValues(alpha: 0.6),
            ),
            SizedBox(height: 4),
            Text(
              '+ Fiscal',
              style: AppTextStyles.caption.copyWith(
                color: _kBalcaoColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Picker de colaborador â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ColaboradorPickerSheet extends StatelessWidget {
  final Caixa balcao;

  const _ColaboradorPickerSheet({required this.balcao});

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context);
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final escalaProvider = Provider.of<EscalaProvider>(context, listen: false);

    final idsEscalaTrabalhando = escalaProvider.turnosHoje
        .where((t) => t.trabalhando)
        .map((t) => t.colaboradorId)
        .toSet();

    // Balcão: mostra todos os colaboradores ativos (sem restrição de alocação)
    final disponiveis = colaboradorProvider.colaboradores
        .where((c) => c.ativo && idsEscalaTrabalhando.contains(c.id))
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
                'Adicionar fiscal — ${balcao.nomeExibicao}',
                style: AppTextStyles.subtitle
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (disponiveis.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Nenhum fiscal disponível no momento'),
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
                      backgroundColor: _kBalcaoColor,
                      child: Text(
                        colaborador.iniciais,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(colaborador.nome),
                    subtitle: Text(colaborador.departamento.nome),
                    onTap: () async {
                      Navigator.pop(context);
                      await alocacaoProvider.alocarColaborador(
                        colaboradorId: colaborador.id,
                        caixaId: balcao.id,
                        fiscalId: authProvider.user?.id ?? '',
                      );
                      // Se retornou exceção (já trabalhou aqui hoje),
                      // abrir diálogo para justificar
                      if (alocacaoProvider.mostrarDialogExcecao &&
                          context.mounted) {
                        final motivo =
                            alocacaoProvider.resultadoExcecao?.motivoExcecao ??
                                'Justifique o motivo da exceção.';
                        final tipo =
                            alocacaoProvider.resultadoExcecao?.tipoExcecao ??
                                '';
                        await showDialog(
                          context: context,
                          builder: (_) => ExcecaoDialog(
                            colaborador: alocacaoProvider.colaboradorExcecao ??
                                colaborador,
                            caixa: alocacaoProvider.caixaExcecao ?? balcao,
                            motivo: motivo,
                            tipo: tipo,
                            onCancel: () {
                              alocacaoProvider.fecharDialogExcecao();
                            },
                            onConfirm: (justificativa) async {
                              alocacaoProvider.fecharDialogExcecao();
                              await alocacaoProvider.alocarColaborador(
                                colaboradorId: colaborador.id,
                                caixaId: balcao.id,
                                fiscalId: authProvider.user?.id ?? '',
                                justificativa: justificativa,
                              );
                              if (alocacaoProvider.error != null &&
                                  context.mounted) {
                                AppNotif.show(
                                  context,
                                  titulo: 'Erro',
                                  mensagem: alocacaoProvider.error!,
                                  tipo: 'alerta',
                                  cor: Colors.red,
                                );
                              }
                            },
                          ),
                        );
                        return;
                      }
                      if (alocacaoProvider.error != null && context.mounted) {
                        AppNotif.show(
                          context,
                          titulo: 'Erro',
                          mensagem: alocacaoProvider.error!,
                          tipo: 'alerta',
                          cor: Colors.red,
                        );
                      }
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
