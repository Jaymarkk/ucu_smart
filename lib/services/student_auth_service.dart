import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'student_api_service.dart';

abstract interface class StudentTokenStore {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> deleteToken();
}

class SecureStudentTokenStore implements StudentTokenStore {
  SecureStudentTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'student_sanctum_access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}

class StudentAuthorizationException implements Exception {
  const StudentAuthorizationException();

  @override
  String toString() => 'This account is not eligible for Student access.';
}

class StudentAuthService extends ChangeNotifier {
  StudentAuthService({
    required StudentApiService api,
    required StudentTokenStore tokenStore,
  })  : _api = api,
        _tokenStore = tokenStore;

  static final StudentAuthService instance = StudentAuthService(
    api: StudentApiService.instance,
    tokenStore: SecureStudentTokenStore(),
  );

  final StudentApiService _api;
  final StudentTokenStore _tokenStore;

  StudentApiService get portalApi => _api;

  StudentProfile? _currentProfile;
  String? _accessToken;

  StudentProfile? get currentProfile => _currentProfile;
  String? get verifiedStudentToken =>
      isStudentAuthenticated ? _accessToken : null;
  bool get isStudentAuthenticated =>
      _accessToken != null &&
      _currentProfile?.role == 'student' &&
      _currentProfile?.status == 'active';

  Future<bool> restoreSession() async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      _clearAuthState();
      return false;
    }

    try {
      final profile = await _api.fetchProfile(token);
      if (!_isEligibleStudent(profile)) {
        await _revokeAndClear(token);
        return false;
      }
      _setAuthenticated(token, profile);
      return true;
    } on StudentApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _tokenStore.deleteToken();
        _clearAuthState();
        return false;
      }
      rethrow;
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await _api.login(username: username, password: password);
    if (!_isEligibleStudent(response.profile)) {
      await _revokeAndClear(response.token);
      throw const StudentAuthorizationException();
    }

    try {
      final verifiedProfile = await _api.fetchProfile(response.token);
      if (!_isEligibleStudent(verifiedProfile)) {
        await _revokeAndClear(response.token);
        throw const StudentAuthorizationException();
      }
      await _tokenStore.writeToken(response.token);
      _setAuthenticated(response.token, verifiedProfile);
    } on StudentApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _revokeAndClear(response.token);
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final token = _accessToken ?? await _tokenStore.readToken();
    try {
      if (token != null && token.isNotEmpty) {
        await _api.logout(token);
      }
    } finally {
      await _tokenStore.deleteToken();
      _clearAuthState();
    }
  }

  bool _isEligibleStudent(StudentProfile profile) =>
      profile.role == 'student' && profile.status == 'active';

  Future<void> _revokeAndClear(String token) async {
    try {
      await _api.logout(token);
    } finally {
      await _tokenStore.deleteToken();
      _clearAuthState();
    }
  }

  void _setAuthenticated(String token, StudentProfile profile) {
    _accessToken = token;
    _currentProfile = profile;
    notifyListeners();
  }

  void _clearAuthState() {
    _accessToken = null;
    _currentProfile = null;
    notifyListeners();
  }
}
