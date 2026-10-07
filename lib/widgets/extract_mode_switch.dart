import 'package:flutter/material.dart';

/// "Extract mode" row with a Switch.
class ExtractModeSwitch extends StatelessWidget {
  const ExtractModeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;

  /// null -> Switch is disabled
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text('Extract mode', style: theme.textTheme.labelLarge),
          const Spacer(),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
