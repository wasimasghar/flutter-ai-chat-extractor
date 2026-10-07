part of 'home_bloc.dart';

/// loading   = waiting for a full (non-streaming) reply
/// streaming = reply is being typed into the last bubble
enum HomeStatus { initial, loading, streaming, success, error }

/// One state class + a status enum. Update it with [copyWith].
class HomeState extends Equatable {
  final HomeStatus status;
  final List<ChatMessage> messages;
  final double temperature;
  final String systemPrompt;
  final String? errorMessage;

  /// true -> Send extracts order details instead of chatting
  final bool isExtractMode;

  const HomeState({
    this.status = HomeStatus.initial,
    this.messages = const [],
    this.temperature = 1.0,
    this.systemPrompt = '',
    this.errorMessage,
    this.isExtractMode = false,
  });

  bool get isLoading => status == HomeStatus.loading;
  bool get isStreaming => status == HomeStatus.streaming;
  bool get isBusy => isLoading || isStreaming;

  /// Note: [errorMessage] is cleared unless you pass it again.
  HomeState copyWith({
    HomeStatus? status,
    List<ChatMessage>? messages,
    double? temperature,
    String? systemPrompt,
    String? errorMessage,
    bool? isExtractMode,
  }) {
    return HomeState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      temperature: temperature ?? this.temperature,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      errorMessage: errorMessage,
      isExtractMode: isExtractMode ?? this.isExtractMode,
    );
  }

  @override
  List<Object?> get props =>
      [status, messages, temperature, systemPrompt, errorMessage, isExtractMode];
}
