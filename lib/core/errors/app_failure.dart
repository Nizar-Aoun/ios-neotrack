/// Categories of failures that map to a short, user-facing message.
enum AppFailureKind {
  network,
  unauthorized,
  fileTooLarge,
  unsupportedFileType,
  server,
  unknown,
}

/// Failure carrying a stable [kind] for the UI plus optional details for logs.
class AppFailure implements Exception {
  final AppFailureKind kind;
  final String? debugMessage;

  const AppFailure(this.kind, {this.debugMessage});

  @override
  String toString() =>
      'AppFailure(${kind.name}${debugMessage == null ? '' : ': $debugMessage'})';
}
