import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/core/constants/environment.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_endpoints.dart';
import 'package:mobile/core/network/api_error_handler.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/network/auth_interceptor.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

class InMemorySecureStorage extends SecureStorageService {
  final Map<String, String> data = {};

  InMemorySecureStorage({Map<String, String>? initialData}) {
    if (initialData != null) data.addAll(initialData);
  }

  @override
  Future<String?> getAccessToken() async => data[AppConstants.keyAccessToken];

  @override
  Future<void> setAccessToken(String token) async => data[AppConstants.keyAccessToken] = token;

  @override
  Future<String?> getRefreshToken() async => data[AppConstants.keyRefreshToken];

  @override
  Future<void> setRefreshToken(String token) async => data[AppConstants.keyRefreshToken] = token;

  @override
  Future<String?> getActiveFamilyId() async => data[AppConstants.keyFamilyId];

  @override
  Future<void> setActiveFamilyId(String familyId) async => data[AppConstants.keyFamilyId] = familyId;

  @override
  Future<void> clearAuthSession() async => data.clear();

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);

  @override
  Future<void> clearAll() async => data.clear();
}

ResponseBody jsonResponse(dynamic data, int statusCode, {Map<String, List<String>>? headers}) {
  final h = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
    ...?headers,
  };
  final body = data is String ? data : jsonEncode(data);
  return ResponseBody.fromString(body, statusCode, headers: h);
}

class MockHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('EnvironmentConfig Tests', () {
    test('Configures environments and URLs correctly', () {
      const devConfig = EnvironmentConfig(
        environment: AppEnvironment.development,
        baseUrl: 'http://10.0.2.2:8000/api/v1',
      );
      expect(devConfig.isDevelopment, isTrue);
      expect(devConfig.baseUrl, 'http://10.0.2.2:8000/api/v1');
      expect(devConfig.sendTimeout, const Duration(seconds: 15));

      const prodConfig = EnvironmentConfig(
        environment: AppEnvironment.production,
        baseUrl: 'https://api.familyexpensemanager.com/api/v1',
      );
      expect(prodConfig.isProduction, isTrue);
      expect(prodConfig.baseUrl, 'https://api.familyexpensemanager.com/api/v1');
    });
  });

  group('ApiErrorHandler & ApiException Mapping Tests', () {
    Response<dynamic> createResponse(int statusCode, dynamic data, [Map<String, List<String>>? headers]) {
      return Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: statusCode,
        data: data,
        headers: Headers.fromMap(headers ?? {}),
      );
    }

    DioException createDioException(int statusCode, dynamic data, [Map<String, List<String>>? headers]) {
      return DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: createResponse(statusCode, data, headers),
        type: DioExceptionType.badResponse,
      );
    }

    test('Maps HTTP 400 with custom backend format to BadRequestException', () {
      final dioErr = createDioException(400, {
        'success': false,
        'error': {'code': 400, 'message': 'Invalid query parameters'},
      });

      final exception = ApiErrorHandler.handle(dioErr);
      expect(exception, isA<BadRequestException>());
      expect(exception.statusCode, 400);
      expect(exception.message, 'Invalid query parameters');
    });

    test('Maps HTTP 401 with detail string to UnauthorizedException', () {
      final dioErr = createDioException(401, {'detail': 'Invalid or expired token'});
      final exception = ApiErrorHandler.handle(dioErr);
      expect(exception, isA<UnauthorizedException>());
      expect(exception.statusCode, 401);
      expect(exception.message, 'Invalid or expired token');
    });

    test('Maps HTTP 403 to ForbiddenException', () {
      final dioErr = createDioException(403, {'detail': 'Insufficient family role'});
      final exception = ApiErrorHandler.handle(dioErr);
      expect(exception, isA<ForbiddenException>());
      expect(exception.statusCode, 403);
      expect(exception.message, 'Insufficient family role');
    });

    test('Maps HTTP 404 to NotFoundException', () {
      final dioErr = createDioException(404, {'detail': 'Expense not found'});
      final exception = ApiErrorHandler.handle(dioErr);
      expect(exception, isA<NotFoundException>());
      expect(exception.statusCode, 404);
      expect(exception.message, 'Expense not found');
    });

    test('Maps HTTP 409 to ConflictException', () {
      final dioErr = createDioException(409, {
        'detail': 'A budget for this category and month already exists',
      });
      final exception = ApiErrorHandler.handle(dioErr);
      expect(exception, isA<ConflictException>());
      expect(exception.statusCode, 409);
      expect(exception.message, 'A budget for this category and month already exists');
    });

    test('Maps HTTP 422 with FastAPI validation error list to ValidationException', () {
      final dioErr = createDioException(422, {
        'detail': [
          {
            'loc': ['body', 'amount'],
            'msg': 'Amount must be greater than zero',
            'type': 'value_error',
          }
        ]
      });

      final exception = ApiErrorHandler.handle(dioErr);
      expect(exception, isA<ValidationException>());
      expect(exception.statusCode, 422);
      expect(exception.message, 'Amount must be greater than zero');
      final validationErr = exception as ValidationException;
      expect(validationErr.fieldErrors?['amount'], 'Amount must be greater than zero');
    });

    test('Maps HTTP 429 with retry-after header to RateLimitException', () {
      final dioErr = createDioException(429, {'detail': 'Rate limit exceeded'}, {'retry-after': ['60']});
      final exception = ApiErrorHandler.handle(dioErr);
      expect(exception, isA<RateLimitException>());
      expect(exception.statusCode, 429);
      expect((exception as RateLimitException).retryAfterSeconds, 60);
    });

    test('Maps HTTP 500 to ServerException', () {
      final dioErr = createDioException(500, {'detail': 'Database connection failure'});
      final exception = ApiErrorHandler.handle(dioErr);
      expect(exception, isA<ServerException>());
      expect(exception.statusCode, 500);
      expect(exception.message, 'Database connection failure');
    });

    test('Maps connectionTimeout to NetworkTimeoutException', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final exception = ApiErrorHandler.handle(dioErr);
      expect(exception, isA<NetworkTimeoutException>());
    });

    test('Maps connectionError to NoInternetException', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );
      final exception = ApiErrorHandler.handle(dioErr);
      expect(exception, isA<NoInternetException>());
    });

    test('Extracts user-friendly UI message', () {
      const exception = NotFoundException(message: 'Record does not exist.');
      final message = ApiErrorHandler.getUserFriendlyMessage(exception);
      expect(message, 'Record does not exist.');
    });
  });

  group('AuthInterceptor Tests', () {
    const baseUrl = 'http://10.0.2.2:8000/api/v1';

    test('Attaches Bearer access token to authenticated requests', () async {
      final storage = InMemorySecureStorage(initialData: {
        AppConstants.keyAccessToken: 'valid_access_token_123',
      });

      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      dio.interceptors.add(AuthInterceptor(storage: storage, baseUrl: baseUrl, retryClient: dio));
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        expect(options.headers['Authorization'], 'Bearer valid_access_token_123');
        return jsonResponse({'status': 'ok'}, 200);
      });

      final response = await dio.get('/expenses');
      expect(response.statusCode, 200);
    });

    test('Does not attach Bearer token to public endpoints', () async {
      final storage = InMemorySecureStorage(initialData: {
        AppConstants.keyAccessToken: 'some_token',
      });

      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      dio.interceptors.add(AuthInterceptor(storage: storage, baseUrl: baseUrl, retryClient: dio));
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        expect(options.headers.containsKey('Authorization'), isFalse);
        return jsonResponse({'token': 'new_login'}, 200);
      });

      final response = await dio.post(ApiEndpoints.login);
      expect(response.statusCode, 200);
    });

    test('Catches 401, refreshes tokens, and retries request successfully', () async {
      final storage = InMemorySecureStorage(initialData: {
        AppConstants.keyAccessToken: 'expired_access_token',
        AppConstants.keyRefreshToken: 'valid_refresh_token',
      });

      var requestCount = 0;
      var refreshCount = 0;

      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      refreshDio.httpClientAdapter = MockHttpAdapter((options) async {
        refreshCount++;
        expect(options.path, ApiEndpoints.refresh);
        return jsonResponse(
          {
            'access_token': 'refreshed_access_token_456',
            'refresh_token': 'new_refresh_token_789',
            'token_type': 'bearer',
            'expires_in': 3600,
          },
          200,
        );
      });

      final mainDio = Dio(BaseOptions(baseUrl: baseUrl));
      final authInterceptor = AuthInterceptor(
        storage: storage,
        baseUrl: baseUrl,
        refreshDio: refreshDio,
        retryClient: mainDio,
      );
      mainDio.interceptors.add(authInterceptor);

      mainDio.httpClientAdapter = MockHttpAdapter((options) async {
        requestCount++;
        if (options.headers['Authorization'] == 'Bearer expired_access_token') {
          return jsonResponse({'detail': 'Token expired'}, 401);
        }

        expect(options.headers['Authorization'], 'Bearer refreshed_access_token_456');
        return jsonResponse([{'id': '1', 'title': 'Grocery'}], 200);
      });

      final response = await mainDio.get('/expenses');
      expect(response.statusCode, 200);
      expect(requestCount, 2); // Initial 401 + 1 retry
      expect(refreshCount, 1); // Exactly 1 refresh call

      // Tokens in storage updated
      expect(await storage.getAccessToken(), 'refreshed_access_token_456');
      expect(await storage.getRefreshToken(), 'new_refresh_token_789');
    });

    test('Prevents multiple simultaneous refresh requests when concurrent 401s occur', () async {
      final storage = InMemorySecureStorage(initialData: {
        AppConstants.keyAccessToken: 'expired_token',
        AppConstants.keyRefreshToken: 'valid_refresh_token',
      });

      var refreshCallCount = 0;

      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      refreshDio.httpClientAdapter = MockHttpAdapter((options) async {
        refreshCallCount++;
        // Simulate network latency during token refresh
        await Future.delayed(const Duration(milliseconds: 50));
        return jsonResponse(
          {
            'access_token': 'new_token_batch',
            'refresh_token': 'new_refresh_batch',
          },
          200,
        );
      });

      final mainDio = Dio(BaseOptions(baseUrl: baseUrl));
      mainDio.interceptors.add(AuthInterceptor(
        storage: storage,
        baseUrl: baseUrl,
        refreshDio: refreshDio,
        retryClient: mainDio,
      ));

      mainDio.httpClientAdapter = MockHttpAdapter((options) async {
        if (options.headers['Authorization'] == 'Bearer expired_token') {
          return jsonResponse({'detail': 'expired'}, 401);
        }
        return jsonResponse({'data': 'ok'}, 200);
      });

      // Fire 3 simultaneous requests that all hit 401
      final results = await Future.wait([
        mainDio.get('/expenses'),
        mainDio.get('/income'),
        mainDio.get('/budgets'),
      ]);

      for (final res in results) {
        expect(res.statusCode, 200);
      }

      // Verify mutex: Refresh endpoint was called EXACTLY ONCE
      expect(refreshCallCount, 1);
      expect(await storage.getAccessToken(), 'new_token_batch');
    });

    test('Invokes onLogout and clears storage when token refresh fails', () async {
      final storage = InMemorySecureStorage(initialData: {
        AppConstants.keyAccessToken: 'expired_token',
        AppConstants.keyRefreshToken: 'revoked_refresh_token',
      });

      var logoutInvoked = false;

      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      refreshDio.httpClientAdapter = MockHttpAdapter((options) async {
        return jsonResponse({'detail': 'Refresh token revoked'}, 401);
      });

      final mainDio = Dio(BaseOptions(baseUrl: baseUrl));
      mainDio.interceptors.add(AuthInterceptor(
        storage: storage,
        baseUrl: baseUrl,
        refreshDio: refreshDio,
        retryClient: mainDio,
        onLogout: () => logoutInvoked = true,
      ));

      mainDio.httpClientAdapter = MockHttpAdapter((options) async {
        return jsonResponse({'detail': 'expired'}, 401);
      });

      expect(() => mainDio.get('/expenses'), throwsA(isA<DioException>()));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(logoutInvoked, isTrue);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });

  group('ApiClient Operations & Error Mapping Tests', () {
    test('Performs GET, POST, PUT, DELETE with error handling', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        if (options.method == 'GET' && options.path == '/items') {
          return jsonResponse([{'id': '1'}], 200);
        }
        if (options.method == 'POST' && options.path == '/items') {
          return jsonResponse({'id': '2', 'created': true}, 201);
        }
        if (options.method == 'PUT' && options.path == '/items/2') {
          return jsonResponse({'id': '2', 'updated': true}, 200);
        }
        if (options.method == 'DELETE' && options.path == '/items/2') {
          return ResponseBody.fromString('', 204);
        }
        if (options.path == '/error-404') {
          return jsonResponse({'detail': 'Item not found'}, 404);
        }
        return jsonResponse('', 400);
      });

      final apiClient = ApiClient(dio);

      final getRes = await apiClient.get<dynamic>('/items');
      expect(getRes.statusCode, 200);
      expect((getRes.data as List).length, 1);

      final postRes = await apiClient.post<dynamic>('/items', data: {'name': 'New'});
      expect(postRes.statusCode, 201);

      final putRes = await apiClient.put<dynamic>('/items/2', data: {'name': 'Updated'});
      expect(putRes.statusCode, 200);

      final delRes = await apiClient.delete<dynamic>('/items/2');
      expect(delRes.statusCode, 204);

      expect(
        () => apiClient.get<dynamic>('/error-404'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
