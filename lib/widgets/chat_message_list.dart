import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import 'chat_empty_view.dart';
import 'extract_card.dart';
import 'message_bubble.dart';
import 'typing_indicator.dart';

/// The list of messages. Picks the right widget for each message type.
class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.messages,
    required this.showTyping,
    this.controller,
  });

  final List<ChatMessage> messages;

  /// true -> show the typing dots at the bottom
  final bool showTyping;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty && !showTyping) return const ChatEmptyView();

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: messages.length + (showTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) return const TypingIndicator();

        final message = messages[index];
        return switch (message.type) {
          MessageType.text => MessageBubble(message: message),
          MessageType.extractCard => ExtractCard(message: message),
        };
      },
    );
  }
}
