import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vintage_button.dart';
import '../../../core/widgets/vintage_card.dart';
import '../../../core/widgets/vintage_text_field.dart';
import 'auth_controller.dart';

/// Screen for creating a new user account with complete field validations and vintage styling.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Calculates password strength: 0 to 4
  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Za-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  String _getStrengthLabel(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
      default:
        return 'Strong';
    }
  }

  Color _getStrengthColor(int score) {
    switch (score) {
      case 0:
      case 1:
        return AppColors.terracotta;
      case 2:
        return AppColors.mutedGold;
      case 3:
      case 4:
      default:
        return AppColors.olive;
    }
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authControllerProvider.notifier).register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
        );

    if (!mounted) return;

    if (success) {
      // Newly registered users do not have a family yet -> route to family setup
      context.go('/family-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final fieldErrors = authState.fieldErrors ?? {};

    final passwordScore = _calculatePasswordStrength(_passwordController.text);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.dark),
          onPressed: () {
            ref.read(authControllerProvider.notifier).clearError();
            context.pop();
          },
        ),
        title: const Text(
          'Create Account',
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Begin Your Journey',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create an account to manage household budgets and expenses in harmony.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // General Error Banner if registration failed
                  if (authState.isError && authState.errorMessage != null) ...[
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.terracotta,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
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
                          // 1. Full Name
                          VintageTextField(
                            controller: _fullNameController,
                            label: 'Full Name *',
                            hint: 'e.g. Priya Sharma',
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              if (val.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          if (fieldErrors.containsKey('full_name')) ...[
                            const SizedBox(height: 4),
                            Text(
                              fieldErrors['full_name']!,
                              style: const TextStyle(
                                color: AppColors.terracotta,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // 2. Email Address
                          VintageTextField(
                            controller: _emailController,
                            label: 'Email Address *',
                            hint: 'priya@example.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email is required';
                              }
                              final emailRegex =
                                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(val.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          if (fieldErrors.containsKey('email')) ...[
                            const SizedBox(height: 4),
                            Text(
                              fieldErrors['email']!,
                              style: const TextStyle(
                                color: AppColors.terracotta,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // 3. Phone Number
                          VintageTextField(
                            controller: _phoneController,
                            label: 'Phone Number (Optional)',
                            hint: '+91 98765 43210',
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                if (val.trim().length < 7 || val.trim().length > 20) {
                                  return 'Enter a valid phone number';
                                }
                              }
                              return null;
                            },
                          ),
                          if (fieldErrors.containsKey('phone')) ...[
                            const SizedBox(height: 4),
                            Text(
                              fieldErrors['phone']!,
                              style: const TextStyle(
                                color: AppColors.terracotta,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // 4. Password
                          VintageTextField(
                            controller: _passwordController,
                            label: 'Password *',
                            hint: 'Minimum 8 characters',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            onChanged: (val) => setState(() {}),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Password is required';
                              }
                              if (val.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              if (!val.contains(RegExp(r'[A-Za-z]')) ||
                                  !val.contains(RegExp(r'[0-9]'))) {
                                return 'Password must contain both letters and numbers';
                              }
                              return null;
                            },
                          ),
                          // Password Strength Indicator
                          if (_passwordController.text.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: passwordScore / 4.0,
                                      minHeight: 4,
                                      backgroundColor:
                                          AppColors.border.withValues(alpha: 0.5),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getStrengthColor(passwordScore),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _getStrengthLabel(passwordScore),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStrengthColor(passwordScore),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          // 5. Confirm Password
                          VintageTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password *',
                            hint: 'Re-enter your password',
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (val != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          VintageButton(
                            text: 'Create Account',
                            isLoading: isLoading,
                            onPressed: _handleRegister,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Already Have an Account Link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.read(authControllerProvider.notifier).clearError();
                          context.pop();
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
