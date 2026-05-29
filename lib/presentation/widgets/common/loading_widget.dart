import 'package:flutter/material.dart';
import 'operational_widgets.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return OperationalLoadingState(message: message ?? 'Carregando...');
  }
}
