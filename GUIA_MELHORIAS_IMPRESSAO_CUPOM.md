# 🖨️ Guia: Melhorias de Impressão do Cupom

## 📋 Resumo das Mudanças

Você vai transformar a impressão do cupom de **texto puro fraco** para **HTML formatado e profissional** que funciona em qualquer impressora.

**Antes:**
- Texto pequeno e claro
- Sem negrito
- Sem espaçamento adequado
- Impressora não tem controle

**Depois:**
- Títulos grandes e em negrito
- Itens destacados
- Espaçamento profissional
- Funciona em qualquer impressora (Epson, HP, genérica, etc)

---

## 🚀 Passo 1: Criar o arquivo `cupom_print_web.dart`

Locais: `lib/app/modules/fiscal_assistant/features/pizza/presentation/cupom_print_web.dart`

```dart
// cupom_print_web.dart

import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'pizza_models.dart';
import '../../../data/services/cupom_config_service.dart';

/// Imprime cupom com HTML/CSS para qualquer impressora
Future<void> imprimirCupomHtml(
  PedidoPizza pedido,
  CupomDadosConfig config,
) async {
  final html_content = _gerarHtmlCupom(pedido, config);
  _abrirImpressao(html_content);
}

String _gerarHtmlCupom(PedidoPizza pedido, CupomDadosConfig config) {
  final emissao = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
  final data = DateFormat('dd/MM/yyyy').format(pedido.dataPedido);

  // Gera HTML dos itens
  final itensHtml = pedido.itens.map((item) {
    final tamanho = item.tamanhoLabel.toUpperCase();
    if (item.ehMeioAMeio) {
      return '''
        <div class="item-container">
          <div class="item-titulo">${item.quantidade}x Pizza $tamanho (Meio a Meio)</div>
          <div class="item-detalhes">
            <span>1/2 ${item.pizzaNome}</span><br>
            <span>1/2 ${item.pizza2Nome}</span>
          </div>
        </div>
      ''';
    } else {
      return '''
        <div class="item-container">
          <div class="item-titulo">${item.quantidade}x Pizza $tamanho</div>
          <div class="item-detalhes">
            <span>${item.pizzaNome}</span>
          </div>
        </div>
      ''';
    }
  }).join('\n');

  // Observações
  final observacoes = <String>[];
  if (pedido.observacoes != null && pedido.observacoes!.trim().isNotEmpty) {
    observacoes.add(pedido.observacoes!.trim());
  }
  if (config.observacaoPadrao.trim().isNotEmpty) {
    observacoes.add(config.observacaoPadrao.trim());
  }
  final obsHtml = observacoes.isNotEmpty
      ? '<div class="obs-section"><strong>OBSERVAÇÕES:</strong><div class="obs-text">${observacoes.join(' | ')}</div></div>'
      : '';

  // Contatos
  final contatos = <String>[];
  if (config.telefone.isNotEmpty) contatos.add('☎️ ${config.telefone}');
  if (config.whatsapp.isNotEmpty) contatos.add('💬 ${config.whatsapp}');
  if (config.instagram.isNotEmpty) contatos.add('📱 ${config.instagram}');
  if (config.website.isNotEmpty) contatos.add('🌐 ${config.website}');

  final contatosHtml = contatos.isNotEmpty
      ? '<div class="contatos">${contatos.join(' • ')}</div>'
      : '';

  return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Cupom - ${pedido.codigoEntrega}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        @media print {
            body {
                margin: 0;
                padding: 0;
            }
            
            .no-print {
                display: none !important;
            }
            
            .cupom {
                width: 80mm;
                margin: 0 auto;
                page-break-after: always;
            }
        }

        body {
            font-family: 'Courier New', monospace;
            background: white;
            padding: 20px;
        }

        .cupom {
            width: 80mm;
            margin: 0 auto;
            background: white;
            border: 1px solid #ccc;
            padding: 10px;
            line-height: 1.4;
        }

        .header {
            text-align: center;
            border-bottom: 2px solid #000;
            padding-bottom: 8px;
            margin-bottom: 8px;
        }

        .titulo {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 4px;
        }

        .subtitulo {
            font-size: 12px;
            margin-bottom: 2px;
        }

        .info-header {
            font-size: 10px;
            margin: 2px 0;
        }

        .contatos {
            font-size: 11px;
            text-align: center;
            margin: 6px 0;
            line-height: 1.6;
        }

        .divider {
            border-top: 1px solid #000;
            margin: 6px 0;
        }

        .info-pedido {
            font-size: 11px;
            line-height: 1.5;
            margin-bottom: 8px;
        }

        .info-pedido div {
            display: flex;
            justify-content: space-between;
        }

        .info-pedido strong {
            font-weight: bold;
        }

        .destaque-mensagem {
            background: #f0f0f0;
            padding: 6px;
            margin: 6px 0;
            text-align: center;
            font-weight: bold;
            font-size: 12px;
            border: 1px dashed #000;
        }

        .secao-itens {
            margin: 8px 0;
        }

        .titulo-itens {
            font-weight: bold;
            font-size: 12px;
            margin-bottom: 4px;
            border-bottom: 1px solid #000;
        }

        .item-container {
            margin-bottom: 8px;
            padding: 4px 0;
            border-bottom: 1px dotted #ccc;
        }

        .item-titulo {
            font-weight: bold;
            font-size: 11px;
            margin-bottom: 2px;
        }

        .item-detalhes {
            font-size: 10px;
            margin-left: 12px;
            color: #333;
        }

        .obs-section {
            margin: 8px 0;
            font-size: 11px;
        }

        .obs-section strong {
            display: block;
            border-bottom: 1px solid #000;
            padding-bottom: 4px;
            margin-bottom: 4px;
        }

        .obs-text {
            padding: 4px 0;
            line-height: 1.3;
        }

        .footer {
            text-align: center;
            margin-top: 8px;
            padding-top: 8px;
            border-top: 2px solid #000;
            font-weight: bold;
            font-size: 14px;
        }

        .botoes {
            margin-top: 20px;
            display: flex;
            gap: 10px;
            justify-content: center;
        }

        .botoes button {
            padding: 10px 20px;
            font-size: 14px;
            cursor: pointer;
            border: 1px solid #ddd;
            background: white;
            border-radius: 4px;
            font-weight: bold;
        }

        .botoes button:hover {
            background: #f5f5f5;
        }

        .botoes button.primary {
            background: #2196F3;
            color: white;
            border-color: #2196F3;
        }

        .botoes button.primary:hover {
            background: #1976D2;
        }
    </style>
</head>
<body>
    <div class="cupom">
        <!-- CABEÇALHO -->
        <div class="header">
            <div class="titulo">${config.tituloCabecalho.isEmpty ? 'CUPOM' : config.tituloCabecalho}</div>
            ${config.subtituloCabecalho.isNotEmpty ? '<div class="subtitulo">${config.subtituloCabecalho}</div>' : ''}
            ${config.cnpj.isNotEmpty ? '<div class="info-header">CNPJ: ${config.cnpj}</div>' : ''}
            ${config.enderecoLinha1.isNotEmpty ? '<div class="info-header">${config.enderecoLinha1}</div>' : ''}
            ${config.enderecoLinha2.isNotEmpty ? '<div class="info-header">${config.enderecoLinha2}</div>' : ''}
        </div>

        $contatosHtml

        <!-- INFORMAÇÕES DO PEDIDO -->
        <div class="info-pedido">
            <div><strong>Código:</strong> <span>${pedido.codigoEntrega}</span></div>
            <div><strong>Data:</strong> <span>$data</span></div>
            <div><strong>Horário:</strong> <span>${pedido.horarioPedido}</span></div>
            <div><strong>Cliente:</strong> <span>${pedido.nomeCliente}</span></div>
        </div>

        <div class="divider"></div>

        <!-- MENSAGENS DESTAQUE -->
        ${config.mensagemTopo.isNotEmpty ? '<div class="destaque-mensagem">${config.mensagemTopo}</div>' : ''}
        ${config.textoDestaque.isNotEmpty ? '<div class="destaque-mensagem">${config.textoDestaque}</div>' : ''}

        <!-- ITENS -->
        <div class="secao-itens">
            <div class="titulo-itens">ITENS DO PEDIDO</div>
            $itensHtml
        </div>

        <div class="divider"></div>

        <!-- OBSERVAÇÕES -->
        $obsHtml

        <!-- RODAPÉ -->
        <div class="footer">
            ${config.mensagemFinal.isEmpty ? 'BOM APETITE!' : config.mensagemFinal}
        </div>
    </div>

    <div class="botoes no-print">
        <button class="primary" onclick="window.print()">🖨️ Imprimir</button>
        <button onclick="window.close()">✕ Fechar</button>
    </div>

    <script>
        // Descomente para auto-imprimir (abre dialog automaticamente)
        // window.onload = () => setTimeout(() => window.print(), 300);
        
        // Fecha a aba após imprimir (opcional)
        // window.addEventListener('afterprint', () => window.close());
    </script>
</body>
</html>
  ''';
}

void _abrirImpressao(String htmlContent) {
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, 'cupom_impressao');
}
```

