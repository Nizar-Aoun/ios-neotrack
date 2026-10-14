import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth tokens per the JWT refresh contract.
/// Access token may live in memory/prefs; refresh token stays in secure storage.
class TokenStore {
  TokenStore({
    required SharedPreferences prefs,
    FlutterSecureStorage? secureStorage,
  })  : _prefs = prefs,
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  static const String _accessTokenKey = 'auth_token';
  static const String _userIdKey = 'id';
  static const String _accessExpiresAtKey = 'access_token_expires_at';
  static const String _refreshTokenKey = 'refresh_token';

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  DateTime? _cachedAccessExpiresAt;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _cachedAccessToken = _prefs.getString(_accessTokenKey);
    final expiresMs = _prefs.getInt(_accessExpiresAtKey);
    if (expiresMs != null) {
      _cachedAccessExpiresAt =
          DateTime.fromMillisecondsSinceEpoch(expiresMs, isUtc: true).toLocal();
    }
    _cachedRefreshToken = await _secureStorage.read(key: _refreshTokenKey);
    _initialized = true;
  }

  Future<String?> getAccessToken() async {
    await init();
    return _cachedAccessToken;
  }

  Future<String?> getRefreshToken() async {
    await init();
    return _cachedRefreshToken;
  }

  Future<DateTime?> getAccessExpiresAt() async {
    await init();
    return _cachedAccessExpiresAt;
  }

  Future<String?> getUserId() async {
    return _prefs.getString(_userIdKey);
  }

  bool get hasAccessToken {
    final token = _cachedAccessToken ?? _prefs.getString(_accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<bool> get hasRefreshToken async {
    await init();
    return _cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty;
  }

  /// Saves tokens. Refresh token is optional (some APIs return only a JWT).
  Future<void> saveTokenPair({
    required String accessToken,
    String? refreshToken,
    required int expiresInSeconds,
    String? userId,
  }) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));

    if (refreshToken != null && refreshToken.isNotEmpty) {
      // Persist refresh token first (rotation safety).
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      _cachedRefreshToken = refreshToken;
    } else {
      await _secureStorage.delete(key: _refreshTokenKey);
      _cachedRefreshToken = null;
    }

    _cachedAccessToken = accessToken;
    _cachedAccessExpiresAt = expiresAt;

    final ops = <Future<bool>>[
      _prefs.setString(_accessTokenKey, accessToken),
      _prefs.setInt(_accessExpiresAtKey, expiresAt.millisecondsSinceEpoch),
    ];
    if (userId != null && userId.isNotEmpty) {
      ops.add(_prefs.setString(_userIdKey, userId));
    }
    await Future.wait(ops);
    _initialized = true;
  }

  Future<void> saveUserId(String userId) async {
    await _prefs.setString(_userIdKey, userId);
  }

  Future<void> clear() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedAccessExpiresAt = null;

    await Future.wait([
      _prefs.remove(_accessTokenKey),
      _prefs.remove(_accessExpiresAtKey),
      _prefs.remove(_userIdKey),
      _prefs.remove('user_data'),
      _secureStorage.delete(key: _refreshTokenKey),
    ]);
    _initialized = true;
  }
}
