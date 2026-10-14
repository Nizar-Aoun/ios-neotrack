import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/core/auth/session_manager.dart';
import 'package:taxi_driver_app/core/auth/token_store.dart';
import 'package:taxi_driver_app/features/auth/data/auth_service.dart';
import 'package:taxi_driver_app/features/auth/domain/user_model.dart';

/// Auth repository with secure refresh-token storage and in-memory caching.
class AuthRepository {
  final AuthService _authService;
  final SharedPreferences _prefs;
  final SessionManager _sessionManager;
  final TokenStore _tokenStore;

  UserModel? _cachedUser;
  bool _cacheInitialized = false;

  static const String _userDataKey = 'user_data';

  AuthRepository({
    required AuthService authService,
    required SharedPreferences prefs,
    SessionManager? sessionManager,
    TokenStore? tokenStore,
  })  : _authService = authService,
        _prefs = prefs,
        _sessionManager = sessionManager ??
            (Get.isRegistered<SessionManager>()
                ? Get.find<SessionManager>()
                : SessionManager(tokenStore: TokenStore(prefs: prefs))),
        _tokenStore = tokenStore ??
            (Get.isRegistered<SessionManager>()
                ? Get.find<SessionManager>().tokenStore
                : TokenStore(prefs: prefs)) {
    _initializeCache();
  }

  void _initializeCache() {
    if (!_cacheInitialized) {
      final userDataString = _prefs.getString(_userDataKey);
      if (userDataString != null) {
        try {
          final userJson =
              Map<String, dynamic>.from(json.decode(userDataString) as Map);
          _cachedUser = UserModel.fromJson(userJson);
        } catch (e) {
          _cachedUser = null;
        }
      }
      _cacheInitialized = true;
    }
  }

  Future<String?> getToken() => _tokenStore.getAccessToken();

  Future<String?> getUserId() => _tokenStore.getUserId();

  Future<UserModel?> getStoredUserData() async {
    try {
      _initializeCache();
      return _cachedUser;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveUserData(UserModel user) async {
    _cachedUser = user;
    _cacheInitialized = true;
    try {
      await _prefs.setString(_userDataKey, json.encode(user.toJson()));
    } catch (_) {}
  }

  Future<void> clearAuthData() async {
    _cachedUser = null;
    await Future.wait([
      _sessionManager.clearSession(),
      _prefs.remove(_userDataKey),
    ]);
  }

  Future<({UserModel user, String token})> login({
    required String phone,
    required String password,
  }) async {
    final response = await _authService.login(
      phone: phone,
      password: password,
    );

    final accessToken =
        (response['access_token'] ?? response['token']) as String?;
    final refreshToken = response['refresh_token'] as String?;
    final userId = response['id'] as String?;
    final expiresInRaw = response['expires_in'];
    final expiresIn = expiresInRaw is int
        ? expiresInRaw
        : int.tryParse('$expiresInRaw') ??
            _expiresInFromJwt(accessToken) ??
            2592000; // 30 days fallback for long-lived JWTs

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token received from server');
    }
    if (userId == null || userId.isEmpty) {
      throw Exception('No user ID received from server');
    }

    await _sessionManager.saveLoginSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresInSeconds: expiresIn,
      userId: userId,
    );

    final userDataResponse = await _authService.getUserData(
      token: accessToken,
      userId: userId,
    );

    final user = UserModel.fromJson(userDataResponse);
    await _saveUserData(user);
    await _tokenStore.saveUserId(user.id);

    return (user: user, token: accessToken);
  }

  Future<void> logout() async {
    try {
      await _sessionManager.logoutRemote();
    } catch (_) {}
    await clearAuthData();
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _tokenStore.getAccessToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    await _authService.updatePassword(
      token: token,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> registerFcmToken(String fcmToken) async {
    try {
      final authToken = await _tokenStore.getAccessToken();
      if (authToken == null) return;

      await _authService.registerFcmToken(
        authToken: authToken,
        fcmToken: fcmToken,
      );
    } catch (_) {}
  }

  Future<void> unregisterFcmToken(String fcmToken) async {
    try {
      final authToken = await _tokenStore.getAccessToken();
      if (authToken == null) return;

      await _authService.unregisterFcmToken(
        authToken: authToken,
        fcmToken: fcmToken,
      );
    } catch (_) {}
  }

  Future<bool> isAuthenticated() async {
    await _tokenStore.init();
    final access = await _tokenStore.getAccessToken();
    final refresh = await _tokenStore.getRefreshToken();
    return (access != null && access.isNotEmpty) ||
        (refresh != null && refresh.isNotEmpty);
  }

  Future<String?> checkPasswordResetIdentifier(String phone) async {
    return _authService.checkPasswordResetIdentifier(phone: phone);
  }

  Future<void> requestPasswordResetOtp({String? phone, String? email}) {
    return _authService.requestPasswordResetOtp(phone: phone, email: email);
  }

  Future<String> verifyPasswordResetOtp({
    String? phone,
    String? email,
    required String otp,
  }) {
    return _authService.verifyPasswordResetOtp(
      phone: phone,
      email: email,
      otp: otp,
    );
  }

  Future<void> resetPassword({
    String? phone,
    String? email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _authService.resetPassword(
      phone: phone,
      email: email,
      resetToken: resetToken,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  void clearCache() {
    _cachedUser = null;
    _cacheInitialized = false;
  }

  /// Derive expires_in (seconds) from a JWT `exp` claim when the API omits it.
  int? _expiresInFromJwt(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload =
          json.decode(utf8.decode(base64Url.decode(normalized))) as Map;
      final exp = payload['exp'];
      if (exp is! int) return null;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final remaining = exp - now;
      return remaining > 0 ? remaining : null;
    } catch (_) {
      return null;
    }
  }
}
