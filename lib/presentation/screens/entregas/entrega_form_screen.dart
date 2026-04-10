import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/entrega_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../../core/utils/app_notif.dart';

/// Tela de FormulÃƒÆ’Ã‚Â¡rio de Entrega
/// Permite cadastrar ou editar uma entrega
class EntregaFormScreen extends StatefulWidget {
  final Entrega?
      entrega; // Null para nova, preenchido para ediÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o

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

  final List<String> _cidades = ['Baependi', 'Caxambu', 'CruzÃƒÆ’Ã‚Â­lia'];

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
            colorScheme: ColorScheme.light(
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

  /// Abre bottom sheet com campo de texto para colar o CSV.
  Future<void> _abrirSheetCsv() async {
    // Tenta prÃƒÆ’Ã‚Â©-preencher com o que estÃƒÆ’Ã‚Â¡ no clipboard
    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    final csvController =
        TextEditingController(text: clipData?.text?.trim() ?? '');

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Preencher via CSV', style: AppTextStyles.h3),
              SizedBox(height: 4),
              Text(
                'Cole abaixo o texto copiado do sistema de pedidos.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: 16),
              TextField(
                controller: csvController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      'fiscal_id,cliente_nome,bairro,...\n[dados da entrega]',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, size: 18),
                    onPressed: () => csvController.clear(),
                    tooltip: 'Limpar',
                  ),
                ),
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.auto_fix_high),
                  label: Text('Preencher FormulÃƒÆ’Ã‚Â¡rio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {
                    final erro = _aplicarCsv(csvController.text.trim());
                    Navigator.of(sheetCtx).pop();
                    if (!mounted) return;
                    if (erro != null) {
                      AppNotif.show(
                        context,
                        titulo: 'Erro no CSV',
                        mensagem: erro,
                        tipo: 'alerta',
                        cor: AppColors.danger,
                      );
                    } else {
                      AppNotif.show(
                        context,
                        titulo: 'CSV Aplicado',
                        mensagem: 'FormulÃƒÆ’Ã‚Â¡rio preenchido com sucesso!',
                        tipo: 'saida',
                        cor: AppColors.success,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    csvController.dispose();
  }

  /// Faz o parse do CSV e preenche os controllers.
  /// Retorna uma mensagem de erro ou null em caso de sucesso.
  String? _aplicarCsv(String texto) {
    if (texto.isEmpty) return 'Nenhum texto para processar.';

    final linhas = const CsvToListConverter(eol: '\n').convert(texto);
    if (linhas.length < 2)
      return 'Formato CSV invÃƒÆ’Ã‚Â¡lido (esperado cabeÃƒÆ’Ã‚Â§alho + dados).';

    final cabecalhos = linhas[0].map((e) => e.toString().trim()).toList();
    final valores = linhas[1].map((e) => e.toString().trim()).toList();

    if (cabecalhos.length != valores.length) {
      return 'NÃƒÆ’Ã‚Âºmero de colunas inconsistente (${cabecalhos.length} cabeÃƒÆ’Ã‚Â§alhos, ${valores.length} valores).';
    }

    final mapa = {
      for (var i = 0; i < cabecalhos.length; i++) cabecalhos[i]: valores[i],
    };

    setState(() {
      if (mapa['cliente_nome']?.isNotEmpty == true) {
        _nomeClienteController.text = mapa['cliente_nome']!;
      }
      if (mapa['bairro']?.isNotEmpty == true) {
        _bairroController.text = mapa['bairro']!;
      }
      if (mapa['endereco']?.isNotEmpty == true) {
        _enderecoController.text = mapa['endereco']!;
      }
      if (mapa['telefone']?.isNotEmpty == true) {
        _telefoneController.text = mapa['telefone']!;
      }
      if (mapa['numero_nota']?.isNotEmpty == true) {
        _numeroNFController.text = mapa['numero_nota']!;
      }
      if (mapa['observacoes']?.isNotEmpty == true) {
        _observacoesController.text = mapa['observacoes']!;
      }
      // ComparaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o case-insensitive para cidade (ex: BAEPENDI ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ Baependi)
      if (mapa['cidade']?.isNotEmpty == true) {
        final cidadeNormalizada = _cidades.firstWhere(
          (c) => c.toLowerCase() == mapa['cidade']!.toLowerCase(),
          orElse: () => '',
        );
        if (cidadeNormalizada.isNotEmpty) {
          _cidadeSelecionada = cidadeNormalizada;
        }
      }
    });

    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final entregaProvider =
        Provider.of<EntregaProvider>(context, listen: false);

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

      final eventoProvider =
          Provider.of<EventoTurnoProvider>(context, listen: false);
      if (eventoProvider.turnoAtivo) {
        final fiscalId =
            Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
        eventoProvider.registrar(
          fiscalId: fiscalId,
          tipo: TipoEvento.entregaCadastrada,
          detalhe:
              'NF ${_numeroNFController.text.trim()} ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ${_nomeClienteController.text.trim()}',
        );
      }

      AppNotif.show(
        context,
        titulo: 'Entrega Cadastrada',
        mensagem: 'Entrega cadastrada com sucesso!',
        tipo: 'saida',
        cor: AppColors.success,
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

      AppNotif.show(
        context,
        titulo: 'Entrega Atualizada',
        mensagem: 'Entrega atualizada com sucesso!',
        tipo: 'saida',
        cor: AppColors.success,
      );

      Navigator.of(context).pop(true);
    }
  }

  String _formatHorario(DateTime? horario) {
    if (horario == null) return 'NÃƒÆ’Ã‚Â£o definido';
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
        actions: [
          IconButton(
            icon: Icon(Icons.content_paste_rounded),
            tooltip: 'Preencher via CSV',
            onPressed: _abrirSheetCsv,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NÃƒÆ’Ã‚Âºmero da NF
              TextFormField(
                controller: _numeroNFController,
                decoration: InputDecoration(
                  labelText: 'NÃƒÆ’Ã‚Âºmero da NF *',
                  hintText: 'Ex: 12345',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'NÃƒÆ’Ã‚Âºmero da NF ÃƒÆ’Ã‚Â© obrigatÃƒÆ’Ã‚Â³rio';
                  }
                  return null;
                },
              ),

              SizedBox(height: Dimensions.spacingMD),

              // Nome do Cliente
              TextFormField(
                controller: _nomeClienteController,
                decoration: InputDecoration(
                  labelText: 'Nome do Cliente *',
                  hintText: 'Digite o nome completo',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome do cliente ÃƒÆ’Ã‚Â© obrigatÃƒÆ’Ã‚Â³rio';
                  }
                  if (value.trim().length < 3) {
                    return 'Nome deve ter pelo menos 3 caracteres';
                  }
                  return null;
                },
              ),

              SizedBox(height: Dimensions.spacingMD),

              // Telefone
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(35) 99999-9999',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),

              SizedBox(height: Dimensions.spacingMD),

              // EndereÃƒÆ’Ã‚Â§o
              TextFormField(
                controller: _enderecoController,
                decoration: InputDecoration(
                  labelText: 'EndereÃƒÆ’Ã‚Â§o *',
                  hintText: 'Rua, nÃƒÆ’Ã‚Âºmero e complemento',
                  prefixIcon: Icon(Icons.home),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'EndereÃƒÆ’Ã‚Â§o ÃƒÆ’Ã‚Â© obrigatÃƒÆ’Ã‚Â³rio';
                  }
                  return null;
                },
              ),

              SizedBox(height: Dimensions.spacingMD),

              // Bairro
              TextFormField(
                controller: _bairroController,
                decoration: InputDecoration(
                  labelText: 'Bairro *',
                  hintText: 'Digite o bairro',
                  prefixIcon: Icon(Icons.location_city),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bairro ÃƒÆ’Ã‚Â© obrigatÃƒÆ’Ã‚Â³rio';
                  }
                  return null;
                },
              ),

              SizedBox(height: Dimensions.spacingMD),

              // Cidade (Dropdown)
              DropdownButtonFormField<String>(
                initialValue: _cidadeSelecionada,
                decoration: InputDecoration(
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

              SizedBox(height: Dimensions.spacingMD),

              // HorÃƒÆ’Ã‚Â¡rio Marcado
              Card(
                child: ListTile(
                  leading: Icon(Icons.access_time, color: AppColors.primary),
                  title: Text('HorÃƒÆ’Ã‚Â¡rio Marcado'),
                  subtitle: Text(_formatHorario(_horarioMarcado)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_horarioMarcado != null)
                        IconButton(
                          icon: Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() => _horarioMarcado = null);
                          },
                          tooltip: 'Remover horÃƒÆ’Ã‚Â¡rio',
                        ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: _selecionarHorario,
                        tooltip: 'Definir horÃƒÆ’Ã‚Â¡rio',
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: Dimensions.spacingMD),

              // ObservaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes
              TextFormField(
                controller: _observacoesController,
                decoration: InputDecoration(
                  labelText: 'ObservaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes',
                  hintText:
                      'InformaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes adicionais sobre a entrega',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              SizedBox(height: Dimensions.spacingXL),

              // InformaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o sobre status inicial
              if (isNova)
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingMD),
                  decoration: BoxDecoration(
                    color: AppColors.alertInfo,
                    borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                      ),
                      SizedBox(width: Dimensions.spacingSM),
                      Expanded(
                        child: Text(
                          'A entrega serÃƒÆ’Ã‚Â¡ criada com status "Separada"',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: Dimensions.spacingLG),

              // BotÃƒÆ’Ã‚Âµes
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(Dimensions.buttonHeight),
                      ),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(Dimensions.buttonHeight),
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
