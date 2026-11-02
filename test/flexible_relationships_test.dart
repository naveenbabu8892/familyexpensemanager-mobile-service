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
import 'package:mobile/features/family/domain/family.dart';
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

ResponseBody jsonResponse(dynamic data, int statusCode,
    {Map<String, List<String>>? headers}) {
  final h = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
    ...?headers,
  };
  final body = data is String ? data : jsonEncode(data);
  return ResponseBody.fromString(body, statusCode, headers: h);
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

  group('Flexible Family Relationships Domain & Repository Tests', () {
    test('1. RelationshipOption decodes value and label correctly', () {
      final json = {'value': 'mother', 'label': 'Mother'};
      final option = RelationshipOption.fromJson(json);
      expect(option.value, 'mother');
      expect(option.label, 'Mother');
    });

    test('2. FamilyMember decodes relationship and relationshipLabel correctly', () {
      final json = {
        'id': 'mem-10',
        'family_id': 'fam-1',
        'user_id': 'usr-10',
        'name': 'Sunita Sharma',
        'email': 'sunita@example.com',
        'role': 'member',
        'relationship': 'mother',
        'relationship_label': 'Mother',
        'status': 'active',
        'joined_at': '2026-10-06T12:00:00Z',
      };
      final member = FamilyMember.fromJson(json);
      expect(member.relationship, 'mother');
      expect(member.relationshipLabel, 'Mother');
      expect(member.fullName, 'Sunita Sharma');
      expect(member.isOwner, isFalse);
    });

    test('3. FamilyRepository.getRelationships fetches supported options from backend', () async {
      setMockAdapter((options) async {
        if (options.path.contains(ApiEndpoints.familyRelationships)) {
          return jsonResponse({
            'data': [
              {'value': 'husband', 'label': 'Husband'},
              {'value': 'wife', 'label': 'Wife'},
              {'value': 'father', 'label': 'Father'},
              {'value': 'mother', 'label': 'Mother'},
              {'value': 'brother', 'label': 'Brother'},
              {'value': 'other', 'label': 'Other'},
            ]
          }, 200);
        }
        return jsonResponse('', 404);
      });

      final repo = FamilyRepositoryImpl(apiClient: apiClient, storage: storage);
      final list = await repo.getRelationships();
      expect(list.length, 6);
      expect(list.map((e) => e.value), containsAll(['husband', 'wife', 'father', 'mother', 'brother', 'other']));
      expect(list.firstWhere((e) => e.value == 'mother').label, 'Mother');
    });

    test('4. FamilyRepository.inviteMember sends relationship in payload', () async {
      Map<String, dynamic>? capturedData;
      setMockAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.familyInvite)) {
          capturedData = options.data as Map<String, dynamic>;
          return jsonResponse({
            'token': 'invite-mother-token',
            'relationship': 'mother',
            'relationship_label': 'Mother',
          }, 201);
        }
        return jsonResponse('', 404);
      });

      final repo = FamilyRepositoryImpl(apiClient: apiClient, storage: storage);
      final token = await repo.inviteMember('mother@example.com', relationship: 'mother');
      expect(token, 'invite-mother-token');
      expect(capturedData?['invited_email'], 'mother@example.com');
      expect(capturedData?['relationship'], 'mother');
    });
  });

  group('Flexible Family Relationships Widget Tests', () {
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
            data: const MediaQueryData(size: Size(800, 1200)),
            child: Scaffold(body: child),
          ),
        ),
      );
    }

    testWidgets('InviteSpouseScreen supports selecting Mother relationship and sends invite', (tester) async {
      Map<String, dynamic>? invitePayload;
      setMockAdapter((options) async {
        if (options.path.contains(ApiEndpoints.familyRelationships)) {
          return jsonResponse({
            'data': [
              {'value': 'husband', 'label': 'Husband'},
              {'value': 'wife', 'label': 'Wife'},
              {'value': 'mother', 'label': 'Mother'},
              {'value': 'father', 'label': 'Father'},
              {'value': 'other', 'label': 'Other'},
            ]
          }, 200);
        }
        if (options.path.endsWith(ApiEndpoints.familyInvite)) {
          invitePayload = options.data as Map<String, dynamic>;
          return jsonResponse({
            'token': 'tok-mother-abc',
          }, 201);
        }
        return jsonResponse('', 404);
      });

      await tester.pumpWidget(createTestApp(const InviteSpouseScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Relationship *'), findsOneWidget);

      // Enter email
      await tester.enterText(find.byType(TextFormField).first, 'mom@example.com');
      await tester.pump();

      // Open Dropdown and choose Mother
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Mother').last, findsOneWidget);
      await tester.tap(find.text('Mother').last);
      await tester.pumpAndSettle();

      // Tap Send Invitation
      await tester.tap(find.text('Send Invitation'));
      await tester.pumpAndSettle();

      expect(find.text('Invitation sent successfully.'), findsOneWidget);
      expect(find.text('tok-mother-abc'), findsOneWidget);
      expect(invitePayload?['relationship'], 'mother');
      expect(invitePayload?['invited_email'], 'mom@example.com');
    });

    testWidgets('FamilyMembersScreen displays arbitrary relationships prominently with role badges', (tester) async {
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
              'name': 'Raj Sharma',
              'email': 'raj@example.com',
              'role': 'owner',
              'relationship': 'father',
              'relationship_label': 'Father',
              'status': 'active',
              'joined_at': '2026-10-01T10:00:00Z',
            },
            {
              'id': 'mem-2',
              'family_id': 'fam-1',
              'user_id': 'usr-2',
              'name': 'Sunita Sharma',
              'email': 'sunita@example.com',
              'role': 'member',
              'relationship': 'mother',
              'relationship_label': 'Mother',
              'status': 'active',
              'joined_at': '2026-10-02T10:00:00Z',
            },
            {
              'id': 'mem-3',
              'family_id': 'fam-1',
              'user_id': 'usr-3',
              'name': 'Amit Sharma',
              'email': 'amit@example.com',
              'role': 'member',
              'relationship': 'son',
              'relationship_label': 'Son',
              'status': 'active',
              'joined_at': '2026-10-03T10:00:00Z',
            },
          ], 200);
        }
        return jsonResponse('', 404);
      });

      await tester.pumpWidget(createTestApp(const FamilyMembersScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify each member and their prominent relationship
      expect(find.text('Father'), findsOneWidget);
      expect(find.text('Raj Sharma'), findsOneWidget);
      expect(find.text('OWNER'), findsOneWidget);

      expect(find.text('Mother'), findsOneWidget);
      expect(find.text('Sunita Sharma'), findsOneWidget);

      expect(find.text('Son'), findsOneWidget);
      expect(find.text('Amit Sharma'), findsOneWidget);

      // Verify two MEMBER badges for the other two
      expect(find.text('MEMBER'), findsNWidgets(2));
    });
  });
}
