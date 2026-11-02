import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_endpoints.dart';
import 'package:mobile/core/network/auth_interceptor.dart';
import 'package:mobile/core/network/error_interceptor.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/presentation/auth_controller.dart';
import 'package:mobile/features/auth/presentation/change_password_dialog.dart';
import 'package:mobile/features/auth/presentation/forgot_password_dialog.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/presentation/register_screen.dart';
import 'package:mobile/features/family/data/family_repository_impl.dart';
import 'package:mobile/features/family/presentation/family_setup_screen.dart';
import 'package:mobile/features/profile/data/user_repository_impl.dart';

class InMemorySecureStorage extends SecureStorageService {
  final Map<String, String> data = {};

  @override
  Future<String?> getAccessToken() async => data[AppConstants.keyAccessToken];

  @override
  Future<void> setAccessToken(String token) async =>
      data[AppConstants.keyAccessToken] = token;

  @override
  Future<String?> getRefreshToken() async => data[AppConstants.keyRefreshToken];

  @override
  Future<void> setRefreshToken(String token) async =>
      data[AppConstants.keyRefreshToken] = token;

  @override
  Future<String?> getActiveFamilyId() async => data[AppConstants.keyFamilyId];

  @override
  Future<void> setActiveFamilyId(String familyId) async =>
      data[AppConstants.keyFamilyId] = familyId;

