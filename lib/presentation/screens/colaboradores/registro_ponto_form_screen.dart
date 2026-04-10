import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/registro_ponto.dart';
import '../../providers/registro_ponto_provider.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../../core/utils/app_notif.dart';

/// Tela para criar ou editar um Registro de Ponto
class RegistroPontoFormScreen extends StatefulWidget {
  final String colaboradorId;
  final RegistroPonto? registroExistente;

  /// Data pré-selecionada (opcional, ex: ao abrir da tela de turno)
  final DateTime? dataInicial;

  const RegistroPontoFormScreen({
    super.key,
    required this.colaboradorId,
    this.registroExistente,
    this.dataInicial,
  });

  @override
  State<RegistroPontoFormScreen> createState() =>
      _RegistroPontoFormScreenState();
}

class _RegistroPontoFormScreenState extends State<RegistroPontoFormScreen> {
  late DateTime _data;
  String _tipo = 'trabalho'; // 'trabalho' | 'folga' | 'feriado'

  final _entradaController = TextEditingController();
  final _intervaloSaidaController = TextEditingController();
  final _intervaloRetornoController = TextEditingController();
  final _saidaController = TextEditingController();
  final _observacaoController = TextEditingController();

  bool _isLoading = false;
  bool get _isEdit => widget.registroExistente != null;

  @override
  void initState() {
    super.initState();
    _data = widget.dataInicial ?? DateTime.now();

    if (_isEdit) {
      final r = widget.registroExistente!;
      _data = r.data;
      _entradaController.text = r.entrada ?? '';
      _intervaloSaidaController.text = r.intervaloSaida ?? '';
      _intervaloRetornoController.text = r.intervaloRetorno ?? '';
      _saidaController.text = r.saida ?? '';

      final obs = r.observacao?.toUpperCase() ?? '';
      if (obs == 'FOLGA') {
        _tipo = 'folga';
      } else if (obs == 'FERIADO') {
        _tipo = 'feriado';
      } else {
        _tipo = 'trabalho';
        _observacaoController.text = r.observacao ?? '';
      }
    }
  }

