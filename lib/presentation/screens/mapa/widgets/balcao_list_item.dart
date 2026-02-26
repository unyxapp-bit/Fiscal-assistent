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
import '../../../providers/colaborador_provider.dart';

const int _kMaxFiscaisPorBalcao = 3;
const Color _kBalcaoColor = Color(0xFF009688);

/// Card de balcão exibindo até 3 slots de fiscais alocados
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
        title: const Text('Liberar fiscal'),
        content: const Text('Deseja liberar este fiscal do balcão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Liberar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await alocacaoProvider.liberarAlocacao(alocacao.id, 'Liberado pelo fiscal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ocupados = alocacoes.length;

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: const BorderSide(color: _kBalcaoColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                const Icon(Icons.support_agent, color: _kBalcaoColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  balcao.nomeExibicao,
                  style: AppTextStyles.subtitle
                      .copyWith(color: _kBalcaoColor, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ocupados > 0
                        ? _kBalcaoColor.withValues(alpha: 0.15)
                        : AppColors.backgroundSection,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$ocupados/$_kMaxFiscaisPorBalcao fiscais',
                    style: AppTextStyles.caption.copyWith(
                      color: ocupados > 0 ? _kBalcaoColor : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: Dimensions.spacingMD),

            // Slots de fiscais
            Row(
              children: List.generate(_kMaxFiscaisPorBalcao, (i) {
                final alocacao = i < alocacoes.length ? alocacoes[i] : null;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < _kMaxFiscaisPorBalcao - 1 ? 8 : 0,
                    ),
                    child: _FiscalSlot(
                      alocacao: alocacao,
                      podeAdicionar: ocupados < _kMaxFiscaisPorBalcao,
                      onAdicionar: () => _abrirPickerFiscal(context),
                      onLiberar: alocacao != null
                          ? () => _liberarSlot(context, alocacao)
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slot individual ────────────────────────────────────────────────────────────

class _FiscalSlot extends StatelessWidget {
  final Alocacao? alocacao;
  final bool podeAdicionar;
  final VoidCallback onAdicionar;
  final VoidCallback? onLiberar;

  const _FiscalSlot({
    required this.alocacao,
    required this.podeAdicionar,
    required this.onAdicionar,
    this.onLiberar,
  });

  @override
  Widget build(BuildContext context) {
    if (alocacao != null) {
      // Slot ocupado — mostra nome do colaborador + botão liberar
      return _OcupadoSlot(alocacao: alocacao!, onLiberar: onLiberar!);
    }

    if (podeAdicionar) {
      // Slot vazio — botão para adicionar fiscal
      return _VazioSlot(onAdicionar: onAdicionar);
    }

    // Slot desativado (balcão cheio mas mostra o slot extra como inativo)
    return _VazioSlot(onAdicionar: onAdicionar, desabilitado: true);
  }
}

class _OcupadoSlot extends StatelessWidget {
  final Alocacao alocacao;
  final VoidCallback onLiberar;

  const _OcupadoSlot({required this.alocacao, required this.onLiberar});

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);
    final colaborador = colaboradorProvider.colaboradores
        .cast<Colaborador?>()
        .firstWhere((c) => c?.id == alocacao.colaboradorId, orElse: () => null);
    final nome = colaborador?.nome ?? 'Fiscal';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: _kBalcaoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBalcaoColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _kBalcaoColor,
            child: Text(
              colaborador?.iniciais ?? nome.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nome.split(' ').first,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onLiberar,
            child: const Icon(Icons.logout, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _VazioSlot extends StatelessWidget {
  final VoidCallback onAdicionar;
  final bool desabilitado;

  const _VazioSlot({required this.onAdicionar, this.desabilitado = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: desabilitado ? null : onAdicionar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: desabilitado
              ? AppColors.backgroundSection
              : _kBalcaoColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: desabilitado
                ? AppColors.cardBorder
                : _kBalcaoColor.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 28,
              color: desabilitado
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : _kBalcaoColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              '+ Fiscal',
              style: AppTextStyles.caption.copyWith(
                color: desabilitado
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : _kBalcaoColor,
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

// ── Picker de colaborador ──────────────────────────────────────────────────────

class _ColaboradorPickerSheet extends StatelessWidget {
  final Caixa balcao;

  const _ColaboradorPickerSheet({required this.balcao});

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context);
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Apenas colaboradores ativos e sem alocação ativa
    final disponiveis = colaboradorProvider.colaboradores
        .where((c) =>
            c.ativo && alocacaoProvider.getAlocacaoColaborador(c.id) == null)
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
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (disponiveis.isEmpty)
            const Padding(
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
                        style: const TextStyle(
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
                      if (alocacaoProvider.error != null &&
                          context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(alocacaoProvider.error!),
                            backgroundColor: Colors.red,
                          ),
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
