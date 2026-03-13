import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../domain/entities/caixa.dart';
import '../../../providers/alocacao_provider.dart';
import '../../../providers/colaborador_provider.dart';
import '../../../providers/caixa_provider.dart';
import '../caixa_form_screen.dart';

/// Card compacto para exibição em grade (3 colunas)
class CaixaGridCard extends StatelessWidget {
  final Caixa caixa;

  const CaixaGridCard({super.key, required this.caixa});

  Color _getStatusColor() {
    if (!caixa.ativo) return AppColors.textSecondary;
    if (caixa.emManutencao) return Colors.orange;
    return AppColors.success;
  }

  String _getStatusLabel() {
    if (!caixa.ativo) return 'Inativo';
    if (caixa.emManutencao) return 'Manut.';
    return 'Ativo';
  }

  void _abrirEdicao(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaixaFormScreen(caixa: caixa)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    // Colaborador alocado neste caixa
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);
    final alocacao = caixa.ativo && !caixa.emManutencao
        ? alocacaoProvider.getAlocacaoCaixa(caixa.id)
        : null;
    final colaboradorNome = alocacao != null
        ? colaboradorProvider.colaboradores
            .where((c) => c.id == alocacao.colaboradorId)
            .firstOrNull
            ?.nome
            .split(' ')
            .first
        : null;

    return GestureDetector(
      onLongPress: () => showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirEdicao(context);
                },
              ),
              if (caixa.ativo && !caixa.emManutencao)
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.red),
                  title: const Text('Desativar',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<CaixaProvider>(context, listen: false)
                        .toggleStatus(caixa.id, false);
                  },
                ),
              if (!caixa.ativo)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Ativar'),
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<CaixaProvider>(context, listen: false)
                        .toggleStatus(caixa.id, true);
                  },
                ),
              if (caixa.ativo && !caixa.emManutencao)
                ListTile(
                  leading: const Icon(Icons.build, color: Colors.orange),
                  title: const Text('Marcar manutenção'),
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<CaixaProvider>(context, listen: false)
                        .toggleManutencao(caixa.id, true);
                  },
                ),
              if (caixa.emManutencao)
                ListTile(
                  leading: const Icon(Icons.check, color: Colors.green),
                  title: const Text('Fim da manutenção'),
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<CaixaProvider>(context, listen: false)
                        .toggleManutencao(caixa.id, false);
                  },
                ),
            ],
          ),
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadius),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(caixa.tipo.icone, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                'Cx ${caixa.numero}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (colaboradorNome != null) ...[
                const SizedBox(height: 4),
                Text(
                  colaboradorNome,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Card de caixa individual
class CaixaCard extends StatelessWidget {
  final Caixa caixa;

  const CaixaCard({
    super.key,
    required this.caixa,
  });

  Color _getStatusColor() {
    if (!caixa.ativo) {
      return AppColors.textSecondary;
    }
    if (caixa.emManutencao) {
      return Colors.orange;
    }
    return AppColors.success;
  }

  String _getStatusLabel() {
    if (!caixa.ativo) {
      return 'Inativo';
    }
    if (caixa.emManutencao) {
      return 'Manutenção';
    }
    return 'Ativo';
  }

  void _abrirEdicao(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaixaFormScreen(caixa: caixa),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: BorderSide(
          color: _getStatusColor().withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          children: [
            Row(
              children: [
                // Ícone e número
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        caixa.tipo.icone,
                        color: _getStatusColor(),
                        size: 28,
                      ),
                      Text(
                        'Cx ${caixa.numero}',
                        style: AppTextStyles.label.copyWith(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: Dimensions.spacingMD),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caixa.tipo.nome,
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Badge de status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusLabel(),
                              style: AppTextStyles.caption.copyWith(
                                color: _getStatusColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (caixa.colaboradorAlocadoNome != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                caixa.colaboradorAlocadoNome!,
                                style:
                                    AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu
                PopupMenuButton(
                  itemBuilder: (BuildContext context) => [
                    // Editar sempre disponível
                    PopupMenuItem(
                      onTap: () => _abrirEdicao(context),
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    if (caixa.ativo && !caixa.emManutencao)
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.close, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Desativar'),
                          ],
                        ),
                        onTap: () {
                          final provider = Provider.of<CaixaProvider>(
                            context,
                            listen: false,
                          );
                          provider.toggleStatus(caixa.id, false);
                        },
                      ),
                    if (!caixa.ativo)
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 20, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Ativar'),
                          ],
                        ),
                        onTap: () {
                          final provider = Provider.of<CaixaProvider>(
                            context,
                            listen: false,
                          );
                          provider.toggleStatus(caixa.id, true);
                        },
                      ),
                    if (caixa.ativo && !caixa.emManutencao)
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.build, size: 20, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Marcar manutenção'),
                          ],
                        ),
                        onTap: () {
                          final provider = Provider.of<CaixaProvider>(
                            context,
                            listen: false,
                          );
                          provider.toggleManutencao(caixa.id, true);
                        },
                      ),
                    if (caixa.emManutencao)
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.check, size: 20, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Fim da manutenção'),
                          ],
                        ),
                        onTap: () {
                          final provider = Provider.of<CaixaProvider>(
                            context,
                            listen: false,
                          );
                          provider.toggleManutencao(caixa.id, false);
                        },
                      ),
                  ],
                ),
              ],
            ),
            if (caixa.observacoes != null) ...[
              const SizedBox(height: Dimensions.spacingSM),
              Text(
                caixa.observacoes!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
