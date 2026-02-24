import 'package:flutter/material.dart';

enum TipoLembrete {
  anotacao,
  tarefa,
  lembrete,
}

extension TipoLembreteExtension on TipoLembrete {
  String get nome {
    switch (this) {
      case TipoLembrete.anotacao:
        return 'Anotação';
      case TipoLembrete.tarefa:
        return 'Tarefa';
      case TipoLembrete.lembrete:
        return 'Lembrete';
    }
  }

  Color get cor {
    switch (this) {
      case TipoLembrete.anotacao:
        return const Color(0xFF2196F3); // Blue
      case TipoLembrete.tarefa:
        return const Color(0xFF4CAF50); // Green
      case TipoLembrete.lembrete:
        return const Color(0xFFFF9800); // Orange
    }
  }

  IconData get icone {
    switch (this) {
      case TipoLembrete.anotacao:
        return Icons.note;
      case TipoLembrete.tarefa:
        return Icons.check_box;
      case TipoLembrete.lembrete:
        return Icons.notifications;
    }
  }
}
