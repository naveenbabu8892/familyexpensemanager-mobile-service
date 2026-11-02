/// Base class for all application-level exceptions.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AppException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'AppException(statusCode: $statusCode, message: $message)';
}

/// Thrown when device has no internet or host is unreachable.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection. Please check your network.',
    super.statusCode,
  });
}

/// Thrown when backend returns 5xx error.
class ServerException extends AppException {
  const ServerException({
    super.message = 'A server error occurred. Please try again later.',
    super.statusCode = 500,
    super.details,
  });
}

/// Thrown when backend returns 401 or token is invalid/expired.
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Your session has expired. Please log in again.',
    super.statusCode = 401,
  });
}

/// Thrown when backend returns 403 Forbidden.
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.statusCode = 403,
  });
}

/// Thrown when requested resource does not exist (404).
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Requested resource was not found.',
    super.statusCode = 404,
  });
}

/// Thrown when validation fails (422).
class ValidationException extends AppException {
  final Map<String, dynamic>? fieldErrors;

  const ValidationException({
    super.message = 'Invalid request data. Please check your inputs.',
    super.statusCode = 422,
    this.fieldErrors,
  }) : super(details: fieldErrors);
}

/// Thrown on rate limiting (429).
class RateLimitException extends AppException {
  final int? retryAfterSeconds;

  const RateLimitException({
    super.message = 'Too many requests. Please slow down and try again later.',
    super.statusCode = 429,
    this.retryAfterSeconds,
  });
}

/// Generic unexpected client or parsing error.
class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred.',
    super.statusCode,
    super.details,
  });
}
