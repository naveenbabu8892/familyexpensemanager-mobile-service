import 'package:dio/dio.dart';
import 'api_exception.dart';

/// Centralized error converter transforming Dio and network exceptions
/// into domain-level [ApiException]s with user-friendly error messages.
class ApiErrorHandler {
  ApiErrorHandler._();

  /// Converts any exception or error into a typed [ApiException].
  static ApiException handle(dynamic error) {
    if (error is ApiException) {
      return error;
    }

    if (error is DioException) {
      return _mapDioException(error);
    }

    if (error is Exception) {
      return UnknownApiException(message: error.toString());
    }

    return const UnknownApiException();
  }

  /// Extracts a human-friendly string suitable for displaying directly in the UI.
  static String getUserFriendlyMessage(dynamic error) {
    final apiException = handle(error);
    return apiException.message;
  }

  static ApiException _mapDioException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkTimeoutException(
          message: 'Connection timed out. Please check your network and try again.',
          details: err.error,
        );

      case DioExceptionType.connectionError:
        return NoInternetException(
          message: 'No internet connection detected. Please verify your connection.',
          details: err.error,
        );

      case DioExceptionType.badCertificate:
        return const NoInternetException(
          message: 'Security certificate verification failed.',
        );

      case DioExceptionType.cancel:
        return const UnknownApiException(
          message: 'Request was cancelled.',
        );

      case DioExceptionType.badResponse:
        return _mapBadResponse(err.response);

      case DioExceptionType.unknown:
      default:
        // Check underlying socket/network exceptions
        final errString = err.error?.toString().toLowerCase() ?? '';
        if (errString.contains('socket') ||
            errString.contains('network') ||
            errString.contains('failed host lookup') ||
            errString.contains('connection refused')) {
          return NoInternetException(
            message: 'Unable to connect to the server. Please check your network.',
            details: err.error,
          );
        }
        return UnknownApiException(
          message: err.message ?? 'An unexpected network error occurred.',
          details: err.error,
        );
    }
  }

  static ApiException _mapBadResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode ?? 500;
    final data = response?.data;

    String? extractedMessage;
    Map<String, dynamic>? fieldErrors;

    if (data is Map<String, dynamic>) {
      // 1. Check custom backend error payload: { "success": false, "error": { "code": 400, "message": "..." } }
      if (data['error'] is Map<String, dynamic>) {
        final errorMap = data['error'] as Map<String, dynamic>;
        extractedMessage = errorMap['message']?.toString();
        if (errorMap['details'] is List) {
          fieldErrors = _extractFieldErrors(errorMap['details'] as List);
        }
      }
      // 2. Check standard FastAPI detail: { "detail": "..." } or { "detail": [ ... ] }
      else if (data['detail'] != null) {
        final detail = data['detail'];
        if (detail is String) {
          extractedMessage = detail;
        } else if (detail is List) {
          fieldErrors = _extractFieldErrors(detail);
          if (detail.isNotEmpty && detail.first is Map) {
            extractedMessage = (detail.first as Map)['msg']?.toString();
          }
        }
      }
      // 3. Check generic message key: { "message": "..." }
      else if (data['message'] != null) {
        extractedMessage = data['message']?.toString();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      extractedMessage = data.trim();
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(
          message: extractedMessage ?? 'Bad request. Please verify the submitted information.',
          details: data,
        );
      case 401:
        return UnauthorizedException(
          message: extractedMessage ?? 'Your session has expired. Please log in again.',
          details: data,
        );
      case 403:
        return ForbiddenException(
          message: extractedMessage ?? 'You do not have permission to perform this action.',
          details: data,
        );
      case 404:
        return NotFoundException(
          message: extractedMessage ?? 'The requested resource was not found.',
          details: data,
        );
      case 409:
        return ConflictException(
          message: extractedMessage ?? 'A record with this information already exists.',
          details: data,
        );
      case 422:
        return ValidationException(
          message: extractedMessage ?? 'Validation failed. Please check the entered fields.',
          fieldErrors: fieldErrors,
          details: data,
        );
      case 429:
        int? retryAfter;
        final retryHeader = response?.headers.value('retry-after');
        if (retryHeader != null) {
          retryAfter = int.tryParse(retryHeader);
        }
        return RateLimitException(
          message: extractedMessage ?? 'Too many requests. Please slow down and try again shortly.',
          retryAfterSeconds: retryAfter,
          details: data,
        );
      default:
        if (statusCode >= 500) {
          return ServerException(
            message: extractedMessage ?? 'A server error occurred. Please try again later.',
            statusCode: statusCode,
            details: data,
          );
        }
        return UnknownApiException(
          message: extractedMessage ?? 'An unexpected server error occurred ($statusCode).',
          statusCode: statusCode,
          details: data,
        );
    }
  }

  static Map<String, dynamic> _extractFieldErrors(List<dynamic> details) {
    final errors = <String, dynamic>{};
    for (final item in details) {
      if (item is Map) {
        final loc = item['loc'] as List?;
        final msg = item['msg']?.toString() ?? 'Invalid value';
        if (loc != null && loc.isNotEmpty) {
          final field = loc.last.toString();
          errors[field] = msg;
        }
      }
    }
    return errors;
  }
}
