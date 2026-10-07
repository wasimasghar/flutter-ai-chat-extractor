import 'package:equatable/equatable.dart';

import 'extracted_field.dart';

enum MessageRole { user, model }

/// text      = normal chat bubble
/// extractCard = label-value pairs pulled from any text (Extract mode)
enum MessageType { text, extractCard }

class ChatMessage extends Equatable {
  final MessageRole role;
  final String text;
  final int? inputTokens;
  final int? outputTokens;
  final int? thinkingTokens;
  final MessageType type;

  /// Extract mode only: document type (e.g. "Electricity Bill") + fields
  final String? title;
  final List<ExtractedField>? fields;

  const ChatMessage({
    required this.role,
    required this.text,
    this.inputTokens,
    this.outputTokens,
    this.thinkingTokens,
    this.type = MessageType.text,
    this.title,
    this.fields,
  });

  bool get isUser => role == MessageRole.user;

  ChatMessage copyWith({
    String? text,
    int? inputTokens,
    int? outputTokens,
    int? thinkingTokens,
  }) {
    return ChatMessage(
      role: role,
      text: text ?? this.text,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      thinkingTokens: thinkingTokens ?? this.thinkingTokens,
      type: type,
      title: title,
      fields: fields,
    );
  }

  bool get hasTokenCounts =>
      inputTokens != null || outputTokens != null || thinkingTokens != null;

  /// e.g. `In: 26 | Out: 354 | Thinking: 1040`
  String get tokenLabel {
    final parts = <String>[];
    if (inputTokens != null) parts.add('In: $inputTokens');
    if (outputTokens != null) parts.add('Out: $outputTokens');
    if (thinkingTokens != null) parts.add('Thinking: $thinkingTokens');
    return parts.join(' | ');
  }

  String get apiRole => role == MessageRole.user ? 'user' : 'model';

  Map<String, dynamic> toApiContent() => {
        'role': apiRole,
        'parts': [
          {'text': text},
        ],
      };

  @override
  List<Object?> get props =>
      [
        role,
        text,
        inputTokens,
        outputTokens,
        thinkingTokens,
        type,
        title,
        fields,
      ];
}
