import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/family_repository_impl.dart';
import '../domain/family.dart';
import '../domain/family_repository.dart';

enum FamilyStatus {
  initial,
  loading,
  loaded,
  error,
}

class FamilyState {
  final FamilyStatus status;
  final Family? family;
  final List<FamilyMember> members;
  final String? errorMessage;
  final String? lastInviteToken;

  const FamilyState({
    required this.status,
    this.family,
    this.members = const [],
    this.errorMessage,
    this.lastInviteToken,
  });

  const FamilyState.initial() : this(status: FamilyStatus.initial);
  const FamilyState.loading({Family? currentFamily, List<FamilyMember> currentMembers = const []})
      : this(
          status: FamilyStatus.loading,
          family: currentFamily,
          members: currentMembers,
        );

  bool get isLoading => status == FamilyStatus.loading;
  bool get isLoaded => status == FamilyStatus.loaded;
  bool get isError => status == FamilyStatus.error;

  bool get hasFamily => family != null;
  bool get hasSpouseJoined => members.length > 1;

  bool get isOwner => family?.userRole?.toLowerCase() == 'owner';

  FamilyState copyWith({
    FamilyStatus? status,
    Family? family,
    List<FamilyMember>? members,
    String? errorMessage,
    String? lastInviteToken,
    bool clearError = false,
  }) {
    return FamilyState(
      status: status ?? this.status,
      family: family ?? this.family,
      members: members ?? this.members,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastInviteToken: lastInviteToken ?? this.lastInviteToken,
    );
  }
}

/// Riverpod NotifierProvider managing family state and actions.
final familyControllerProvider =
    NotifierProvider<FamilyController, FamilyState>(() {
  return FamilyController();
});

class FamilyController extends Notifier<FamilyState> {
  FamilyRepository get _familyRepo => ref.read(familyRepositoryProvider);

  @override
  FamilyState build() {
    return const FamilyState.initial();
  }

  /// Loads current family details and its active members.
  Future<void> loadFamilyData() async {
    state = FamilyState.loading(
      currentFamily: state.family,
      currentMembers: state.members,
    );

    try {
      final family = await _familyRepo.getCurrentFamily();
      if (family == null) {
        state = const FamilyState(
          status: FamilyStatus.loaded,
          family: null,
          members: [],
        );
        return;
      }

      List<FamilyMember> members = [];
      try {
        members = await _familyRepo.getFamilyMembers();
      } catch (e) {
        // Fallback: if members endpoint has issue, still keep family loaded
        members = [];
      }

      state = FamilyState(
        status: FamilyStatus.loaded,
        family: family,
        members: members,
      );

      // Keep AuthState updated as well
      ref.read(authControllerProvider.notifier).setFamily(family);
    } on ApiException catch (e) {
      state = FamilyState(
        status: FamilyStatus.error,
        family: state.family,
        members: state.members,
        errorMessage: e.message,
      );
    } catch (e) {
      state = FamilyState(
        status: FamilyStatus.error,
        family: state.family,
        members: state.members,
        errorMessage: 'Failed to load family information. Please try again.',
      );
    }
  }

  /// Create a new family household.
  Future<Family?> createFamily({
    required String name,
    required String currency,
    required String timezone,
  }) async {
    state = FamilyState.loading(
      currentFamily: state.family,
      currentMembers: state.members,
    );

    try {
      final family = await _familyRepo.createFamily(
        name: name,
        currency: currency,
        timezone: timezone,
      );

      ref.read(authControllerProvider.notifier).setFamily(family);

      // Load members for new family
      final members = await _familyRepo.getFamilyMembers();

      state = FamilyState(
        status: FamilyStatus.loaded,
        family: family,
        members: members,
      );
      return family;
    } on ApiException catch (e) {
      state = FamilyState(
        status: FamilyStatus.error,
        family: state.family,
        members: state.members,
        errorMessage: e.message,
      );
      return null;
    } catch (_) {
      state = FamilyState(
        status: FamilyStatus.error,
        family: state.family,
        members: state.members,
        errorMessage: 'Failed to create family. Please check your network.',
      );
      return null;
    }
  }

  /// Update family settings (Requires owner authorization on backend).
  Future<bool> updateFamilySettings({
    String? name,
    String? currency,
    String? timezone,
  }) async {
    try {
      final updated = await _familyRepo.updateCurrentFamily(
        name: name,
        currency: currency,
        timezone: timezone,
      );

      ref.read(authControllerProvider.notifier).setFamily(updated);
      state = state.copyWith(
        family: updated,
        clearError: true,
      );
      return true;
    } on ForbiddenException catch (e) {
      // Backend authorization failure: gracefully inform the user
      state = state.copyWith(
        errorMessage: e.message.isNotEmpty
            ? e.message
            : 'Only the family owner has permission to update family settings.',
      );
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'An unexpected error occurred while updating family settings.',
      );
      return false;
    }
  }

  /// Send an invitation to a family member with their relationship (Requires owner authorization).
  Future<String?> inviteMember(String email, {String relationship = 'other'}) async {
    try {
      final token = await _familyRepo.inviteMember(email.trim(), relationship: relationship);
      state = state.copyWith(
        lastInviteToken: token,
        clearError: true,
      );
      return token;
    } on ForbiddenException catch (e) {
      // Backend authorization: non-owners cannot invite
      state = state.copyWith(
        errorMessage: e.message.isNotEmpty
            ? e.message
            : 'Only the family owner can invite new members.',
      );
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Failed to send invitation. Please try again.',
      );
      return null;
    }
  }

  /// Backward-compatible alias for inviteMember
  Future<String?> inviteSpouse(String email, {String relationship = 'wife'}) async {
    return inviteMember(email, relationship: relationship);
  }

  /// Accept an invitation to join an existing family.
  Future<Family?> acceptInvitation(String token) async {
    state = FamilyState.loading(
      currentFamily: state.family,
      currentMembers: state.members,
    );

    try {
      final family = await _familyRepo.acceptInvitation(token.trim());
      ref.read(authControllerProvider.notifier).setFamily(family);

      final members = await _familyRepo.getFamilyMembers();

      state = FamilyState(
        status: FamilyStatus.loaded,
        family: family,
        members: members,
      );
      return family;
    } on ApiException catch (e) {
      state = FamilyState(
        status: FamilyStatus.error,
        family: state.family,
        members: state.members,
        errorMessage: e.message,
      );
      return null;
    } catch (_) {
      state = FamilyState(
        status: FamilyStatus.error,
        family: state.family,
        members: state.members,
        errorMessage: 'Invalid or expired invitation token.',
      );
      return null;
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}
