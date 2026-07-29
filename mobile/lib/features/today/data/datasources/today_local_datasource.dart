import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/agenda_entities.dart';

/// Local datasource for agenda cache and offline queue persistence.
class TodayLocalDatasource {
  static const _cacheBodyKey = 'today_agenda_cache_body_v1';
  static const _cacheTimeKey = 'today_agenda_cache_time_v1';
  static const _queueKey = 'today_offline_queue_v1';

  final SharedPreferences _prefs;

  TodayLocalDatasource(this._prefs);

  ({String? body, DateTime? time}) readCache() {
    final body = _prefs.getString(_cacheBodyKey);
    final timeStr = _prefs.getString(_cacheTimeKey);
    return (
      body: body,
      time: timeStr != null ? DateTime.tryParse(timeStr) : null,
    );
  }

  Future<void> writeCache(String body, DateTime time) async {
    await _prefs.setString(_cacheBodyKey, body);
    await _prefs.setString(_cacheTimeKey, time.toIso8601String());
  }

  List<OfflineQueueEntry> readOfflineQueue() {
    final raw = _prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => offlineQueueEntryFromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeOfflineQueue(List<OfflineQueueEntry> queue) async {
    await _prefs.setString(
      _queueKey,
      jsonEncode(queue.map(offlineQueueEntryToJson).toList()),
    );
  }
}
