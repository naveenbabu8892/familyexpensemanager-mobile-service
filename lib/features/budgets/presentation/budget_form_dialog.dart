import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../categories/data/category_repository_impl.dart';
import '../domain/budget.dart';
import 'budget_form_controller.dart';

/// Modal dialog or full-page form to Add or Edit a Monthly Category Budget.
class BudgetFormDialog extends ConsumerStatefulWidget {
  final Budget? initialBudget;
  final int? initialMonth;
  final int? initialYear;

  const BudgetFormDialog({
    super.key,
    this.initialBudget,
    this.initialMonth,
    this.initialYear,
  });

  static Future<bool?> show(
    BuildContext context, {
    Budget? initialBudget,
    int? initialMonth,
    int? initialYear,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BudgetFormDialog(
        initialBudget: initialBudget,
        initialMonth: initialMonth,
        initialYear: initialYear,
      ),
    );
  }

  @override
  ConsumerState<BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends ConsumerState<BudgetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  String? _selectedCategoryId;
  late int _selectedMonth;
  late int _selectedYear;
  String? _validationError;

  bool get isEditing => widget.initialBudget != null;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    final budget = widget.initialBudget;
    if (budget != null) {
      _amountController = TextEditingController(
        text: budget.amount % 1 == 0
            ? budget.amount.toInt().toString()
            : budget.amount.toStringAsFixed(2),
      );
      _selectedCategoryId = budget.categoryId;
      _selectedMonth = budget.month;
      _selectedYear = budget.year;
    } else {
      _amountController = TextEditingController();
      _selectedMonth = widget.initialMonth ?? now.month;
      _selectedYear = widget.initialYear ?? now.year;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _validationError = null);

    // Validate Category
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      setState(() => _validationError = 'Please select an expense category.');
      return;
    }

    // Validate Amount
    final rawAmount = _amountController.text.trim().replaceAll(',', '');
    final parsedAmount = double.tryParse(rawAmount);
    if (parsedAmount == null || parsedAmount <= 0) {
      setState(() => _validationError = 'Budget amount must be greater than zero.');
      return;
    }

    final controller = ref.read(budgetFormControllerProvider.notifier);

    if (isEditing) {
      final updated = await controller.updateBudget(
        widget.initialBudget!.id,
        amount: parsedAmount,
        month: _selectedMonth,
        year: _selectedYear,
        categoryId: _selectedCategoryId,
      );
      if (updated != null && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget updated successfully!'),
            backgroundColor: AppColors.olive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final created = await controller.createBudget(
        categoryId: _selectedCategoryId!,
        amount: parsedAmount,
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (created != null && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully!'),
            backgroundColor: AppColors.olive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(budgetFormControllerProvider);
    final categoriesAsync = ref.watch(categoriesListProvider('EXPENSE'));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Handle & Title
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Budget' : 'Add Monthly Budget',
                    style: AppTypography.headingMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Error messages
              if (_validationError != null || formState.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.terracottaLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.terracotta, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _validationError ?? formState.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.terracotta,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 1. Amount Input
              AmountInput(
                controller: _amountController,
                label: 'BUDGET AMOUNT',
                autofocus: !isEditing,
              ),
              const SizedBox(height: 16),

              // 2. Category Dropdown
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (categories) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        hint: const Text('Select Category',
                            style: TextStyle(color: AppColors.textMuted)),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Row(
                              children: [
                                CategoryIcon(
                                  iconKey: cat.icon,
                                  color: AppColors.terracotta,
                                  backgroundColor: AppColors.terracottaLight,
                                  containerSize: 32,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.dark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                      ),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Error loading categories'),
              ),
              const SizedBox(height: 16),

              // 3. Month & Year Selectors
              Row(
                children: [
                  // Month Selector
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Month',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedMonth,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.primary),
                              items: List.generate(12, (index) {
                                final m = index + 1;
                                return DropdownMenuItem<int>(
                                  value: m,
                                  child: Text(
                                    _monthNames[index],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedMonth = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Year Selector
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Year',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedYear,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.primary),
                              items: [2024, 2025, 2026, 2027, 2028].map((y) {
                                return DropdownMenuItem<int>(
                                  value: y,
                                  child: Text(
                                    y.toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedYear = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              VintageButton(
                text: isEditing ? 'Save Changes' : 'Create Budget',
                isLoading: formState.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
