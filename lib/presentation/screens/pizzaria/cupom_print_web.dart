// lib/modules/pizza/cupom_print_web.dart
// Usado apenas no Flutter Web

import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

void imprimirCupom(String texto) {
  const estilo = '''
    <style>
      @page {
        size: 80mm auto;
        margin: 4mm;
      }
      body {
        font-family: 'Courier New', Courier, monospace;
        font-size: 11px;
        white-space: pre;
        line-height: 1.4;
      }
      pre {
        margin: 0;
      }
    </style>
  ''';

  final conteudoEscapado = const HtmlEscape(HtmlEscapeMode.element).convert(
    texto,
  );
  final documento = '''
    <!doctype html>
    <html>
      <head>
        <meta charset="UTF-8">
        $estilo
      </head>
      <body onload="window.focus(); window.print();">
        <pre>$conteudoEscapado</pre>
      </body>
    </html>
  ''';

  final janela = web.window.open('', '_blank', 'width=420,height=640');
  if (janela == null) return;

  janela.document.open();
  janela.document.write(documento.toJS);
  janela.document.close();
}
