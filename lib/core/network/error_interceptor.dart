import 'package:dio/dio.dart';
import 'api_error_handler.dart';

/// Interceptor that converts low-level DioExceptions into typed [ApiException]s
/// and attaches user-friendly error messages.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = ApiErrorHandler.handle(err);
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        message: apiException.message,
      ),
    );
  }
}
