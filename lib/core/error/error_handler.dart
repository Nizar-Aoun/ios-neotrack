/// Centralized error handler for converting exceptions to failures.
///
/// This class provides utility methods to convert various exception types
/// into appropriate Failure objects for consistent error handling across the app.

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'failure.dart';

class ErrorHandler {
  /// Private constructor to prevent instantiation
  ErrorHandler._();

  /// Converts an exception to a Failure object
  ///
  /// This method handles common exception types and converts them to
  /// appropriate Failure subclasses. If the exception is already a Failure,
  /// it returns it as-is.
  static Failure handleError(dynamic error, [StackTrace? stackTrace]) {
    // If it's already a Failure, return it
    if (error is Failure) {
      return error;
    }

    // Log the error in debug mode
    // Removed debug logging

    // Handle specific exception types
    if (error is SocketException) {
      return const NoInternetConnectionFailure();
    }

    if (error is TimeoutException) {
      return const TimeoutFailure();
    }

    if (error is FormatException) {
      return const InvalidResponseFailure();
    }

    if (error is http.ClientException) {
      return const ServerUnreachableFailure();
    }

    // Handle generic Exception with message extraction
    if (error is Exception) {
      final message = error.toString().replaceFirst('Exception: ', '');
      return _parseExceptionMessage(message, error);
    }

    // Handle Error types
    if (error is Error) {
      return UnexpectedFailure(
        message: 'An unexpected error occurred: ${error.toString()}',
        originalError: error,
      );
    }

    // Fallback for unknown error types
    return UnexpectedFailure(
      message: error?.toString() ?? 'An unknown error occurred',
      originalError: error,
    );
  }

  /// Converts an HTTP response to a Failure based on status code
  static Failure handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return BadRequestFailure(
          message: _extractErrorMessage(response.body) ?? 'Bad request',
        );
      case 401:
        return const UnauthorizedFailure();
      case 403:
        return const ForbiddenFailure();
      case 404:
        return const NotFoundFailure();
      case 429:
        return const TooManyRequestsFailure();
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerFailure(
          message:
              _extractErrorMessage(response.body) ?? 'Server error occurred',
          code: response.statusCode.toString(),
        );
      default:
        return ServerFailure(
          message: _extractErrorMessage(response.body) ??
              'Request failed with status ${response.statusCode}',
          code: response.statusCode.toString(),
        );
    }
  }

  /// Parses exception messages and converts them to specific Failures
  static Failure _parseExceptionMessage(String message, dynamic originalError) {
    final lowerMessage = message.toLowerCase();

    // Network-related errors
    if (lowerMessage.contains('no internet') ||
        lowerMessage.contains('network') ||
        lowerMessage.contains('connection')) {
      return NoInternetConnectionFailure();
    }

    if (lowerMessage.contains('timeout') ||
        lowerMessage.contains('timed out')) {
      return const TimeoutFailure();
    }

    if (lowerMessage.contains('invalid response') ||
        lowerMessage.contains('parse') ||
        lowerMessage.contains('format')) {
      return const InvalidResponseFailure();
    }

    // Authentication-related errors
    if (lowerMessage.contains('unauthorized') ||
        lowerMessage.contains('not authorized') ||
        lowerMessage.contains('authentication')) {
      return const UnauthorizedFailure();
    }

    if (lowerMessage.contains('invalid credentials') ||
        lowerMessage.contains('incorrect password') ||
        lowerMessage.contains('wrong password') ||
        lowerMessage.contains('échec de connexion')) {
      return const InvalidCredentialsFailure();
    }

    if (lowerMessage.contains('session expired') ||
        lowerMessage.contains('token expired')) {
      return const SessionExpiredFailure();
    }

    if (lowerMessage.contains('invalid token') ||
        lowerMessage.contains('no token') ||
        lowerMessage.contains('missing token')) {
      return const InvalidTokenFailure();
    }

    if (lowerMessage.contains('user not found') ||
        lowerMessage.contains('account not found')) {
      return const UserNotFoundFailure();
    }

    if (lowerMessage.contains('password') &&
        (lowerMessage.contains('weak') ||
            lowerMessage.contains('too short') ||
            lowerMessage.contains('must contain'))) {
      return WeakPasswordFailure(message: message);
    }

    if (lowerMessage.contains('current password is incorrect')) {
      return const IncorrectPasswordFailure();
    }

    // Location-related errors
    if (lowerMessage.contains('location permission')) {
      return const LocationPermissionDeniedFailure();
    }

    if (lowerMessage.contains('location service')) {
      return const LocationServiceDisabledFailure();
    }

    // Permission errors
    if (lowerMessage.contains('permission denied')) {
      return PermissionDeniedFailure(
        permission: _extractPermissionName(message),
      );
    }

    // Server errors
    if (lowerMessage.contains('server') || lowerMessage.contains('500')) {
      return ServerFailure(message: message, originalError: originalError);
    }

    // Default to server failure with custom message
    return ServerFailure(
      message: message.isNotEmpty ? message : 'An error occurred',
      originalError: originalError,
    );
  }

  /// Attempts to extract error message from response body (JSON)
  static String? _extractErrorMessage(String responseBody) {
    try {
      // Assuming most APIs return JSON with a 'message' or 'error' field
      if (responseBody.isEmpty) return null;

      // Try to parse as JSON
      final decoded = responseBody;
      if (decoded.contains('"message"')) {
        final regex = RegExp(r'"message"\s*:\s*"([^"]*)"');
        final match = regex.firstMatch(decoded);
        if (match != null) return match.group(1);
      }
      if (decoded.contains('"error"')) {
        final regex = RegExp(r'"error"\s*:\s*"([^"]*)"');
        final match = regex.firstMatch(decoded);
        if (match != null) return match.group(1);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extracts permission name from error message
  static String _extractPermissionName(String message) {
    final regex = RegExp(r'permission[:\s]+(\w+)', caseSensitive: false);
    final match = regex.firstMatch(message);
    return match?.group(1) ?? 'unknown';
  }

  /// Wraps an async function with error handling
  ///
  /// This method catches any errors thrown by the function and converts
  /// them to Failures using handleError.
  ///
  /// Usage:
  /// ```dart
  /// final result = await ErrorHandler.guard(() async {
  ///   return await someAsyncOperation();
  /// });
  /// ```
  static Future<T> guard<T>(Future<T> Function() function) async {
    try {
      return await function();
    } catch (error, stackTrace) {
      throw handleError(error, stackTrace);
    }
  }

  /// Synchronous version of guard for non-async operations
  static T guardSync<T>(T Function() function) {
    try {
      return function();
    } catch (error, stackTrace) {
      throw handleError(error, stackTrace);
    }
  }

  /// Converts a Failure to a user-friendly message
  ///
  /// This can be used to display error messages in the UI
  static String getDisplayMessage(Failure failure) {
    // You can add localization here if needed
    return failure.message;
  }

  /// Checks if a failure is recoverable (user can retry)
  static bool isRecoverable(Failure failure) {
    return failure is NetworkFailure ||
        failure is TimeoutFailure ||
        failure is ServerUnreachableFailure;
  }

  /// Checks if a failure requires re-authentication
  static bool requiresReauth(Failure failure) {
    return failure is UnauthorizedFailure ||
        failure is SessionExpiredFailure ||
        failure is InvalidTokenFailure;
  }

  /// Checks if a failure is related to network connectivity
  static bool isNetworkFailure(Failure failure) {
    return failure is NetworkFailure;
  }
}
