import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/network/api_service.dart';

/// Thrown when the Assistant streaming endpoint (`POST /ai/chat/stream`)
/// returns a non-200 status or the connection fails mid-stream. The notifier
/// maps any thrown error to an honest, user-facing error state.
class AssistantStreamException implements Exception {
  const AssistantStreamException(this.message);

  final String message;

  @override
  String toString() => 'AssistantStreamException: $message';
}

/// Streams an Assistant reply chunk-by-chunk so the UI can render it
/// progressively instead of waiting for the whole response.
///
/// This is an Assistant-feature-scoped seam (kept separate from the shared
/// [ApiService] so the streaming concern does not leak into every feature).
/// The backend contract is `POST /ai/chat/stream` returning `text/plain`
/// chunks; see `backend/app/routers/ai.py`.
abstract class AssistantStreamClient {
  /// Returns a stream of UTF-8 text chunks for the Assistant's reply.
  ///
  /// [intentCategory] is the client-side pre-classification tag (the backend
  /// enum check is authoritative). The stream yields plain reply text only —
  /// guardrail metadata (`in_scope`/`escalate`) is intentionally NOT carried
  /// here; out-of-scope intents are handled by the notifier via the JSON
  /// `POST /ai/chat` endpoint, which returns that metadata.
  Stream<String> streamReply({
    required String caseId,
    required String message,
    required String intentCategory,
  });
}

/// Production implementation backed by `package:http`'s [http.Client.send],
/// which exposes the response body as a [Stream] for progressive decoding.
class HttpAssistantStreamClient implements AssistantStreamClient {
  HttpAssistantStreamClient(this._api, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final ApiService _api;
  final http.Client _httpClient;

  @override
  Stream<String> streamReply({
    required String caseId,
    required String message,
    required String intentCategory,
  }) async* {
    final token = await _api.getToken();
    final request = http.Request(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/ai/chat/stream'),
    )
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'case_id': caseId,
        'message': message,
        'intent_category': intentCategory,
      });
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final http.StreamedResponse response;
    try {
      response = await _httpClient.send(request);
    } catch (_) {
      throw const AssistantStreamException(
        'Could not reach assistant. Please try again.',
      );
    }

    if (response.statusCode != 200) {
      // Drain the body so the socket can be released, then surface an error.
      await response.stream.drain<void>();
      throw const AssistantStreamException(
        'Could not reach assistant. Please try again.',
      );
    }

    // utf8.decoder is a stateful transformer: it correctly reassembles
    // multi-byte code points that arrive split across chunk boundaries.
    yield* response.stream.transform(utf8.decoder);
  }
}

/// Overridable in tests via `ProviderScope.overrides`.
final assistantStreamClientProvider = Provider<AssistantStreamClient>((ref) {
  return HttpAssistantStreamClient(ref.read(apiServiceProvider));
});
