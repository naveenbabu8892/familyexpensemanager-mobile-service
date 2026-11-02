import 'app_exception.dart';

/// Clean Architecture Failure representation consumed by Domain and Presentation layers.
class Failure {
  final String message;
  final int? statusCode;
  final dynamic error;

  const Failure({
    required this.message,
    this.statusCode,
    this.error,
  });

  /// Convert any [AppException] or general exception into a user-facing [Failure].
  factory Failure.fromException(Object exception) {
    if (exception is AppException) {
      return Failure(
        message: exception.message,
        statusCode: exception.statusCode,
        error: exception,
      );
    }
    return Failure(
      message: exception.toString(),
      error: exception,
    );
  }

  @override
  String toString() => message;
}
