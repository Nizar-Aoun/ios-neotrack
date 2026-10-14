class Env {
  static const String _environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const String _devBaseUrl = 'https://dev.track.neotrack.tn';
  static const String _prodBaseUrl = 'https://track.neos.tn';
  static bool get isProd => _environment.toLowerCase() == 'prod';
  static String get baseUrl => isProd ? _prodBaseUrl : _devBaseUrl;
  static String get apiUrl => '$baseUrl/api';
  static String get devurl => '$baseUrl/';
  static String get websocketUrl => baseUrl;
  static String get loginEndpoint => '$apiUrl/login';
  static String get refreshEndpoint => '$apiUrl/refresh';
  static String get logoutEndpoint => '$apiUrl/logout';
  static String get userEndpoint => '$apiUrl/users';
  static String get updateProfileEndpoint => '$apiUrl/users/profile';
  static String get requestProfileChangeOtpEndpoint =>
      '$apiUrl/users/profile/request-change-otp';
  static String get verifyProfileChangeOtpEndpoint =>
      '$apiUrl/users/profile/verify-change-otp';
  static String get getUserCarsEndpoint => '$apiUrl/get-user-cars';
  static String get getCarLocationEndpoint => '$apiUrl/get-car-location';
  static String get remoteStopEndpoint => '$apiUrl/cars/stop';
  static String get remoteStartEndpoint => '$apiUrl/cars/start';
  static String get remoteRestartEndpoint => '$apiUrl/cars/restart';
  static String get carStatusEndpoint => '$apiUrl/cars/status';
  static String get statisticsEndpoint => '$apiUrl/statistics/car';
  static String get deleteRideEndpoint => '$apiUrl/rides';
  static String get carsEndpoint => '$apiUrl/cars';
  static String get carPreferencesEndpoint => '$apiUrl/cars/preferences';
  static String appVersionCheckEndpoint(String version) =>
      '$apiUrl/app-versions/check/$version';
  static const String mapTileUrlTemplate =
      'https://osm.neos.tn/tile/{z}/{x}/{y}.png';

  // Forgot password endpoints
  static String get forgotPasswordCheckIdentifierEndpoint =>
      '$apiUrl/forgot-password/check-identifier';
  static String get forgotPasswordRequestOtpEndpoint =>
      '$apiUrl/forgot-password/request-otp';
  static String get forgotPasswordVerifyOtpEndpoint =>
      '$apiUrl/forgot-password/verify-otp';
  static String get forgotPasswordResetEndpoint =>
      '$apiUrl/forgot-password/reset-password';
}
