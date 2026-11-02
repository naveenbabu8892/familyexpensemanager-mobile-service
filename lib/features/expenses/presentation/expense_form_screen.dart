import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/data/category_repository_impl.dart';
import '../../categories/domain/category.dart';
import '../../family/data/family_repository_impl.dart';
import '../../family/domain/family.dart';
import '../domain/expense.dart';
import 'expense_form_controller.dart';

/// Form screen for Adding or Editing an Expense.
/// Amount is the primary focus. Validates amount, category, date, paid by, and payment method.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  final Expense? initialExpense;

  const ExpenseFormScreen({
    super.key,
    this.initialExpense,
  });

  bool get isEditing => initialExpense != null;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  String? _selectedCategoryId;
  late DateTime _selectedDate;
  String? _selectedPaidById;
  late String _selectedPaymentMethod;
  late bool _isShared;

  // Validation feedback messages
  String? _amountError;
  String? _titleError;
  String? _categoryError;
  String? _paidByError;

  static const List<Map<String, String>> _paymentMethods = [
    {'key': 'upi', 'label': 'UPI'},
    {'key': 'credit_card', 'label': 'Credit Card'},
    {'key': 'debit_card', 'label': 'Debit Card'},
    {'key': 'cash', 'label': 'Cash'},
    {'key': 'bank_transfer', 'label': 'Bank Transfer'},
  ];

  @override
  void initState() {
    super.initState();
    final exp = widget.initialExpense;

    final initialAmountStr = exp != null
        ? (exp.amount % 1 == 0 ? exp.amount.toInt().toString() : exp.amount.toString())
        : '';

    _amountController = TextEditingController(text: initialAmountStr);
    _titleController = TextEditingController(text: exp?.title ?? '');
    _notesController = TextEditingController(text: exp?.description ?? '');

    _selectedCategoryId = exp?.categoryId;
    _selectedDate = exp != null && exp.expenseDate.isNotEmpty
        ? (DateTime.tryParse(exp.expenseDate) ?? DateTime.now())
        : DateTime.now();
    _selectedPaidById = exp?.paidBy;
    _selectedPaymentMethod = exp?.paymentMethod ?? 'upi';
    _isShared = exp?.isShared ?? true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _amountError = null;
      _titleError = null;
      _categoryError = null;
      _paidByError = null;
    });

    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amountVal = double.tryParse(amountText);

    // Validation checks
    var hasError = false;
    if (amountVal == null || amountVal <= 0) {
      setState(() => _amountError = 'Please enter an amount greater than 0');
      hasError = true;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _titleError = 'Title is required');
      hasError = true;
    }
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      setState(() => _categoryError = 'Please select a category');
      hasError = true;
    }
    if (_selectedPaidById == null || _selectedPaidById!.isEmpty) {
      setState(() => _paidByError = 'Please select who paid');
      hasError = true;
    }

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || hasError) {
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final formCtrl = ref.read(expenseFormControllerProvider.notifier);

    Expense? saved;
    if (widget.isEditing) {
      saved = await formCtrl.updateExpense(
        widget.initialExpense!.id,
        amount: amountVal!,
        categoryId: _selectedCategoryId!,
        expenseDate: dateStr,
        paidBy: _selectedPaidById!,
        paymentMethod: _selectedPaymentMethod,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        isShared: _isShared,
      );
    } else {
      saved = await formCtrl.createExpense(
        amount: amountVal!,
        categoryId: _selectedCategoryId!,
        expenseDate: dateStr,
        paidBy: _selectedPaidById!,
        paymentMethod: _selectedPaymentMethod,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        isShared: _isShared,
      );
    }

    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Expense updated successfully.'
                : 'Expense added successfully.',
          ),
          backgroundColor: AppColors.olive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(saved);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(expenseFormControllerProvider);
    final categoriesAsync = ref.watch(categoriesListProvider('EXPENSE'));
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user;

    // Default paid by to current user if not yet chosen
    if (_selectedPaidById == null && currentUser != null) {
      _selectedPaidById = currentUser.id;
    }

    final membersAsync = ref.watch(familyRepositoryProvider).getFamilyMembers();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Expense' : 'Add Expense'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              // 1. Primary Focus: Large Numeric Amount Input
              AmountInput(
                controller: _amountController,
                currencySymbol: '₹',
                label: 'AMOUNT',
                autofocus: !widget.isEditing,
              ),
              if (_amountError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    _amountError!,
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // 2. Title Field
              VintageTextField(
                label: 'Title',
                hint: 'e.g. Grocery Supermarket',
                controller: _titleController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              if (_titleError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    _titleError!,
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // 3. Category Selector
              Text(
                'Category',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (categories) {
                  if (_selectedCategoryId == null && categories.isNotEmpty) {
                    _selectedCategoryId = categories.first.id;
                  }
                  return _buildCategoryDropdown(categories);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LoadingState(size: 20),
                ),
                error: (e, _) => Text(
                  'Failed to load categories',
                  style: TextStyle(color: AppColors.terracotta),
                ),
              ),
              if (_categoryError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    _categoryError!,
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // 4. Date Picker
              _buildDatePickerRow(context),
              const SizedBox(height: 20),

              // 5. Paid By (Member Selector)
              FutureBuilder<List<FamilyMember>>(
                future: membersAsync,
                builder: (context, snapshot) {
                  final members = snapshot.data ?? [];
                  return _buildPaidByRow(members, currentUser?.fullName ?? 'You');
                },
              ),
              if (_paidByError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    _paidByError!,
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // 6. Payment Method Chips
              Text(
                'Payment Method',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _buildPaymentMethodChips(),
              const SizedBox(height: 20),

              // 7. Shared / Personal Switcher Card
              _buildSharedSwitch(),
              const SizedBox(height: 20),

              // 8. Notes / Description
              VintageTextField(
                label: 'Notes (Optional)',
                hint: 'Add receipt notes or memo...',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // 9. Error display if API fails
              if (formState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.terracottaLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.terracotta),
                    ),
                    child: Text(
                      formState.errorMessage!,
                      style: const TextStyle(color: AppColors.terracotta),
                    ),
                  ),
                ),

              // 10. Save / Update Button
              VintageButton(
                text: widget.isEditing ? 'Update Expense' : 'Save Expense',
                isLoading: formState.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategoryId,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat.id,
              child: Row(
                children: [
                  CategoryIcon(
                    iconKey: cat.icon,
                    size: 16,
                    containerSize: 28,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    cat.name,
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedCategoryId = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDatePickerRow(BuildContext context) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: AppColors.card,
                      surface: AppColors.card,
                      onSurface: AppColors.dark,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.edit_calendar_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaidByRow(List<FamilyMember> members, String currentUserName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paid By',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPaidById,
              isExpanded: true,
              hint: const Text('Select payer'),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
              items: members.isNotEmpty
                  ? members.map((m) {
                      return DropdownMenuItem<String>(
                        value: m.userId,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              m.relationshipLabel.isNotEmpty && m.relationshipLabel != 'Other'
                                  ? '${m.fullName ?? m.userId} · ${m.relationshipLabel}'
                                  : (m.fullName ?? m.userId),
                              style: const TextStyle(
                                color: AppColors.dark,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                  : [
                      DropdownMenuItem<String>(
                        value: _selectedPaidById,
                        child: Text(currentUserName),
                      ),
                    ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPaidById = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _paymentMethods.map((m) {
        final isSelected = _selectedPaymentMethod == m['key'];
        return ChoiceChip(
          label: Text(m['label']!),
          selected: isSelected,
          onSelected: (_) {
            setState(() => _selectedPaymentMethod = m['key']!);
          },
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.card : AppColors.dark,
          ),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSharedSwitch() {
    return VintageCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  _isShared ? Icons.people_outline_rounded : Icons.person_outline_rounded,
                  color: _isShared ? AppColors.primary : AppColors.mutedGold,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isShared ? 'Shared Expense' : 'Personal Expense',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        _isShared
                            ? 'Counted in family shared budget'
                            : 'Counted as individual expense',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: _isShared,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _isShared = val);
            },
          ),
        ],
      ),
    );
  }
}
