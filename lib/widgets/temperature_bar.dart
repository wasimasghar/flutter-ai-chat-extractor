import 'package:flutter/material.dart';

/// Thin bar under the app bar showing the current temperature.
class TemperatureBar extends StatelessWidget {
  const TemperatureBar({super.key, required this.temperature});

  final double temperature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Text(
        'Temp: ${temperature.toStringAsFixed(1)}',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
