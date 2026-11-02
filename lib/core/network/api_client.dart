import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/environment.dart';
import '../storage/secure_storage_service.dart';
import 'api_error_handler.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../features/auth/presentation/auth_controller.dart';

/// Provider for active [EnvironmentConfig].
final environmentConfigProvider = Provider<EnvironmentConfig>((ref) {
  return EnvironmentConfig.fromDartDefines();
});

/// Callback provider for handling session termination / logout when token refresh fails.
final onSessionExpiredProvider = Provider<VoidCallback?>((ref) {
  return () {
    try {
      ref.read(authControllerProvider.notifier).handleSessionExpired();
    } catch (_) {}
    rootNavigatorKey.currentContext?.go('/login');
  };
});

/// Provider for configured [Dio] HTTP client instance.
final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(environmentConfigProvider);
  final storage = ref.watch(secureStorageProvider);
  final onLogout = ref.watch(onSessionExpiredProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: env.baseUrl,
      connectTimeout: env.connectTimeout,
      receiveTimeout: env.receiveTimeout,
      sendTimeout: env.sendTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(
      storage: storage,
      baseUrl: env.baseUrl,
      onLogout: onLogout,
      retryClient: dio,
    ),
    ErrorInterceptor(),
    if (env.isDevelopment)
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
  ]);

  return dio;
});

/// Generic centralized API client wrapper over Dio providing safe,
/// typed HTTP operations with automatic exception conversion.
class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  /// Access the underlying Dio client if low-level configurations are required.
  Dio get dio => _dio;

  /// HTTP GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// HTTP POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// HTTP PUT
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// HTTP DELETE
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// HTTP PATCH
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(dynamic error) {
    if (error is DioException && error.error is ApiException) {
      return error.error as ApiException;
    }
    return ApiErrorHandler.handle(error);
  }
}

/// Riverpod provider for [ApiClient].
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});