---

## 🔧 Passo 2: Atualizar `cupom_widget.dart`

No arquivo `lib/app/modules/fiscal_assistant/features/pizza/presentation/cupom_widget.dart`:

### 2.1 - Atualizar o import

**ANTES:**
```dart
import 'cupom_print_stub.dart' if (dart.library.html) 'cupom_print_web.dart';
```

**DEPOIS:**
```dart
import 'cupom_print_stub.dart' if (dart.library.html) 'cupom_print_web.dart';

// Para usar a nova versão com HTML (opcional, pode importar as duas)
import 'cupom_print_web.dart' as cupom_web;
```

### 2.2 - Atualizar o botão de impressão

**ANTES:**
```dart
if (kIsWeb)
  Expanded(
    child: OutlinedButton.icon(
      icon: const Icon(Icons.print, size: 18),
      label: const Text('Imprimir'),
      onPressed: _loadingConfig ? null : () => imprimirCupom(texto),
    ),
  ),
```

**DEPOIS:**
```dart
if (kIsWeb)
  Expanded(
    child: FilledButton.icon(
      icon: const Icon(Icons.print, size: 18),
      label: const Text('Imprimir'),
      onPressed: _loadingConfig
          ? null
          : () {
              final config = _config ?? CupomDadosConfig.padrao();
              cupom_web.imprimirCupomHtml(widget.pedido, config);
            },
    ),
  ),
```

