import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isSignedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? _fullName;
  String? _email;
  String? _phone;
  String? _dateOfBirth;
  String? _primaryCondition;

  bool get isSignedIn => _isSignedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get fullName => _fullName;
  String? get email => _email;
  String? get phone => _phone;
  String? get dateOfBirth => _dateOfBirth;
  String? get primaryCondition => _primaryCondition;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _email = email;
      _fullName = 'Sarah Mitchell';
      _isSignedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
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
  }

  Future<bool> verifyCode(String code) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeSetup({
    required String dateOfBirth,
    required String primaryCondition,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _dateOfBirth = dateOfBirth;
      _primaryCondition = primaryCondition;
      _isSignedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _isSignedIn = false;
    _fullName = null;
    _email = null;
    _phone = null;
    _dateOfBirth = null;
    _primaryCondition = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
