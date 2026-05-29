import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_styles.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_notif.dart';
import '../../../providers/alocacao_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cafe_provider.dart';
import '../../../providers/caixa_provider.dart';
import '../../../providers/colaborador_provider.dart';
import '../../../providers/escala_provider.dart';

class MonitorTempoReal extends StatelessWidget {
  final CafeProvider cafeProvider;
  final ColaboradorProvider colaboradorProvider;
  final CaixaProvider caixaProvider;
  final EscalaProvider escalaProvider;

  const MonitorTempoReal({
    super.key,
    required this.cafeProvider,
    required this.colaboradorProvider,
    required this.caixaProvider,
    required this.escalaProvider,
  });

  Future<void> _finalizarPausaDoMonitor(
    BuildContext context,
    PausaCafe pausa,
  ) async {
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final fiscalId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';

    if (fiscalId.isEmpty) {
      if (context.mounted) {
        AppNotif.show(
          context,
          titulo: 'Erro',
          mensagem: 'Usu\u00e1rio n\u00e3o autenticado para finalizar pausa.',
          tipo: 'alerta',
          cor: AppColors.danger,
        );
      }
      return;
    }

    _RetornoMonitorEscolha? escolhaIntervalo;
    String? erro;
    if (pausa.isIntervalo) {
      escolhaIntervalo = await _escolherRetornoIntervalo(
        context: context,
        pausa: pausa,
        alocacaoProvider: alocacaoProvider,
      );
      if (escolhaIntervalo == null) return;

      erro = await cafeProvider.finalizarPausaComRegra(
        pausa: pausa,
        alocacaoProvider: alocacaoProvider,
        fiscalId: fiscalId,
        caixaDestinoIntervaloId: escolhaIntervalo.caixaDestinoId,
        permitirMesmoCaixaNoIntervalo: escolhaIntervalo.permitirMesmoCaixa,
        justificativaMesmoCaixa: escolhaIntervalo.justificativaMesmoCaixa,
      );
    } else {
      erro = await cafeProvider.finalizarPausaComRegra(
        pausa: pausa,
        alocacaoProvider: alocacaoProvider,
        fiscalId: fiscalId,
      );
    }

    if (!context.mounted) return;

    if (erro != null) {
      AppNotif.show(
        context,
        titulo: 'Pausa finalizada',
        mensagem: erro,
        tipo: 'alerta',
        cor: AppColors.warning,
      );
      return;
    }

    final caixaDestino = pausa.isCafe
        ? caixaProvider.caixas
            .where((c) => c.id == pausa.caixaId)
            .firstOrNull
            ?.nomeExibicao
        : caixaProvider.caixas
            .where((c) => c.id == escolhaIntervalo?.caixaDestinoId)
            .firstOrNull
            ?.nomeExibicao;

    final usouExcecaoMesmoCaixa =
        pausa.isIntervalo && pausa.caixaId == escolhaIntervalo?.caixaDestinoId;

    AppNotif.show(
      context,
      titulo: 'Pausa finalizada',
      mensagem: pausa.isCafe
          ? '${pausa.colaboradorNome} voltou ao ${caixaDestino ?? 'caixa'}.'
          : '${pausa.colaboradorNome} realocado(a) para ${caixaDestino ?? 'caixa'}'
              '${usouExcecaoMesmoCaixa ? ' (exce\u00e7\u00e3o registrada)' : ''}.',
      tipo: 'saida',
      cor: AppColors.success,
    );
  }

