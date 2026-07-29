import 'dart:convert';

import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/auth/presentation/providers/auth_provider.dart';
import 'package:remotecare/core/telemetry/telemetry_service.dart';
import 'package:remotecare/features/today/providers/today_agenda_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_api_service.dart';

Map<String, dynamic> slotJson({
  String slotId = 'rem-1',
  String medicationId = 'med-1',
  String medicationName = 'Ibuprofen',
  String dose = '400 mg',
  String? notes,
  String scheduledTime = '2026-07-26T08:00:00Z',
  String state = 'due',
  String? loggedAt,
  String? doseLogId,
  String? previousStatus,
}) {
  return {
    'slot_id': slotId,
    'medication_id': medicationId,
    'medication_name': medicationName,
    'dose': dose,
    'notes': notes,
    'scheduled_time': scheduledTime,
    'state': state,
    'logged_at': loggedAt,
    'dose_log_id': doseLogId,
    'previous_status': previousStatus,
  };
}

Map<String, dynamic> agendaJson({
  List<Map<String, dynamic>>? slots,
  List<Map<String, dynamic>>? prn,
}) {
  return {
    'date': '2026-07-26',
    'slots': slots ?? [slotJson()],
    'prn': prn ?? [],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiService fakeApi;
  late ProviderContainer container;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeApi = FakeApiService();
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  TodayAgendaNotifier notifier() =>
      container.read(todayAgendaNotifierProvider.notifier);

  AgendaState agendaState() =>
      container.read(todayAgendaNotifierProvider).value!;

  group('loadAgenda', () {
    test(
      'fresh fetch parses server slots and marks sourceState fresh',
      () async {
        fakeApi.agendaHandler = (date) => http.Response(
          jsonEncode(
            agendaJson(
              slots: [
                slotJson(notes: 'with food'),
                slotJson(
                  slotId: 'rem-2',
                  medicationName: 'Metoprolol',
                  dose: '25 mg',
                  scheduledTime: '2026-07-26T20:00:00Z',
                  state: 'upcoming',
                ),
              ],
              prn: [
                {
                  'medication_id': 'med-9',
                  'medication_name': 'Tramadol',
                  'dose': '50 mg',
                  'notes': null,
                },
              ],
            ),
          ),
          200,
        );

        await notifier().loadAgenda();

        final state = agendaState();
        expect(state.sourceState, AgendaSourceState.fresh);
        expect(state.lastSyncedAt, isNotNull);
        expect(state.slots, hasLength(2));
        expect(state.slots[0].slotId, 'rem-1');
        expect(state.slots[0].medicationName, 'Ibuprofen');
        expect(state.slots[0].dose, '400 mg');
        expect(state.slots[0].notes, 'with food');
        expect(state.slots[0].state, SlotState.due);
        expect(
          state.slots[0].scheduledTime,
          DateTime.parse('2026-07-26T08:00:00Z'),
        );
        expect(state.slots[1].state, SlotState.upcoming);
        expect(state.prn, hasLength(1));
        expect(state.prn[0].medicationName, 'Tramadol');
      },
    );

    test('200 with zero slots and zero PRN maps to empty (C9)', () async {
      fakeApi.agendaHandler = (date) =>
          http.Response(jsonEncode(agendaJson(slots: [], prn: [])), 200);

      await notifier().loadAgenda();

      expect(agendaState().sourceState, AgendaSourceState.empty);
      expect(agendaState().slots, isEmpty);
      expect(agendaState().prn, isEmpty);
    });

    test(
      'fetch failure with cache present maps to stale and keeps cached slots',
      () async {
        fakeApi.agendaHandler = (date) =>
            http.Response(jsonEncode(agendaJson()), 200);
        await notifier().loadAgenda();
        expect(agendaState().sourceState, AgendaSourceState.fresh);

        // Simulate a later cold start: fresh state, persisted cache, network down.
        fakeApi.agendaHandler = (date) => throw Exception('socket closed');
        await notifier().loadAgenda();

        final state = agendaState();
        expect(state.sourceState, AgendaSourceState.stale);
        expect(state.slots, hasLength(1));
        expect(state.slots[0].slotId, 'rem-1');
      },
    );

    test(
      'cold start with persisted cache and network down maps to stale',
      () async {
        fakeApi.agendaHandler = (date) =>
            http.Response(jsonEncode(agendaJson()), 200);
        await notifier().loadAgenda();
        container.dispose();

        // App restart: fresh container, same persisted store, network down.
        final restartedApi = FakeApiService()
          ..agendaHandler = (date) => throw Exception('socket closed');
        final restarted = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(restartedApi),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
        );
        addTearDown(restarted.dispose);

        await restarted.read(todayAgendaNotifierProvider.notifier).start();

        final state = restarted.read(todayAgendaNotifierProvider).value!;
        expect(state.sourceState, AgendaSourceState.stale);
        expect(state.slots, hasLength(1));
        expect(state.slots[0].slotId, 'rem-1');
        expect(state.lastSyncedAt, isNotNull);
      },
    );

    test('fetch failure with no cache maps to error', () async {
      fakeApi.agendaHandler = (date) =>
          http.Response(jsonEncode({'detail': 'Server error'}), 500);

      await notifier().loadAgenda();

      final state = agendaState();
      expect(state.sourceState, AgendaSourceState.error);
      expect(state.slots, isEmpty);
      final telemetry = container.read(telemetryServiceProvider);
      final failed = telemetry.events.firstWhere(
        (e) => e.name == 'mobile.today.agenda_failed',
      );
      expect(failed.properties, {'error_class': 'http_500'});
    });
  });

  group('logDose', () {
    Future<AgendaSlot> loadOneSlot() async {
      fakeApi.agendaHandler = (date) =>
          http.Response(jsonEncode(agendaJson()), 200);
      final n = notifier()..undoWindow = const Duration(milliseconds: 40);
      await n.loadAgenda();
      return agendaState().slots.single;
    }

    test(
      'applies optimistic state, commits after undo window, syncs server truth',
      () async {
        fakeApi.adherenceLogHandler = (reminderId, status) => http.Response(
          jsonEncode({
            'id': 'log-1',
            'scheduled_reminder_id': reminderId,
            'status': status,
            'logged_at': '2026-07-26T08:42:00Z',
          }),
          201,
        );

        final slot = await loadOneSlot();
        expect(slot.state, SlotState.due);

        await notifier().logDose(slot, DoseLogStatus.taken);

        // Optimistic: state flips immediately, write marked in flight.
        var state = agendaState();
        expect(state.slots.single.state, SlotState.taken);
        expect(state.writeInFlightSlotIds, contains('rem-1'));
        expect(fakeApi.requestsTo('/adherence/log', method: 'POST'), isEmpty);

        // Undo window elapses → single POST commits.
        await Future<void>.delayed(const Duration(milliseconds: 80));

        state = agendaState();
        final posts = fakeApi.requestsTo('/adherence/log', method: 'POST');
        expect(posts, hasLength(1));
        expect(
          posts.single['path'],
          '/adherence/log?scheduled_reminder_id=rem-1&status=taken',
        );
        expect(state.slots.single.state, SlotState.taken);
        expect(state.slots.single.doseLogId, 'log-1');
        expect(
          state.slots.single.loggedAt,
          DateTime.parse('2026-07-26T08:42:00Z'),
        );
        expect(state.writeInFlightSlotIds, isNot(contains('rem-1')));
      },
    );

    test(
      'double-tap while write in flight is ignored — exactly one write',
      () async {
        fakeApi.adherenceLogHandler = (reminderId, status) =>
            http.Response(jsonEncode({'id': 'log-1'}), 201);

        final slot = await loadOneSlot();
        await notifier().logDose(slot, DoseLogStatus.taken);
        // Second tap during the undo window must not stage another write.
        await notifier().logDose(slot, DoseLogStatus.skipped);

        await Future<void>.delayed(const Duration(milliseconds: 80));

        expect(
          fakeApi.requestsTo('/adherence/log', method: 'POST'),
          hasLength(1),
        );
        expect(agendaState().slots.single.state, SlotState.taken);
      },
    );

    test(
      'undo within the window reverts locally and nothing reaches server',
      () async {
        fakeApi.adherenceLogHandler = (reminderId, status) =>
            http.Response(jsonEncode({'id': 'log-1'}), 201);

        final slot = await loadOneSlot();
        await notifier().logDose(slot, DoseLogStatus.taken);
        expect(agendaState().slots.single.state, SlotState.taken);

        notifier().undoDoseLog('rem-1');

        final state = agendaState();
        expect(state.slots.single.state, SlotState.due);
        expect(state.writeInFlightSlotIds, isNot(contains('rem-1')));

        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(fakeApi.requestsTo('/adherence/log', method: 'POST'), isEmpty);
        expect(
          container.read(telemetryServiceProvider).events.map((e) => e.name),
          contains('mobile.today.dose_log_undone'),
        );
      },
    );

    test(
      '409 reconciles the slot to server truth from the detail body',
      () async {
        fakeApi.adherenceLogHandler = (reminderId, status) => http.Response(
          jsonEncode({
            'detail': {
              'message': 'Dose already logged for this reminder',
              'id': 'log-existing',
              'scheduled_reminder_id': reminderId,
              'status': 'skipped',
              'logged_at': '2026-07-26T08:15:00Z',
            },
          }),
          409,
        );

        final slot = await loadOneSlot();
        await notifier().logDose(slot, DoseLogStatus.taken);
        await Future<void>.delayed(const Duration(milliseconds: 80));

        final state = agendaState();
        expect(state.slots.single.state, SlotState.skipped);
        expect(state.slots.single.doseLogId, 'log-existing');
        expect(
          state.slots.single.loggedAt,
          DateTime.parse('2026-07-26T08:15:00Z'),
        );
        expect(state.rollbackErrorSlotId, isNull);
      },
    );

    test(
      'network failure enqueues a create entry with a uuid idempotency key',
      () async {
        fakeApi.adherenceLogHandler = (reminderId, status) =>
            throw Exception('offline');

        final slot = await loadOneSlot();
        await notifier().logDose(slot, DoseLogStatus.taken);
        await Future<void>.delayed(const Duration(milliseconds: 80));

        final state = agendaState();
        // Optimistic state stays — the log is saved on device.
        expect(state.slots.single.state, SlotState.taken);
        expect(state.writeInFlightSlotIds, isNot(contains('rem-1')));
        expect(state.offlineQueue, hasLength(1));
        final entry = state.offlineQueue.single;
        expect(entry.kind, OfflineQueueKind.create);
        expect(entry.slotId, 'rem-1');
        expect(entry.status, DoseLogStatus.taken);
        expect(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          ).hasMatch(entry.idempotencyKey),
          isTrue,
        );
        expect(state.rollbackErrorSlotId, isNull);
      },
    );

    test('server error after retry rolls back with an error signal', () async {
      var attempts = 0;
      fakeApi.adherenceLogHandler = (reminderId, status) {
        attempts++;
        return http.Response(jsonEncode({'detail': 'boom'}), 500);
      };

      final slot = await loadOneSlot();
      await notifier().logDose(slot, DoseLogStatus.taken);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final state = agendaState();
      expect(attempts, 2, reason: 'one retry before rollback');
      expect(state.slots.single.state, SlotState.due);
      expect(state.rollbackErrorSlotId, 'rem-1');
      expect(state.offlineQueue, isEmpty);
      expect(state.writeInFlightSlotIds, isNot(contains('rem-1')));
      final rolledBack = container
          .read(telemetryServiceProvider)
          .events
          .firstWhere((e) => e.name == 'mobile.today.dose_log_rolled_back');
      expect(rolledBack.properties, {'error_class': 'http_500'});
    });
  });

  group('correctLog', () {
    Future<AgendaSlot> loadLoggedSlot() async {
      fakeApi.agendaHandler = (date) => http.Response(
        jsonEncode(
          agendaJson(
            slots: [
              slotJson(
                state: 'taken',
                loggedAt: '2026-07-26T08:42:00Z',
                doseLogId: 'log-1',
              ),
            ],
          ),
        ),
        200,
      );
      await notifier().loadAgenda();
      return agendaState().slots.single;
    }

    test('PATCH success updates status and preserves previous value', () async {
      fakeApi.correctionHandler = (logId, body) => http.Response(
        jsonEncode({
          'id': logId,
          'scheduled_reminder_id': 'rem-1',
          'status': body['status'],
          'previous_status': 'taken',
          'logged_at': '2026-07-26T08:42:00Z',
          'corrected_at': '2026-07-26T11:30:00Z',
        }),
        200,
      );

      final slot = await loadLoggedSlot();
      await notifier().correctLog(slot, DoseLogStatus.skipped);

      final state = agendaState();
      expect(state.slots.single.state, SlotState.skipped);
      expect(state.slots.single.previousStatus, 'taken');
      expect(state.slots.single.doseLogId, 'log-1');
      final patches = fakeApi.requestsTo('/adherence/logs/', method: 'PATCH');
      expect(patches, hasLength(1));
      expect(patches.single['path'], '/adherence/logs/log-1');
      expect(patches.single['body'], {'status': 'skipped'});
    });

    test(
      'offline correction is queued as kind=correct and syncPending shows',
      () async {
        fakeApi.correctionHandler = (logId, body) => throw Exception('offline');

        final slot = await loadLoggedSlot();
        await notifier().correctLog(slot, DoseLogStatus.skipped);

        final state = agendaState();
        expect(state.offlineQueue, hasLength(1));
        final entry = state.offlineQueue.single;
        expect(entry.kind, OfflineQueueKind.correct);
        expect(entry.doseLogId, 'log-1');
        expect(entry.slotId, 'rem-1');
        expect(entry.status, DoseLogStatus.skipped);
      },
    );
  });

  group('logPrn', () {
    Future<PrnMedication> loadOnePrn() async {
      fakeApi.agendaHandler = (date) => http.Response(
        jsonEncode(
          agendaJson(
            slots: [],
            prn: [
              {
                'medication_id': 'med-9',
                'medication_name': 'Tramadol',
                'dose': '50 mg',
                'notes': null,
              },
            ],
          ),
        ),
        200,
      );
      await notifier().loadAgenda();
      return agendaState().prn.single;
    }

    test('201 appends the returned slot to the agenda', () async {
      fakeApi.adhocLogHandler = (body) => http.Response(
        jsonEncode(
          slotJson(
            slotId: 'rem-adhoc-1',
            medicationId: body['medication_id'] as String,
            medicationName: 'Tramadol',
            dose: '50 mg',
            scheduledTime: '2026-07-26T12:00:00Z',
            state: 'taken',
            loggedAt: '2026-07-26T12:00:00Z',
            doseLogId: 'log-adhoc-1',
          ),
        ),
        201,
      );

      final med = await loadOnePrn();
      await notifier().logPrn(med, DoseLogStatus.taken);

      final state = agendaState();
      expect(state.slots, hasLength(1));
      expect(state.slots.single.slotId, 'rem-adhoc-1');
      expect(state.slots.single.state, SlotState.taken);
      final posts = fakeApi.requestsTo('/adherence/log-adhoc', method: 'POST');
      expect(posts, hasLength(1));
      final body = posts.single['body'] as Map<String, dynamic>;
      expect(body['medication_id'], 'med-9');
      expect(body['status'], 'taken');
      expect(body['idempotency_key'], isNotNull);
      expect(state.writeInFlightPrnIds, isNot(contains('med-9')));
    });

    test(
      'offline ad-hoc queues with the key and retries reuse the same key',
      () async {
        fakeApi.adhocLogHandler = (body) => throw Exception('offline');

        final med = await loadOnePrn();
        await notifier().logPrn(med, DoseLogStatus.taken);

        var state = agendaState();
        expect(state.offlineQueue, hasLength(1));
        final entry = state.offlineQueue.single;
        expect(entry.kind, OfflineQueueKind.adhoc);
        expect(entry.medicationId, 'med-9');

        // Connectivity returns — flush retries with the SAME idempotency key.
        fakeApi.adhocLogHandler = (body) => http.Response(
          jsonEncode(
            slotJson(
              slotId: 'rem-adhoc-1',
              medicationId: 'med-9',
              medicationName: 'Tramadol',
              dose: '50 mg',
              state: 'taken',
              doseLogId: 'log-adhoc-1',
            ),
          ),
          201,
        );
        await notifier().flushOfflineQueue();

        state = agendaState();
        expect(state.offlineQueue, isEmpty);
        final posts = fakeApi.requestsTo(
          '/adherence/log-adhoc',
          method: 'POST',
        );
        expect(posts, hasLength(2));
        expect(
          (posts[0]['body'] as Map)['idempotency_key'],
          (posts[1]['body'] as Map)['idempotency_key'],
        );
        expect(
          (posts[1]['body'] as Map)['idempotency_key'],
          entry.idempotencyKey,
        );
      },
    );
  });

  group('offline queue flush', () {
    test('flush order: creates before corrections', () async {
      // Agenda with two slots; slot rem-2 already logged (correctable).
      fakeApi.agendaHandler = (date) => http.Response(
        jsonEncode(
          agendaJson(
            slots: [
              slotJson(),
              slotJson(
                slotId: 'rem-2',
                state: 'taken',
                doseLogId: 'log-2',
                loggedAt: '2026-07-26T09:00:00Z',
              ),
            ],
          ),
        ),
        200,
      );
      final n = notifier()..undoWindow = const Duration(milliseconds: 20);
      await n.loadAgenda();
      final slots = agendaState().slots;

      // Go offline: queue a correction FIRST, then a create.
      fakeApi.correctionHandler = (logId, body) => throw Exception('offline');
      await n.correctLog(slots[1], DoseLogStatus.skipped);
      fakeApi.adherenceLogHandler = (id, status) => throw Exception('offline');
      await n.logDose(slots[0], DoseLogStatus.taken);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(agendaState().offlineQueue, hasLength(2));
      expect(agendaState().offlineQueue.map((e) => e.kind), [
        OfflineQueueKind.correct,
        OfflineQueueKind.create,
      ]);

      // Back online — record the order requests hit the server.
      fakeApi.adherenceLogHandler = (id, status) =>
          http.Response(jsonEncode({'id': 'log-new'}), 201);
      fakeApi.correctionHandler = (logId, body) => http.Response(
        jsonEncode({'id': logId, 'status': body['status']}),
        200,
      );
      fakeApi.requestsLog.clear(); // ignore the failed offline attempts
      await n.flushOfflineQueue();

      expect(agendaState().offlineQueue, isEmpty);
      final writes = fakeApi.requestsLog
          .where(
            (r) =>
                (r['path'] as String).startsWith('/adherence/log') &&
                r['method'] != 'GET',
          )
          .toList();
      expect(writes, hasLength(2));
      expect(writes[0]['method'], 'POST', reason: 'create flushes first');
      expect(writes[1]['method'], 'PATCH', reason: 'correction flushes last');
    });

    test(
      'queue survives an app kill: fresh notifier flushes persisted entries',
      () async {
        fakeApi.agendaHandler = (date) =>
            http.Response(jsonEncode(agendaJson()), 200);
        final n = notifier()..undoWindow = const Duration(milliseconds: 20);
        await n.loadAgenda();
        final slot = agendaState().slots.single;

        fakeApi.adherenceLogHandler = (id, status) =>
            throw Exception('offline');
        await n.logDose(slot, DoseLogStatus.taken);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(agendaState().offlineQueue, hasLength(1));
        container.dispose();

        // App relaunch: fresh container, same persisted store, back online.
        final relaunchedApi = FakeApiService();
        relaunchedApi.agendaHandler = (date) =>
            http.Response(jsonEncode(agendaJson()), 200);
        relaunchedApi.adherenceLogHandler = (id, status) =>
            http.Response(jsonEncode({'id': 'log-1'}), 201);
        final relaunched = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(relaunchedApi),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
        );
        addTearDown(relaunched.dispose);

        await relaunched.read(todayAgendaNotifierProvider.notifier).start();

        final state = relaunched.read(todayAgendaNotifierProvider).value!;
        expect(state.offlineQueue, isEmpty);
        expect(
          relaunchedApi.requestsTo('/adherence/log', method: 'POST'),
          hasLength(1),
        );
      },
    );

    test('per-entry 409 during flush reconciles instead of erroring', () async {
      fakeApi.agendaHandler = (date) =>
          http.Response(jsonEncode(agendaJson()), 200);
      final n = notifier()..undoWindow = const Duration(milliseconds: 20);
      await n.loadAgenda();
      final slot = agendaState().slots.single;

      fakeApi.adherenceLogHandler = (id, status) => throw Exception('offline');
      await n.logDose(slot, DoseLogStatus.taken);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(agendaState().offlineQueue, hasLength(1));

      // Server says another device already logged this slot as skipped.
      fakeApi.adherenceLogHandler = (id, status) => http.Response(
        jsonEncode({
          'detail': {
            'id': 'log-other-device',
            'scheduled_reminder_id': id,
            'status': 'skipped',
            'logged_at': '2026-07-26T08:05:00Z',
          },
        }),
        409,
      );
      await n.flushOfflineQueue();

      final state = agendaState();
      expect(state.offlineQueue, isEmpty);
      expect(state.slots.single.state, SlotState.skipped);
      expect(state.slots.single.doseLogId, 'log-other-device');
      expect(state.rollbackErrorSlotId, isNull);
    });
  });

  group('measurement events', () {
    test(
      'agenda + write events fire with spec §5 properties (no PHI)',
      () async {
        fakeApi.agendaHandler = (date) => http.Response(
          jsonEncode(
            agendaJson(
              prn: [
                {
                  'medication_id': 'med-9',
                  'medication_name': 'Tramadol',
                  'dose': '50 mg',
                  'notes': null,
                },
              ],
            ),
          ),
          200,
        );
        fakeApi.adherenceLogHandler = (id, status) => http.Response(
          jsonEncode({'id': 'log-1', 'logged_at': '2026-07-26T08:42:00Z'}),
          201,
        );

        final n = notifier()..undoWindow = const Duration(milliseconds: 20);
        await n.loadAgenda();
        final slot = agendaState().slots.single;
        await n.logDose(slot, DoseLogStatus.taken);
        await Future<void>.delayed(const Duration(milliseconds: 60));

        final telemetry = container.read(telemetryServiceProvider);
        final names = telemetry.events.map((e) => e.name).toList();
        expect(names, contains('mobile.today.agenda_viewed'));
        expect(names, contains('mobile.today.dose_log_tapped'));
        expect(names, contains('mobile.today.dose_log_committed'));

        final viewed = telemetry.events.firstWhere(
          (e) => e.name == 'mobile.today.agenda_viewed',
        );
        expect(viewed.properties, {
          'slot_count': 1,
          'has_prn': true,
          'stale': false,
        });
        final tapped = telemetry.events.firstWhere(
          (e) => e.name == 'mobile.today.dose_log_tapped',
        );
        expect(tapped.properties, {
          'slot_state_before': 'due',
          'action': 'taken',
        });
        final committed = telemetry.events.firstWhere(
          (e) => e.name == 'mobile.today.dose_log_committed',
        );
        expect(committed.properties, {'status': 'taken', 'was_offline': false});
      },
    );
  });

  group('C8 side-effect prompt', () {
    Future<AgendaSlot> commitSkipped() async {
      fakeApi.agendaHandler = (date) =>
          http.Response(jsonEncode(agendaJson()), 200);
      fakeApi.adherenceLogHandler = (id, status) => http.Response(
        jsonEncode({'id': 'log-1', 'logged_at': '2026-07-26T08:42:00Z'}),
        201,
      );
      final n = notifier()..undoWindow = const Duration(milliseconds: 20);
      await n.loadAgenda();
      final slot = agendaState().slots.single;
      await n.logDose(slot, DoseLogStatus.skipped);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      return agendaState().slots.single;
    }

    void seedAuthWithCase() {
      fakeApi.savedToken = 'tok';
      fakeApi.getHandlers['/auth/me'] = () => http.Response(
        jsonEncode({'id': 'p1', 'email': 'p@x.io', 'full_name': 'Pat'}),
        200,
      );
      fakeApi.getHandlers['/patients/p1/case'] = () =>
          http.Response(jsonEncode({'id': 'case-1'}), 200);
    }

    test('skipped commit raises the C8 prompt', () async {
      await commitSkipped();
      expect(agendaState().c8PromptSlotId, 'rem-1');
      notifier().dismissC8Prompt();
      expect(agendaState().c8PromptSlotId, isNull);
    });

    test(
      'answer yes → telemetry + emergency phone from the case endpoint',
      () async {
        seedAuthWithCase();
        fakeApi.getHandlers['/cases/case-1/emergency-contact'] = () =>
            http.Response(
              jsonEncode({'name': 'Dr. Connor', 'phone': '+1 555-0122'}),
              200,
            );
        await container.read(authProvider.notifier).fetchProfile();

        await commitSkipped();
        final phone = await notifier().answerC8Prompt(severeSymptoms: true);

        expect(phone, '+1 555-0122');
        final names = container
            .read(telemetryServiceProvider)
            .events
            .map((e) => e.name);
        expect(names, contains('mobile.today.skip_sideeffect_yes'));
      },
    );

    test(
      'answer yes with no contact on file → null (no-contact branch)',
      () async {
        seedAuthWithCase();
        fakeApi.getHandlers['/cases/case-1/emergency-contact'] = () =>
            http.Response(jsonEncode({'name': null, 'phone': null}), 200);
        await container.read(authProvider.notifier).fetchProfile();

        await commitSkipped();
        final phone = await notifier().answerC8Prompt(severeSymptoms: true);

        expect(phone, isNull);
      },
    );

    test('answer no → telemetry, silent completion', () async {
      await commitSkipped();
      final phone = await notifier().answerC8Prompt(severeSymptoms: false);

      expect(phone, isNull);
      final names = container
          .read(telemetryServiceProvider)
          .events
          .map((e) => e.name);
      expect(names, contains('mobile.today.skip_sideeffect_no'));
      expect(agendaState().c8PromptSlotId, isNull);
    });
  });
}
