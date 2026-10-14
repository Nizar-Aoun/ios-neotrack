abstract class ProfileRepository {
  /// Get authentication token
  Future<String?> getAuthToken();

  /// Get user profile image URL
  Future<String?> getProfileImageUrl();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
