import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vintage_button.dart';
import '../../../core/widgets/vintage_card.dart';
import '../../../core/widgets/vintage_text_field.dart';
import 'family_controller.dart';

/// Screen allowing an authenticated user to create a new family space.
class CreateFamilyScreen extends ConsumerStatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  ConsumerState<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends ConsumerState<CreateFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCurrency = 'INR';
  String _selectedTimezone = 'Asia/Kolkata';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateFamily() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final family = await ref.read(familyControllerProvider.notifier).createFamily(
          name: _nameController.text.trim(),
          currency: _selectedCurrency,
          timezone: _selectedTimezone,
        );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (family != null) {
      // Prompt requirement: "After creation: Navigate to Family Home."
      context.go('/family');
    } else {
      final stateError = ref.read(familyControllerProvider).errorMessage;
      setState(() {
        _errorMessage = stateError ?? 'Failed to create family. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Create Family',
          style: TextStyle(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Emblem
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.add_home_work_rounded,
                        color: AppColors.primary,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Establish Your Household',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create a shared space to manage income, budgets, and expenses with your spouse.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error notification if creation fails
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.terracotta.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.terracotta, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.terracotta,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Form Container inside VintageCard
                  VintageCard(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Family Name
                          VintageTextField(
                            controller: _nameController,
                            label: 'Family Name *',
                            hint: 'e.g. The Sharma Family',
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(
                              Icons.home_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Family name is required';
                              }
                              if (val.trim().length < 2) {
                                return 'Family name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // 2. Currency Selector
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Currency *',
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
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'INR', child: Text('INR (₹) - Indian Rupee')),
                                  DropdownMenuItem(
                                      value: 'USD', child: Text('USD (\$) - US Dollar')),
                                  DropdownMenuItem(
                                      value: 'EUR', child: Text('EUR (€) - Euro')),
                                  DropdownMenuItem(
                                      value: 'GBP', child: Text('GBP (£) - British Pound')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCurrency = val);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 3. Timezone Selector
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Timezone *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 7),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedTimezone,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Asia/Kolkata',
                                      child: Text('Asia/Kolkata (IST)')),
                                  DropdownMenuItem(
                                      value: 'UTC', child: Text('UTC (Universal)')),
                                  DropdownMenuItem(
                                      value: 'America/New_York',
                                      child: Text('America/New_York (EST)')),
                                  DropdownMenuItem(
                                      value: 'Europe/London',
                                      child: Text('Europe/London (GMT)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedTimezone = val);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          VintageButton(
                            text: 'Create Family',
                            isLoading: _isSubmitting,
                            icon: Icons.check_circle_outline_rounded,
                            onPressed: _handleCreateFamily,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