---

## 🎨 Passo 3: Customizações (Opcional)

### Aumentar tamanho das fontes

No `_gerarHtmlCupom()`, procure por:

```dart
.titulo {
    font-size: 18px;      // Aumenta para 20, 22, etc
    font-weight: bold;
}

.item-titulo {
    font-size: 11px;      // Aumenta para 12, 13, etc
}
```

### Mudar largura do cupom (para impressoras diferentes)

```dart
width: 80mm;  // Padrão para térmicas

// Opções:
// width: 80mm;  ← Térmica padrão (80mm)
// width: 58mm;  ← Térmica pequena
// width: 100mm; ← Impressora de etiqueta
```

### Auto-imprimir automaticamente

Descomente essa linha no `_gerarHtmlCupom()`:

```javascript
// Descomente para auto-imprimir (abre dialog automaticamente)
window.onload = () => setTimeout(() => window.print(), 300);
```

### Fechar aba automaticamente após imprimir

Descomente:

```javascript
// Fecha a aba após imprimir (opcional)
window.addEventListener('afterprint', () => window.close());
```

---

## ✅ Checklist de Implementação

- [ ] Criar arquivo `cupom_print_web.dart` com o código acima
- [ ] Atualizar imports em `cupom_widget.dart`
- [ ] Atualizar botão de impressão
- [ ] Testar impressão em impressora térmica
- [ ] Testar em impressora A4/comum
- [ ] Testar em impressora genérica
- [ ] Ajustar tamanhos de fonte se necessário

---

## 🧪 Como Testar

1. **No app web**, clique em "Imprimir"
2. Abre uma nova aba com preview do cupom
3. Clique em "Imprimir" ou use `Ctrl+P`
4. Escolha a impressora no dialog do navegador
5. Ajuste:
   - Orientação (Retrato)
   - Margens (Nenhuma ou Mínima)
   - Papel (80mm ou custom)

---

## 🐛 Troubleshooting

### "Cupom fica muito pequeno/grande"

Ajuste `width: 80mm` no CSS ou o `font-size` das classes.

### "Não funciona em tal impressora"

Cada driver de impressora é diferente. Teste as configurações de impressão (margens, orientação, escala).

### "Quer auto-imprimir?"

Descomente a linha do `window.print()` no JavaScript.

### "Quer fechar a aba depois?"

Descomente a linha do `window.addEventListener('afterprint')`.

---

## 📱 Comparação: Antes vs Depois

| Aspecto | Antes | Depois |
|---------|-------|--------|
| Tamanho título | Pequeno (12px) | Grande (18px) + negrito |
| Itens | Texto simples | Destaque + indentação |
| Espaçamento | Apertado | Profissional (1.4-1.6 line-height) |
| Contatos | Em linhas | Centralizados com emojis |
| Impressora | Limitado a Epson | Qualquer impressora |
| Controle | Sem | Dialog nativo do SO |

---

## 💡 Dicas Extras

1. **Copiar para WhatsApp**: Mantenha o botão "Copiar" que usa `textoVisual` puro
2. **Teste múltiplas impressoras**: Peça para clientes testarem em suas impressoras
3. **Customize cores/espaçamento**: Edite o CSS sem medo
4. **Adicione logo**: Coloque uma imagem base64 no header
5. **Gere PDF**: Use `window.print()` → "Salvar como PDF"

---

## 🚀 Próximos Passos (Opcional)

- [ ] Adicionar logo da pizzaria no cabeçalho
- [ ] Suporte a múltiplas cópias
- [ ] QR Code do pedido
- [ ] Tempo de entrega estimado em destaque
- [ ] Histórico de cupons impressos
