import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';

/// Interceptor that attaches JWT Bearer tokens to authenticated requests,
/// detects HTTP 401 Unauthorized errors, silently refreshes tokens without
/// race conditions (preventing multiple simultaneous refresh calls),
/// retries original requests, and invokes logout when refresh fails.
class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService storage;
  final String baseUrl;
  final VoidCallback? onLogout;
  final Dio? retryClient;
  final Dio _refreshDio;

  // Synchronization mutex preventing simultaneous refresh requests
  Completer<bool>? _refreshCompleter;

  AuthInterceptor({
    required this.storage,
    required this.baseUrl,
    this.onLogout,
    this.retryClient,
    Dio? refreshDio,
  }) : _refreshDio = refreshDio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    // Attach Bearer token if not already explicitly attached
    if (!options.headers.containsKey('Authorization')) {
      final token = await storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only intercept 401s on protected endpoints
    if (err.response?.statusCode != 401 || _isPublicEndpoint(err.requestOptions.path)) {
      return handler.next(err);
    }

    // Case 1: If storage already has a newer access token than the one in the request that failed,
    // another request has already refreshed the token. Immediately retry with the new token!
    final currentTokenInStorage = await storage.getAccessToken();
    final tokenInRequest = err.requestOptions.headers['Authorization']
        ?.toString()
        .replaceFirst('Bearer ', '');

    if (currentTokenInStorage != null &&
        currentTokenInStorage.isNotEmpty &&
        tokenInRequest != null &&
        currentTokenInStorage != tokenInRequest) {
      err.requestOptions.headers['Authorization'] = 'Bearer $currentTokenInStorage';
      try {
        final retriedResponse = await _retryRequest(err.requestOptions);
        return handler.resolve(retriedResponse);
      } catch (_) {
        return handler.next(err);
      }
    }

    // Case 2: Another request is currently refreshing the token.
    // Await that refresh completion rather than launching a concurrent refresh.
    if (_refreshCompleter != null) {
      final refreshSuccess = await _refreshCompleter!.future;
      if (refreshSuccess) {
        final newAccessToken = await storage.getAccessToken();
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        }
        try {
          final retriedResponse = await _retryRequest(err.requestOptions);
          return handler.resolve(retriedResponse);
        } catch (_) {
          return handler.next(err);
        }
      } else {
        return handler.next(err);
      }
    }

    // Case 2: This request is the first to encounter 401. Lock and perform refresh.
    _refreshCompleter = Completer<bool>();

    try {
      final currentRefreshToken = await storage.getRefreshToken();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        _finishRefresh(false);
        await _handleLogout();
        return handler.next(err);
      }

      // Execute refresh via dedicated unintercepted Dio instance
      final response = await _refreshDio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': currentRefreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await storage.setAccessToken(newAccessToken);
        }
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await storage.setRefreshToken(newRefreshToken);
        }

        _finishRefresh(true);

        // Update headers and retry the failing request
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        }
        final retriedResponse = await _retryRequest(err.requestOptions);
        return handler.resolve(retriedResponse);
      } else {
        _finishRefresh(false);
        await _handleLogout();
        return handler.next(err);
      }
    } catch (_) {
      _finishRefresh(false);
      await _handleLogout();
      return handler.next(err);
    }
  }

  void _finishRefresh(bool success) {
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      _refreshCompleter!.complete(success);
    }
    _refreshCompleter = null;
  }

  Future<void> _handleLogout() async {
    try {
      await storage.clearAuthSession();
    } catch (_) {}
    onLogout?.call();
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) {
    if (retryClient != null) {
      return retryClient!.fetch(requestOptions);
    }

    final retryDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: requestOptions.connectTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
        sendTimeout: requestOptions.sendTimeout,
      ),
    );

    return retryDio.fetch(requestOptions);
  }

  bool _isPublicEndpoint(String path) {
    final publicEndpoints = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.refresh,
    ];
    return publicEndpoints.any((endpoint) => path.endsWith(endpoint));
  }
}
