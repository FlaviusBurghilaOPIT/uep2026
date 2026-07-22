import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.frequency,
    required this.scheduleTimes,
    required this.duration,
    this.notes,
  });

  final String id;
  final String name;
  final String dose;
  final String frequency; // "QD" | "BID" | "TID" | "QID" | "PRN"
  final List<String> scheduleTimes; // ["08:00", "13:00", "20:00"]
  final String duration;
  final String? notes;

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'] as String,
        name: json['name'] as String,
        dose: json['dose'] as String,
        frequency: (json['frequency'] ?? json['schedule_text'] ?? 'QD') as String,
        scheduleTimes: List<String>.from(json['schedule_times'] as List? ?? []),
        duration: json['duration'] as String,
        notes: json['notes'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Read-only active prescription list for the Medications tab.
class MedicationsNotifier extends AsyncNotifier<List<Medication>> {
  @override
  List<Medication> build() => [];

  ApiService get _api => ref.read(apiServiceProvider);

  /// GET /cases/{caseId}/medications -> full active prescription list.
  Future<void> loadMedications(String caseId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await _api.get('/cases/$caseId/medications');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((m) => Medication.fromJson(m as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load medications (${res.statusCode})');
    });
  }
}

final medicationsNotifierProvider =
    AsyncNotifierProvider<MedicationsNotifier, List<Medication>>(
      MedicationsNotifier.new,
    );
