import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vintage_button.dart';
import '../../../core/widgets/vintage_card.dart';
import '../../../core/widgets/vintage_text_field.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/family_repository_impl.dart';

/// Screen displayed when an authenticated user has not created or joined a family yet.
class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Create Family Form
  final _createFormKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  String _selectedCurrency = 'INR';
  String _selectedTimezone = 'Asia/Kolkata';
  bool _isCreating = false;

  // Join Family Form
  final _joinFormKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _isJoining = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _familyNameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateFamily() async {
    if (!(_createFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final familyRepo = ref.read(familyRepositoryProvider);
      final family = await familyRepo.createFamily(
        name: _familyNameController.text.trim(),
        currency: _selectedCurrency,
        timezone: _selectedTimezone,
      );

      ref.read(authControllerProvider.notifier).setFamily(family);

      if (mounted) {
        context.go('/home');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to create family. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _handleJoinFamily() async {
    if (!(_joinFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final familyRepo = ref.read(familyRepositoryProvider);
      final family = await familyRepo.acceptInvitation(_tokenController.text.trim());

      ref.read(authControllerProvider.notifier).setFamily(family);

      if (mounted) {
        context.go('/home');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Invalid or expired invitation token.');
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.fullName ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Family Setup',
          style: TextStyle(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Text(
                'Welcome, $userName!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'To get started with expense tracking, create your family space or accept an invitation from your spouse.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Error display
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.terracotta.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.terracotta, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tab Selector
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondaryBeige.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: AppColors.dark,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Create Family'),
                    Tab(text: 'Join with Token'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab Views
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCreateTab(),
                    _buildJoinTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return VintageCard(
      child: Form(
        key: _createFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Up New Family',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'You will become the family OWNER and can invite your spouse.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            VintageTextField(
              controller: _familyNameController,
              label: 'Family Name',
              hint: 'e.g. The Sharma Family',
              prefixIcon: const Icon(Icons.home_outlined, color: AppColors.textSecondary, size: 20),
              validator: (val) {
                if (val == null || val.trim().length < 2) {
                  return 'Please enter a family name (at least 2 chars)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Currency',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCurrency,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                          DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                          DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCurrency = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Timezone',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTimezone,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata')),
                          DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                          DropdownMenuItem(value: 'America/New_York', child: Text('New York')),
                          DropdownMenuItem(value: 'Europe/London', child: Text('London')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedTimezone = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            VintageButton(
              text: 'Create Family',
              isLoading: _isCreating,
              icon: Icons.add_home_rounded,
              onPressed: _handleCreateFamily,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinTab() {
    return VintageCard(
      child: Form(
        key: _joinFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Join Existing Family',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Paste the secure invitation token shared by your spouse.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            VintageTextField(
              controller: _tokenController,
              label: 'Invitation Token',
              hint: 'Paste invitation token here',
              prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.textSecondary, size: 20),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter the invitation token';
                }
                return null;
              },
            ),
            const Spacer(),
            VintageButton(
              text: 'Accept & Join Family',
              isLoading: _isJoining,
              icon: Icons.group_add_rounded,
              onPressed: _handleJoinFamily,
            ),
          ],
        ),
      ),
    );
  }
}
