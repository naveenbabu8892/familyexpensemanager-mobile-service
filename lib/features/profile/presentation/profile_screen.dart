import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/preferences_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/vintage_button.dart';
import '../../../core/widgets/vintage_card.dart';
import '../../../core/widgets/vintage_text_field.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/change_password_dialog.dart';
import 'profile_controller.dart';

/// User Profile and Application Settings screen.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Preset avatars for vintage aesthetic
  static const List<String> _avatarPresets = [
    '☕', '🌿', '📖', '🏡', '💼', '🎨', '🚲', '🕰️', '🌻', '🥧'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadProfile();
    });
  }

  Future<void> _checkAndLoadProfile() async {
    final authState = ref.read(authStateProvider);
    if (authState.user == null) {
      final updatedState =
          await ref.read(authControllerProvider.notifier).checkAuthStatus();
      if (!mounted) return;
      if (!updatedState.isAuthenticated) {
        try {
          context.go('/login');
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(profileControllerProvider);
    final preferences = ref.watch(preferencesControllerProvider);
    final preferencesNotifier = ref.read(preferencesControllerProvider.notifier);

    final user = authState.user;
    final family = authState.family;

    if (authState.isLoading && user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Profile & Settings',
            style: TextStyle(
              color: AppColors.dark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: const Center(
          child: LoadingState(message: 'Checking your profile...'),
        ),
      );
    }

    final userName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Family Member';
    final userEmail = user?.email.isNotEmpty == true ? user!.email : 'member@example.com';
    final userPhone = user?.phone ?? '';
    final avatar = user?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile & Settings',
          style: TextStyle(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => _showEditProfileDialog(context, userName, userPhone, avatar),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          final updatedState =
              await ref.read(authControllerProvider.notifier).checkAuthStatus();
          if (!context.mounted) return;
          if (!updatedState.isAuthenticated) {
            try {
              context.go('/login');
            } catch (_) {}
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
          // Banner for status feedback
          if (profileState.successMessage != null) ...[
            _buildFeedbackBanner(
              message: profileState.successMessage!,
              isError: false,
              onDismiss: () => ref.read(profileControllerProvider.notifier).clearMessages(),
            ),
            const SizedBox(height: 12),
          ],
          if (profileState.errorMessage != null) ...[
            _buildFeedbackBanner(
              message: profileState.errorMessage!,
              isError: true,
              onDismiss: () => ref.read(profileControllerProvider.notifier).clearMessages(),
            ),
            const SizedBox(height: 12),
          ],

          // 1. Profile Card
          VintageCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            avatar != null && avatar.isNotEmpty
                                ? avatar
                                : _getInitials(userName),
                            style: TextStyle(
                              color: avatar != null && avatar.isNotEmpty
                                  ? AppColors.dark
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: avatar != null && avatar.isNotEmpty ? 28 : 20,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _showAvatarPicker(context, avatar),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  userEmail,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (userPhone.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  userPhone,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        family?.userRole != null
                            ? 'Role: ${family!.userRole!.toUpperCase()}'
                            : 'Personal Account',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditProfileDialog(context, userName, userPhone, avatar),
                      icon: const Icon(Icons.edit, size: 15, color: AppColors.primary),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Settings Section
          _buildSectionHeader('Preferences'),
          const SizedBox(height: 8),
          VintageCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Currency Selector
                ListTile(
                  leading: const Icon(Icons.payments_outlined, color: AppColors.primary),
                  title: const Text('Currency', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${preferences.currency.label} (${preferences.currency.symbol})'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => _showCurrencyPicker(context, preferences.currency, preferencesNotifier),
                ),
                const Divider(height: 1, color: AppColors.border),
                // Notifications Toggle
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined, color: AppColors.mutedGold),
                  title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    preferences.notificationsEnabled
                        ? 'Reminders & alerts enabled'
                        : 'Notifications turned off',
                  ),
                  value: preferences.notificationsEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => preferencesNotifier.setNotificationsEnabled(val),
                ),
                const Divider(height: 1, color: AppColors.border),
                // Theme Mode Selector
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: AppColors.olive),
                  title: const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_getThemeTitle(preferences.themeMode)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => _showThemePicker(context, preferences.themeMode, preferencesNotifier),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Family Space Section
          _buildSectionHeader('Family Hub'),
          const SizedBox(height: 8),
          VintageCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.family_restroom_rounded, color: AppColors.primary),
                  title: const Text('Family Space', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(family?.name ?? 'Manage family group'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => context.push('/family'),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.group_outlined, color: AppColors.secondary),
                  title: const Text('Family Members', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Manage members & roles'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => context.push('/family/members'),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.terracotta),
                  title: const Text('Invite Spouse / Partner', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Send invitation to join family space'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => context.push('/family/invite'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Security Section
          _buildSectionHeader('Security'),
          const SizedBox(height: 8),
          VintageCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded, color: AppColors.terracotta),
                  title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Update account login password'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => ChangePasswordDialog.show(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Information & Legal
          _buildSectionHeader('Information'),
          const SizedBox(height: 8),
          VintageCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  title: const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('App version & developer details'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.olive),
                  title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('How your data is kept secure'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => _showPrivacyPolicyDialog(context),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.mutedGold),
                  title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Usage terms and conditions'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => _showTermsDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 6. Logout Button
          OutlinedButton.icon(
            key: const Key('logout_button'),
            onPressed: () => _showLogoutConfirmation(context),
            icon: const Icon(Icons.logout_rounded, color: AppColors.terracotta),
            label: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.terracotta,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.terracotta.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: AppColors.dark,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildFeedbackBanner({
    required String message,
    required bool isError,
    required VoidCallback onDismiss,
  }) {
    final color = isError ? AppColors.terracotta : AppColors.olive;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 18, color: color),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    return name
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join()
        .toUpperCase();
  }

  String _getThemeTitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default (Vintage)';
      case ThemeMode.light:
        return 'Vintage Light (Warm Ivory)';
      case ThemeMode.dark:
        return 'Vintage Dark (Deep Mocha)';
    }
  }

  // --- Profile Edit Dialog ---
  void _showEditProfileDialog(
    BuildContext context,
    String initialName,
    String initialPhone,
    String? currentAvatar,
  ) {
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController(text: initialPhone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isSaving = ref.watch(profileControllerProvider).isSaving;

          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Edit Profile',
              style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VintageTextField(
                      controller: nameController,
                      label: 'Full Name',
                      hint: 'Enter your name',
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    VintageTextField(
                      controller: phoneController,
                      label: 'Phone Number',
                      hint: '+91 9876543210',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              VintageButton(
                text: 'Save',
                isFullWidth: false,
                isLoading: isSaving,
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final success = await ref.read(profileControllerProvider.notifier).updateProfile(
                        fullName: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        avatarUrl: currentAvatar,
                      );
                  if (success && ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Avatar Picker Dialog ---
  void _showAvatarPicker(BuildContext context, String? currentAvatar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Avatar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select an icon or avatar representation for your profile.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatarPresets.map((avatarEmoji) {
                final isSelected = currentAvatar == avatarEmoji;
                return InkWell(
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ref.read(profileControllerProvider.notifier).updateProfile(
                          avatarUrl: avatarEmoji,
                        );
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      avatarEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // --- Currency Picker ---
  void _showCurrencyPicker(
    BuildContext context,
    AppCurrency selectedCurrency,
    PreferencesController notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Currency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ),
            ...AppCurrency.values.map(
              (c) => InkWell(
                onTap: () {
                  notifier.setCurrency(c);
                  Navigator.of(ctx).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${c.label} (${c.symbol})',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            Text(
                              c.code,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (selectedCurrency == c)
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      else
                        const Icon(Icons.radio_button_unchecked, color: AppColors.secondaryBeige),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // --- Theme Picker ---
  void _showThemePicker(
    BuildContext context,
    ThemeMode selectedMode,
    PreferencesController notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Appearance & Theme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ),
            _buildThemeOption(
              ctx,
              'System Default',
              'Matches system settings with warm ivory tone',
              ThemeMode.system,
              selectedMode,
              notifier,
            ),
            _buildThemeOption(
              ctx,
              'Light Theme',
              'Ivory background and warm espresso contrast',
              ThemeMode.light,
              selectedMode,
              notifier,
            ),
            _buildThemeOption(
              ctx,
              'Dark Theme',
              'Deep espresso styling',
              ThemeMode.dark,
              selectedMode,
              notifier,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext ctx,
    String title,
    String subtitle,
    ThemeMode mode,
    ThemeMode current,
    PreferencesController notifier,
  ) {
    final isSelected = mode == current;
    return InkWell(
      onTap: () {
        notifier.setThemeMode(mode);
        Navigator.of(ctx).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary)
            else
              const Icon(Icons.radio_button_unchecked, color: AppColors.secondaryBeige),
          ],
        ),
      ),
    );
  }

  // --- About Dialog ---
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.family_restroom, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text(
              'About',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.appName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark),
            ),
            const SizedBox(height: 4),
            Text(
              'Version ${AppConstants.appVersion}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Text(
              'A beautifully crafted collaborative personal finance companion designed for couples and modern families. Track shared expenses, manage combined budgets, and organize household financial health with ease.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.dark),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // --- Privacy Policy Dialog ---
  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your privacy is our core principle. Family Expense Manager encrypts sensitive authentication tokens and ensures only verified household members have access to shared budgeting and transaction logs.\n\n'
                '• Data Isolation: Family data is partitioned and protected with role-based policies.\n'
                '• Encryption: Stored securely using hardware-backed secure storage.\n'
                '• Zero Marketing: We do not sell or monetize personal financial entries.',
                style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.dark),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // --- Terms of Service Dialog ---
  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Terms of Service',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'By using Family Expense Manager, you agree to:\n\n'
                '1. Accept responsibility for account credentials and secure password choices.\n'
                '2. Use the application for personal and household financial organization.\n'
                '3. Avoid unauthorized access attempts to other households or API endpoints.',
                style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.dark),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('I Agree', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // --- Logout Confirmation Dialog ---
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
        ),
        content: const Text(
          'Are you sure you want to sign out of Family Expense Manager?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            key: const Key('confirm_logout_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                try {
                  context.go('/login');
                } catch (_) {
                  // In isolated widget tests without GoRouter root, router isn't attached
                }
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
