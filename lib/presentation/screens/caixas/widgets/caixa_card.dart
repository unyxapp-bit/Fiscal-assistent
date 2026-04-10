import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../domain/entities/caixa.dart';
import '../../../providers/alocacao_provider.dart';
import '../../../providers/cafe_provider.dart';
import '../../../providers/colaborador_provider.dart';
import '../../../providers/caixa_provider.dart';
import '../caixa_form_screen.dart';

/// Card compacto para exibiÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o em grade (3 colunas)
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

  Future<void> _confirmarExclusao(
    BuildContext context, {
    required bool emUso,
  }) async {
    if (emUso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Libere o caixa antes de excluir.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir caixa'),
        content: Text(
          'Deseja excluir ${caixa.nomeExibicao}? Essa aÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o nÃƒÆ’Ã‚Â£o pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Excluir',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    final provider = Provider.of<CaixaProvider>(context, listen: false);
    final ok = await provider.deleteCaixa(caixa.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '${caixa.nomeExibicao} excluÃƒÆ’Ã‚Â­do.'
            : (provider.errorMessage ??
                'NÃƒÆ’Ã‚Â£o foi possÃƒÆ’Ã‚Â­vel excluir o caixa.')),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    // Colaborador alocado neste caixa
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final cafeProvider = Provider.of<CafeProvider>(context, listen: false);
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);
    final alocacao = caixa.ativo && !caixa.emManutencao
        ? alocacaoProvider.getAlocacaoCaixa(caixa.id)
        : null;
    final pausaAtiva = cafeProvider.getPausaAtivaPorCaixa(caixa.id);
    final emUso = alocacao != null || pausaAtiva != null;
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
                leading: Icon(Icons.edit),
                title: Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirEdicao(context);
                },
              ),
              if (caixa.ativo && !caixa.emManutencao)
                ListTile(
                  leading: Icon(Icons.close, color: Colors.red),
                  title: Text('Desativar', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<CaixaProvider>(context, listen: false)
                        .toggleStatus(caixa.id, false);
                  },
                ),
              if (!caixa.ativo)
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Ativar'),
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<CaixaProvider>(context, listen: false)
                        .toggleStatus(caixa.id, true);
                  },
                ),
              if (caixa.ativo && !caixa.emManutencao)
                ListTile(
                  leading: Icon(Icons.build, color: Colors.orange),
                  title: Text('Marcar manutenÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o'),
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<CaixaProvider>(context, listen: false)
                        .toggleManutencao(caixa.id, true);
                  },
                ),
              if (caixa.emManutencao)
                ListTile(
                  leading: Icon(Icons.check, color: Colors.green),
                  title: Text('Fim da manutenÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o'),
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<CaixaProvider>(context, listen: false)
                        .toggleManutencao(caixa.id, false);
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.danger),
                title: Text(
                  'Excluir',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarExclusao(context, emUso: emUso);
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
              SizedBox(height: 6),
              Text(
                'Cx ${caixa.numero}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                SizedBox(height: 4),
                Text(
                  colaboradorNome,
                  style: TextStyle(
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
      return 'ManutenÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o';
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
                // ÃƒÆ’Ã‚Âcone e nÃƒÆ’Ã‚Âºmero
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

                SizedBox(width: Dimensions.spacingMD),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caixa.tipo.nome,
                        style: AppTextStyles.subtitle,
                      ),
                      SizedBox(height: 4),
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
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                caixa.colaboradorAlocadoNome!,
                                style: AppTextStyles.caption.copyWith(
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
                    // Editar sempre disponÃƒÆ’Ã‚Â­vel
                    PopupMenuItem(
                      onTap: () => _abrirEdicao(context),
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    if (caixa.ativo && !caixa.emManutencao)
                      PopupMenuItem(
                        child: Row(
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
                        child: Row(
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
                        child: Row(
                          children: [
                            Icon(Icons.build, size: 20, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Marcar manutenÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o'),
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
                        child: Row(
                          children: [
                            Icon(Icons.check, size: 20, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Fim da manutenÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o'),
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
              SizedBox(height: Dimensions.spacingSM),
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
