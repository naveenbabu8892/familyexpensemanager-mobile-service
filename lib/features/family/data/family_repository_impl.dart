import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/family.dart';
import '../domain/family_repository.dart';

/// Concrete implementation of [FamilyRepository] consuming FastAPI endpoints.
class FamilyRepositoryImpl implements FamilyRepository {
  final ApiClient apiClient;
  final SecureStorageService storage;

  FamilyRepositoryImpl({
    required this.apiClient,
    required this.storage,
  });

  @override
  Future<Family?> getCurrentFamily() async {
    try {
      final response = await apiClient.get(ApiEndpoints.familyCurrent);
      final family = Family.fromJson(response.data as Map<String, dynamic>);
      await storage.setActiveFamilyId(family.id);
      return family;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Family> createFamily({
    required String name,
    String currency = 'USD',
    String timezone = 'UTC',
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.families,
      data: {
        'name': name.trim(),
        'currency': currency,
        'timezone': timezone,
      },
    );
    final family = Family.fromJson(response.data as Map<String, dynamic>);
    await storage.setActiveFamilyId(family.id);
    return family;
  }

  @override
  Future<Family> updateCurrentFamily({
    String? name,
    String? currency,
    String? timezone,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name.trim();
    if (currency != null) payload['currency'] = currency;
    if (timezone != null) payload['timezone'] = timezone;

    final response = await apiClient.put(
      ApiEndpoints.familyCurrent,
      data: payload,
    );
    return Family.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<String> inviteMember(String email, {String relationship = 'other'}) async {
    final response = await apiClient.post(
      ApiEndpoints.familyInvite,
      data: {
        'invited_email': email.trim().toLowerCase(),
        'relationship': relationship.trim().toLowerCase(),
      },
    );
    final map = response.data as Map<String, dynamic>;
    return (map['token'] ?? map['invitation_code'] ?? map['invite_token']) as String;
  }

  @override
  Future<Family> acceptInvitation(String token) async {
    final response = await apiClient.post(
      ApiEndpoints.familyInviteAccept,
      data: {'token': token.trim()},
    );
    final family = Family.fromJson(response.data as Map<String, dynamic>);
    await storage.setActiveFamilyId(family.id);
    return family;
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    final response = await apiClient.get(ApiEndpoints.familyMembers);
    final list = response.data as List;
    return list
        .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<RelationshipOption>> getRelationships() async {
    final response = await apiClient.get(ApiEndpoints.familyRelationships);
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data
        .map((e) => RelationshipOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Riverpod provider for [FamilyRepository].
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

/// Riverpod FutureProvider for current family.
final currentFamilyProvider = FutureProvider<Family?>((ref) async {
  return ref.watch(familyRepositoryProvider).getCurrentFamily();
});

/// Riverpod FutureProvider for family relationship options.
final familyRelationshipsProvider = FutureProvider<List<RelationshipOption>>((ref) async {
  return ref.watch(familyRepositoryProvider).getRelationships();
});
