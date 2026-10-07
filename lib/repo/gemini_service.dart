import 'dart:convert';

import '../models/chat_message.dart';
import '../models/gemini_response.dart';
import '../models/extracted_field.dart';
import '../models/stream_event.dart';
import '../networking/api_client.dart';
import '../networking/api_exception.dart';

/// REPOSITORY LAYER
/// Builds the Gemini request, calls [ApiClient], and converts the
/// response into something the Bloc can use directly.
class GeminiService {
  GeminiService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static const _apiKey = String.fromEnvironment('GEMINI_KEY');
  static const _model = 'gemini-3.5-flash-lite';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model';

  /// NON-STREAMING: POST /models/{model}:generateContent
  /// Waits for the whole reply.
  Future<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    String systemPrompt = '',
    double temperature = 1.0,
  }) async {
    // 1. Call API
    final json = await _api.post(
      '$_baseUrl:generateContent',
      headers: _headers,
      body: _body(history, systemPrompt, temperature),
    );

    // 2. Parse response
    final response = GeminiResponse.fromJson(json);
    if (response.text.isEmpty) {
      throw const ApiException('Empty response from Gemini');
    }

    // 3. Return model message
    final usage = response.usageMetadata;
    return ChatMessage(
      role: MessageRole.model,
      text: response.text,
      inputTokens: usage?.promptTokenCount,
      outputTokens: usage?.candidatesTokenCount,
      thinkingTokens: usage?.thoughtsTokenCount,
    );
  }

  /// STREAMING: POST /models/{model}:streamGenerateContent?alt=sse
  /// Same headers + body. Yields [StreamText] for every chunk, then one
  /// [StreamDone] with the token usage from the last chunk.
  ///
  /// Complete [stopSignal] to cancel the request (Stop button).
  Stream<StreamEvent> streamMessage({
    required List<ChatMessage> history,
    String systemPrompt = '',
    double temperature = 1.0,
    Future<void>? stopSignal,
  }) async* {
    // 1. Open the stream
    final bytes = await _api.postStream(
      '$_baseUrl:streamGenerateContent?alt=sse',
      headers: _headers,
      body: _body(history, systemPrompt, temperature),
      abortTrigger: stopSignal,
    );

    // 2. Bytes -> text -> lines. SSE sends each chunk as "data: {json}"
    //    followed by an empty line.
    final lines = bytes.transform(utf8.decoder).transform(const LineSplitter());

    UsageMetadata? usage;
    await for (final line in lines) {
      if (!line.startsWith('data:')) continue; // skip empty separator lines
      final data = line.substring(5).trim();
      if (data.isEmpty) continue;

      // ignore: avoid_print
      print('[STREAM] $data');

      // 3. Each data line is a normal generateContent-style JSON
      final json = jsonDecode(data) as Map<String, dynamic>;
      final error = json['error'];
      if (error is Map) {
        throw ApiException('${error['message'] ?? 'Stream error'}');
      }

      final chunk = GeminiResponse.fromJson(json);
      usage = chunk.usageMetadata ?? usage; // final counts are on the last chunk
      if (chunk.text.isNotEmpty) yield StreamText(chunk.text);
    }

    // 4. Done -> send token usage
    yield StreamDone(usage);
  }

  /// EXTRACT MODE: POST /models/{model}:generateContent (non-streaming)
  /// Works on any text (orders, bills, receipts...). Sends ONLY this message
  /// (no chat history) and asks Gemini for JSON matching [_extractSchema]:
  /// { "title": "...", "fields": [ { "label": "...", "value": "..." } ] }
  /// Returns an extractCard message.
  Future<ChatMessage> extractData(String text) async {
    // 1. Call API
    final json = await _api.post(
      '$_baseUrl:generateContent',
      headers: _headers,
      body: {
        'systemInstruction': {
          'parts': [
            {
              'text': "Extract all important information from the user's "
                  'text as label-value pairs. Use short, clear labels in '
                  'Title Case (e.g. Due Date, Ref ID, Amount). Keep values '
                  'exactly as written. Never invent or guess values. '
                  'If nothing useful is found, return an empty list.',
            },
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': text},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0,
          'thinkingConfig': {'thinkingLevel': 'minimal'},
          'responseMimeType': 'application/json',
          'responseSchema': _extractSchema,
        },
      },
    );

    // 2. The reply text IS the JSON -> parse title + fields
    final response = GeminiResponse.fromJson(json);
    final String title;
    final List<ExtractedField> fields;
    try {
      final data = jsonDecode(response.text) as Map<String, dynamic>;
      title = data['title']?.toString() ?? '';
      fields = (data['fields'] as List<dynamic>? ?? [])
          .map((e) => ExtractedField.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException('Could not read extracted data: $e');
    }

    // 3. Return an extractCard message with token counts.
    //    `text` is a plain summary so chat history never has an empty message.
    final usage = response.usageMetadata;
    return ChatMessage(
      role: MessageRole.model,
      type: MessageType.extractCard,
      title: title,
      fields: fields,
      text: fields.isEmpty
          ? '$title: no information found'
          : '$title: ${fields.map((f) => '${f.label}: ${f.value}').join(', ')}',
      inputTokens: usage?.promptTokenCount,
      outputTokens: usage?.candidatesTokenCount,
      thinkingTokens: usage?.thoughtsTokenCount,
    );
  }

  /// JSON shape Gemini must return in Extract mode.
  static const Map<String, dynamic> _extractSchema = {
    'type': 'OBJECT',
    'properties': {
      'title': {'type': 'STRING'},
      'fields': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'label': {'type': 'STRING'},
            'value': {'type': 'STRING'},
          },
          'required': ['label', 'value'],
          'propertyOrdering': ['label', 'value'],
        },
      },
    },
    'required': ['title', 'fields'],
    'propertyOrdering': ['title', 'fields'],
  };

  // ---------------- shared by the chat methods ----------------

  Map<String, String> get _headers {
    if (_apiKey.isEmpty) {
      throw const ApiException(
        'Missing GEMINI_KEY. Run with --dart-define-from-file=env.json',
      );
    }
    return {'x-goog-api-key': _apiKey};
  }

  Map<String, dynamic> _body(
    List<ChatMessage> history,
    String systemPrompt,
    double temperature,
  ) {
    return {
      if (systemPrompt.trim().isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
      'contents': history.map((m) => m.toApiContent()).toList(),
      'generationConfig': {
        'temperature': temperature,
        'thinkingConfig': {'thinkingLevel': 'minimal'},
      },
    };
  }

  void dispose() => _api.close();
}
