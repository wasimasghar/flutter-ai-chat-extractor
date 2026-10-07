import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/home/home_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _systemPromptController;

  static const _presets = [
    (label: 'Precise', value: 0.2),
    (label: 'Balanced', value: 1.0),
    (label: 'Creative', value: 1.5),
  ];

  @override
  void initState() {
    super.initState();
    _systemPromptController = TextEditingController(
      text: context.read<HomeBloc>().state.systemPrompt,
    );
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  void _updateSettings({double? temperature, String? systemPrompt}) {
    final bloc = context.read<HomeBloc>();
    bloc.add(
      UpdateSettings(
        temperature: temperature ?? bloc.state.temperature,
        systemPrompt: systemPrompt ?? _systemPromptController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Config'),
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final temp = state.temperature;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Text(
                    'Temperature',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    temp.toStringAsFixed(1),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: temp,
                min: 0,
                max: 2,
                divisions: 20,
                label: temp.toStringAsFixed(1),
                onChanged: (value) => _updateSettings(temperature: value),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0 (Precise)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '2 (Creative)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Presets',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((preset) {
                  final selected = (temp - preset.value).abs() < 0.05;
                  return ChoiceChip(
                    label: Text('${preset.label} (${preset.value})'),
                    selected: selected,
                    onSelected: (_) =>
                        _updateSettings(temperature: preset.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Text(
                'System prompt',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _systemPromptController,
                minLines: 3,
                maxLines: 8,
                onChanged: (value) => _updateSettings(systemPrompt: value),
                decoration: InputDecoration(
                  hintText: 'Optional instructions for the model…',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Temperature and system prompt are kept in HomeBloc and sent '
                'with every Gemini generateContent request.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
