import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/vintage_card.dart';
import '../data/income_repository_impl.dart';
import '../domain/income.dart';
import 'income_form_controller.dart';
import 'income_form_screen.dart';

/// Screen displaying complete details of an Income entry.
/// Supports navigation to edit income and delete with confirmation dialog.
class IncomeDetailScreen extends ConsumerStatefulWidget {
  final String incomeId;
  final Income? initialIncome;

  const IncomeDetailScreen({
    super.key,
    required this.incomeId,
    this.initialIncome,
  });

  @override
  ConsumerState<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends ConsumerState<IncomeDetailScreen> {
  late Future<Income> _incomeFuture;
  Income? _currentIncome;

  @override
  void initState() {
    super.initState();
    _currentIncome = widget.initialIncome;
    _loadIncome();
  }

  void _loadIncome() {
    final repo = ref.read(incomeRepositoryProvider);
    _incomeFuture = repo.getIncomeById(widget.incomeId);
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete this income?',
          style: AppTypography.headingSmall,
        ),
        content: const Text(
          'Are you sure you want to permanently delete this income entry? This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(incomeFormControllerProvider.notifier)
          .deleteIncome(widget.incomeId);

      if (success && mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Income deleted.'),
            backgroundColor: AppColors.dark,
            behavior: SnackBarBehavior.floating,
          ),
        );
        nav.pop(true);
      }
    }
  }

  Future<void> _navigateToEdit(BuildContext context, Income income) async {
    final updated = await Navigator.of(context).push<Income>(
      MaterialPageRoute(
        builder: (_) => IncomeFormScreen(initialIncome: income),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentIncome = updated;
        _loadIncome();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Income Details'),
        centerTitle: true,
        actions: [
          if (_currentIncome != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Income',
              onPressed: () => _navigateToEdit(context, _currentIncome!),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.terracotta),
              tooltip: 'Delete Income',
              onPressed: () => _confirmAndDelete(context),
            ),
          ],
        ],
      ),
      body: FutureBuilder<Income>(
        future: _incomeFuture,
        initialData: _currentIncome,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _currentIncome == null) {
            return const Center(child: LoadingState(message: 'Loading income details...'));
          }

          if (snapshot.hasError && _currentIncome == null) {
            return Center(
              child: ErrorState(
                message: 'Could not load income details.',
                onRetry: () => setState(_loadIncome),
              ),
            );
          }

          final income = snapshot.data ?? _currentIncome;
          if (income == null) {
            return const Center(child: EmptyState(title: 'Not Found', message: 'Income not found'));
          }

          _currentIncome = income;

          final formattedAmount = CurrencyFormatter.format(income.amount, currency: income.currency);
          final displayDate = income.incomeDate.isNotEmpty
              ? (DateFormatter.parseIsoDate(income.incomeDate) != null
                  ? DateFormatter.formatDisplay(DateFormatter.parseIsoDate(income.incomeDate)!)
                  : income.incomeDate)
              : '';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Hero Amount Card with Vintage styling
              VintageCard(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                child: Column(
                  children: [
                    CategoryIcon(
                      iconKey: income.categoryName ?? 'payments',
                      color: AppColors.olive,
                      backgroundColor: AppColors.oliveLight,
                      size: 32,
                      containerSize: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      income.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+$formattedAmount',
                      style: AppTypography.amountHero.copyWith(
                        color: AppColors.olive,
                        fontSize: 34,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.oliveLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        income.categoryName ?? 'Income',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.olive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Detailed metadata list
              VintageCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildMetaRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: displayDate,
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _buildMetaRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Received By',
                      value: income.receivedByName ?? 'Family Member',
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _buildMetaRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: income.categoryName ?? 'Income',
                    ),
                    if (income.createdAt != null) ...[
                      const Divider(height: 20, color: AppColors.border),
                      _buildMetaRow(
                        icon: Icons.access_time_rounded,
                        label: 'Recorded On',
                        value: DateFormat('MMM dd, yyyy • hh:mm a').format(income.createdAt!.toLocal()),
                      ),
                    ],
                  ],
                ),
              ),

              // Notes Card (if present)
              if (income.description != null && income.description!.isNotEmpty) ...[
                const SizedBox(height: 20),
                VintageCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Notes',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        income.description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.dark,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
