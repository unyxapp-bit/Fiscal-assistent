import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/entrega_provider.dart';

/// Tela de Formulário de Entrega
/// Permite cadastrar ou editar uma entrega
class EntregaFormScreen extends StatefulWidget {
  final Entrega? entrega; // Null para nova, preenchido para edição

  const EntregaFormScreen({
    super.key,
    this.entrega,
  });

  @override
  State<EntregaFormScreen> createState() => _EntregaFormScreenState();
}

class _EntregaFormScreenState extends State<EntregaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroNFController = TextEditingController();
  final _nomeClienteController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _observacoesController = TextEditingController();

  String _cidadeSelecionada = 'Baependi';
  DateTime? _horarioMarcado;

  final List<String> _cidades = ['Baependi', 'Caxambu', 'Cruzília'];

  @override
  void initState() {
    super.initState();
    if (widget.entrega != null) {
      _numeroNFController.text = widget.entrega!.numeroNota;
      _nomeClienteController.text = widget.entrega!.clienteNome;
      _telefoneController.text = widget.entrega!.telefone ?? '';
      _enderecoController.text = widget.entrega!.endereco;
      _bairroController.text = widget.entrega!.bairro;
      _cidadeSelecionada = widget.entrega!.cidade;
      _horarioMarcado = widget.entrega!.horarioMarcado;
      _observacoesController.text = widget.entrega!.observacoes ?? '';
    }
  }

  @override
  void dispose() {
    _numeroNFController.dispose();
    _nomeClienteController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _bairroController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selecionarHorario() async {
    final TimeOfDay? horario = await showTimePicker(
      context: context,
      initialTime: _horarioMarcado != null
          ? TimeOfDay.fromDateTime(_horarioMarcado!)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (horario != null) {
      final now = DateTime.now();
      setState(() {
        _horarioMarcado = DateTime(
          now.year,
          now.month,
          now.day,
          horario.hour,
          horario.minute,
        );
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final entregaProvider = Provider.of<EntregaProvider>(context, listen: false);

    if (widget.entrega == null) {
      // Nova entrega
      entregaProvider.adicionarEntrega(
        numeroNota: _numeroNFController.text.trim(),
        clienteNome: _nomeClienteController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty
            ? null
            : _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeSelecionada,
        observacoes: _observacoesController.text.trim().isEmpty
            ? null
            : _observacoesController.text.trim(),
        horarioMarcado: _horarioMarcado,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrega cadastrada com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop(true);
    } else {
      // Editar entrega existente
      entregaProvider.atualizarEntrega(
        id: widget.entrega!.id,
        numeroNota: _numeroNFController.text.trim(),
        clienteNome: _nomeClienteController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty
            ? null
            : _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeSelecionada,
        observacoes: _observacoesController.text.trim().isEmpty
            ? null
            : _observacoesController.text.trim(),
        horarioMarcado: _horarioMarcado,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrega atualizada com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop(true);
    }
  }

  String _formatHorario(DateTime? horario) {
    if (horario == null) return 'Não definido';
    return '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isNova = widget.entrega == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          isNova ? 'Nova Entrega' : 'Editar Entrega',
          style: AppTextStyles.h3,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Número da NF
              TextFormField(
                controller: _numeroNFController,
                decoration: const InputDecoration(
                  labelText: 'Número da NF *',
                  hintText: 'Ex: 12345',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Número da NF é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: Dimensions.spacingMD),

              // Nome do Cliente
              TextFormField(
                controller: _nomeClienteController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Cliente *',
                  hintText: 'Digite o nome completo',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome do cliente é obrigatório';
                  }
                  if (value.trim().length < 3) {
                    return 'Nome deve ter pelo menos 3 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: Dimensions.spacingMD),

              // Telefone
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(35) 99999-9999',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: Dimensions.spacingMD),

              // Endereço
              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(
                  labelText: 'Endereço *',
                  hintText: 'Rua, número e complemento',
                  prefixIcon: Icon(Icons.home),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Endereço é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: Dimensions.spacingMD),

              // Bairro
              TextFormField(
                controller: _bairroController,
                decoration: const InputDecoration(
                  labelText: 'Bairro *',
                  hintText: 'Digite o bairro',
                  prefixIcon: Icon(Icons.location_city),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bairro é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: Dimensions.spacingMD),

              // Cidade (Dropdown)
              DropdownButtonFormField<String>(
                initialValue: _cidadeSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Cidade *',
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: _cidades.map((cidade) {
                  return DropdownMenuItem(
                    value: cidade,
                    child: Text(cidade),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _cidadeSelecionada = value);
                  }
                },
              ),

              const SizedBox(height: Dimensions.spacingMD),

              // Horário Marcado
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time, color: AppColors.primary),
                  title: const Text('Horário Marcado'),
                  subtitle: Text(_formatHorario(_horarioMarcado)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_horarioMarcado != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() => _horarioMarcado = null);
                          },
                          tooltip: 'Remover horário',
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _selecionarHorario,
                        tooltip: 'Definir horário',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.spacingMD),

              // Observações
              TextFormField(
                controller: _observacoesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Informações adicionais sobre a entrega',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: Dimensions.spacingXL),

              // Informação sobre status inicial
              if (isNova)
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingMD),
                  decoration: BoxDecoration(
                    color: AppColors.alertInfo,
                    borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: Dimensions.spacingSM),
                      Expanded(
                        child: Text(
                          'A entrega será criada com status "Separada"',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: Dimensions.spacingLG),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isNova ? 'Cadastrar' : 'Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
