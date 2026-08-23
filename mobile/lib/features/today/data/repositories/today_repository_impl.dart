import 'package:http/http.dart' as http;

import '../../domain/entities/agenda_entities.dart';
import '../../domain/repositories/today_repository.dart';
import '../datasources/today_local_datasource.dart';
import '../datasources/today_remote_datasource.dart';

/// Concrete [TodayRepository] over remote and local datasources.
class TodayRepositoryImpl implements TodayRepository {
  final TodayRemoteDatasource remote;
  final TodayLocalDatasource local;

  TodayRepositoryImpl({
    required this.remote,
    required this.local,
  });

  @override
  Future<http.Response> fetchAgenda({required String date}) =>
      remote.fetchAgenda(date: date);

  @override
  Future<http.Response> logDose({
    required String scheduledReminderId,
    required String status,
  }) => remote.logDose(
    scheduledReminderId: scheduledReminderId,
    status: status,
  );

  @override
  Future<http.Response> logAdhocDose({
    required String medicationId,
    required String status,
    String? takenAt,
    required String idempotencyKey,
  }) => remote.logAdhocDose(
    medicationId: medicationId,
    status: status,
    takenAt: takenAt,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<http.Response> correctDoseLog({
    required String logId,
    required String status,
  }) => remote.correctDoseLog(logId: logId, status: status);

  @override
  Future<http.Response> fetchCase(String patientId) =>
      remote.fetchCase(patientId);

  @override
  Future<http.Response> fetchEmergencyContact(String caseId) =>
      remote.fetchEmergencyContact(caseId);

  @override
  Future<({String? body, DateTime? time})> readCache() async =>
      local.readCache();

  @override
  Future<void> writeCache(String body, DateTime time) =>
      local.writeCache(body, time);

  @override
  Future<List<OfflineQueueEntry>> readOfflineQueue() async =>
      local.readOfflineQueue();

  @override
  Future<void> writeOfflineQueue(List<OfflineQueueEntry> queue) =>
      local.writeOfflineQueue(queue);
}
