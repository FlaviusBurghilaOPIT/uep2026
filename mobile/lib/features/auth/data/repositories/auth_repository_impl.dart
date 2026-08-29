import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Concrete [AuthRepository] over [AuthRemoteDatasource] and
/// [AuthLocalDatasource].
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remote;
  final AuthLocalDatasource local;

  AuthRepositoryImpl({
    required this.remote,
    required this.local,
  });

  @override
  Future<AuthState?> fetchProfile() => remote.fetchProfile();

  @override
  Future<({String? caseId, String? primaryCondition, String? physicianName})> fetchCase(
    String patientId,
  ) => remote.fetchCase(patientId);

  @override
  Future<String?> login({required String email, required String password}) =>
      remote.login(email: email, password: password);

  @override
  Future<bool> requestCode({required String email}) =>
      remote.requestCode(email: email);

  @override
  Future<VerifyCodeResult?> verifyCode({
    required String email,
    required String code,
  }) => remote.verifyCode(email: email, code: code);

  @override
  Future<String?> completeOnboarding({
    required String email,
    required String inviteCode,
    String? dateOfBirth,
    String? fullName,
    required String phone,
    String? password,
  }) => remote.completeOnboarding(
    email: email,
    inviteCode: inviteCode,
    dateOfBirth: dateOfBirth,
    fullName: fullName,
    phone: phone,
    password: password,
  );

  @override
  Future<String?> getToken() => remote.getToken();

  @override
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? dateOfBirth,
  }) => remote.updateProfile(
    fullName: fullName,
    phone: phone,
    dateOfBirth: dateOfBirth,
  );

  @override
  Future<String?> changePassword({
    required String newPassword,
    String? currentPassword,
  }) => remote.changePassword(
    newPassword: newPassword,
    currentPassword: currentPassword,
  );

  @override
  Future<void> setToken(String token) => remote.setToken(token);

  @override
  Future<void> clearToken() => remote.clearToken();

  @override
  Future<DemoAuthState> loadDemoAuth() async => local.load();

  @override
  Future<void> saveDemoAuth({
    required bool isFirstTime,
    required bool hasActiveSession,
    String? email,
  }) => local.save(
    isFirstTime: isFirstTime,
    hasActiveSession: hasActiveSession,
    email: email,
  );

  @override
  Future<void> clearDemoAuth() => local.clear();
}
