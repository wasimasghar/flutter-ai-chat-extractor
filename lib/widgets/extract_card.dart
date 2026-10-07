import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/extracted_field.dart';

/// Extract mode result: title on top + label/value fields in a grid
/// (2 per row, 3 per row on wide screens) + token counts under the card.
class ExtractCard extends StatelessWidget {
  const ExtractCard({super.key, required this.message});

  final ChatMessage message;

  static const _spacing = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth >= 600 ? 3 : 2;
    final fields = message.fields ?? const <ExtractedField>[];
    final title = (message.title ?? '').trim();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title.isEmpty ? 'Extracted data' : title,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Fields grid (or empty message)
                  if (fields.isEmpty)
                    Text(
                      'No information found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = (constraints.maxWidth -
                                _spacing * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: _spacing,
                          runSpacing: _spacing,
                          children: [
                            for (final field in fields)
                              SizedBox(
                                width: itemWidth,
                                child: _FieldTile(field: field),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            if (message.hasTokenCounts)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  message.tokenLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Label (small grey) with the value (bold) below it.
class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.field});

  final ExtractedField field;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          field.value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
