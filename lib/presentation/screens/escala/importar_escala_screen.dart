import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/app_notif.dart';
import '../../../domain/entities/colaborador.dart';
import '../../../domain/entities/registro_ponto.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/registro_ponto_provider.dart';

// Ã¢â€â‚¬Ã¢â€â‚¬ Helpers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

bool _isTime(String s) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s);

String _normalizeNome(String s) {
  // Remove parenthesized suffixes e.g. "(Self)", "(Fiscal)"
  var r =
      s.toUpperCase().trim().replaceAll(RegExp(r'\s*\([^)]*\)\s*'), ' ').trim();
  // Remove excess spaces
  r = r.replaceAll(RegExp(r'\s+'), ' ');
  // Remove common Portuguese accents
  const Map<String, String> accents = {
    'Ãƒâ‚¬': 'A',
    'ÃƒÂ': 'A',
    'Ãƒâ€š': 'A',
    'ÃƒÆ’': 'A',
    'Ãƒâ€ž': 'A',
    'ÃƒË†': 'E',
    'Ãƒâ€°': 'E',
    'ÃƒÅ ': 'E',
    'Ãƒâ€¹': 'E',
    'ÃƒÅ’': 'I',
    'ÃƒÂ': 'I',
    'ÃƒÅ½': 'I',
    'ÃƒÂ': 'I',
    'Ãƒâ€™': 'O',
    'Ãƒâ€œ': 'O',
    'Ãƒâ€': 'O',
    'Ãƒâ€¢': 'O',
    'Ãƒâ€“': 'O',
    'Ãƒâ„¢': 'U',
    'ÃƒÅ¡': 'U',
    'Ãƒâ€º': 'U',
    'ÃƒÅ“': 'U',
    'Ãƒâ€¡': 'C',
    'Ãƒâ€˜': 'N',
  };
  for (final e in accents.entries) {
    r = r.replaceAll(e.key, e.value);
  }
  return r;
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Modelo de linha parseada Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

enum _Status { ok, parcial, naoEncontrado }

class _LinhaParseada {
  final String linhaOriginal;
  final String nomeTexto;
  final String? colaboradorId;
  final String? nomeEncontrado;
  final DateTime data;
  final String? entrada;
  final String? intervaloSaida;
  final String? intervaloRetorno;
  final String? saida;
  final String? observacao;
  final String? aviso;

  const _LinhaParseada({
    required this.linhaOriginal,
    required this.nomeTexto,
    required this.data,
    this.colaboradorId,
    this.nomeEncontrado,
    this.entrada,
    this.intervaloSaida,
    this.intervaloRetorno,
    this.saida,
    this.observacao,
    this.aviso,
  });

  _Status get status {
    if (colaboradorId == null) return _Status.naoEncontrado;
    if (aviso != null) return _Status.parcial;
    return _Status.ok;
  }

  bool get importavel => colaboradorId != null;

  RegistroPonto toRegistroPonto() {
    return RegistroPonto(
      id: 'new',
      colaboradorId: colaboradorId!,
      data: data,
      entrada: entrada,
      intervaloSaida: intervaloSaida,
      intervaloRetorno: intervaloRetorno,
      saida: saida,
      observacao: observacao,
    );
  }
}

_LinhaParseada _parseLinha(
    String linha, DateTime data, Map<String, Colaborador> mapa) {
  final tokens = linha.trim().split(RegExp(r'\s+'));
  if (tokens.isEmpty || (tokens.length == 1 && tokens[0].isEmpty)) {
    return _LinhaParseada(
        linhaOriginal: linha, nomeTexto: '', data: data, aviso: 'Linha vazia');
  }

  // Detect FOLGA / FERIADO
  final lastUpper = tokens.last.toUpperCase();
  if (lastUpper == 'FOLGA' || lastUpper == 'FERIADO') {
    final nomeParts = tokens.sublist(0, tokens.length - 1);
    final nomeTexto = nomeParts.join(' ');
    final colab = mapa[_normalizeNome(nomeTexto)];
    return _LinhaParseada(
      linhaOriginal: linha,
      nomeTexto: nomeTexto,
      data: data,
      colaboradorId: colab?.id,
      nomeEncontrado: colab?.nome,
      observacao: lastUpper == 'FOLGA' ? 'Folga' : 'Feriado',
    );
  }

  // Count trailing time tokens (from right)
  int timeCount = 0;
  for (int i = tokens.length - 1; i >= 0; i--) {
    if (_isTime(tokens[i])) {
      timeCount++;
    } else {
      break;
    }
  }

  final nameEnd = tokens.length - timeCount;
  if (nameEnd <= 0) {
    // All tokens look like times Ã¢â‚¬â€ no name
    return _LinhaParseada(
      linhaOriginal: linha,
      nomeTexto: linha,
      data: data,
      aviso: 'Nome nÃƒÂ£o identificado',
    );
  }

  final nomeParts = tokens.sublist(0, nameEnd);
  final times = tokens.sublist(nameEnd);
  final nomeTexto = nomeParts.join(' ');
  final colab = mapa[_normalizeNome(nomeTexto)];

  String? aviso;
  if (timeCount > 0 && timeCount < 4) {
    aviso = 'Apenas $timeCount horÃƒÂ¡rio(s) encontrado(s)';
  } else if (timeCount == 0) {
    aviso = 'Nenhum horÃƒÂ¡rio encontrado';
  }

  return _LinhaParseada(
    linhaOriginal: linha,
    nomeTexto: nomeTexto,
    data: data,
    colaboradorId: colab?.id,
    nomeEncontrado: colab?.nome,
    entrada: times.isNotEmpty ? times[0] : null,
    intervaloSaida: times.length > 1 ? times[1] : null,
    intervaloRetorno: times.length > 2 ? times[2] : null,
    saida: times.length > 3 ? times[3] : null,
    aviso: aviso,
  );
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Tela principal Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class ImportarEscalaScreen extends StatefulWidget {
  const ImportarEscalaScreen({super.key});

  @override
  State<ImportarEscalaScreen> createState() => _ImportarEscalaScreenState();
}

class _ImportarEscalaScreenState extends State<ImportarEscalaScreen> {
  DateTime _data = DateTime.now();
  final _textController = TextEditingController();
  List<_LinhaParseada>? _linhas;
  bool _importando = false;

  @override
  void dispose() {
    _textController.dispose();
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
      setState(() {
        _data = picked;
        _linhas = null; // reset preview on date change
      });
    }
  }

  void _analisar() {
    final colaboradorProvider = context.read<ColaboradorProvider>();
    final todos = colaboradorProvider.todosColaboradores;

    // Build normalized name Ã¢â€ â€™ Colaborador map
    final mapa = <String, Colaborador>{};
    for (final c in todos) {
      mapa[_normalizeNome(c.nome)] = c;
    }

    final texto = _textController.text;
    final linhasTexto = texto
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final resultado =
        linhasTexto.map((l) => _parseLinha(l, _data, mapa)).toList();

    setState(() => _linhas = resultado);
  }

  Future<void> _importar() async {
    final linhas = _linhas;
    if (linhas == null) return;

    final importaveis = linhas
        .where((l) => l.importavel)
        .map((l) => l.toRegistroPonto())
        .toList();
    if (importaveis.isEmpty) return;

    setState(() => _importando = true);

    final provider = context.read<RegistroPontoProvider>();
    final resultado = await provider.importarBatch(importaveis);

    if (!mounted) return;
    setState(() => _importando = false);

    final ok = resultado['ok'] ?? 0;
    final erro = resultado['erro'] ?? 0;

    AppNotif.show(
      context,
      titulo: erro == 0
          ? 'ImportaÃƒÂ§ÃƒÂ£o ConcluÃƒÂ­da'
          : 'ImportaÃƒÂ§ÃƒÂ£o com Erros',
      mensagem: '$ok registro(s) importado(s).'
          '${erro > 0 ? " $erro falhou." : ""}',
      tipo: erro == 0 ? 'saida' : 'alerta',
      cor: erro == 0 ? AppColors.success : AppColors.danger,
    );

    if (erro == 0) Navigator.of(context).pop(_data);
  }

  @override
  Widget build(BuildContext context) {
    final linhas = _linhas;
    final importaveis = linhas?.where((l) => l.importavel).length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Importar Registros'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ã¢â€â‚¬Ã¢â€â‚¬ Data Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  Text('Data dos registros', style: AppTextStyles.subtitle),
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
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusMD),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: AppColors.primary, size: 20),
                          SizedBox(width: Dimensions.spacingSM),
                          Text(_formatDate(_data), style: AppTextStyles.body),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: Dimensions.spacingLG),

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Texto Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  Text('Cole o texto da escala abaixo',
                      style: AppTextStyles.subtitle),
                  SizedBox(height: Dimensions.spacingSM),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: 10,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: InputDecoration(
                        hintText:
                            'Ex:\nANA VITORIA 08:00 12:00 13:00 17:00\nMARCO AURELIO 09:00 13:00 14:00 18:00\nJOAO FOLGA',
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) {
                        if (_linhas != null) setState(() => _linhas = null);
                      },
                    ),
                  ),

                  SizedBox(height: Dimensions.spacingMD),

                  // Ã¢â€â‚¬Ã¢â€â‚¬ BotÃƒÂ£o Analisar Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _textController.text.trim().isEmpty
                          ? null
                          : _analisar,
                      icon: Icon(Icons.search),
                      label: Text('Analisar Texto'),
                    ),
                  ),

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Preview Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  if (linhas != null) ...[
                    SizedBox(height: Dimensions.spacingLG),
                    Row(
                      children: [
                        Text('PrÃƒÂ©via', style: AppTextStyles.subtitle),
                        const Spacer(),
                        Text(
                          '$importaveis/${linhas.length} encontrados',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimensions.spacingSM),
                    ...linhas.map((l) => _LinhaCard(linha: l)),
                  ],

                  SizedBox(height: 80), // space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: linhas != null && importaveis > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingMD, 8, Dimensions.paddingMD, 12),
                child: ElevatedButton.icon(
                  onPressed: _importando ? null : _importar,
                  icon: _importando
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.upload),
                  label: Text(_importando
                      ? 'Importando...'
                      : 'Importar $importaveis registro(s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    const dias = [
      'Segunda',
      'TerÃƒÂ§a',
      'Quarta',
      'Quinta',
      'Sexta',
      'SÃƒÂ¡bado',
      'Domingo'
    ];
    final diaSemana = dias[date.weekday - 1];
    return '$diaSemana, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Card de prÃƒÂ©via Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _LinhaCard extends StatelessWidget {
  final _LinhaParseada linha;

  const _LinhaCard({required this.linha});

  @override
  Widget build(BuildContext context) {
    final status = linha.status;

    Color borderColor;
    Color iconColor;
    IconData icon;

    switch (status) {
      case _Status.ok:
        borderColor = AppColors.success;
        iconColor = AppColors.success;
        icon = Icons.check_circle_outline;
      case _Status.parcial:
        borderColor = AppColors.statusAtencao;
        iconColor = AppColors.statusAtencao;
        icon = Icons.warning_amber_outlined;
      case _Status.naoEncontrado:
        borderColor = AppColors.danger;
        iconColor = AppColors.danger;
        icon = Icons.person_off_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      padding: const EdgeInsets.all(Dimensions.paddingSM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          SizedBox(width: Dimensions.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  linha.nomeEncontrado ?? linha.nomeTexto,
                  style: AppTextStyles.subtitle.copyWith(
                    color: status == _Status.naoEncontrado
                        ? AppColors.danger
                        : AppColors.textPrimary,
                  ),
                ),
                if (linha.nomeEncontrado != null &&
                    linha.nomeTexto.toUpperCase() !=
                        linha.nomeEncontrado!.toUpperCase())
                  Text(
                    'Texto: ${linha.nomeTexto}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                if (status == _Status.naoEncontrado)
                  Text(
                    'Colaborador nÃƒÂ£o encontrado',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.danger),
                  ),

                SizedBox(height: 4),

                // Times / observacao
                if (linha.observacao != null)
                  _Tag(label: linha.observacao!, color: AppColors.statusFolga)
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (linha.entrada != null)
                        _Tag(
                            label: 'Ã¢â€ â€˜ ${linha.entrada!}',
                            color: AppColors.primary),
                      if (linha.intervaloSaida != null)
                        _Tag(
                            label: 'Ã¢ÂÂ¸ ${linha.intervaloSaida!}',
                            color: AppColors.statusCafe),
                      if (linha.intervaloRetorno != null)
                        _Tag(
                            label: 'Ã¢â€“Â¶ ${linha.intervaloRetorno!}',
                            color: AppColors.statusAtivo),
                      if (linha.saida != null)
                        _Tag(
                            label: 'Ã¢â€ â€œ ${linha.saida!}',
                            color: AppColors.statusSaida),
                    ],
                  ),

                if (linha.aviso != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      linha.aviso!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.statusAtencao),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
