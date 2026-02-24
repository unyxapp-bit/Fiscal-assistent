import 'package:flutter/material.dart';

enum StatusPresenca {
  confirmado,
  pendente,
  atrasado,
  ausente,
  folga,
}

extension StatusPresencaExtension on StatusPresenca {
  String get nome {
    switch (this) {
      case StatusPresenca.confirmado:
        return 'Confirmado';
      case StatusPresenca.pendente:
        return 'Pendente';
      case StatusPresenca.atrasado:
        return 'Atrasado';
      case StatusPresenca.ausente:
        return 'Ausente';
      case StatusPresenca.folga:
        return 'Folga';
    }
  }

  Color get cor {
    switch (this) {
      case StatusPresenca.confirmado:
        return const Color(0xFF4CAF50); // Green
      case StatusPresenca.pendente:
        return const Color(0xFFFF9800); // Orange
      case StatusPresenca.atrasado:
        return const Color(0xFFFF5722); // Red-Orange
      case StatusPresenca.ausente:
        return const Color(0xFFF44336); // Red
      case StatusPresenca.folga:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  IconData get icone {
    switch (this) {
      case StatusPresenca.confirmado:
        return Icons.check_circle;
      case StatusPresenca.pendente:
        return Icons.pending;
      case StatusPresenca.atrasado:
        return Icons.schedule;
      case StatusPresenca.ausente:
        return Icons.cancel;
      case StatusPresenca.folga:
        return Icons.beach_access;
    }
  }
}
