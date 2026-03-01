import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/ocorrencia_provider.dart';

class OcorrenciaFormScreen extends StatefulWidget {
  const OcorrenciaFormScreen({super.key});

  @override
  State<OcorrenciaFormScreen> createState() => _OcorrenciaFormScreenState();
}

class _OcorrenciaFormScreenState extends State<OcorrenciaFormScreen> {
  final _descricaoCtrl = TextEditingController();
  TipoOcorrencia _tipo = TipoOcorrencia.outro;
  GravidadeOcorrencia _gravidade = GravidadeOcorrencia.media;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    final descricao = _descricaoCtrl.text.trim();
    if (descricao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descreva o que aconteceu'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    Provider.of<OcorrenciaProvider>(context, listen: false).registrar(
      tipo: _tipo,
      descricao: descricao,
      gravidade: _gravidade,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ocorrência registrada!'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            // ── Tipo ──────────────────────────────────────────────────────
            const Text('Tipo de ocorrência *', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TipoOcorrencia.values.map((tipo) {
                final sel = _tipo == tipo;
                return GestureDetector(
                  onTap: () => setState(() => _tipo = tipo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: sel ? AppColors.primary : AppColors.inactive,
                        width: sel ? 2 : 1,
                      ),
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusMD),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tipo.icone,
                            size: 16,
                            color: sel
                                ? AppColors.primary
                                : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          tipo.nome,
                          style: TextStyle(
                            color: sel
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: Dimensions.spacingLG),

            // ── Gravidade ─────────────────────────────────────────────────
            const Text('Gravidade *', style: AppTextStyles.h4),
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
                        child: Column(
                          children: [
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
                                color: sel ? g.cor : AppColors.textSecondary,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
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
                    'Descreva a ocorrência com detalhes: quem, o quê, onde...',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: Dimensions.spacingXL),

            // ── Botões ────────────────────────────────────────────────────
            Row(
              children: [
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
