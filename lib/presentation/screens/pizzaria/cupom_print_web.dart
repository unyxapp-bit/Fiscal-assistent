// lib/modules/pizza/cupom_print_web.dart
// Usado apenas no Flutter Web

import 'dart:convert';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
  <body><pre>$conteudoEscapado</pre></body>
</html>
''';

  final url = Uri.dataFromString(
    documento,
    mimeType: 'text/html',
    encoding: utf8,
  ).toString();
  html.window.open(url, '_blank');
}
