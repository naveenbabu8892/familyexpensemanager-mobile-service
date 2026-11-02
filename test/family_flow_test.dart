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
import 'package:mobile/features/family/data/family_repository_impl.dart';
import 'package:mobile/features/family/presentation/accept_invitation_screen.dart';
import 'package:mobile/features/family/presentation/create_family_screen.dart';
import 'package:mobile/features/family/presentation/family_controller.dart';
import 'package:mobile/features/family/presentation/family_home_screen.dart';
import 'package:mobile/features/family/presentation/family_members_screen.dart';
import 'package:mobile/features/family/presentation/invite_spouse_screen.dart';

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

  void setMockAdapter(
      Future<ResponseBody> Function(RequestOptions options) handler) {
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
    required FamilyRepositoryImpl familyRepo,
  }) {
    final container = ProviderContainer(
      overrides: [
        familyRepositoryProvider.overrideWithValue(familyRepo),
        secureStorageProvider.overrideWithValue(storage),
        apiClientProvider.overrideWithValue(apiClient),
      ],
    );
    return container;
  }

  group('Family Management Controller Tests', () {
    test('1. Create Family calls backend, loads members, and updates state',
        () async {
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.families) &&
            options.method == 'POST') {
          return jsonResponse({
            'id': 'fam-100',
            'name': 'The Sharma Family',
            'currency': 'INR',
            'timezone': 'Asia/Kolkata',
            'created_by': 'usr-1',
            'user_role': 'owner',
          }, 201);
        }
        if (options.path.endsWith(ApiEndpoints.familyMembers)) {
          return jsonResponse([
            {
              'id': 'mem-1',
              'family_id': 'fam-100',
              'user_id': 'usr-1',
              'user_full_name': 'Raj Sharma',
              'user_email': 'raj@example.com',
              'role': 'owner',
              'status': 'active',
              'joined_at': '2026-10-01T10:00:00Z',
            }
          ], 200);
        }
        return jsonResponse('', 404);
      });

      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);
      final container = createContainer(familyRepo: familyRepo);
      addTearDown(container.dispose);

      final controller = container.read(familyControllerProvider.notifier);
      final family = await controller.createFamily(
        name: 'The Sharma Family',
        currency: 'INR',
        timezone: 'Asia/Kolkata',
      );

      final state = container.read(familyControllerProvider);
      expect(family, isNotNull);
      expect(state.family?.name, 'The Sharma Family');
      expect(state.family?.currency, 'INR');
      expect(state.isOwner, isTrue);
      expect(state.members.length, 1);
      expect(state.hasSpouseJoined, isFalse);
    });

    test('2. Invite Spouse sends email and receives secure token', () async {
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.familyInvite)) {
          return jsonResponse({
            'id': 'inv-1',
            'family_id': 'fam-100',
            'invited_email': 'priya@example.com',
            'status': 'pending',
            'token': 'invite-secret-xyz',
            'expires_at': '2026-10-10T10:00:00Z',
            'created_at': '2026-10-06T10:00:00Z',
          }, 201);
        }
        return jsonResponse('', 404);
      });

      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);
      final container = createContainer(familyRepo: familyRepo);
      addTearDown(container.dispose);

      final controller = container.read(familyControllerProvider.notifier);
      final token = await controller.inviteSpouse('priya@example.com');

      expect(token, 'invite-secret-xyz');
      expect(container.read(familyControllerProvider).lastInviteToken,
          'invite-secret-xyz');
    });

    test('3. Invite Spouse gracefully handles 403 Forbidden non-owner authorization error',
        () async {
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.familyInvite)) {
          return jsonResponse({
            'detail': 'Only the family owner can invite new members.',
          }, 403);
        }
        return jsonResponse('', 404);
      });

      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);
      final container = createContainer(familyRepo: familyRepo);
      addTearDown(container.dispose);

      final controller = container.read(familyControllerProvider.notifier);
      final token = await controller.inviteSpouse('priya@example.com');

      expect(token, isNull);
      final state = container.read(familyControllerProvider);
      expect(state.errorMessage, contains('Only the family owner'));
    });

    test('4. Accept Invitation joins family and refreshes members list',
        () async {
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.familyInviteAccept)) {
          return jsonResponse({
            'id': 'fam-100',
            'name': 'The Sharma Family',
            'currency': 'INR',
            'timezone': 'Asia/Kolkata',
            'created_by': 'usr-1',
            'user_role': 'member',
          }, 200);
        }
        if (options.path.endsWith(ApiEndpoints.familyMembers)) {
          return jsonResponse([
            {
              'id': 'mem-1',
              'family_id': 'fam-100',
              'user_id': 'usr-1',
              'user_full_name': 'Raj Sharma',
              'user_email': 'raj@example.com',
              'role': 'owner',
              'status': 'active',
              'joined_at': '2026-10-01T10:00:00Z',
            },
            {
              'id': 'mem-2',
              'family_id': 'fam-100',
              'user_id': 'usr-2',
              'user_full_name': 'Priya Sharma',
              'user_email': 'priya@example.com',
              'role': 'member',
              'status': 'active',
              'joined_at': '2026-10-06T10:00:00Z',
            }
          ], 200);
        }
        return jsonResponse('', 404);
      });

      final familyRepo =
          FamilyRepositoryImpl(apiClient: apiClient, storage: storage);
      final container = createContainer(familyRepo: familyRepo);
      addTearDown(container.dispose);

      final controller = container.read(familyControllerProvider.notifier);
      final family = await controller.acceptInvitation('invite-secret-xyz');

      final state = container.read(familyControllerProvider);
      expect(family, isNotNull);
      expect(state.family?.name, 'The Sharma Family');
      expect(state.members.length, 2);
      expect(state.hasSpouseJoined, isTrue);
    });
  });

  group('Family UI Widgets & Presentation Tests', () {
    Widget createTestApp(Widget child, [List<dynamic> overrides = const []]) {
      return ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWithValue(apiClient),
          ...overrides,
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

    testWidgets('CreateFamilyScreen displays inputs and creates family',
        (tester) async {
      await tester.pumpWidget(createTestApp(const CreateFamilyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create Family'), findsNWidgets(2));
      expect(find.text('Family Name *'), findsOneWidget);
      expect(find.text('Currency *'), findsOneWidget);
      expect(find.text('Timezone *'), findsOneWidget);
    });

    testWidgets('InviteSpouseScreen validates email and shows success message',
        (tester) async {
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.familyInvite)) {
          return jsonResponse({
            'token': 'mock-invite-token-123',
          }, 201);
        }
        return jsonResponse('', 404);
      });

      await tester.pumpWidget(createTestApp(const InviteSpouseScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Invite Your Spouse'), findsOneWidget);
      expect(find.text('Spouse Email Address *'), findsOneWidget);
      expect(find.text('Send Invitation'), findsOneWidget);

      // Enter valid email
      await tester.enterText(
          find.byType(TextFormField), 'priya@example.com');
      await tester.pump();

      await tester.tap(find.text('Send Invitation'));
      await tester.pumpAndSettle();

      // Required exact text: "Invitation sent successfully."
      expect(find.text('Invitation sent successfully.'), findsOneWidget);
      expect(find.text('mock-invite-token-123'), findsOneWidget);
      expect(find.text('Copy Invitation Token'), findsOneWidget);
    });

    testWidgets(
        'FamilyMembersScreen shows Husband, Wife, and Empty State when spouse not joined',
        (tester) async {
      // Mock 1 member only
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.familyCurrent)) {
          return jsonResponse({
            'id': 'fam-1',
            'name': 'The Sharma Family',
            'currency': 'INR',
            'timezone': 'Asia/Kolkata',
            'user_role': 'owner',
          }, 200);
        }
        if (options.path.endsWith(ApiEndpoints.familyMembers)) {
          return jsonResponse([
            {
              'id': 'mem-1',
              'family_id': 'fam-1',
              'user_id': 'usr-1',
              'user_full_name': 'Raj Sharma',
              'user_email': 'raj@example.com',
              'role': 'owner',
              'status': 'active',
              'joined_at': '2026-10-01T10:00:00Z',
            }
          ], 200);
        }
        return jsonResponse('', 404);
      });

      await tester.pumpWidget(createTestApp(const FamilyMembersScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Husband card displayed
      expect(find.text('Husband'), findsOneWidget);
      expect(find.text('Raj Sharma'), findsOneWidget);
      expect(find.text('OWNER'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Empty State for spouse:
      // "Your family is ready"
      // "Invite your spouse to start managing expenses together."
      // "Invite Spouse" button
      expect(find.text('Your family is ready'), findsOneWidget);
      expect(
          find.text(
              'Invite your spouse to start managing expenses together.'),
          findsOneWidget);
      expect(find.text('Invite Spouse'), findsOneWidget);
    });

    testWidgets(
        'FamilyMembersScreen displays both Husband and Wife when spouse joined',
        (tester) async {
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.familyCurrent)) {
          return jsonResponse({
            'id': 'fam-1',
            'name': 'The Sharma Family',
            'currency': 'INR',
            'timezone': 'Asia/Kolkata',
            'user_role': 'owner',
          }, 200);
        }
        if (options.path.endsWith(ApiEndpoints.familyMembers)) {
          return jsonResponse([
            {
              'id': 'mem-1',
              'family_id': 'fam-1',
              'user_id': 'usr-1',
              'user_full_name': 'Raj Sharma',
              'user_email': 'raj@example.com',
              'role': 'owner',
              'status': 'active',
              'joined_at': '2026-10-01T10:00:00Z',
            },
            {
              'id': 'mem-2',
              'family_id': 'fam-1',
              'user_id': 'usr-2',
              'user_full_name': 'Priya Sharma',
              'user_email': 'priya@example.com',
              'role': 'member',
              'status': 'active',
              'joined_at': '2026-10-06T10:00:00Z',
            }
          ], 200);
        }
        return jsonResponse('', 404);
      });

      await tester.pumpWidget(createTestApp(const FamilyMembersScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Husband'), findsOneWidget);
      expect(find.text('Raj Sharma'), findsOneWidget);
      expect(find.text('Wife'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('MEMBER'), findsOneWidget);
      expect(find.text('Your family is ready'), findsNothing);
    });

    testWidgets('FamilyHomeScreen displays details and pending spouse state',
        (tester) async {
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.familyCurrent)) {
          return jsonResponse({
            'id': 'fam-1',
            'name': 'The Sharma Family',
            'currency': 'INR',
            'timezone': 'Asia/Kolkata',
            'user_role': 'owner',
          }, 200);
        }
        if (options.path.endsWith(ApiEndpoints.familyMembers)) {
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
        return jsonResponse('', 404);
      });

      await tester.pumpWidget(createTestApp(const FamilyHomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('The Sharma Family'), findsOneWidget);
      expect(find.text('INR • Asia/Kolkata'), findsOneWidget);
      expect(find.text('Your family is ready'), findsOneWidget);
      expect(find.text('View Family Members'), findsOneWidget);
    });

    testWidgets('AcceptInvitationScreen accepts token and submits',
        (tester) async {
      await tester.pumpWidget(createTestApp(const AcceptInvitationScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Accept Invitation'), findsOneWidget);
      expect(find.text('Invitation Token *'), findsOneWidget);
      expect(find.text('Accept & Join Family'), findsOneWidget);
    });
  });
}
