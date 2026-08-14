import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// The patient's case subset shown in the Profile "Treatment Plan" section
/// (WI 06 / Req 22): only what `GET /patients/{id}/case` actually exposes.
/// Condition has no backend model field and Clinician has no patient-
/// accessible endpoint, so neither exists here — the section renders honest
/// absence instead (same idiom as the Recovery screen).
class ProfileCaseInfo {
  const ProfileCaseInfo({this.surgeryType, this.surgeryDate});

  final String? surgeryType;
  final DateTime? surgeryDate;
}

/// Loads the signed-in patient's case via the WI 05 `getPatientCase` seam.
/// `null` when there is no patient, no case, or the fetch fails — the
/// section renders honest absence in all of those cases, never a fallback.
final profileCaseProvider = FutureProvider.autoDispose<ProfileCaseInfo?>((
  ref,
) async {
  final patientId = ref.watch(authProvider.select((a) => a.patientId));
  if (patientId == null) return null;
  try {
    final res = await ref
        .watch(apiServiceProvider)
        .getPatientCase(patientId: patientId);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final rawDate = data['surgery_date'] as String?;
    return ProfileCaseInfo(
      surgeryType: data['surgery_type'] as String?,
      surgeryDate: rawDate != null ? DateTime.tryParse(rawDate) : null,
    );
  } catch (_) {
    return null;
  }
});
