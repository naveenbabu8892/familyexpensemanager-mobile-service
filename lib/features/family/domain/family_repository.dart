import 'family.dart';

/// Abstract contract for Family repository.
abstract class FamilyRepository {
  Future<Family?> getCurrentFamily();
  Future<Family> createFamily({
    required String name,
    String currency = 'USD',
    String timezone = 'UTC',
  });
  Future<Family> updateCurrentFamily({
    String? name,
    String? currency,
    String? timezone,
  });
  Future<String> inviteMember(String email, {String relationship = 'other'});
  Future<Family> acceptInvitation(String token);
  Future<List<FamilyMember>> getFamilyMembers();
  Future<List<RelationshipOption>> getRelationships();
}
