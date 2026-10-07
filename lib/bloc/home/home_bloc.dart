import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/chat_message.dart';
import '../../models/stream_event.dart';
import '../../repo/gemini_service.dart';

part 'home_event.dart';
part 'home_state.dart';

/// BLOC LAYER
/// Event -> call repo -> emit new state.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  /// [useStreaming] = true  -> reply is typed live (streamMessage)
  /// [useStreaming] = false -> wait for the full reply (sendMessage)
  HomeBloc(this._repo, {this.useStreaming = true}) : super(const HomeState()) {
    on<SendMessage>(_onSendMessage);
    on<StopStreaming>(_onStopStreaming);
    on<ToggleExtractMode>(_onToggleExtractMode);
    on<ExtractData>(_onExtractData);
    on<UpdateSettings>(_onUpdateSettings);
    on<ClearChat>(_onClearChat);
  }

  final GeminiService _repo;
  final bool useStreaming;

  /// Completing this cancels the running stream request.
  Completer<void>? _stop;

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<HomeState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || state.isBusy) return;

    // Extract mode -> different flow (extract card instead of chat reply)
    if (state.isExtractMode) {
      add(ExtractData(text));
      return;
    }

    final history = [
      ...state.messages,
      ChatMessage(role: MessageRole.user, text: text),
    ];

    if (useStreaming) {
      await _streamReply(history, emit);
    } else {
      await _fetchReply(history, emit);
    }
  }

  /// NON-STREAMING: show loading, wait for the full reply.
  Future<void> _fetchReply(
    List<ChatMessage> history,
    Emitter<HomeState> emit,
  ) async {
    // 1. Show user message + loading
    emit(state.copyWith(status: HomeStatus.loading, messages: history));

    try {
      // 2. Repo -> ApiClient -> Gemini
      final reply = await _repo.sendMessage(
        history: history,
        systemPrompt: state.systemPrompt,
        temperature: state.temperature,
      );

      // 3. Success: add reply
      emit(state.copyWith(
        status: HomeStatus.success,
        messages: [...history, reply],
      ));
    } catch (e) {
      // 4. Error: ApiException.toString() is already the readable message
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// STREAMING: add an empty model bubble and append each chunk to it.
  Future<void> _streamReply(
    List<ChatMessage> history,
    Emitter<HomeState> emit,
  ) async {
    // 1. User message + empty placeholder bubble for the reply
    var reply = const ChatMessage(role: MessageRole.model, text: '');
    emit(state.copyWith(
      status: HomeStatus.streaming,
      messages: [...history, reply],
    ));

    final stop = _stop = Completer<void>();
    try {
      // 2. Repo -> ApiClient -> Gemini (SSE)
      final stream = _repo.streamMessage(
        history: history,
        systemPrompt: state.systemPrompt,
        temperature: state.temperature,
        stopSignal: stop.future,
      );

      await for (final event in stream) {
        switch (event) {
          // 3. Append text -> bubble updates as it is typed
          case StreamText(:final text):
            reply = reply.copyWith(text: reply.text + text);
          // 4. End of stream -> set token counts
          case StreamDone(:final usage):
            reply = reply.copyWith(
              inputTokens: usage?.promptTokenCount,
              outputTokens: usage?.candidatesTokenCount,
              thinkingTokens: usage?.thoughtsTokenCount,
            );
        }
        emit(state.copyWith(messages: [...history, reply]));
      }

      // 5. Finished normally
      emit(state.copyWith(
        status: HomeStatus.success,
        messages: [...history, reply],
      ));
    } catch (e) {
      // Keep the text received so far; drop the bubble if nothing arrived.
      final messages = reply.text.isEmpty ? history : [...history, reply];

      if (stop.isCompleted) {
        // 6a. Stop button -> not an error
        emit(state.copyWith(status: HomeStatus.success, messages: messages));
      } else {
        // 6b. Real error -> SnackBar
        emit(state.copyWith(
          status: HomeStatus.error,
          messages: messages,
          errorMessage: e.toString(),
        ));
      }
    } finally {
      _stop = null;
    }
  }

  /// EXTRACT MODE: user message -> loading -> extract card.
  Future<void> _onExtractData(
    ExtractData event,
    Emitter<HomeState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || state.isBusy) return;

    // 1. Show user message + loading
    final history = [
      ...state.messages,
      ChatMessage(role: MessageRole.user, text: text),
    ];
    emit(state.copyWith(status: HomeStatus.loading, messages: history));

    try {
      // 2. Repo -> ApiClient -> Gemini (JSON mode, only this message)
      final card = await _repo.extractData(text);

      // 3. Success: add the extract card
      emit(state.copyWith(
        status: HomeStatus.success,
        messages: [...history, card],
      ));
    } catch (e) {
      // 4. API or JSON parsing failed -> SnackBar
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onToggleExtractMode(
    ToggleExtractMode event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(isExtractMode: !state.isExtractMode));
  }

  void _onStopStreaming(StopStreaming event, Emitter<HomeState> emit) {
    _cancelStream();
  }

  void _cancelStream() {
    final stop = _stop;
    if (stop != null && !stop.isCompleted) stop.complete();
  }

  void _onUpdateSettings(UpdateSettings event, Emitter<HomeState> emit) {
    final temp = (event.temperature.clamp(0.0, 2.0) * 10).round() / 10;
    emit(state.copyWith(
      temperature: temp,
      systemPrompt: event.systemPrompt,
    ));
  }

  void _onClearChat(ClearChat event, Emitter<HomeState> emit) {
    if (state.isBusy) return; // stop the reply first
    emit(HomeState(
      temperature: state.temperature,
      systemPrompt: state.systemPrompt,
      isExtractMode: state.isExtractMode,
    ));
  }

  @override
  Future<void> close() {
    _cancelStream();
    _repo.dispose();
    return super.close();
  }
}
