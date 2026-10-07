import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/home/home_bloc.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/extract_mode_switch.dart';
import '../widgets/temperature_bar.dart';
import 'settings_screen.dart';

/// Only wiring: reads HomeBloc state, passes data to widgets,
/// and sends user actions back to the Bloc as events.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  HomeBloc get _bloc => context.read<HomeBloc>();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: _onStateChanged,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Chat Agent'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear chat',
                onPressed:
                    state.isBusy ? null : () => _bloc.add(const ClearChat()),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: _openSettings,
              ),
            ],
          ),
          body: Column(
            children: [
              TemperatureBar(temperature: state.temperature),
              Expanded(
                child: ChatMessageList(
                  messages: state.messages,
                  showTyping: state.isLoading,
                  controller: _scrollController,
                ),
              ),
              const Divider(height: 1),
              ExtractModeSwitch(
                value: state.isExtractMode,
                onChanged: state.isBusy
                    ? null
                    : (_) => _bloc.add(const ToggleExtractMode()),
              ),
              ChatInputBar(
                controller: _inputController,
                hintText: state.isExtractMode
                    ? 'Paste any text to extract...'
                    : 'Type your message...',
                isLoading: state.isLoading,
                isStreaming: state.isStreaming,
                onSend: _onSend,
                onStop: () => _bloc.add(const StopStreaming()),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- actions ----------------

  void _onSend() {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    _bloc.add(SendMessage(text));
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _bloc,
          child: const SettingsScreen(),
        ),
      ),
    );
  }

  // ---------------- side effects ----------------

  void _onStateChanged(BuildContext context, HomeState state) {
    // Error -> SnackBar
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
    // New message / streamed text -> scroll down
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}
