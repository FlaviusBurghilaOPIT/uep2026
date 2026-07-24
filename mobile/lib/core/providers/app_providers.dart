import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_service.dart';

/// Auth state held in a [ChangeNotifier] so existing screen code
/// (converted to [ConsumerWidget]) can continue calling the same
/// public API (signIn, signOut, verifyInvite, etc.).
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._api) {
    checkAuthStatus();
  }

  final ApiService _api;

  bool _isSignedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? _patientId;
  String? _caseId;
  String? _fullName;
  String? _email;
  String? _phone;
  String? _dateOfBirth;
  String? _primaryCondition;
  String? _inviteCode;

  bool get isSignedIn => _isSignedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get patientId => _patientId;
  String? get caseId => _caseId;
  String? get fullName => _fullName;
  String? get email => _email;
  String? get phone => _phone;
  String? get dateOfBirth => _dateOfBirth;
  String? get primaryCondition => _primaryCondition;
  String? get inviteCode => _inviteCode;

  Future<void> checkAuthStatus() async {
    final token = await _api.getToken();
    if (token != null && token.isNotEmpty) {
      final success = await fetchProfile();
      if (!success) {
        await _api.clearToken();
        _isSignedIn = false;
      }
    }
  }

  Future<bool> fetchProfile() async {
    try {
      final res = await _api.get('/auth/me');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _patientId = data['id'];
        _email = data['email'];
        _fullName = data['full_name'];
        _phone = data['phone'];
        _dateOfBirth = data['date_of_birth'];
        _isSignedIn = true;

        if (_patientId != null) {
          final caseRes = await _api.get('/patients/$_patientId/case');
          if (caseRes.statusCode == 200) {
            final caseData = jsonDecode(caseRes.body);
            _caseId = caseData['id'];
            _primaryCondition = caseData['surgery_type'];
          }
        }
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> requestCode({required String email}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await _api.post('/auth/patient/request-code', {
        'email': email,
      });
      if (res.statusCode == 200) {
        _email = email;
        return true;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['detail'] ?? 'Failed to send code';
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
    return false;
  }

  /// Returns 'onboarding', 'authenticated', or null on failure (see [errorMessage]).
  Future<String?> verifyCode({
    required String email,
    required String code,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await _api.post('/auth/patient/verify-code', {
        'email': email,
        'code': code,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = data['result'] as String;
        if (result == 'authenticated') {
          final token = data['access_token'];
          await _api.setToken(token);
          await fetchProfile();
        } else {
          _email = data['email'];
          _fullName = data['full_name'];
          _inviteCode = code;
        }
        return result;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['detail'] ?? 'Invalid or expired code';
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
    return null;
  }

  Future<bool> completeOnboarding({
    required String email,
    required String inviteCode,
    required String dateOfBirth,
    required String phone,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await _api.post('/auth/complete-onboarding', {
        'email': email,
        'invite_code': inviteCode,
        'date_of_birth': dateOfBirth,
        'phone': phone,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['access_token'];
        await _api.setToken(token);
        await fetchProfile();
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['detail'] ?? 'Failed to complete onboarding';
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
    return false;
  }

  void setSignUpInfo({
    required String fullName,
    required String email,
    required String phone,
  }) {
    _fullName = fullName;
    _email = email;
    _phone = phone;
  }

  Future<void> signOut() async {
    await _api.clearToken();
    _isSignedIn = false;
    _patientId = null;
    _caseId = null;
    _fullName = null;
    _email = null;
    _phone = null;
    _dateOfBirth = null;
    _primaryCondition = null;
    _inviteCode = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

/// Navigation state — tracks the selected bottom-nav tab.
class NavigationNotifier extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setTab(int index, {bool notify = true}) {
    if (index < 0 || index > 4 || _currentIndex == index) return;
    _currentIndex = index;
    if (notify) notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

final navigationProvider = ChangeNotifierProvider<NavigationNotifier>((ref) {
  return NavigationNotifier();
});
