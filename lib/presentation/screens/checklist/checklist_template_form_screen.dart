import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/checklist_provider.dart';
import '../../../core/utils/app_notif.dart';

class ChecklistTemplateFormScreen extends StatefulWidget {
  final ChecklistTemplate? template; // null = novo

  const ChecklistTemplateFormScreen({super.key, this.template});

  @override
  State<ChecklistTemplateFormScreen> createState() =>
      _ChecklistTemplateFormScreenState();
}

class _ChecklistTemplateFormScreenState
    extends State<ChecklistTemplateFormScreen> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late String _iconeKey;
  late String _corHex;
  late List<String> _itens;
  final List<TextEditingController> _itemCtrls = [];
  late PeriodizacaoChecklist _periodizacao;
  late ModoExecucaoChecklist _modoExecucao;
  String?
      _horarioNotificacao; // "HH:mm" quando _periodizacao == horarioEspecifico

  bool get _editando => widget.template != null;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _tituloCtrl.text = t?.titulo ?? '';
    _descCtrl.text = t?.descricao ?? '';
    _iconeKey = t?.iconeKey ?? kChecklistIcones.first.$1;
    _corHex = t?.corHex ?? '4CAF50';
    _itens = List<String>.from(t?.itens ?? ['']);
    _periodizacao = t?.periodizacao ?? PeriodizacaoChecklist.qualquerHorario;
    _modoExecucao = t?.modoExecucao ?? ModoExecucaoChecklist.continuo;
    _horarioNotificacao = t?.horarioNotificacao;
    _syncControllers();
  }

  void _syncControllers() {
    // Dispose extras
    for (final c in _itemCtrls) {
      c.dispose();
    }
    _itemCtrls.clear();
    for (final item in _itens) {
      _itemCtrls.add(TextEditingController(text: item));
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _itemCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _itens.add('');
      _itemCtrls.add(TextEditingController());
    });
  }

  void _removeItem(int index) {
    if (_itens.length <= 1) return;
    setState(() {
      _itemCtrls[index].dispose();
      _itens.removeAt(index);
      _itemCtrls.removeAt(index);
    });
  }

  Future<void> _salvar() async {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      AppNotif.show(
        context,
        titulo: 'Campo Inválido',
        mensagem: 'Informe um título para o checklist',
        tipo: 'alerta',
      );
      return;
    }
    final itens = _itemCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (itens.isEmpty) {
      AppNotif.show(
        context,
        titulo: 'Campo Inválido',
        mensagem: 'Adicione pelo menos um item ao checklist',
        tipo: 'alerta',
      );
      return;
    }

    final provider = Provider.of<ChecklistProvider>(context, listen: false);

    final horario = _periodizacao == PeriodizacaoChecklist.horarioEspecifico
        ? _horarioNotificacao
        : null;

    bool supabaseFalhou = false;
    try {
      if (_editando) {
        final atualizado = widget.template!.copyWith(
          titulo: titulo,
          descricao: _descCtrl.text.trim(),
          iconeKey: _iconeKey,
          corHex: _corHex,
          itens: itens,
          periodizacao: _periodizacao,
          modoExecucao: _modoExecucao,
          horarioNotificacao: horario,
          clearHorario: horario == null,
        );
        await provider.atualizarTemplate(atualizado);
      } else {
        final novo = ChecklistTemplate(
          id: const Uuid().v4(),
          titulo: titulo,
          descricao: _descCtrl.text.trim(),
          iconeKey: _iconeKey,
          corHex: _corHex,
          itens: itens,
          createdAt: DateTime.now(),
          periodizacao: _periodizacao,
          modoExecucao: _modoExecucao,
          horarioNotificacao: horario,
        );
        await provider.adicionarTemplate(novo);
      }
    } catch (_) {
      supabaseFalhou = true;
    }

    if (!mounted) return;

    if (supabaseFalhou) {
      // Salvo localmente — mostra aviso mas ainda navega de volta
      AppNotif.show(
        context,
        titulo: 'Salvo localmente',
        mensagem:
            'Checklist salvo no dispositivo. Falha ao sincronizar com o servidor.',
        tipo: 'alerta',
        cor: AppColors.warning,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_editando ? 'Editar Checklist' : 'Novo Checklist'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _salvar,
            child: Text(
              'Salvar',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.hPad(constraints.maxWidth),
                  vertical: Dimensions.paddingMD,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // â”€â”€ Título â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    TextField(
                      controller: _tituloCtrl,
                      decoration: InputDecoration(
                        labelText: 'Título *',
                        hintText: 'Ex: Checklist de Limpeza',
                        prefixIcon: Icon(Icons.title),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    SizedBox(height: Dimensions.spacingMD),

                    // â”€â”€ Descrição â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    TextField(
                      controller: _descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Descrição (opcional)',
                        hintText: 'Breve descrição do checklist',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    SizedBox(height: Dimensions.spacingLG),

                    // â”€â”€ Cor â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Text(
                      'Como esse checklist funciona?',
                      style: AppTextStyles.h4,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Uso contínuo pode ser respondido novamente. Uso único some da lista depois da primeira conclusão.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingSM),
                    ...ModoExecucaoChecklist.values.map((modo) {
                      final selecionado = _modoExecucao == modo;
                      final cor = modo == ModoExecucaoChecklist.continuo
                          ? AppColors.primary
                          : AppColors.statusAtencao;
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: Dimensions.spacingSM),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusMD),
                          onTap: () => setState(() => _modoExecucao = modo),
                          child: Container(
                            width: double.infinity,
                            decoration: AppStyles.softCard(
                              tint: selecionado ? cor : AppColors.cardBorder,
                              radius: Dimensions.radiusMD,
                              elevated: false,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(Dimensions.paddingMD),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selecionado
                                          ? cor.withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: selecionado
                                            ? cor
                                            : AppColors.cardBorder,
                                      ),
                                    ),
                                    child: Icon(
                                      selecionado
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      size: 16,
                                      color: selecionado
                                          ? cor
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          modo.label,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: selecionado
                                                ? cor
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          modo.descricaoCurta,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: Dimensions.spacingSM),

                    Text('Cor', style: AppTextStyles.h4),
                    SizedBox(height: Dimensions.spacingSM),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: kChecklistCores.map((c) {
                        final hex = c
                            .toARGB32()
                            .toRadixString(16)
                            .substring(2)
                            .toUpperCase();
                        final sel = _corHex == hex;
                        return GestureDetector(
                          onTap: () => setState(() => _corHex = hex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: sel
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                          color: c.withValues(alpha: 0.5),
                                          blurRadius: 8)
                                    ]
                                  : null,
                            ),
                            child: sel
                                ? Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: Dimensions.spacingLG),

                    // â”€â”€ Ícone â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Text('Ícone', style: AppTextStyles.h4),
                    SizedBox(height: Dimensions.spacingSM),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kChecklistIcones.map((entry) {
                        final sel = _iconeKey == entry.$1;
                        final cor = Color(int.parse('FF$_corHex', radix: 16));
                        return GestureDetector(
                          onTap: () => setState(() => _iconeKey = entry.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: sel
                                  ? cor.withValues(alpha: 0.15)
                                  : AppColors.cardBackground,
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusMD),
                              border: Border.all(
                                color: sel ? cor : AppColors.cardBorder,
                                width: sel ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(entry.$2,
                                    color: sel ? cor : AppColors.textSecondary,
                                    size: 20),
                                SizedBox(height: 2),
                                Text(
                                  entry.$3,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: sel ? cor : AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: Dimensions.spacingLG),

                    // â”€â”€ Periodização â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Text('Quando notificar?', style: AppTextStyles.h4),
                    SizedBox(height: 4),
                    Text(
                      'O alerta aparece somente durante o horário escolhido.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: Dimensions.spacingSM),
                    RadioGroup<PeriodizacaoChecklist>(
                      groupValue: _periodizacao,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _periodizacao = v;
                          if (v != PeriodizacaoChecklist.horarioEspecifico) {
                            _horarioNotificacao = null;
                          }
                        });
                      },
                      child: Column(
                        children: PeriodizacaoChecklist.values.map((p) {
                          return RadioListTile<PeriodizacaoChecklist>(
                            value: p,
                            title: Text(p.label, style: AppTextStyles.body),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          );
                        }).toList(),
                      ),
                    ),
                    if (_periodizacao ==
                        PeriodizacaoChecklist.horarioEspecifico) ...[
                      SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final parts = _horarioNotificacao?.split(':');
                          final initial = parts != null && parts.length == 2
                              ? TimeOfDay(
                                  hour: int.tryParse(parts[0]) ?? 8,
                                  minute: int.tryParse(parts[1]) ?? 0,
                                )
                              : const TimeOfDay(hour: 8, minute: 0);
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: initial,
                          );
                          if (picked != null) {
                            setState(() {
                              _horarioNotificacao =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        icon: Icon(Icons.access_time, size: 18),
                        label: Text(
                          _horarioNotificacao != null
                              ? 'Horário: $_horarioNotificacao  (±30 min)'
                              : 'Selecionar horário',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],

                    SizedBox(height: Dimensions.spacingLG),

                    // â”€â”€ Itens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Itens do checklist', style: AppTextStyles.h4),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: Icon(Icons.add, size: 18),
                          label: Text('Adicionar'),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimensions.spacingSM),

                    ...List.generate(_itemCtrls.length, (i) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: Dimensions.spacingSM),
                        child: Row(
                          children: [
                            // Número
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Color(int.parse('FF$_corHex', radix: 16))
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Color(int.parse('FF$_corHex', radix: 16)),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            // Campo
                            Expanded(
                              child: TextField(
                                controller: _itemCtrls[i],
                                decoration: InputDecoration(
                                  hintText: 'Item ${i + 1}',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                            ),
                            // Remover
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline,
                                  color: AppColors.danger, size: 20),
                              onPressed: _itens.length > 1
                                  ? () => _removeItem(i)
                                  : null,
                              tooltip: 'Remover item',
                            ),
                          ],
                        ),
                      );
                    }),

                    SizedBox(height: Dimensions.spacingXL),

                    // â”€â”€ Botão salvar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _salvar,
                        icon: Icon(Icons.save),
                        label: Text(_editando
                            ? 'Salvar alterações'
                            : 'Criar checklist'),
                        style: ElevatedButton.styleFrom(
                          minimumSize:
                              const Size.fromHeight(Dimensions.buttonHeight),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingMD),
                  ],
                ),
              )),
    );
  }
}
