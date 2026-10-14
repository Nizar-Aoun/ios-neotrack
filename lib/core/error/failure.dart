/// Common Failure hierarchy for error handling across the application.
///
/// This provides a type-safe way to handle errors and failures in the domain layer.
/// All failures should extend from [Failure] to maintain consistency.

/// Base class for all failures in the application
abstract class Failure {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() =>
      'Failure: $message ${code != null ? "(Code: $code)" : ""}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.message == message &&
        other.code == code &&
        other.originalError == originalError;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode ^ originalError.hashCode;
}

/// Base class for all network-related failures
abstract class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Failure when there is no internet connection
class NoInternetConnectionFailure extends NetworkFailure {
  const NoInternetConnectionFailure()
      : super(
          'No internet connection. Please check your network settings.',
          code: 'NO_INTERNET',
        );
}

/// Failure when the request times out
class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure()
      : super(
          'Connection timed out. Please try again.',
          code: 'TIMEOUT',
        );
}

/// Failure when the server is unreachable
class ServerUnreachableFailure extends NetworkFailure {
  const ServerUnreachableFailure()
      : super(
          'Unable to reach the server. Please try again later.',
          code: 'SERVER_UNREACHABLE',
        );
}

/// Failure when the server returns an error
class ServerFailure extends NetworkFailure {
  const ServerFailure({
    String message = 'Server error occurred. Please try again.',
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);
}

/// Failure when the response from server is invalid or cannot be parsed
class InvalidResponseFailure extends NetworkFailure {
  const InvalidResponseFailure()
      : super(
          'Invalid response from server. Please try again.',
          code: 'INVALID_RESPONSE',
        );
}

/// Failure when API request is malformed (400)
class BadRequestFailure extends NetworkFailure {
  const BadRequestFailure({
    String message = 'Bad request. Please check your input.',
    String? code,
  }) : super(message, code: code ?? 'BAD_REQUEST');
}

/// Failure when user is not authorized (401)
class UnauthorizedFailure extends NetworkFailure {
  const UnauthorizedFailure({
    String message = 'Unauthorized. Please login again.',
  }) : super(message, code: 'UNAUTHORIZED');
}

/// Failure when user doesn't have permission (403)
class ForbiddenFailure extends NetworkFailure {
  const ForbiddenFailure({
    String message = 'You do not have permission to perform this action.',
  }) : super(message, code: 'FORBIDDEN');
}

/// Failure when the user's subscription is not paid / inactive.
///
/// The backend access middleware returns `{ "status": false, "error": "..." }`
/// on protected endpoints when the account has no active (paid) subscription.
class SubscriptionRequiredFailure extends NetworkFailure {
  const SubscriptionRequiredFailure({
    String message = 'Your subscription is not active. Please pay your subscription to continue.',
  }) : super(message, code: 'SUBSCRIPTION_REQUIRED');
}

/// Failure when the requested resource is not found (404)
class NotFoundFailure extends NetworkFailure {
  const NotFoundFailure({
    String message = 'Requested resource not found.',
  }) : super(message, code: 'NOT_FOUND');
}

/// Failure when too many requests are made (429)
class TooManyRequestsFailure extends NetworkFailure {
  const TooManyRequestsFailure()
      : super(
          'Too many requests. Please try again later.',
          code: 'TOO_MANY_REQUESTS',
        );
}

// ============================================================================
// Authentication Failures
// ============================================================================

/// Base class for authentication-related failures
abstract class AuthFailure extends Failure {
  const AuthFailure(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Failure when login credentials are invalid
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure()
      : super(
          'Invalid phone number or password.',
          code: 'INVALID_CREDENTIALS',
        );
}

/// Failure when the session has expired
class SessionExpiredFailure extends AuthFailure {
  const SessionExpiredFailure()
      : super(
          'Your session has expired. Please login again.',
          code: 'SESSION_EXPIRED',
        );
}

/// Failure when the token is invalid or missing
class InvalidTokenFailure extends AuthFailure {
  const InvalidTokenFailure()
      : super(
          'Invalid or missing authentication token.',
          code: 'INVALID_TOKEN',
        );
}

/// Failure when user account is not found
class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure()
      : super(
          'User account not found.',
          code: 'USER_NOT_FOUND',
        );
}

/// Failure when password does not meet requirements
class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure({
    String message = 'Password does not meet requirements.',
  }) : super(message, code: 'WEAK_PASSWORD');
}

/// Failure when the current password is incorrect
class IncorrectPasswordFailure extends AuthFailure {
  const IncorrectPasswordFailure()
      : super(
          'Current password is incorrect.',
          code: 'INCORRECT_PASSWORD',
        );
}

// ============================================================================
// Data Failures
// ============================================================================

