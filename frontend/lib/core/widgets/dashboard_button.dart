import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';

/// Reusable icon button to quickly navigate back to the main Citizen Dashboard.
class DashboardButton extends StatelessWidget {
  final Color? color;
  final String tooltip;

  const DashboardButton({
    super.key,
    this.color,
    this.tooltip = 'Go to Dashboard',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.dashboard_rounded),
      color: color ?? AppTheme.primaryBlue,
      tooltip: tooltip,
      onPressed: () => context.go('/dashboard'),
    );
  }
}
