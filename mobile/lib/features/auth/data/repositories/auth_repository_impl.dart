import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Concrete [AuthRepository] over [AuthRemoteDatasource] and
/// [AuthLocalDatasource].
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final AuthLocalDatasource _local;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remote,
    required AuthLocalDatasource local,
  }) : _remote = remote,
       _local = local;

  @override
  Future<AuthState?> fetchProfile() => _remote.fetchProfile();

  @override
  Future<({String? caseId, String? primaryCondition})> fetchCase(
    String patientId,
  ) => _remote.fetchCase(patientId);

  @override
  Future<String?> login({required String email, required String password}) =>
      _remote.login(email: email, password: password);

  @override
  Future<bool> requestCode({required String email}) =>
      _remote.requestCode(email: email);

  @override
  Future<VerifyCodeResult?> verifyCode({
    required String email,
    required String code,
  }) => _remote.verifyCode(email: email, code: code);

  @override
  Future<String?> completeOnboarding({
    required String email,
    required String inviteCode,
    String? dateOfBirth,
    String? fullName,
    required String phone,
    String? password,
  }) => _remote.completeOnboarding(
    email: email,
    inviteCode: inviteCode,
    dateOfBirth: dateOfBirth,
    fullName: fullName,
    phone: phone,
    password: password,
  );

  @override
  Future<String?> getToken() => _remote.getToken();

  @override
  Future<void> setToken(String token) => _remote.setToken(token);

  @override
  Future<void> clearToken() => _remote.clearToken();

  @override
  Future<DemoAuthState> loadDemoAuth() async => _local.load();

  @override
  Future<void> saveDemoAuth({
    required bool isFirstTime,
    required bool hasActiveSession,
    String? email,
  }) => _local.save(
    isFirstTime: isFirstTime,
    hasActiveSession: hasActiveSession,
    email: email,
  );

  @override
  Future<void> clearDemoAuth() => _local.clear();
}
