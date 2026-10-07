import 'gemini_response.dart';

/// What [GeminiService.streamMessage] sends to the Bloc.
sealed class StreamEvent {
  const StreamEvent();
}

/// A new piece of reply text -> append it to the bubble.
class StreamText extends StreamEvent {
  final String text;

  const StreamText(this.text);
}

/// Stream finished. Token counts come from the last chunk.
class StreamDone extends StreamEvent {
  final UsageMetadata? usage;

  const StreamDone(this.usage);
}
