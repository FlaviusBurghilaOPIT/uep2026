import 'package:http/http.dart' as http;

import '../../domain/entities/agenda_entities.dart';
import '../../domain/repositories/today_repository.dart';
import '../datasources/today_local_datasource.dart';
import '../datasources/today_remote_datasource.dart';

/// Concrete [TodayRepository] over remote and local datasources.
class TodayRepositoryImpl implements TodayRepository {
  final TodayRemoteDatasource _remote;
  final TodayLocalDatasource _local;

  TodayRepositoryImpl({
    required TodayRemoteDatasource remote,
    required TodayLocalDatasource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<http.Response> fetchAgenda({required String date}) =>
      _remote.fetchAgenda(date: date);

  @override
  Future<http.Response> logDose({
    required String scheduledReminderId,
    required String status,
  }) => _remote.logDose(
    scheduledReminderId: scheduledReminderId,
    status: status,
  );

  @override
  Future<http.Response> logAdhocDose({
    required String medicationId,
    required String status,
    String? takenAt,
    required String idempotencyKey,
  }) => _remote.logAdhocDose(
    medicationId: medicationId,
    status: status,
    takenAt: takenAt,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<http.Response> correctDoseLog({
    required String logId,
    required String status,
  }) => _remote.correctDoseLog(logId: logId, status: status);

  @override
  Future<http.Response> fetchCase(String patientId) =>
      _remote.fetchCase(patientId);

  @override
  Future<http.Response> fetchEmergencyContact(String caseId) =>
      _remote.fetchEmergencyContact(caseId);

  @override
  Future<({String? body, DateTime? time})> readCache() async =>
      _local.readCache();

  @override
  Future<void> writeCache(String body, DateTime time) =>
      _local.writeCache(body, time);

  @override
  Future<List<OfflineQueueEntry>> readOfflineQueue() async =>
      _local.readOfflineQueue();

  @override
  Future<void> writeOfflineQueue(List<OfflineQueueEntry> queue) =>
      _local.writeOfflineQueue(queue);
}