/// Base class for data-related failures
abstract class DataFailure extends Failure {
  const DataFailure(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Failure when local cache/storage operations fail
class CacheFailure extends DataFailure {
  const CacheFailure({
    String message = 'Failed to access local storage.',
    dynamic originalError,
  }) : super(message, code: 'CACHE_ERROR', originalError: originalError);
}

/// Failure when data parsing/serialization fails
class ParseFailure extends DataFailure {
  const ParseFailure({
    String message = 'Failed to parse data.',
    dynamic originalError,
  }) : super(message, code: 'PARSE_ERROR', originalError: originalError);
}

/// Failure when required data is not found locally
class DataNotFoundFailure extends DataFailure {
  const DataNotFoundFailure({
    String message = 'Requested data not found.',
  }) : super(message, code: 'DATA_NOT_FOUND');
}

/// Failure when data validation fails
class ValidationFailure extends DataFailure {
  const ValidationFailure({
    String message = 'Data validation failed.',
  }) : super(message, code: 'VALIDATION_ERROR');
}

/// Failure when database operations fail
class DatabaseFailure extends DataFailure {
  const DatabaseFailure({
    String message = 'Database operation failed.',
    dynamic originalError,
  }) : super(message, code: 'DATABASE_ERROR', originalError: originalError);
}

// ============================================================================
// Location/GPS Failures
// ============================================================================

/// Base class for location-related failures
abstract class LocationFailure extends Failure {
  const LocationFailure(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Failure when location permission is denied
class LocationPermissionDeniedFailure extends LocationFailure {
  const LocationPermissionDeniedFailure()
      : super(
          'Location permission denied. Please enable location permissions.',
          code: 'LOCATION_PERMISSION_DENIED',
        );
}

/// Failure when location services are disabled
class LocationServiceDisabledFailure extends LocationFailure {
  const LocationServiceDisabledFailure()
      : super(
          'Location services are disabled. Please enable location services.',
          code: 'LOCATION_SERVICE_DISABLED',
        );
}

/// Failure when unable to get current location
class UnableToGetLocationFailure extends LocationFailure {
  const UnableToGetLocationFailure({
    String message = 'Unable to get your current location.',
    dynamic originalError,
  }) : super(message, code: 'LOCATION_ERROR', originalError: originalError);
}

// ============================================================================
// Permission Failures
// ============================================================================

/// Failure when a required permission is not granted
class PermissionDeniedFailure extends Failure {
  final String permission;

  const PermissionDeniedFailure({
    required this.permission,
    String? message,
  }) : super(
          message ?? 'Permission denied: $permission',
          code: 'PERMISSION_DENIED',
        );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PermissionDeniedFailure &&
        other.message == message &&
        other.code == code &&
        other.permission == permission;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode ^ permission.hashCode;
}

/// Failure when a permission is permanently denied
class PermissionPermanentlyDeniedFailure extends Failure {
  final String permission;

  const PermissionPermanentlyDeniedFailure({
    required this.permission,
  }) : super(
          'Permission permanently denied: $permission. Please enable it in settings.',
          code: 'PERMISSION_PERMANENTLY_DENIED',
        );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PermissionPermanentlyDeniedFailure &&
        other.message == message &&
        other.code == code &&
        other.permission == permission;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode ^ permission.hashCode;
}

// ============================================================================
// Feature-Specific Failures
// ============================================================================

/// Failure when car/vehicle operations fail
class CarOperationFailure extends Failure {
  const CarOperationFailure({
    String message = 'Car operation failed.',
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);
}

/// Failure when ride operations fail
class RideOperationFailure extends Failure {
  const RideOperationFailure({
    String message = 'Ride operation failed.',
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);
}

/// Failure when expense operations fail
class ExpenseOperationFailure extends Failure {
  const ExpenseOperationFailure({
    String message = 'Expense operation failed.',
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);
}

/// Failure when notification operations fail
class NotificationFailure extends Failure {
  const NotificationFailure({
    String message = 'Notification operation failed.',
    dynamic originalError,
  }) : super(message, code: 'NOTIFICATION_ERROR', originalError: originalError);
}

/// Failure when FCM/push notification operations fail
class PushNotificationFailure extends Failure {
  const PushNotificationFailure({
    String message = 'Push notification operation failed.',
    dynamic originalError,
  }) : super(message,
            code: 'PUSH_NOTIFICATION_ERROR', originalError: originalError);
}

/// Failure when file operations fail (upload, download, etc.)
class FileOperationFailure extends Failure {
  const FileOperationFailure({
    String message = 'File operation failed.',
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);
}

// ============================================================================
// Generic/Unknown Failures
// ============================================================================

/// Generic failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    String message = 'An unexpected error occurred. Please try again.',
    dynamic originalError,
  }) : super(message, code: 'UNEXPECTED_ERROR', originalError: originalError);
}

/// Failure for operations that are not yet implemented
class NotImplementedFailure extends Failure {
  const NotImplementedFailure({
    String message = 'This feature is not yet implemented.',
  }) : super(message, code: 'NOT_IMPLEMENTED');
}

/// Failure when an operation is cancelled by the user
class CancelledFailure extends Failure {
  const CancelledFailure({
    String message = 'Operation was cancelled.',
  }) : super(message, code: 'CANCELLED');
}
