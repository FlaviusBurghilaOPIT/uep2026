import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_service.dart';

class TelemetryEvent {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> properties;

  TelemetryEvent({
    required this.name,
    required this.timestamp,
    required this.properties,
  });

  Map<String, dynamic> toJson() => {
        'event_name': name,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'platform': 'mobile',
        'app_version': '1.0.0',
        'properties': properties,
      };
}

class TelemetryService {
  final ApiService? _api;
  final List<TelemetryEvent> events = [];

  TelemetryService([this._api]);

  Future<void> trackEvent(String eventName, Map<String, dynamic> properties) async {
    final event = TelemetryEvent(
      name: eventName,
      timestamp: DateTime.now(),
      properties: properties,
    );
    events.add(event);

    if (_api != null) {
      try {
        await _api.post('/telemetry/events', event.toJson());
      } catch (_) {
        // Silently swallow network errors for telemetry tracking
      }
    }
  }
}

final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  return TelemetryService(ref.read(apiServiceProvider));
});