  @override
  void dispose() {
    _entradaController.dispose();
    _intervaloSaidaController.dispose();
    _intervaloRetornoController.dispose();
    _saidaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _data = picked);
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final parts = controller.text.split(':');
    final initial = (parts.length == 2)
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          )
        : TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  String? _buildObservacao() {
    if (_tipo == 'folga') return 'Folga';
    if (_tipo == 'feriado') return 'Feriado';
    final obs = _observacaoController.text.trim();
    return obs.isEmpty ? null : obs;
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<RegistroPontoProvider>(context, listen: false);

    bool success;

    if (_isEdit) {
      // Build directly to allow clearing nullable fields
      final atualizado = RegistroPonto(
        id: widget.registroExistente!.id,
        colaboradorId: widget.colaboradorId,
        data: _data,
        entrada: _tipo == 'trabalho'
            ? (_entradaController.text.trim().isEmpty
                ? null
                : _entradaController.text.trim())
            : null,
        intervaloSaida: _tipo == 'trabalho'
            ? (_intervaloSaidaController.text.trim().isEmpty
                ? null
                : _intervaloSaidaController.text.trim())
            : null,
        intervaloRetorno: _tipo == 'trabalho'
            ? (_intervaloRetornoController.text.trim().isEmpty
                ? null
                : _intervaloRetornoController.text.trim())
            : null,
        saida: _tipo == 'trabalho'
            ? (_saidaController.text.trim().isEmpty
                ? null
                : _saidaController.text.trim())
            : null,
        observacao: _buildObservacao(),
      );
      success = await provider.updateRegistroPonto(atualizado);
    } else {
      success = await provider.createRegistroPonto(
        colaboradorId: widget.colaboradorId,
        data: _data,
        entrada: _tipo == 'trabalho'
            ? (_entradaController.text.trim().isEmpty
                ? null
                : _entradaController.text.trim())
            : null,
        intervaloSaida: _tipo == 'trabalho'
            ? (_intervaloSaidaController.text.trim().isEmpty
                ? null
                : _intervaloSaidaController.text.trim())
            : null,
        intervaloRetorno: _tipo == 'trabalho'
            ? (_intervaloRetornoController.text.trim().isEmpty
                ? null
                : _intervaloRetornoController.text.trim())
            : null,
        saida: _tipo == 'trabalho'
            ? (_saidaController.text.trim().isEmpty
                ? null
                : _saidaController.text.trim())
            : null,
        observacao: _buildObservacao(),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      AppNotif.show(
        context,
        titulo: 'Registro Salvo',
        mensagem: _isEdit ? 'Registro atualizado!' : 'Registro criado!',
        tipo: 'saida',
        cor: AppColors.success,
      );
      Navigator.of(context).pop();
    } else {
      AppNotif.show(
        context,
        titulo: 'Erro',
        mensagem: provider.errorMessage ?? 'Erro ao salvar',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isEdit ? 'Editar Registro' : 'Novo Registro de Ponto',
          style: AppTextStyles.h3,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data
            Text('Data', style: AppTextStyles.subtitle),
            SizedBox(height: Dimensions.spacingSM),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(Dimensions.radiusMD),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingMD,
                  vertical: Dimensions.paddingSM,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: Dimensions.spacingSM),
                    Text(
                      _formatDate(_data),
                      style: AppTextStyles.body,
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            SizedBox(height: Dimensions.spacingLG),

            // Tipo
            Text('Tipo', style: AppTextStyles.subtitle),
            SizedBox(height: Dimensions.spacingSM),
            _buildTipoSelector(),

            SizedBox(height: Dimensions.spacingLG),

            // Horários (somente para trabalho)
            if (_tipo == 'trabalho') ...[
              Text('Horários', style: AppTextStyles.subtitle),
              SizedBox(height: Dimensions.spacingSM),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeTile(
                      label: 'Entrada',
                      icon: Icons.login,
                      controller: _entradaController,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingMD),
                  Expanded(
                    child: _buildTimeTile(
                      label: 'Saída',
                      icon: Icons.logout,
                      controller: _saidaController,
                      color: AppColors.statusSaida,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Dimensions.spacingMD),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeTile(
                      label: 'Intervalo',
                      icon: Icons.pause_circle_outline,
                      controller: _intervaloSaidaController,
                      color: AppColors.statusCafe,
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingMD),
                  Expanded(
                    child: _buildTimeTile(
                      label: 'Retorno',
                      icon: Icons.play_circle_outline,
                      controller: _intervaloRetornoController,
                      color: AppColors.statusAtivo,
                    ),
                  ),
                ],
              ),

              SizedBox(height: Dimensions.spacingLG),

              // Observação (trabalho)
              Text('Observação (Opcional)', style: AppTextStyles.subtitle),
              SizedBox(height: Dimensions.spacingSM),
              TextFormField(
                controller: _observacaoController,
                decoration: InputDecoration(
                  hintText: 'Ex: Self, Vipp, etc',
                  prefixIcon: Icon(Icons.note),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                    borderSide: BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                maxLines: 2,
              ),

              SizedBox(height: Dimensions.spacingLG),
            ],

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSM,
                      ),
                    ),
                    child: Text('Cancelar'),
                  ),
                ),
                SizedBox(width: Dimensions.spacingMD),
                Expanded(
                  child: PrimaryButton(
                    onPressed: _isLoading ? () {} : _handleSave,
                    text: _isEdit ? 'Atualizar' : 'Salvar',
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoSelector() {
    final tipos = [
      (
        key: 'trabalho',
        label: 'Trabalho',
        icon: Icons.work,
        color: AppColors.primary
      ),
      (
        key: 'folga',
        label: 'Folga',
        icon: Icons.weekend,
        color: AppColors.statusFolga
      ),
      (
        key: 'feriado',
        label: 'Feriado',
        icon: Icons.celebration,
        color: AppColors.statusAtencao
      ),
    ];

    return Row(
      children: tipos.map((t) {
        final isSelected = _tipo == t.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tipo = t.key),
            child: Container(
              margin: EdgeInsets.only(
                right: t.key != 'feriado' ? Dimensions.spacingSM : 0,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSM,
                horizontal: Dimensions.paddingXS,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? t.color.withValues(alpha: 0.12)
                    : AppColors.cardBackground,
                border: Border.all(
                  color: isSelected ? t.color : AppColors.cardBorder,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(Dimensions.radiusMD),
              ),
              child: Column(
                children: [
                  Icon(t.icon,
                      color: isSelected ? t.color : AppColors.textSecondary,
                      size: 22),
                  SizedBox(height: 4),
                  Text(
                    t.label,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? t.color : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _pickTime(controller),
      borderRadius: BorderRadius.circular(Dimensions.radiusMD),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSM,
          vertical: Dimensions.paddingSM,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (_, val, __) => Text(
                      val.text.isEmpty ? '--:--' : val.text,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: val.text.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const dias = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo'
    ];
    final diaSemana = dias[date.weekday - 1];
    return '$diaSemana, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
