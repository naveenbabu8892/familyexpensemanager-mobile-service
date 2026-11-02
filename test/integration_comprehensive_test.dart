import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/router.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_endpoints.dart';
import 'package:mobile/core/network/auth_interceptor.dart';
import 'package:mobile/core/network/error_interceptor.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/widgets.dart';
import 'package:mobile/features/auth/presentation/auth_controller.dart';

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

    final authInterceptor = AuthInterceptor(
      storage: storage,
      baseUrl: 'http://10.0.2.2:8000/api/v1',
      refreshDio: refreshDio,
      retryClient: dio,
    );

    dio.interceptors.addAll([
      authInterceptor,
      ErrorInterceptor(),
    ]);

    apiClient = ApiClient(dio);
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        secureStorageProvider.overrideWithValue(storage),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('End-to-End & Integration Testing Flows', () {
    testWidgets('Integration Flow 1: Login -> Dashboard -> Add Expense -> Transaction List -> Dashboard Updated',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool expenseAdded = false;

      setMockAdapter((options) async {
        final path = options.path;

        // Startup checkAuthStatus
        if (options.method == 'GET' && path.endsWith(ApiEndpoints.usersMe)) {
          return jsonResponse({
            'id': 'usr-1',
            'full_name': 'Raj Sharma',
            'email': 'raj@example.com',
            'phone': '+91 9876543210',
            'is_active': true,
          }, 200);
        }

        // Login
        if (options.method == 'POST' && path.endsWith(ApiEndpoints.login)) {
          return jsonResponse({
            'access_token': 'access_token_123',
            'refresh_token': 'refresh_token_123',
            'token_type': 'bearer',
            'expires_in': 3600,
          }, 200);
        }

        // Family resolution
        if (options.method == 'GET' && path.endsWith(ApiEndpoints.familyCurrent)) {
          return jsonResponse({
            'id': 'fam-1',
            'name': 'Sharma Family',
            'currency': 'INR',
            'created_by': 'usr-1',
            'user_role': 'owner',
          }, 200);
        }

        // Dashboard data (Returns updated stats once expense is added)
        if (options.method == 'GET' && path.endsWith(ApiEndpoints.dashboard)) {
          return jsonResponse({
            'total_income': 80000.0,
            'total_expenses': expenseAdded ? 47450.0 : 45000.0,
            'remaining_balance': expenseAdded ? 32550.0 : 35000.0,
            'shared_expenses': expenseAdded ? 22450.0 : 20000.0,
            'my_expenses': 15000.0,
            'spouse_expenses': 10000.0,
            'currency': 'INR',
            'month': 10,
            'year': 2026,
            'recent_transactions': expenseAdded
                ? [
                    {
                      'id': 'exp-new',
                      'title': 'Organic Grocery',
                      'category_name': 'Grocery',
                      'person_name': 'Raj Sharma',
                      'date': '2026-10-06',
                      'amount': 2450.0,
                      'is_expense': true,
                    }
                  ]
                : [],
            'budgets': [],
            'category_expenses': [],
            'member_expenses': [],
            'trend': [],
          }, 200);
        }

        // Categories
        if (options.method == 'GET' && path.endsWith(ApiEndpoints.categories)) {
          return jsonResponse([
            {
              'id': 'cat-1',
              'name': 'Grocery',
              'type': 'EXPENSE',
              'icon': 'shopping_basket',
              'color': '#B86B4B',
              'is_default': true,
            }
          ], 200);
        }

        // Family members
        if (options.method == 'GET' && path.endsWith(ApiEndpoints.familyMembers)) {
          return jsonResponse([
            {
              'id': 'mem-1',
              'family_id': 'fam-1',
              'user_id': 'usr-1',
              'user_full_name': 'Raj Sharma',
              'role': 'owner',
              'status': 'active',
            }
          ], 200);
        }

        // Add Expense POST
        if (options.method == 'POST' && path.endsWith(ApiEndpoints.expenses)) {
          expenseAdded = true;
          return jsonResponse({
            'id': 'exp-new',
            'family_id': 'fam-1',
            'created_by': 'usr-1',
            'title': 'Organic Grocery',
            'amount': 2450.0,
            'currency': 'INR',
            'category_id': 'cat-1',
            'category_name': 'Grocery',
            'expense_date': '2026-10-06',
            'payment_method': 'upi',
            'paid_by': 'usr-1',
            'paid_by_name': 'Raj Sharma',
            'is_shared': true,
          }, 201);
        }

        // Transactions list GET
        if (options.method == 'GET' && path.contains('/expenses')) {
          return jsonResponse({
            'items': expenseAdded
                ? [
                    {
                      'id': 'exp-new',
                      'family_id': 'fam-1',
                      'created_by': 'usr-1',
                      'title': 'Organic Grocery',
                      'amount': 2450.0,
                      'currency': 'INR',
                      'category_id': 'cat-1',
                      'category_name': 'Grocery',
                      'expense_date': '2026-10-06',
                      'payment_method': 'upi',
                      'paid_by': 'usr-1',
                      'paid_by_name': 'Raj Sharma',
                      'is_shared': true,
                    }
                  ]
                : [],
            'total': expenseAdded ? 1 : 0,
            'page': 1,
            'page_size': 20,
          }, 200);
        }

        return jsonResponse({}, 200);
      });

      await tester.pumpWidget(buildApp());
      // Splash screen delay
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // 1. Splash screen moves to Login
      expect(find.text('Welcome Back'), findsOneWidget);

      // Fill login form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'raj@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '••••••••'),
        'SecurePassword123!',
      );

      // Submit Login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // 2. Verified on Dashboard
      expect(find.text('Good evening, Raj'), findsOneWidget);
      expect(find.text('₹35,000'), findsOneWidget);

      // 3. Navigate to Add Expense Screen (via Shell / Route)
      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      final router = container.read(routerProvider);
      router.push('/expenses/add');
      await tester.pumpAndSettle();

      expect(find.text('Add Expense'), findsOneWidget);

      // Enter amount via AmountInput
      final amountInput = find.byType(AmountInput);
      expect(amountInput, findsOneWidget);
      await tester.enterText(amountInput, '2450');

      // Enter Title via VintageTextField
      final titleField = find.widgetWithText(VintageTextField, 'Title');
      expect(titleField, findsOneWidget);
      await tester.enterText(titleField, 'Organic Grocery');

      // Save Expense
      await tester.tap(find.widgetWithText(VintageButton, 'Save Expense'));
      await tester.pumpAndSettle();

      // 4. Navigate to Transactions List
      router.go('/transactions');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Transactions'), findsOneWidget);
      expect(find.text('Organic Grocery'), findsOneWidget);
      expect(find.text('-₹2,450'), findsOneWidget);

      // 5. Navigate back to Home/Dashboard and verify state refreshed
      router.go('/home');
      await tester.pumpAndSettle();

      expect(find.text('Organic Grocery'), findsOneWidget);
      expect(find.text('₹32,550'), findsOneWidget);
    });

    testWidgets('Integration Flow 2: Register -> Create Family -> Invite Spouse',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      setMockAdapter((options) async {
        final path = options.path;

        if (options.method == 'POST' && path.endsWith(ApiEndpoints.register)) {
          return jsonResponse({
            'access_token': 'new_user_token',
            'refresh_token': 'new_user_refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
          }, 201);
        }

        if (options.method == 'GET' && path.endsWith(ApiEndpoints.usersMe)) {
          return jsonResponse({
            'id': 'usr-2',
            'full_name': 'Priya Patel',
            'email': 'priya@example.com',
            'is_active': true,
          }, 200);
        }

        if (options.method == 'POST' && path.endsWith(ApiEndpoints.families)) {
          return jsonResponse({
            'id': 'fam-patel',
            'name': 'The Patel Household',
            'currency': 'INR',
            'created_by': 'usr-2',
            'user_role': 'owner',
          }, 201);
        }

        if (options.method == 'GET' && path.endsWith(ApiEndpoints.familyCurrent)) {
          return jsonResponse({
            'id': 'fam-patel',
            'name': 'The Patel Household',
            'currency': 'INR',
            'created_by': 'usr-2',
            'user_role': 'owner',
          }, 200);
        }

        if (options.method == 'POST' && path.endsWith(ApiEndpoints.familyInvite)) {
          return jsonResponse({
            'token': 'token-invite-12345',
            'invite_token': 'token-invite-12345',
            'invitation_link': 'https://fem.app/invite/token-invite-12345',
            'expires_at': '2026-10-13T10:00:00Z',
          }, 200);
        }

        return jsonResponse({}, 200);
      });

      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      final router = container.read(routerProvider);

      // Navigate to Register screen
      router.go('/register');
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsWidgets);

      await tester.enterText(
        find.widgetWithText(VintageTextField, 'Full Name *'),
        'Priya Patel',
      );
      await tester.enterText(
        find.widgetWithText(VintageTextField, 'Email Address *'),
        'priya@example.com',
      );
      await tester.enterText(
        find.widgetWithText(VintageTextField, 'Password *'),
        'StrongPassword123!',
      );
      await tester.enterText(
        find.widgetWithText(VintageTextField, 'Confirm Password *'),
        'StrongPassword123!',
      );

      final createAccountBtn = find.widgetWithText(VintageButton, 'Create Account');
      await tester.ensureVisible(createAccountBtn);
      await tester.tap(createAccountBtn);
      await tester.pumpAndSettle();

      // User registered -> Navigate to Create Family screen
      router.go('/family/create');
      await tester.pumpAndSettle();

      expect(find.text('Establish Your Household'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(VintageTextField, 'Family Name *'),
        'The Patel Household',
      );

      final createFamilyBtn = find.widgetWithText(VintageButton, 'Create Family');
      await tester.ensureVisible(createFamilyBtn);
      await tester.tap(createFamilyBtn);
      await tester.pumpAndSettle();

      // Family created -> Navigate to Invite Spouse
      router.go('/family/invite');
      await tester.pumpAndSettle();

      expect(find.text('Invite Your Spouse'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(VintageTextField, 'Spouse Email Address *'),
        'partner@example.com',
      );

      final sendInviteBtn = find.widgetWithText(VintageButton, 'Send Invitation');
      await tester.ensureVisible(sendInviteBtn);
      await tester.tap(sendInviteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Invitation sent successfully.'), findsOneWidget);
      expect(find.text('token-invite-12345'), findsOneWidget);
    });

    testWidgets('Integration Flow 3: Network Errors & Offline handling',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      setMockAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          error: 'Connection timeout',
        );
      });

      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // Submit login under connection timeout
      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'raj@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '••••••••'),
        'SecurePassword123!',
      );

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Shows friendly connection error from ApiErrorHandler
      expect(
        find.text('Connection timed out. Please check your network and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('Integration Flow 4: Expired Authentication Session & Logout',
        (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pre-seed storage with expired token
      await storage.setAccessToken('expired_token');
      await storage.setRefreshToken('expired_refresh');

      setMockAdapter((options) async {
        final path = options.path;

        // Startup verification fails with 401 Unauthorized
        if (path.endsWith(ApiEndpoints.usersMe)) {
          return jsonResponse({'detail': 'Token expired'}, 401);
        }

        // Refresh token attempt fails with 401 Unauthorized
        if (path.endsWith(ApiEndpoints.refresh)) {
          return jsonResponse({'detail': 'Refresh token expired'}, 401);
        }

        return jsonResponse({}, 200);
      });

      await tester.pumpWidget(buildApp());
      // Splash duration
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

      // Session tokens must be wiped
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(container.read(authStateProvider).isUnauthenticated, isTrue);

      // Returns to Login Screen
      expect(find.text('Welcome Back'), findsOneWidget);
    });
  });
}
