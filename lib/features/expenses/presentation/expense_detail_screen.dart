import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/widgets.dart';
import '../data/expense_repository_impl.dart';
import '../domain/expense.dart';
import 'expense_form_controller.dart';
import 'expense_form_screen.dart';

/// Detailed view for an individual Expense record.
/// Allows viewing all metadata, Editing, and Deleting with explicit confirmation.
class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;
  final Expense? initialExpense;

  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
    this.initialExpense,
  });

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  late Future<Expense> _expenseFuture;
  Expense? _currentExpense;

  @override
  void initState() {
    super.initState();
    _currentExpense = widget.initialExpense;
    _loadExpense();
  }

  void _loadExpense() {
    final repo = ref.read(expenseRepositoryProvider);
    _expenseFuture = repo.getExpenseById(widget.expenseId);
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
          'Delete this expense?',
          style: AppTypography.headingSmall,
        ),
        content: const Text(
          'Are you sure you want to permanently delete this expense? This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
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
          .read(expenseFormControllerProvider.notifier)
          .deleteExpense(widget.expenseId);

      if (success && mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Expense deleted.'),
            backgroundColor: AppColors.dark,
            behavior: SnackBarBehavior.floating,
          ),
        );
        nav.pop(true);
      }
    }
  }

  Future<void> _navigateToEdit(BuildContext context, Expense expense) async {
    final updated = await Navigator.of(context).push<Expense>(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(initialExpense: expense),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentExpense = updated;
        _loadExpense();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expense Details'),
        centerTitle: true,
        actions: [
          if (_currentExpense != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Expense',
              onPressed: () => _navigateToEdit(context, _currentExpense!),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.terracotta),
              tooltip: 'Delete Expense',
              onPressed: () => _confirmAndDelete(context),
            ),
          ],
        ],
      ),
      body: FutureBuilder<Expense>(
        future: _expenseFuture,
        initialData: _currentExpense,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _currentExpense == null) {
            return const Center(child: LoadingState(message: 'Loading expense details...'));
          }

          if (snapshot.hasError && _currentExpense == null) {
            return Center(
              child: ErrorState(
                message: 'Could not load expense details.',
                onRetry: () => setState(_loadExpense),
              ),
            );
          }

          final expense = snapshot.data ?? _currentExpense;
          if (expense == null) {
            return const Center(child: EmptyState(title: 'Not Found', message: 'Expense not found'));
          }

          _currentExpense = expense;
          return _buildContent(context, expense);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Expense expense) {
    final formattedAmount = CurrencyFormatter.format(
      expense.amount,
      currency: expense.currency,
    );
    final formattedDate = expense.expenseDate.isNotEmpty
        ? (DateFormatter.parseIsoDate(expense.expenseDate) != null
            ? DateFormatter.formatDisplay(DateFormatter.parseIsoDate(expense.expenseDate)!)
            : expense.expenseDate)
        : '';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        // 1. Hero Amount Card
        VintageCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.terracottaLight,
                  shape: BoxShape.circle,
                ),
                child: CategoryIcon(
                  iconKey: expense.categoryName ?? 'expense',
                  color: AppColors.terracotta,
                  backgroundColor: AppColors.terracottaLight,
                  size: 28,
                  containerSize: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '-$formattedAmount',
                style: AppTypography.amountHero.copyWith(
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                expense.title,
                textAlign: TextAlign.center,
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (expense.isShared ? AppColors.primary : AppColors.mutedGold)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  expense.isShared ? 'Shared Family Expense' : 'Personal Expense',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: expense.isShared ? AppColors.primary : AppColors.mutedGold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Metadata Section
        VintageCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _buildDetailRow(
                icon: Icons.category_outlined,
                label: 'Category',
                value: expense.categoryName ?? 'General',
              ),
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: formattedDate,
              ),
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Paid By',
                value: expense.paidByName ?? 'Family Member',
              ),
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.payment_rounded,
                label: 'Payment Method',
                value: _formatPaymentMethod(expense.paymentMethod),
              ),
              if (expense.description != null && expense.description!.isNotEmpty) ...[
                const Divider(height: 24),
                _buildDetailRow(
                  icon: Icons.notes_rounded,
                  label: 'Notes',
                  value: expense.description!,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. Action Buttons Row (Edit & Delete)
        Row(
          children: [
            Expanded(
              child: VintageOutlinedButton(
                text: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: () => _navigateToEdit(context, expense),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracottaLight,
                  foregroundColor: AppColors.terracotta,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.terracotta, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () => _confirmAndDelete(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'upi':
        return 'UPI';
      case 'credit_card':
        return 'Credit Card';
      case 'debit_card':
        return 'Debit Card';
      case 'cash':
        return 'Cash';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return method.replaceAll('_', ' ').toUpperCase();
    }
  }
}
