import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/widgets.dart';
import '../../categories/data/category_repository_impl.dart';
import '../../family/data/family_repository_impl.dart';
import '../../family/domain/family.dart';
import '../domain/expense.dart';
import 'expense_detail_screen.dart';
import 'expense_form_screen.dart';
import 'expense_list_controller.dart';

/// Standalone Expense List Screen.
/// Includes Filter Tabs (All, Shared, My Expenses, Spouse Expenses),
/// Advanced Filters Sheet (Category, Date range, Person, Payment Method),
/// Infinite Scrolling pagination, and Add Expense navigation.
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(expenseListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openAddExpense(BuildContext context) async {
    final result = await Navigator.of(context).push<Expense>(
      MaterialPageRoute(
        builder: (_) => const ExpenseFormScreen(),
      ),
    );
    if (result != null && mounted) {
      ref.read(expenseListControllerProvider.notifier).refresh();
    }
  }

  Future<void> _openExpenseDetail(BuildContext context, Expense expense) async {
    final deletedOrUpdated = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(
          expenseId: expense.id,
          initialExpense: expense,
        ),
      ),
    );
    if (deletedOrUpdated != null && mounted) {
      ref.read(expenseListControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseStateAsync = ref.watch(expenseListControllerProvider);
    final filterState = ref.watch(expenseFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expenses'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list_rounded),
                if (filterState.hasActiveAdvancedFilters)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.terracotta,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter Expenses',
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Filter Tabs Bar: All, Shared, My Expenses, Spouse Expenses
            _buildFilterTabs(filterState.tab),

            // 2. Active Filter Chips Indicator (if advanced filters are set)
            if (filterState.hasActiveAdvancedFilters)
              _buildActiveFiltersBar(filterState),

            // 3. Paginated Expense List / States
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.card,
                onRefresh: () async {
                  await ref.read(expenseListControllerProvider.notifier).refresh();
                },
                child: expenseStateAsync.when(
                  data: (state) {
                    if (state.items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No Expenses Found',
                              message: filterState.hasActiveAdvancedFilters
                                  ? 'No expenses match the selected filters.'
                                  : 'Start tracking household spending by adding your first expense.',
                              actionLabel: 'Add Expense',
                              onAction: () => _openAddExpense(context),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: state.items.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: LoadingState(size: 24, message: 'Loading more expenses...'),
                            ),
                          );
                        }

                        final expense = state.items[index];
                        return _buildExpenseTile(context, expense);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: LoadingState(message: 'Loading expenses...'),
                  ),
                  error: (error, _) => Center(
                    child: ErrorState(
                      message: 'Failed to load expenses. Please try again.',
                      onRetry: () =>
                          ref.read(expenseListControllerProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AppFloatingActionButton(
        label: 'Add Expense',
        icon: Icons.add_rounded,
        onPressed: () => _openAddExpense(context),
      ),
    );
  }

  Widget _buildFilterTabs(ExpenseFilterTab activeTab) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabChip('All', ExpenseFilterTab.all, activeTab),
            const SizedBox(width: 8),
            _buildTabChip('Shared', ExpenseFilterTab.shared, activeTab),
            const SizedBox(width: 8),
            _buildTabChip('My Expenses', ExpenseFilterTab.myExpenses, activeTab),
            const SizedBox(width: 8),
            _buildTabChip('Spouse Expenses', ExpenseFilterTab.spouseExpenses, activeTab),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, ExpenseFilterTab tab, ExpenseFilterTab current) {
    final isSelected = tab == current;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(expenseFilterProvider.notifier).setTab(tab);
      },
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.card : AppColors.dark,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBar(ExpenseFilterState filter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primaryContainer,
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Filtered results',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(expenseFilterProvider.notifier).clearFilters();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.terracotta,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(BuildContext context, Expense expense) {
    final formattedAmount = expense.amount % 1 == 0
        ? CurrencyFormatter.formatNoDecimals(expense.amount, currency: expense.currency)
        : CurrencyFormatter.format(expense.amount, currency: expense.currency);

    final displayDate = expense.expenseDate.isNotEmpty
        ? (DateFormatter.parseIsoDate(expense.expenseDate) != null
            ? DateFormatter.formatDisplay(DateFormatter.parseIsoDate(expense.expenseDate)!)
            : expense.expenseDate)
        : '';

    return VintageCard(
      onTap: () => _openExpenseDetail(context, expense),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CategoryIcon(
            iconKey: expense.categoryName ?? 'expense',
            color: AppColors.terracotta,
            backgroundColor: AppColors.terracottaLight,
            containerSize: 44,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      displayDate,
                      style: AppTypography.bodySmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: (expense.isShared ? AppColors.primary : AppColors.mutedGold)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.isShared ? 'Shared' : 'Personal',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: expense.isShared ? AppColors.primary : AppColors.mutedGold,
                        ),
                      ),
                    ),
                    if (expense.paidByName != null && expense.paidByName!.isNotEmpty)
                      Text(
                        '• ${expense.paidByName!.split(' ').first}',
                        style: AppTypography.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '-$formattedAmount',
            style: AppTypography.amountMedium.copyWith(
              color: AppColors.terracotta,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ExpenseFilterSheet(),
    );
  }
}

class _ExpenseFilterSheet extends ConsumerStatefulWidget {
  const _ExpenseFilterSheet();

  @override
  ConsumerState<_ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends ConsumerState<_ExpenseFilterSheet> {
  String? _tempCategoryId;
  String? _tempPaidById;
  String? _tempPaymentMethod;
  DateTimeRange? _tempDateRange;

  @override
  void initState() {
    super.initState();
    final current = ref.read(expenseFilterProvider);
    _tempCategoryId = current.categoryId;
    _tempPaidById = current.paidBy;
    _tempPaymentMethod = current.paymentMethod;
    if (current.fromDate != null && current.toDate != null) {
      _tempDateRange = DateTimeRange(
        start: DateTime.tryParse(current.fromDate!) ?? DateTime.now(),
        end: DateTime.tryParse(current.toDate!) ?? DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider('EXPENSE'));
    final membersAsync = ref.watch(familyRepositoryProvider).getFamilyMembers();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempCategoryId = null;
                      _tempPaidById = null;
                      _tempPaymentMethod = null;
                      _tempDateRange = null;
                    });
                  },
                  child: const Text('Reset', style: TextStyle(color: AppColors.terracotta)),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Date Range
            const Text('Date Range', style: AppTypography.labelSmall),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: _tempDateRange,
                );
                if (range != null) {
                  setState(() => _tempDateRange = range);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      _tempDateRange == null
                          ? 'Select date range'
                          : '${DateFormat('MMM dd').format(_tempDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_tempDateRange!.end)}',
                      style: const TextStyle(fontSize: 14, color: AppColors.dark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Filter
            const Text('Category', style: AppTypography.labelSmall),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSel = _tempCategoryId == cat.id;
                  return ChoiceChip(
                    label: Text(cat.name),
                    selected: isSel,
                    onSelected: (val) {
                      setState(() => _tempCategoryId = val ? cat.id : null);
                    },
                    selectedColor: AppColors.terracottaLight,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.terracotta : AppColors.dark,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              loading: () => const LoadingState(size: 16),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // Paid By Member
            const Text('Paid By', style: AppTypography.labelSmall),
            const SizedBox(height: 8),
            FutureBuilder<List<FamilyMember>>(
              future: membersAsync,
              builder: (context, snap) {
                final members = snap.data ?? [];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: members.map((m) {
                    final isSel = _tempPaidById == m.userId;
                    return ChoiceChip(
                      label: Text(m.fullName ?? m.userId),
                      selected: isSel,
                      onSelected: (val) {
                        setState(() => _tempPaidById = val ? m.userId : null);
                      },
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        color: isSel ? AppColors.primary : AppColors.dark,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),

            // Payment Method
            const Text('Payment Method', style: AppTypography.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                {'key': 'upi', 'label': 'UPI'},
                {'key': 'credit_card', 'label': 'Credit Card'},
                {'key': 'debit_card', 'label': 'Debit Card'},
                {'key': 'cash', 'label': 'Cash'},
                {'key': 'bank_transfer', 'label': 'Bank Transfer'},
              ].map((pm) {
                final isSel = _tempPaymentMethod == pm['key'];
                return ChoiceChip(
                  label: Text(pm['label']!),
                  selected: isSel,
                  onSelected: (val) {
                    setState(() => _tempPaymentMethod = val ? pm['key'] : null);
                  },
                  selectedColor: AppColors.primaryLight,
                  labelStyle: TextStyle(
                    color: isSel ? AppColors.primary : AppColors.dark,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final notifier = ref.read(expenseFilterProvider.notifier);
                  notifier.setCategory(_tempCategoryId);
                  notifier.setPaidBy(_tempPaidById);
                  notifier.setPaymentMethod(_tempPaymentMethod);
                  if (_tempDateRange != null) {
                    notifier.setDateRange(
                      DateFormat('yyyy-MM-dd').format(_tempDateRange!.start),
                      DateFormat('yyyy-MM-dd').format(_tempDateRange!.end),
                    );
                  } else {
                    notifier.setDateRange(null, null);
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
