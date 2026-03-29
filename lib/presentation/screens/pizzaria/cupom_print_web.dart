// lib/modules/pizza/cupom_print_web.dart
// Usado apenas no Flutter Web

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void imprimirCupom(String texto) {
  final estilo = '''
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

  final conteudo = texto
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  final janela = html.window.open('', '_blank');
  janela?.document.write('''
    <html>
      <head>
        <meta charset="UTF-8">
        $estilo
      </head>
      <body>$conteudo</body>
    </html>
  ''');
  janela?.document.close();
  janela?.print();
}
