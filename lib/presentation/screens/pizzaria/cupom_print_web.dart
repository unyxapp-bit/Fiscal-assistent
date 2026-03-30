import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _escape = HtmlEscape(HtmlEscapeMode.element);

void imprimirCupom(String texto) {
  final corpoHtml = _renderCupom(texto);
  final normalizedLines = texto.replaceAll('\r\n', '\n').split('\n');
  final ruleChars = normalizedLines
      .map((line) => line.trim())
      .where(
        (line) =>
            line.length >= 16 &&
            (RegExp(r'^=+$').hasMatch(line) ||
                RegExp(r'^-+$').hasMatch(line)),
      )
      .fold<int>(0, (max, line) => line.length > max ? line.length : max);
  final baseChars = ruleChars > 0 ? ruleChars : 32;
  final paperWidthMm = baseChars <= 34 ? 58 : 80;
  final safeCupomWidthMm = paperWidthMm == 58 ? 52 : 72;

  final estilo = '''
    <style>
      @page {
        size: ${paperWidthMm}mm auto;
        margin: 0;
      }

      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        padding: 12px 10px;
        background: #f2f3f5;
        color: #111;
        font-family: Consolas, "Courier New", monospace;
      }

      .cupom {
        width: min(100%, ${safeCupomWidthMm}mm);
        max-width: ${safeCupomWidthMm}mm;
        margin: 0 auto;
        background: #fff;
        border: 1px solid #111;
        border-radius: 6px;
        padding: 10px 10px 12px;
        box-shadow: 0 3px 14px rgba(0, 0, 0, 0.15);
      }

      .line {
        white-space: pre-wrap;
        font-size: 13px;
        line-height: 1.45;
        color: #111;
        font-weight: 600;
      }

      .rule {
        margin: 6px 0;
        border-top: 1px solid #111;
      }

      .rule.thick {
        border-top-width: 2px;
      }

      .section-title {
        margin-top: 6px;
        margin-bottom: 4px;
        font-size: 13px;
        font-weight: 800;
        letter-spacing: .4px;
        text-transform: uppercase;
      }

      .item-title {
        margin-top: 4px;
        font-size: 13px;
        font-weight: 800;
        line-height: 1.35;
      }

      .item-detail {
        white-space: pre-wrap;
        margin-left: 8px;
        font-size: 12.5px;
        color: #1d1d1d;
        line-height: 1.35;
      }

      .meta {
        display: grid;
        grid-template-columns: auto 1fr;
        align-items: baseline;
        gap: 8px;
        font-size: 12.5px;
        line-height: 1.45;
      }

      .meta .k {
        font-weight: 700;
      }

      .meta .v {
        font-weight: 700;
        text-align: right;
        min-width: 0;
        overflow-wrap: anywhere;
      }

      .obs {
        margin: 6px 0;
        padding: 6px;
        border: 1px dashed #666;
        background: #fafafa;
        white-space: pre-wrap;
        font-size: 12.5px;
        line-height: 1.35;
        font-weight: 700;
      }

      .highlight {
        margin: 6px 0;
        padding: 6px 7px;
        border: 1px solid #111;
        background: #111;
        color: #fff;
        font-weight: 900;
        text-align: center;
        white-space: pre-wrap;
        font-size: 12.5px;
      }

      .sp {
        height: 4px;
      }

      .actions {
        display: flex;
        justify-content: center;
        gap: 8px;
        margin-top: 10px;
      }

      .actions button {
        border: 1px solid #d0d0d0;
        background: #fff;
        padding: 8px 14px;
        border-radius: 6px;
        cursor: pointer;
        font-weight: 700;
      }

      .actions button.primary {
        border-color: #0d6efd;
        background: #0d6efd;
        color: #fff;
      }

      @media print {
        @page {
          size: ${paperWidthMm}mm auto;
          margin: 0;
        }

        html,
        body {
          width: ${paperWidthMm}mm;
        }

        body {
          background: #fff;
          padding: 0;
        }

        .cupom {
          width: ${safeCupomWidthMm}mm;
          max-width: ${safeCupomWidthMm}mm;
          border: none;
          border-radius: 0;
          box-shadow: none;
          padding: 0;
        }

        .actions {
          display: none !important;
        }
      }
    </style>
  ''';

  final documento = '''
    <!doctype html>
    <html>
      <head>
        <meta charset="UTF-8">
        $estilo
      </head>
      <body onload="window.focus(); window.print();">
        <div class="cupom">$corpoHtml</div>
        <div class="actions">
          <button class="primary" onclick="window.print()">Imprimir</button>
          <button onclick="window.close()">Fechar</button>
        </div>
      </body>
    </html>
  ''';

  final previewWidthPx = paperWidthMm == 58 ? 360 : 430;
  final janela = web.window.open(
    '',
    '_blank',
    'width=$previewWidthPx,height=760',
  );
  if (janela == null) return;

  janela.document.open();
  janela.document.write(documento.toJS);
  janela.document.close();
}

String _renderCupom(String texto) {
  final lines = texto.replaceAll('\r\n', '\n').split('\n');
  final out = StringBuffer();

  for (final raw in lines) {
    final line = raw.replaceAll('\r', '');
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      out.writeln('<div class="sp"></div>');
      continue;
    }
    if (_isRule(trimmed, '=')) {
      out.writeln('<div class="rule thick"></div>');
      continue;
    }
    if (_isRule(trimmed, '-')) {
      out.writeln('<div class="rule"></div>');
      continue;
    }
    if (trimmed == 'ITENS:') {
      out.writeln('<div class="section-title">Itens do pedido</div>');
      continue;
    }
    if (trimmed.startsWith('>>>') && trimmed.endsWith('<<<')) {
      out.writeln('<div class="highlight">${_escape.convert(trimmed)}</div>');
      continue;
    }
    if (trimmed.startsWith('OBS:')) {
      out.writeln('<div class="obs">${_escape.convert(trimmed)}</div>');
      continue;
    }
    if (_looksLikeMeta(trimmed)) {
      final idx = trimmed.indexOf(':');
      final k = trimmed.substring(0, idx + 1);
      final v = trimmed.substring(idx + 1).trim();
      out.writeln(
        '<div class="meta"><span class="k">${_escape.convert(k)}</span><span class="v">${_escape.convert(v)}</span></div>',
      );
      continue;
    }
    if (_looksLikeItemTitle(trimmed)) {
      out.writeln('<div class="item-title">${_escape.convert(trimmed)}</div>');
      continue;
    }
    if (line.startsWith('   ')) {
      out.writeln('<div class="item-detail">${_escape.convert(trimmed)}</div>');
      continue;
    }

    out.writeln('<div class="line">${_escape.convert(line)}</div>');
  }

  return out.toString();
}

bool _isRule(String line, String char) {
  if (line.length < 16) return false;
  return line.runes.every((r) => r == char.codeUnitAt(0));
}

bool _looksLikeItemTitle(String line) {
  return RegExp(r'^\d+x Pizza\b', caseSensitive: false).hasMatch(line);
}

bool _looksLikeMeta(String line) {
  final keys = [
    'Emissao',
    'Cod. Entrega',
    'Data',
    'Horario',
    'Cliente',
  ];
  return keys.any((k) => line.startsWith(k));
}