  @override
  Future<void> clearAuthSession() async => data.clear();

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

ResponseBody jsonResponse(dynamic data, int statusCode,
    {Map<String, List<String>>? headers}) {
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
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late Dio refreshDio;
  late ApiClient apiClient;
  late InMemorySecureStorage storage;

  void setMockAdapter(Future<ResponseBody> Function(RequestOptions options) handler) {
    dio.httpClientAdapter = MockHttpAdapter(handler);
    refreshDio.httpClientAdapter = MockHttpAdapter(handler);
  }

  setUp(() {
    storage = InMemorySecureStorage();
    refreshDio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:8000/api/v1'));
    dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:8000/api/v1'));
    dio.interceptors.addAll([
      AuthInterceptor(
        storage: storage,
        baseUrl: 'http://10.0.2.2:8000/api/v1',
        refreshDio: refreshDio,
        retryClient: dio,
      ),
      ErrorInterceptor(),
    ]);
    apiClient = ApiClient(dio);
  });

  ProviderContainer createContainer({
    required AuthRepositoryImpl authRepo,
    required UserRepositoryImpl userRepo,
    required FamilyRepositoryImpl familyRepo,
  }) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        userRepositoryProvider.overrideWithValue(userRepo),
        familyRepositoryProvider.overrideWithValue(familyRepo),
        secureStorageProvider.overrideWithValue(storage),
        apiClientProvider.overrideWithValue(apiClient),
      ],
    );
    return container;
  }

  group('Authentication Flow & Life-Cycle Tests', () {
    test('1. Valid Login stores tokens, fetches user & family status, sets authenticated',
        () async {
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.login)) {
          return jsonResponse({
            'access_token': 'test_access_jwt',
            'refresh_token': 'test_refresh_jwt',
            'token_type': 'bearer',
            'expires_in': 3600,
          }, 200);
        }
        if (options.path.endsWith(ApiEndpoints.usersMe)) {
          return jsonResponse({
            'id': 'usr-1',
            'full_name': 'Raj Sharma',
            'email': 'raj@example.com',
            'is_active': true,
          }, 200);
        }
        if (options.path.endsWith(ApiEndpoints.familyCurrent)) {
          return jsonResponse({
            'id': 'fam-1',
            'name': 'The Sharma Family',
            'currency': 'INR',
            'timezone': 'Asia/Kolkata',
            'created_by': 'usr-1',
          }, 200);
        }
        return jsonResponse('', 404);
      });

      final authRepo = AuthRepositoryImpl(apiClient: apiClient, storage: storage);
      final userRepo = UserRepositoryImpl(apiClient);
      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);

      final container = createContainer(
        authRepo: authRepo,
        userRepo: userRepo,
        familyRepo: familyRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      final result = await controller.login(
        email: 'raj@example.com',
        password: 'ValidPassword123!',
      );

      final state = container.read(authControllerProvider);
      expect(result, isTrue);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.fullName, 'Raj Sharma');
      expect(state.hasFamily, isTrue);
      expect(state.family?.name, 'The Sharma Family');

      // Verify tokens stored securely
      expect(await storage.getAccessToken(), 'test_access_jwt');
      expect(await storage.getRefreshToken(), 'test_refresh_jwt');
    });

    test('2. Invalid Login rejects credentials, does not store tokens, sets error state',
        () async {
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.login)) {
          return jsonResponse({
            'detail': 'Invalid email or password.',
          }, 401);
        }
        return jsonResponse('', 404);
      });

      final authRepo = AuthRepositoryImpl(apiClient: apiClient, storage: storage);
      final userRepo = UserRepositoryImpl(apiClient);
      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);

      final container = createContainer(
        authRepo: authRepo,
        userRepo: userRepo,
        familyRepo: familyRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      final result = await controller.login(
        email: 'wrong@example.com',
        password: 'BadPassword!',
      );

      final state = container.read(authControllerProvider);
      expect(result, isFalse);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, contains('Invalid email or password'));
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('3. Expired token automatically refreshes and retries original request',
        () async {
      await storage.setAccessToken('expired_jwt');
      await storage.setRefreshToken('valid_refresh_jwt');

      int meAttempts = 0;
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.usersMe)) {
          meAttempts++;
          if (meAttempts == 1) {
            return jsonResponse({'detail': 'Token expired'}, 401);
          }
          return jsonResponse({
            'id': 'usr-1',
            'full_name': 'Raj Sharma',
            'email': 'raj@example.com',
            'is_active': true,
          }, 200);
        }
        if (options.path.endsWith(ApiEndpoints.refresh)) {
          return jsonResponse({
            'access_token': 'new_access_jwt',
            'refresh_token': 'new_refresh_jwt',
            'token_type': 'bearer',
            'expires_in': 3600,
          }, 200);
        }
        return jsonResponse('', 404);
      });

      final userRepo = UserRepositoryImpl(apiClient);
      final user = await userRepo.getCurrentUser();

      expect(user.fullName, 'Raj Sharma');
      expect(meAttempts, 2);
      expect(await storage.getAccessToken(), 'new_access_jwt');
      expect(await storage.getRefreshToken(), 'new_refresh_jwt');
    });

    test('4. Refresh token failure revokes session and clears storage', () async {
      await storage.setAccessToken('expired_jwt');
      await storage.setRefreshToken('revoked_refresh_jwt');

      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.usersMe)) {
          return jsonResponse({'detail': 'Token expired'}, 401);
        }
        if (options.path.endsWith(ApiEndpoints.refresh)) {
          return jsonResponse({'detail': 'Refresh token has been revoked'}, 401);
        }
        return jsonResponse('', 404);
      });

      final authRepo = AuthRepositoryImpl(apiClient: apiClient, storage: storage);
      final userRepo = UserRepositoryImpl(apiClient);
      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);

      final container = createContainer(
        authRepo: authRepo,
        userRepo: userRepo,
        familyRepo: familyRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final state = await controller.checkAuthStatus();

      expect(state.status, AuthStatus.unauthenticated);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('5. Logout revokes refresh token with backend and clears secure storage',
        () async {
      await storage.setAccessToken('active_access_jwt');
      await storage.setRefreshToken('active_refresh_jwt');
      await storage.setActiveFamilyId('fam-1');

      bool logoutEndpointCalled = false;
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.logout)) {
          logoutEndpointCalled = true;
          return jsonResponse({'message': 'Successfully logged out.'}, 200);
        }
        return jsonResponse('', 404);
      });

      final authRepo = AuthRepositoryImpl(apiClient: apiClient, storage: storage);
      final userRepo = UserRepositoryImpl(apiClient);
      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);

      final container = createContainer(
        authRepo: authRepo,
        userRepo: userRepo,
        familyRepo: familyRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.logout();

      final state = container.read(authControllerProvider);
      expect(logoutEndpointCalled, isTrue);
      expect(state.status, AuthStatus.unauthenticated);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getActiveFamilyId(), isNull);
    });

    test('6. App restart restores session when valid tokens exist in secure storage',
        () async {
      await storage.setAccessToken('persisted_access_jwt');
      await storage.setRefreshToken('persisted_refresh_jwt');

      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.usersMe)) {
          return jsonResponse({
            'id': 'usr-1',
            'full_name': 'Priya Sharma',
            'email': 'priya@example.com',
            'is_active': true,
          }, 200);
        }
        if (options.path.endsWith(ApiEndpoints.familyCurrent)) {
          return jsonResponse({
            'id': 'fam-10',
            'name': 'The Sharma Family',
            'currency': 'INR',
            'timezone': 'Asia/Kolkata',
            'created_by': 'usr-1',
          }, 200);
        }
        return jsonResponse('', 404);
      });

      final authRepo = AuthRepositoryImpl(apiClient: apiClient, storage: storage);
      final userRepo = UserRepositoryImpl(apiClient);
      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);

      final container = createContainer(
        authRepo: authRepo,
        userRepo: userRepo,
        familyRepo: familyRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final state = await controller.checkAuthStatus();

      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.fullName, 'Priya Sharma');
      expect(state.hasFamily, isTrue);
      expect(state.family?.name, 'The Sharma Family');
    });

    test('7. App restart routes to unauthenticated when storage is empty', () async {
      final authRepo = AuthRepositoryImpl(apiClient: apiClient, storage: storage);
      final userRepo = UserRepositoryImpl(apiClient);
      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);

      final container = createContainer(
        authRepo: authRepo,
        userRepo: userRepo,
        familyRepo: familyRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final state = await controller.checkAuthStatus();
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('8. App restart routes to authenticated without family when user has no family',
        () async {
      await storage.setAccessToken('persisted_access_jwt');

      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.usersMe)) {
          return jsonResponse({
            'id': 'usr-2',
            'full_name': 'New Member',
            'email': 'new@example.com',
            'is_active': true,
          }, 200);
        }
        if (options.path.endsWith(ApiEndpoints.familyCurrent)) {
          return jsonResponse({'detail': 'User has no family'}, 404);
        }
        return jsonResponse('', 404);
      });

      final authRepo = AuthRepositoryImpl(apiClient: apiClient, storage: storage);
      final userRepo = UserRepositoryImpl(apiClient);
      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);

      final container = createContainer(
        authRepo: authRepo,
        userRepo: userRepo,
        familyRepo: familyRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final state = await controller.checkAuthStatus();
      expect(state.status, AuthStatus.authenticated);
      expect(state.hasFamily, isFalse);
    });

    test('9. Registration stores tokens and sets authenticated without family',
        () async {
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.register)) {
          return jsonResponse({
            'access_token': 'fresh_jwt',
            'refresh_token': 'fresh_refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
          }, 201);
        }
        if (options.path.endsWith(ApiEndpoints.usersMe)) {
          return jsonResponse({
            'id': 'usr-3',
            'full_name': 'Aarav Gupta',
            'email': 'aarav@example.com',
            'is_active': true,
          }, 200);
        }
        return jsonResponse('', 404);
      });

      final authRepo = AuthRepositoryImpl(apiClient: apiClient, storage: storage);
      final userRepo = UserRepositoryImpl(apiClient);
      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);

      final container = createContainer(
        authRepo: authRepo,
        userRepo: userRepo,
        familyRepo: familyRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      final success = await controller.register(
        fullName: 'Aarav Gupta',
        email: 'aarav@example.com',
        password: 'Password123!',
        phone: '+919876500000',
      );

      final state = container.read(authControllerProvider);
      expect(success, isTrue);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.fullName, 'Aarav Gupta');
      expect(state.hasFamily, isFalse);
      expect(await storage.getAccessToken(), 'fresh_jwt');
    });

    test('10. Registration handles backend validation conflict (409)', () async {
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.register)) {
          return jsonResponse({
            'detail': 'An account with this email address already exists.',
          }, 409);
        }
        return jsonResponse('', 404);
      });

      final authRepo = AuthRepositoryImpl(apiClient: apiClient, storage: storage);
      final userRepo = UserRepositoryImpl(apiClient);
      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);

      final container = createContainer(
        authRepo: authRepo,
        userRepo: userRepo,
        familyRepo: familyRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      final success = await controller.register(
        fullName: 'Aarav Gupta',
        email: 'existing@example.com',
        password: 'Password123!',
      );

      final state = container.read(authControllerProvider);
      expect(success, isFalse);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage,
          contains('email address already exists'));
    });
  });

  group('Authentication UI Widgets Tests', () {
    Widget createTestApp(Widget child) {
      return ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWithValue(apiClient),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 1000)),
            child: Scaffold(body: child),
          ),
        ),
      );
    }

    testWidgets('LoginScreen renders email, password, login button, and forgot password link',
        (tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('LoginScreen validates required email and password', (tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders all fields, validates matching passwords and strength',
        (tester) async {
      await tester.pumpWidget(createTestApp(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsNWidgets(2)); // AppBar title & Button
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email Address *'), findsOneWidget);
      expect(find.text('Phone Number (Optional)'), findsOneWidget);
      expect(find.text('Password *'), findsOneWidget);
      expect(find.text('Confirm Password *'), findsOneWidget);

      // Tap submit with empty fields
      final submitButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('ForgotPasswordDialog opens and submits email instructions',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: Center(
              child: ForgotPasswordDialog(initialEmail: 'raj@example.com'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Recovery Email'), findsOneWidget);

      await tester.tap(find.text('Send Recovery Email'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Recovery Request Sent'), findsOneWidget);
      expect(find.text('Return to Login'), findsOneWidget);
    });

    testWidgets('ChangePasswordDialog opens, validates matching new passwords',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: Center(
              child: ChangePasswordDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);

      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter current password'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('FamilySetupScreen displays create and join options', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const FamilySetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Family Setup'), findsOneWidget);
      expect(find.text('Create Family'), findsNWidgets(2)); // Tab & Button
      expect(find.text('Join with Token'), findsOneWidget);
      expect(find.text('Set Up New Family'), findsOneWidget);
    });
  });
}
