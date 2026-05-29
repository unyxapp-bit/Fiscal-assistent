import 'package:flutter/material.dart';
import 'operational_widgets.dart';

/// Shown when a list has no data.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OperationalEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: buttonLabel,
      onAction: onButtonPressed,
    );
  }
}
