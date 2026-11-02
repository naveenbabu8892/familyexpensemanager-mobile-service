import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/amount_input.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/vintage_button.dart';
import '../../../core/widgets/vintage_text_field.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/data/category_repository_impl.dart';
import '../../categories/domain/category.dart';
import '../../family/data/family_repository_impl.dart';
import '../../family/domain/family.dart';
import '../domain/income.dart';
import 'income_form_controller.dart';

/// Screen for Adding or Editing Income entries.
/// Fields: Amount (hero), Category, Date, Received By, Title, Notes.
class IncomeFormScreen extends ConsumerStatefulWidget {
  final Income? initialIncome;

  const IncomeFormScreen({
    super.key,
    this.initialIncome,
  });

  bool get isEditing => initialIncome != null;

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  String? _selectedCategoryId;
  late DateTime _selectedDate;
  String? _selectedReceivedById;

  // Validation feedback messages
  String? _amountError;
  String? _titleError;
  String? _categoryError;
  String? _receivedByError;

  @override
  void initState() {
    super.initState();
    final inc = widget.initialIncome;

    final initialAmountStr = inc != null
        ? (inc.amount % 1 == 0 ? inc.amount.toInt().toString() : inc.amount.toString())
        : '';

    _amountController = TextEditingController(text: initialAmountStr);
    _titleController = TextEditingController(text: inc?.title ?? '');
    _notesController = TextEditingController(text: inc?.description ?? '');

    _selectedCategoryId = inc?.categoryId;
    _selectedDate = inc != null && inc.incomeDate.isNotEmpty
        ? (DateTime.tryParse(inc.incomeDate) ?? DateTime.now())
        : DateTime.now();
    _selectedReceivedById = inc?.receivedBy ?? inc?.userId;
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
      _receivedByError = null;
    });

    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amountVal = double.tryParse(amountText);

    // Field Validations
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
    if (_selectedReceivedById == null || _selectedReceivedById!.isEmpty) {
      setState(() => _receivedByError = 'Please select recipient');
      hasError = true;
    }

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || hasError) {
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final formCtrl = ref.read(incomeFormControllerProvider.notifier);

    Income? saved;
    if (widget.isEditing) {
      saved = await formCtrl.updateIncome(
        widget.initialIncome!.id,
        amount: amountVal!,
        categoryId: _selectedCategoryId!,
        incomeDate: dateStr,
        receivedBy: _selectedReceivedById!,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
    } else {
      saved = await formCtrl.createIncome(
        amount: amountVal!,
        categoryId: _selectedCategoryId!,
        incomeDate: dateStr,
        receivedBy: _selectedReceivedById!,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
    }

    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Income updated successfully.'
                : 'Income added successfully.',
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
    final formState = ref.watch(incomeFormControllerProvider);
    final categoriesAsync = ref.watch(categoriesListProvider('INCOME'));
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user;

    // Default received by to current user if not yet chosen
    if (_selectedReceivedById == null && currentUser != null) {
      _selectedReceivedById = currentUser.id;
    }

    final membersAsync = ref.watch(familyRepositoryProvider).getFamilyMembers();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Income' : 'Add Income'),
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
                hint: 'e.g. Monthly Salary, Freelance project',
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
                error: (e, _) => const Text(
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

              // 5. Received By (Recipient Family Member)
              FutureBuilder<List<FamilyMember>>(
                future: membersAsync,
                builder: (context, snapshot) {
                  final members = snapshot.data ?? [];
                  return _buildReceivedByRow(members, currentUser?.fullName ?? 'You');
                },
              ),
              if (_receivedByError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    _receivedByError!,
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // 6. Notes / Description
              VintageTextField(
                label: 'Notes (Optional)',
                hint: 'Add payment reference or memo...',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // 7. Error display if API fails
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

              // 8. Save / Update Button
              VintageButton(
                text: widget.isEditing ? 'Update Income' : 'Save Income',
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
                    color: AppColors.olive,
                    backgroundColor: AppColors.oliveLight,
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

  Widget _buildReceivedByRow(List<FamilyMember> members, String currentUserName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Received By',
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
              value: _selectedReceivedById,
              isExpanded: true,
              hint: const Text('Select recipient'),
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
                        value: _selectedReceivedById,
                        child: Text(currentUserName),
                      ),
                    ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedReceivedById = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
