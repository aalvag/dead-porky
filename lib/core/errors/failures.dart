/// Base failure class for error handling across the app
abstract class Failure {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.code, this.stackTrace});

  @override
  String toString() => 'Failure: $message (code: $code)';
}

/// Server/Firebase failures
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.stackTrace});
}

/// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.stackTrace});
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.stackTrace});
}

/// Cache/Local database failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code, super.stackTrace});
}

/// BLE/Device failures
class DeviceFailure extends Failure {
  const DeviceFailure(super.message, {super.code, super.stackTrace});
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(
    super.message, {
    this.fieldErrors,
    super.code,
    super.stackTrace,
  });
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code, super.stackTrace});
}

/// AI/Gateway failures
class AIFailure extends Failure {
  const AIFailure(super.message, {super.code, super.stackTrace});
}

/// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code, super.stackTrace});
}
