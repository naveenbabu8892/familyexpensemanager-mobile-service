/// Base class for all API exceptions thrown by the centralized API client.
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => '$runtimeType(statusCode: $statusCode, message: $message)';
}

/// HTTP 400 Bad Request
class BadRequestException extends ApiException {
  const BadRequestException({
    super.message = 'Bad request. Please check your submission.',
    super.statusCode = 400,
    super.details,
  });
}

/// HTTP 401 Unauthorized - token expired or credentials invalid
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Your session has expired or credentials are invalid. Please log in again.',
    super.statusCode = 401,
    super.details,
  });
}

/// HTTP 403 Forbidden - insufficient permissions
class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.statusCode = 403,
    super.details,
  });
}

/// HTTP 404 Not Found - resource does not exist
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.statusCode = 404,
    super.details,
  });
}

/// HTTP 409 Conflict - e.g. duplicate email, unique constraint violation
class ConflictException extends ApiException {
  const ConflictException({
    super.message = 'A conflicting record already exists.',
    super.statusCode = 409,
    super.details,
  });
}

/// HTTP 422 Unprocessable Entity - validation error
class ValidationException extends ApiException {
  final Map<String, dynamic>? fieldErrors;

  const ValidationException({
    super.message = 'Validation error. Please verify the input data.',
    super.statusCode = 422,
    this.fieldErrors,
    super.details,
  });
}

/// HTTP 429 Too Many Requests - rate limit exceeded
class RateLimitException extends ApiException {
  final int? retryAfterSeconds;

  const RateLimitException({
    super.message = 'Too many requests. Please slow down and try again later.',
    super.statusCode = 429,
    this.retryAfterSeconds,
    super.details,
  });
}

/// HTTP 500+ Internal Server Error
class ServerException extends ApiException {
  const ServerException({
    super.message = 'A server error occurred. Please try again later.',
    super.statusCode = 500,
    super.details,
  });
}

/// Connection, Send, or Receive Timeout
class NetworkTimeoutException extends ApiException {
  const NetworkTimeoutException({
    super.message = 'The request timed out. Please check your internet connection and try again.',
    super.statusCode,
    super.details,
  });
}

/// No internet connection or host unreachable
class NoInternetException extends ApiException {
  const NoInternetException({
    super.message = 'No internet connection detected. Please check your network.',
    super.statusCode,
    super.details,
  });
}

/// Fallback unexpected error
class UnknownApiException extends ApiException {
  const UnknownApiException({
    super.message = 'An unexpected error occurred.',
    super.statusCode,
    super.details,
  });
}
