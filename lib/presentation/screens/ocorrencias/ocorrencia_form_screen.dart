import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../providers/ocorrencia_provider.dart';
import '../../../core/utils/app_notif.dart';

class OcorrenciaFormScreen extends StatefulWidget {
  final String? caixaId;
  final String? caixaNome;
  final String? colaboradorId;
  final String? colaboradorNome;

  const OcorrenciaFormScreen({
    super.key,
    this.caixaId,
    this.caixaNome,
    this.colaboradorId,
    this.colaboradorNome,
  });
  @override
  State<OcorrenciaFormScreen> createState() => _OcorrenciaFormScreenState();
}

class _OcorrenciaFormScreenState extends State<OcorrenciaFormScreen> {
  final _tipoCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  GravidadeOcorrencia _gravidade = GravidadeOcorrencia.media;

  @override
  void dispose() {
    _tipoCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    final descricao = _descricaoCtrl.text.trim();
    if (descricao.isEmpty) {
      AppNotif.show(
        context,
        titulo: 'Campo Inválido',
        mensagem: 'Descreva o que aconteceu',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
      return;
    }
    final tipo = _tipoCtrl.text.trim().isEmpty ? 'Outro' : _tipoCtrl.text.trim();
    Provider.of<OcorrenciaProvider>(context, listen: false).registrar(
      tipo: tipo,
      caixaId: widget.caixaId,
      caixaNome: widget.caixaNome,
      colaboradorId: widget.colaboradorId,
      colaboradorNome: widget.colaboradorNome,
      descricao: descricao,
      gravidade: _gravidade,
    );
    final eventoProvider = Provider.of<EventoTurnoProvider>(context, listen: false);
    if (eventoProvider.turnoAtivo) {
      final fiscalId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.ocorrenciaRegistrada,
        detalhe: '$tipo — ${_gravidade.nome}',
      );
    }
    AppNotif.show(
      context,
      titulo: 'Ocorrência Registrada',
      mensagem: 'Ocorrência registrada!',
      tipo: 'saida',
      cor: AppColors.success,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tipoAtual = _tipoCtrl.text.trim();
    final hasContexto = (widget.caixaNome != null &&
            widget.caixaNome!.isNotEmpty) ||
        (widget.colaboradorNome != null &&
            widget.colaboradorNome!.isNotEmpty);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrar Ocorrência', style: AppTextStyles.h3),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasContexto) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSection,
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.caixaNome != null &&
                        widget.caixaNome!.isNotEmpty)
                      Text(
                        'Caixa: ${widget.caixaNome}',
                        style: AppTextStyles.body,
                      ),
                    if (widget.colaboradorNome != null &&
                        widget.colaboradorNome!.isNotEmpty)
                      Text(
                        'Colaborador: ${widget.colaboradorNome}',
                        style: AppTextStyles.body,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.spacingMD),
            ],
            // ── Tipo livre ────────────────────────────────────────────────
            const Text('Tipo de ocorrência', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            TextField(
              controller: _tipoCtrl,
              decoration: InputDecoration(
                hintText: 'Ex: Briga, Erro de Caixa, Furto...',
                prefixIcon: Icon(iconForTipo(tipoAtual), color: AppColors.danger),
                suffixIcon: tipoAtual.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _tipoCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Dimensions.spacingSM),
            Text(
              'Sugestões:',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kTiposSugestao.map((s) {
                final sel = tipoAtual == s;
                return GestureDetector(
                  onTap: () {
                    _tipoCtrl.text = s;
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.danger.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: sel ? AppColors.danger : AppColors.inactive,
                        width: sel ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            sel ? FontWeight.w600 : FontWeight.normal,
                        color: sel
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: Dimensions.spacingLG),

            // ── Gravidade ─────────────────────────────────────────────────
            const Text('Gravidade', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            Row(
              children: GravidadeOcorrencia.values.map((g) {
                final sel = _gravidade == g;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _gravidade = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel
                              ? g.cor.withValues(alpha: 0.12)
                              : Colors.transparent,
                          border: Border.all(
                            color: sel ? g.cor : AppColors.inactive,
                            width: sel ? 2 : 1,
                          ),
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusMD),
                        ),
                        child: Column(children: [
                          Icon(
                            sel
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: sel ? g.cor : AppColors.inactive,
                            size: 18,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            g.nome,
                            style: TextStyle(
                              color: sel
                                  ? g.cor
                                  : AppColors.textSecondary,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: Dimensions.spacingLG),

            // ── Descrição ─────────────────────────────────────────────────
            const Text('O que aconteceu? *', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            TextFormField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(
                hintText:
                    'Descreva com detalhes: quem, o quê, onde...',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: Dimensions.spacingXL),

            // ── Botões ────────────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(Dimensions.buttonHeight),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.save),
                  label: const Text('Registrar'),
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(Dimensions.buttonHeight),
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