  Future<_RetornoMonitorEscolha?> _escolherRetornoIntervalo({
    required BuildContext context,
    required PausaCafe pausa,
    required AlocacaoProvider alocacaoProvider,
  }) async {
    final caixasAtivos = caixaProvider.caixas
        .where((c) => c.ativo && !c.emManutencao)
        .toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));

    final caixasLivres = caixasAtivos
        .where((c) => alocacaoProvider.getAlocacaoCaixa(c.id) == null)
        .toList();

    if (caixasLivres.isEmpty) {
      if (context.mounted) {
        AppNotif.show(
          context,
          titulo: 'Sem caixa dispon\u00edvel',
          mensagem: 'N\u00e3o h\u00e1 caixa livre para retorno do intervalo.',
          tipo: 'alerta',
          cor: AppColors.warning,
        );
      }
      return null;
    }

    String? caixaSelecionadoId = caixasLivres
        .where((c) => c.id != pausa.caixaId)
        .map((c) => c.id)
        .firstOrNull;
    caixaSelecionadoId ??= caixasLivres.first.id;
    bool permitirMesmoCaixa = false;
    final justificativaCtrl = TextEditingController();

    final escolha = await showDialog<_RetornoMonitorEscolha>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final mesmoCaixaSelecionado = pausa.caixaId != null &&
              pausa.caixaId!.isNotEmpty &&
              caixaSelecionadoId == pausa.caixaId;
          final precisaJustificativa =
              mesmoCaixaSelecionado && permitirMesmoCaixa;
          final podeConfirmar = caixaSelecionadoId != null &&
              (!precisaJustificativa ||
                  justificativaCtrl.text.trim().isNotEmpty);

          return AlertDialog(
            title: const Text('Retorno do intervalo'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: RadioGroup<String>(
                  groupValue: caixaSelecionadoId,
                  onChanged: (v) =>
                      setStateDialog(() => caixaSelecionadoId = v),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Regra padrao: retornar em caixa diferente.'),
                      const SizedBox(height: 12),
                      ...caixasAtivos.map((caixa) {
                        final ocupado =
                            alocacaoProvider.getAlocacaoCaixa(caixa.id) != null;
                        Widget tile = RadioListTile<String>(
                          value: caixa.id,
                          title: Text(caixa.nomeExibicao),
                          subtitle:
                              Text(ocupado ? 'Ocupado agora' : 'Disponivel'),
                          dense: true,
                        );
                        if (ocupado) {
                          tile = Opacity(
                            opacity: 0.5,
                            child: IgnorePointer(child: tile),
                          );
                        }
                        return tile;
                      }),
                      if (mesmoCaixaSelecionado) ...[
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: permitirMesmoCaixa,
                          onChanged: (v) => setStateDialog(
                            () => permitirMesmoCaixa = v ?? false,
                          ),
                          title: const Text(
                              'Permitir mesmo caixa (exce\u00e7\u00e3o)'),
                          subtitle: const Text(
                            'Necess\u00e1rio justificar para auditoria.',
                          ),
                        ),
                        if (permitirMesmoCaixa) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: justificativaCtrl,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Justificativa da exce\u00e7\u00e3o *',
                            ),
                            onChanged: (_) => setStateDialog(() {}),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: !podeConfirmar
                    ? null
                    : () => Navigator.pop(
                          ctx,
                          _RetornoMonitorEscolha(
                            caixaDestinoId: caixaSelecionadoId!,
                            permitirMesmoCaixa: permitirMesmoCaixa,
                            justificativaMesmoCaixa:
                                justificativaCtrl.text.trim().isEmpty
                                    ? null
                                    : justificativaCtrl.text.trim(),
                          ),
                        ),
                child: const Text('Confirmar retorno'),
              ),
            ],
          );
        },
      ),
    );

    justificativaCtrl.dispose();
    return escolha;
  }

  @override
  Widget build(BuildContext context) {
    final pausasAtivas = cafeProvider.pausasAtivas;

    // PrÃƒÆ’Ã‚Â³ximos intervalos (ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¤15 min) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â apenas colaboradores ativos no turno
    final proximos = <_ProximoIntervalo>[];
    for (final turno in escalaProvider.turnosHoje) {
      if (turno.intervalo == null) continue;
      final parts = turno.intervalo!.split(':');
      if (parts.length < 2) continue;
      final agora = DateTime.now();
      final agoraMin = agora.hour * 60 + agora.minute;
      final intervaloMin =
          (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      final diff = intervaloMin - agoraMin;
      if (diff >= 0 && diff <= 15) {
        final colab = colaboradorProvider.colaboradores
            .cast<dynamic>()
            .firstWhere((c) => c.id == turno.colaboradorId, orElse: () => null);
        if (colab != null) {
          proximos.add(_ProximoIntervalo(
            nome: colab.nome as String,
            minutosRestantes: diff,
            horario: turno.intervalo!,
          ));
        }
      }
    }

    final semAlertas = pausasAtivas.isEmpty && proximos.isEmpty;
    final tokens = context.appTheme;

    return Container(
      decoration: AppStyles.softCard(
        context: context,
        tint: AppColors.primary,
        radius: tokens.cardRadius + 2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Monitor em tempo real', style: AppTextStyles.h4),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: AppStyles.softTile(
                    context: context,
                    tint: semAlertas ? AppColors.success : AppColors.warning,
                    radius: 999,
                  ),
                  child: Text(
                    semAlertas ? 'Est\u00e1vel' : 'Ao vivo',
                    style: AppTextStyles.caption.copyWith(
                      color: semAlertas ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (semAlertas)
              Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Tudo em ordem, nenhum alerta no momento',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
                ],
              )
            else ...[
              // Pausas ativas
              if (pausasAtivas.isNotEmpty) ...[
                Text(
                  'EM PAUSA',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                ...pausasAtivas.map((p) {
                  final caixa = p.caixaId != null
                      ? caixaProvider.caixas.cast<dynamic>().firstWhere(
                          (c) => c.id == p.caixaId,
                          orElse: () => null)
                      : null;
                  final isCafe = p.isCafe;
                  final cor = p.emAtraso
                      ? AppColors.danger
                      : (isCafe ? AppColors.coffee : AppColors.warning);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: AppStyles.softTile(
                      context: context,
                      tint: cor,
                      radius: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCafe ? Icons.coffee : Icons.restaurant,
                          color: cor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.colaboradorNome,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cor,
                                ),
                              ),
                              Text(
                                caixa != null
                                    ? '${caixa.nomeExibicao} Â· ${p.minutosDecorridos}/${p.duracaoMinutos} min'
                                    : '${p.minutosDecorridos}/${p.duracaoMinutos} min',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (p.emAtraso)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${p.minutosExcedidos}min',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _finalizarPausaDoMonitor(context, p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      AppColors.success.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'Retornou',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // PrÃƒÆ’Ã‚Â³ximos intervalos
              if (proximos.isNotEmpty) ...[
                if (pausasAtivas.isNotEmpty) const SizedBox(height: 10),
                Text(
                  'INTERVALO EM BREVE',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                ...proximos.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: AppStyles.softTile(
                        context: context,
                        tint: AppColors.warning,
                        radius: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.nome,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          Text(
                            '\u00e0s ${p.horario} \u00b7 em ${p.minutosRestantes} min',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.warning),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _RetornoMonitorEscolha {
  final String caixaDestinoId;
  final bool permitirMesmoCaixa;
  final String? justificativaMesmoCaixa;

  const _RetornoMonitorEscolha({
    required this.caixaDestinoId,
    required this.permitirMesmoCaixa,
    this.justificativaMesmoCaixa,
  });
}

class _ProximoIntervalo {
  final String nome;
  final int minutosRestantes;
  final String horario;

  const _ProximoIntervalo({
    required this.nome,
    required this.minutosRestantes,
    required this.horario,
  });
}

// ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Helpers de layout ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
