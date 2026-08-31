import 'dart:async';

import 'package:remotecare/features/assistant/data/assistant_stream_client.dart';

/// Test fake for [AssistantStreamClient].
///
/// Set [handler] to return any `Stream<String>` — multi-chunk streams to
/// assert progressive rendering, `Stream.error(...)` to assert error states, or
/// a [StreamController]'s stream to control emission timing manually. Records
/// every call in [requests] for assertions.
class FakeAssistantStreamClient implements AssistantStreamClient {
  Stream<String> Function(String caseId, String message, String intentCategory)?
  handler;

  final List<Map<String, String>> requests = [];

  @override
  Stream<String> streamReply({
    required String caseId,
    required String message,
    required String intentCategory,
    String? locale,
  }) {
    requests.add({
      'caseId': caseId,
      'message': message,
      'intentCategory': intentCategory,
      'locale': ?locale,
    });
    final h = handler;
    if (h != null) return h(caseId, message, intentCategory);
    return const Stream.empty();
  }
}
