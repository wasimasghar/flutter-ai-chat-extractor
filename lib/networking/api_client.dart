import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// NETWORK LAYER
/// Only job: send HTTP requests and hand back the result.
/// Anything that goes wrong is turned into an [ApiException].
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 60);

  /// NON-STREAMING: send request, wait for the full body, return decoded JSON.
  Future<Map<String, dynamic>> post(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String> headers = const {},
  }) async {
    // ignore: avoid_print
    print('[REQUEST] ${jsonEncode({'url': url, 'body': body})}');

    // 1. Send request
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json', ...headers},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('Request timed out');
    } catch (e) {
      // ignore: avoid_print
      print('[ERROR] $e');
      // Shows the real reason (e.g. SocketException / permission denied)
      throw ApiException('Network error: $e');
    }

    // 2. Decode JSON
    final json = _decode(response.body);
    // ignore: avoid_print
    print('[RESPONSE] ${response.statusCode} ${json.isEmpty ? response.body : jsonEncode(json)}');

    // 3. Success -> return JSON
    if (_isOk(response.statusCode)) return json;

    // 4. Error -> throw readable message
    throw ApiException(
      _errorMessage(json, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  /// STREAMING: send request and return the raw response byte stream
  /// (the body arrives piece by piece while the server is still writing it).
  ///
  /// Complete [abortTrigger] to cancel the request at any moment. The stream
  /// (or this call, if the response hasn't started yet) then fails with
  /// `http.RequestAbortedException`.
  Future<Stream<List<int>>> postStream(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String> headers = const {},
    Future<void>? abortTrigger,
  }) async {
    // ignore: avoid_print
    print('[REQUEST] ${jsonEncode({'url': url, 'body': body})}');

    final request = http.AbortableRequest(
      'POST',
      Uri.parse(url),
      abortTrigger: abortTrigger,
    )
      ..headers.addAll({'Content-Type': 'application/json', ...headers})
      ..body = jsonEncode(body);

    // 1. Send request, wait only for the status + headers
    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(_timeout);
    } on http.RequestAbortedException {
      rethrow; // Stop pressed before the reply started
    } on TimeoutException {
      throw const ApiException('Request timed out');
    } catch (e) {
      // ignore: avoid_print
      print('[ERROR] $e');
      throw ApiException('Network error: $e');
    }

    // 2. Error -> read the (small) error body and throw
    if (!_isOk(response.statusCode)) {
      final raw = await response.stream.bytesToString();
      // ignore: avoid_print
      print('[RESPONSE] ${response.statusCode} $raw');
      throw ApiException(
        _errorMessage(_decode(raw), response.statusCode),
        statusCode: response.statusCode,
      );
    }

    // 3. Success -> hand the live byte stream to the caller
    // ignore: avoid_print
    print('[RESPONSE] ${response.statusCode} (streaming...)');
    return response.stream;
  }

  bool _isOk(int statusCode) => statusCode >= 200 && statusCode < 300;

  /// Gemini sends errors as { "error": { "message": "..." } }
  String _errorMessage(Map<String, dynamic> json, int statusCode) {
    final error = json['error'];
    return error is Map && error['message'] is String
        ? error['message'] as String
        : 'Request failed ($statusCode)';
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  void close() => _client.close();
}
