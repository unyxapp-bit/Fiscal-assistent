import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/importacao_provider.dart';
import '../../providers/ocorrencia_provider.dart';
import '../../providers/nota_provider.dart';

class ImportacaoScreen extends StatefulWidget {
  const ImportacaoScreen({super.key});

  @override
  State<ImportacaoScreen> createState() => _ImportacaoScreenState();
}

class _ImportacaoScreenState extends State<ImportacaoScreen> {
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  // ── Ações ─────────────────────────────────────────────────────────────────

  Future<void> _analisar() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cole uma conversa antes de analisar')),
      );
      return;
    }
    await Provider.of<ImportacaoProvider>(context, listen: false)
        .analisar(text);
  }

  Future<void> _salvar() async {
    final provider =
        Provider.of<ImportacaoProvider>(context, listen: false);
    final ocorrencias =
        Provider.of<OcorrenciaProvider>(context, listen: false);
    final notas = Provider.of<NotaProvider>(context, listen: false);

    final total = await provider.salvar(ocorrencias, notas);

    if (!mounted) return;
    _textCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$total evento(s) salvos — '
          'veja em Ocorrências e Notas',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ImportacaoProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Importar WhatsApp'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (provider.eventos.isNotEmpty)
            TextButton(
              onPressed: () {
                provider.limpar();
                _textCtrl.clear();
              },
              child: const Text('Limpar',
                  style: TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner API não configurada ──────────────────────────────
            if (!provider.configurado)
              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.only(bottom: Dimensions.spacingMD),
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.statusAtencao.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusMD),
                  border: Border.all(
                      color: AppColors.statusAtencao.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key_off,
                        color: AppColors.statusAtencao, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Adicione sua chave Claude no arquivo .env:\n'
                        'CLAUDE_API_KEY=sk-ant-...',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.statusAtencao),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Como usar ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cole uma conversa do grupo de trabalho. '
                      'A IA extrai ocorrências, faltas, atestados e tarefas '
                      'e salva nos módulos corretos automaticamente.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.spacingLG),

            // ── Campo de texto ─────────────────────────────────────────
            Text('Conversa do WhatsApp', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            TextField(
              controller: _textCtrl,
              maxLines: 8,
              minLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText:
                    '28/01/2026 08:33 - Vanessa: O caixa da Talita faltou 9,90\n'
                    '28/01/2026 09:00 - Ana: Ingrid não veio hoje\n'
                    '28/01/2026 09:05 - Ana: Precisa lavar os carrinhos',
                hintStyle: AppTextStyles.caption
                    .copyWith(color: AppColors.inactive),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusMD),
                  borderSide:
                      const BorderSide(color: AppColors.cardBorder),
                ),
                contentPadding: const EdgeInsets.all(Dimensions.paddingMD),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_textCtrl.text.length} caracteres',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                if (_textCtrl.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _textCtrl.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Limpar'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger),
                  ),
              ],
            ),

            const SizedBox(height: Dimensions.spacingMD),

            // ── Botão analisar ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.carregando || !provider.configurado
                    ? null
                    : _analisar,
                icon: provider.carregando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  provider.carregando ? 'Analisando...' : 'Analisar com IA',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(Dimensions.buttonHeight),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.inactive,
                ),
              ),
            ),

            // ── Erro ───────────────────────────────────────────────────
            if (provider.erro != null) ...[
              const SizedBox(height: Dimensions.spacingMD),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusMD),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.erro!,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Lista de eventos detectados ────────────────────────────
            if (provider.eventos.isNotEmpty) ...[
              const SizedBox(height: Dimensions.spacingLG),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${provider.eventos.length} evento(s) detectado(s)',
                    style: AppTextStyles.h3,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.eventos.length}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spacingSM),

              ...provider.eventos.asMap().entries.map((entry) =>
                  _EventoCard(
                    evento: entry.value,
                    index: entry.key,
                    onRemover: () => provider.remover(entry.key),
                  )),

              const SizedBox(height: Dimensions.spacingMD),

              // ── Botões de ação ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        provider.limpar();
                        _textCtrl.clear();
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Descartar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side:
                            const BorderSide(color: AppColors.danger),
                        minimumSize: const Size.fromHeight(
                            Dimensions.buttonHeight),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _salvar,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar todos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(
                            Dimensions.buttonHeight),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: Dimensions.spacingXL),
          ],
        ),
      ),
    );
  }
}

// ── Card de evento ─────────────────────────────────────────────────────────────

class _EventoCard extends StatelessWidget {
  final EventoImportado evento;
  final int index;
  final VoidCallback onRemover;

  const _EventoCard({
    required this.evento,
    required this.index,
    required this.onRemover,
  });

  IconData _icone(TipoEventoImportado tipo) {
    switch (tipo) {
      case TipoEventoImportado.discrepanciaValor:
        return Icons.point_of_sale;
      case TipoEventoImportado.atestado:
        return Icons.medical_services;
      case TipoEventoImportado.ausencia:
        return Icons.person_off;
      case TipoEventoImportado.tarefa:
        return Icons.task_alt;
      case TipoEventoImportado.entrega:
        return Icons.local_shipping;
      case TipoEventoImportado.reclamacao:
        return Icons.report_problem;
      case TipoEventoImportado.outro:
        return Icons.info_outline;
    }
  }

  Color _cor(TipoEventoImportado tipo) {
    switch (tipo) {
      case TipoEventoImportado.discrepanciaValor:
        return AppColors.danger;
      case TipoEventoImportado.atestado:
      case TipoEventoImportado.ausencia:
        return AppColors.statusAtencao;
      case TipoEventoImportado.tarefa:
        return AppColors.primary;
      case TipoEventoImportado.entrega:
        return AppColors.success;
      case TipoEventoImportado.reclamacao:
        return AppColors.danger;
      case TipoEventoImportado.outro:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _cor(evento.tipo);
    final destino =
        evento.tipo.vaiParaOcorrencia ? 'Ocorrência' : 'Nota';
    final destinoCor =
        evento.tipo.vaiParaOcorrencia ? AppColors.danger : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ícone do tipo
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cor.withValues(alpha: 0.12),
                  child: Icon(_icone(evento.tipo), color: cor, size: 18),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(evento.tipo.label,
                          style: AppTextStyles.h4),
                      const SizedBox(height: 2),
                      // Badge destino
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              destinoCor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '→ $destino',
                          style: AppTextStyles.caption.copyWith(
                            color: destinoCor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão remover
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: AppColors.inactive),
                  onPressed: onRemover,
                  tooltip: 'Remover evento',
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Descrição
            Text(evento.descricao, style: AppTextStyles.body),

            // Detalhes extras
            if (evento.nomeColaborador != null ||
                evento.valor != null ||
                evento.dataEvento != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (evento.nomeColaborador != null)
                    _Chip(
                      icon: Icons.person,
                      texto: evento.nomeColaborador!,
                    ),
                  if (evento.valor != null)
                    _Chip(
                      icon: Icons.attach_money,
                      texto:
                          'R\$ ${evento.valor!.toStringAsFixed(2)}',
                      cor: AppColors.danger,
                    ),
                  if (evento.dataEvento != null)
                    _Chip(
                      icon: Icons.calendar_today,
                      texto:
                          '${evento.dataEvento!.day.toString().padLeft(2, '0')}/'
                          '${evento.dataEvento!.month.toString().padLeft(2, '0')}',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color? cor;

  const _Chip({required this.icon, required this.texto, this.cor});

  @override
  Widget build(BuildContext context) {
    final c = cor ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(
          texto,
          style:
              AppTextStyles.caption.copyWith(color: c, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
