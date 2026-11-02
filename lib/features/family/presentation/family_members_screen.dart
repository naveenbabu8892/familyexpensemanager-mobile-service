import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/vintage_button.dart';
import '../../../core/widgets/vintage_card.dart';
import '../domain/family.dart';
import 'family_controller.dart';

/// Screen displaying the list of family members with relationships prominently shown.
class FamilyMembersScreen extends ConsumerStatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  ConsumerState<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends ConsumerState<FamilyMembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyControllerProvider.notifier).loadFamilyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyControllerProvider);
    final members = familyState.members;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Family Members',
          style: TextStyle(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
            tooltip: 'Invite Family Member',
            onPressed: () => context.push('/family/invite'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(familyControllerProvider.notifier).loadFamilyData(),
          child: familyState.isLoading && members.isEmpty
              ? const LoadingState(message: 'Loading family members...')
              : _buildContent(familyState, members),
        ),
      ),
    );
  }

  Widget _buildContent(FamilyState state, List<FamilyMember> members) {
    final bool singleMember = members.length <= 1;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      children: [
        // Subtitle header
        Text(
          state.family?.name ?? 'Household Members',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Shared expense tracking and budgeting for your family.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),

        // Display all members dynamically
        for (int i = 0; i < members.length; i++) ...[
          _buildMemberCard(
            member: members[i],
            fallbackLabel: i == 0 ? 'Husband' : (i == 1 ? 'Wife' : 'Member'),
            icon: _getRelationshipIcon(members[i].relationship),
          ),
          const SizedBox(height: 14),
        ],

        // Empty state when only owner is present
        if (singleMember) ...[
          const SizedBox(height: 12),
          _buildSpousePendingEmptyState(),
        ],
      ],
    );
  }

  IconData _getRelationshipIcon(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'husband':
      case 'father':
      case 'brother':
      case 'son':
      case 'grandfather':
      case 'grandson':
      case 'uncle':
        return Icons.face_rounded;
      case 'wife':
      case 'mother':
      case 'sister':
      case 'daughter':
      case 'grandmother':
      case 'granddaughter':
      case 'aunt':
        return Icons.face_3_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Widget _buildMemberCard({
    required FamilyMember member,
    required String fallbackLabel,
    required IconData icon,
  }) {
    final initials = (member.fullName != null && member.fullName!.isNotEmpty)
        ? member.fullName!.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    final joinedText = member.joinedAt != null
        ? 'Joined ${DateFormatter.formatDisplay(member.joinedAt!)}'
        : 'Active Member';

    // Highlight relationship prominently, using fallback if not set/other
    final displayRelationship = (member.relationship != 'other' && member.relationshipLabel.isNotEmpty)
        ? member.relationshipLabel
        : fallbackLabel;

    return VintageCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header label: Relationship is visually primary
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                displayRelationship,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              // Role badge (OWNER / MEMBER)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: member.isOwner
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.mutedGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  member.role.toUpperCase(),
                  style: TextStyle(
                    color: member.isOwner ? AppColors.primary : AppColors.dark,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Member Profile Row
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: member.isOwner ? AppColors.primary : AppColors.secondaryBeige,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: member.isOwner ? Colors.white : AppColors.dark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName ?? 'Family Member',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (member.email != null)
                      Text(
                        member.email!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 6),

                    // Joined date & Online/active indicator
                    Row(
                      children: [
                        // Online / active status dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: member.isActive ? AppColors.olive : AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          member.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: member.isActive ? AppColors.olive : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '•',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          joinedText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Empty state when other family members have not joined yet
  Widget _buildSpousePendingEmptyState() {
    return VintageCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.terracotta.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_add_rounded,
              color: AppColors.terracotta,
              size: 40,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your family is ready',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Invite your spouse to start managing expenses together.', // Preserves backwards compatibility test finder
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          VintageButton(
            text: 'Invite Spouse',
            icon: Icons.send_rounded,
            onPressed: () => context.push('/family/invite'),
          ),
        ],
      ),
    );
  }
}
