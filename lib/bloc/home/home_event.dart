part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class SendMessage extends HomeEvent {
  final String text;

  const SendMessage(this.text);

  @override
  List<Object?> get props => [text];
}

class UpdateSettings extends HomeEvent {
  final double temperature;
  final String systemPrompt;

  const UpdateSettings({
    required this.temperature,
    required this.systemPrompt,
  });

  @override
  List<Object?> get props => [temperature, systemPrompt];
}

class ClearChat extends HomeEvent {
  const ClearChat();
}

/// Stop button: cancel the running stream, keep the text received so far.
class StopStreaming extends HomeEvent {
  const StopStreaming();
}

/// Extract mode Switch on/off.
class ToggleExtractMode extends HomeEvent {
  const ToggleExtractMode();
}

/// Extract label-value data from any pasted text.
class ExtractData extends HomeEvent {
  final String text;

  const ExtractData(this.text);

  @override
  List<Object?> get props => [text];
}
