import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
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
  String? _tempPassword;

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
  String? get tempPassword => _tempPassword;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      final success = await fetchProfile();
      if (!success) {
        await ApiService.clearToken();
        _isSignedIn = false;
      }
    }
  }

  Future<bool> fetchProfile() async {
    try {
      final res = await ApiService.get('/auth/me');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _patientId = data['id'];
        _email = data['email'];
        _fullName = data['full_name'];
        _phone = data['phone'];
        _dateOfBirth = data['date_of_birth'];
        _isSignedIn = true;

        if (_patientId != null) {
          final caseRes = await ApiService.get('/patients/$_patientId/case');
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

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['access_token'];
        await ApiService.setToken(token);
        await fetchProfile();
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['detail'] ?? 'Login failed';
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> verifyInvite({
    required String email,
    required String inviteCode,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await ApiService.post('/auth/verify-invite', {
        'email': email,
        'invite_code': inviteCode,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _email = data['email'];
        _fullName = data['full_name'];
        _inviteCode = data['invite_code'];
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['detail'] ?? 'Invalid email or invite code';
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> completeOnboarding({
    required String email,
    required String inviteCode,
    required String password,
    required String dateOfBirth,
    required String phone,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await ApiService.post('/auth/complete-onboarding', {
        'email': email,
        'invite_code': inviteCode,
        'password': password,
        'date_of_birth': dateOfBirth,
        'phone': phone,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['access_token'];
        await ApiService.setToken(token);
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
    required String password,
  }) {
    _fullName = fullName;
    _email = email;
    _phone = phone;
    _tempPassword = password;
  }

  Future<void> signOut() async {
    await ApiService.clearToken();
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
