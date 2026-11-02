import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/vintage_button.dart';
import '../../../core/widgets/vintage_card.dart';
import '../../../core/widgets/vintage_text_field.dart';
import '../domain/family.dart';
import 'family_controller.dart';

/// Central dashboard for managing the active family household.
class FamilyHomeScreen extends ConsumerStatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  ConsumerState<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends ConsumerState<FamilyHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyControllerProvider.notifier).loadFamilyData();
    });
  }

  void _openEditFamilyDialog(Family family) {
    final nameController = TextEditingController(text: family.name);
    String selectedCurrency = family.currency;
    String selectedTimezone = family.timezone;
    bool isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Family Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (dialogError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dialogError!,
                      style: const TextStyle(
                        color: AppColors.terracotta,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                VintageTextField(
                  controller: nameController,
                  label: 'Family Name',
                  hint: 'Enter family name',
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedCurrency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: const [
                    DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                    DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                    DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCurrency = val);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedTimezone,
                  decoration: const InputDecoration(labelText: 'Timezone'),
                  items: const [
                    DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata')),
                    DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                    DropdownMenuItem(value: 'America/New_York', child: Text('New York')),
                    DropdownMenuItem(value: 'Europe/London', child: Text('London')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedTimezone = val);
                  },
                ),
                const SizedBox(height: 20),
                VintageButton(
                  text: 'Save Changes',
                  isLoading: isSaving,
                  onPressed: () async {
                    setDialogState(() => isSaving = true);
                    final success = await ref
                        .read(familyControllerProvider.notifier)
                        .updateFamilySettings(
                          name: nameController.text.trim(),
                          currency: selectedCurrency,
                          timezone: selectedTimezone,
                        );

                    if (!mounted) return;

                    if (success) {
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }
                    } else {
                      final stateError =
                          ref.read(familyControllerProvider).errorMessage;
                      setDialogState(() {
                        isSaving = false;
                        dialogError = stateError ?? 'Update failed.';
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyControllerProvider);
    final family = familyState.family;
    final members = familyState.members;
    final spouseJoined = members.length > 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Family Space',
          style: TextStyle(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (family != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
              tooltip: 'Family Settings',
              onPressed: () => _openEditFamilyDialog(family),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              ref.read(familyControllerProvider.notifier).loadFamilyData(),
          child: familyState.isLoading && family == null
              ? const LoadingState(message: 'Loading family details...')
              : family == null
                  ? _buildNoFamilyView()
                  : _buildFamilyHomeContent(family, members, spouseJoined),
        ),
      ),
    );
  }

  Widget _buildFamilyHomeContent(
      Family family, List<FamilyMember> members, bool spouseJoined) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      children: [
        // 1. Family Hero Card
        VintageCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${family.currency} • ${family.timezone}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // User Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.olive.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (family.userRole ?? 'MEMBER').toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.olive,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Spouse Status: Either members overview or Empty State
        if (!spouseJoined) ...[
          _buildSpousePendingCard(),
        ] else ...[
          _buildMembersSummaryCard(members),
        ],
        const SizedBox(height: 24),

        // 3. Quick Action Hub
        const Text(
          'Family Hub Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 10),
        VintageCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.group_outlined, color: AppColors.primary),
                  title: const Text('View Family Members',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${members.length} members connected'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/family/members'),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined,
                      color: AppColors.terracotta),
                  title: const Text('Invite Spouse',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Send secure invitation token via email'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/family/invite'),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined,
                      color: AppColors.mutedGold),
                  title: const Text('Join Another Family',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Enter an invitation token to switch'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/family/accept-invite'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Empty state when spouse has not joined yet
  Widget _buildSpousePendingCard() {
    return VintageCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.terracotta.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_add_rounded,
              color: AppColors.terracotta,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
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
            'Invite your spouse to start managing expenses together.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          VintageButton(
            text: 'Invite Spouse',
            icon: Icons.send_rounded,
            onPressed: () => context.push('/family/invite'),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSummaryCard(List<FamilyMember> members) {
    return VintageCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Husband & Wife Connected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/family/members'),
                child: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: members.take(2).map((m) {
              final initials = (m.fullName != null && m.fullName!.isNotEmpty)
                  ? m.fullName!.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                  : 'U';
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: m.isOwner ? AppColors.primary : AppColors.secondaryBeige,
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: m.isOwner ? Colors.white : AppColors.dark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.fullName ?? 'Member',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              m.role.toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFamilyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.holiday_village_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Family',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a new family household or accept an invitation from your spouse.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            VintageButton(
              text: 'Create Family',
              onPressed: () => context.push('/family/create'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/family/accept-invite'),
              child: const Text('Join with Token'),
            ),
          ],
        ),
      ),
    );
  }
}
