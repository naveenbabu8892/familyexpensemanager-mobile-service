import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vintage_button.dart';
import '../../../core/widgets/vintage_card.dart';
import '../../../core/widgets/vintage_text_field.dart';
import '../data/family_repository_impl.dart';
import 'family_controller.dart';

/// Screen allowing the family owner to invite family members with flexible relationships.
class InviteSpouseScreen extends ConsumerStatefulWidget {
  const InviteSpouseScreen({super.key});

  @override
  ConsumerState<InviteSpouseScreen> createState() => _InviteSpouseScreenState();
}

class _InviteSpouseScreenState extends ConsumerState<InviteSpouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  String _selectedRelationship = 'other';
  bool _isSending = false;
  String? _errorMessage;
  String? _generatedToken;
  bool _isCopied = false;

  static const List<Map<String, String>> _fallbackRelationships = [
    {'value': 'husband', 'label': 'Husband'},
    {'value': 'wife', 'label': 'Wife'},
    {'value': 'father', 'label': 'Father'},
    {'value': 'mother', 'label': 'Mother'},
    {'value': 'son', 'label': 'Son'},
    {'value': 'daughter', 'label': 'Daughter'},
    {'value': 'brother', 'label': 'Brother'},
    {'value': 'sister', 'label': 'Sister'},
    {'value': 'grandfather', 'label': 'Grandfather'},
    {'value': 'grandmother', 'label': 'Grandmother'},
    {'value': 'grandson', 'label': 'Grandson'},
    {'value': 'granddaughter', 'label': 'Granddaughter'},
    {'value': 'uncle', 'label': 'Uncle'},
    {'value': 'aunt', 'label': 'Aunt'},
    {'value': 'cousin', 'label': 'Cousin'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleInvite() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _generatedToken = null;
    });

    final token = await ref.read(familyControllerProvider.notifier).inviteMember(
          _emailController.text.trim(),
          relationship: _selectedRelationship,
        );

    if (!mounted) return;

    setState(() => _isSending = false);

    if (token != null) {
      setState(() {
        _generatedToken = token;
      });
    } else {
      final stateError = ref.read(familyControllerProvider).errorMessage;
      setState(() {
        _errorMessage = stateError ?? 'Failed to send invitation. Please try again.';
      });
    }
  }

  void _copyTokenToClipboard() {
    if (_generatedToken == null) return;
    Clipboard.setData(ClipboardData(text: _generatedToken!));
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation token copied to clipboard!'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Invite Family Member',
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
              child: _generatedToken != null
                  ? _buildSuccessView()
                  : _buildInviteForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteForm() {
    final relationshipsAsync = ref.watch(familyRelationshipsProvider);

    final relationshipOptions = relationshipsAsync.maybeWhen(
      data: (list) => list.map((e) => {'value': e.value, 'label': e.label}).toList(),
      orElse: () => _fallbackRelationships,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Emblem
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.2),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Invite Your Spouse', // Backwards-compatible subtitle text finder
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Invite someone to your family to manage income, budgets, and expenses together.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Error Banner
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

        // Input Card
        VintageCard(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email / Phone field
                VintageTextField(
                  controller: _emailController,
                  label: 'Spouse Email Address *',
                  hint: 'spouse@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Relationship selection
                const Text(
                  'Relationship *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedRelationship,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: relationshipOptions.map((opt) {
                    return DropdownMenuItem<String>(
                      value: opt['value'],
                      child: Text(opt['label'] ?? opt['value']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRelationship = val);
                    }
                  },
                ),
                const SizedBox(height: 24),
                VintageButton(
                  text: 'Send Invitation',
                  isLoading: _isSending,
                  icon: Icons.send_rounded,
                  onPressed: _handleInvite,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Emblem
        Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.olive,
              size: 50,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Invitation sent successfully.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'An invitation has been generated for ${_emailController.text.trim()}.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Token Copy Card
        VintageCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invitation Token',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your family member can enter this secure token in the app to join instantly:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _generatedToken!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isCopied ? Icons.check : Icons.copy_rounded,
                        color: _isCopied ? AppColors.olive : AppColors.primary,
                        size: 20,
                      ),
                      onPressed: _copyTokenToClipboard,
                      tooltip: 'Copy Token',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _copyTokenToClipboard,
                icon: Icon(
                  _isCopied ? Icons.check : Icons.copy_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                label: Text(
                  _isCopied ? 'Token Copied' : 'Copy Invitation Token',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Navigation back
        VintageButton(
          text: 'Back to Family Home',
          onPressed: () => context.go('/family'),
        ),
      ],
    );
  }
}
