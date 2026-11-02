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
import '../../income/domain/income.dart';
import '../../income/presentation/income_detail_screen.dart';
import '../../income/presentation/income_form_screen.dart';
import '../domain/expense.dart';
import '../domain/transaction_item.dart';
import 'expense_detail_screen.dart';
import 'expense_form_screen.dart';
import 'transactions_list_controller.dart';

/// Complete Unified Transactions Screen.
/// Tabs: All, Expenses, Income.
/// Features:
/// - Server-side pagination & Infinite scrolling
/// - Pull-to-refresh
/// - Search
/// - Category filter
/// - Person filter
/// - Date filter
/// - Payment method filter
/// - Shared / personal filter
/// - Sorting (Date, Amount, Title)
/// - Expenses visually distinct from income (Terracotta minus vs Sage Olive plus)
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionsListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openAddTransaction(BuildContext context, TransactionTab currentTab) async {
    // If on Income tab, open Add Income; otherwise open Add Expense or show choice
    if (currentTab == TransactionTab.income) {
      final saved = await Navigator.of(context).push<Income>(
        MaterialPageRoute(builder: (_) => const IncomeFormScreen()),
      );
      if (saved != null && mounted) {
        ref.read(transactionsListControllerProvider.notifier).refresh();
      }
    } else if (currentTab == TransactionTab.expenses) {
      final saved = await Navigator.of(context).push<Expense>(
        MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
      );
      if (saved != null && mounted) {
        ref.read(transactionsListControllerProvider.notifier).refresh();
      }
    } else {
      // In "All" tab: present bottom sheet modal to choose Expense or Income
      _showAddChoiceSheet(context);
    }
  }

  void _showAddChoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('Add New Transaction', style: AppTypography.headingSmall),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.terracottaLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, color: AppColors.terracotta),
                ),
                title: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Track household or personal spending'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final saved = await Navigator.of(context).push<Expense>(
                    MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
                  );
                  if (saved != null && mounted) {
                    ref.read(transactionsListControllerProvider.notifier).refresh();
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.oliveLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_downward_rounded, color: AppColors.olive),
                ),
                title: const Text('Add Income', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Record salary, bonus, or earnings'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final saved = await Navigator.of(context).push<Income>(
                    MaterialPageRoute(builder: (_) => const IncomeFormScreen()),
                  );
                  if (saved != null && mounted) {
                    ref.read(transactionsListControllerProvider.notifier).refresh();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTransactionDetail(BuildContext context, TransactionItem item) async {
    if (item.isExpense) {
      final result = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute(
          builder: (_) => ExpenseDetailScreen(
            expenseId: item.id,
            initialExpense: item.rawEntity as Expense?,
          ),
        ),
      );
      if (result != null && mounted) {
        ref.read(transactionsListControllerProvider.notifier).refresh();
      }
    } else {
      final result = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute(
          builder: (_) => IncomeDetailScreen(
            incomeId: item.id,
            initialIncome: item.rawEntity as Income?,
          ),
        ),
      );
      if (result != null && mounted) {
        ref.read(transactionsListControllerProvider.notifier).refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsStateAsync = ref.watch(transactionsListControllerProvider);
    final filterState = ref.watch(transactionsFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(transactionsFilterProvider.notifier).setSearch(null);
                      setState(() => _isSearchVisible = false);
                    },
                  ),
                ),
                style: const TextStyle(color: AppColors.dark, fontSize: 16),
                onSubmitted: (query) {
                  ref.read(transactionsFilterProvider.notifier).setSearch(query);
                },
              )
            : const Text('Transactions'),
        centerTitle: !_isSearchVisible,
        actions: [
          if (!_isSearchVisible)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search',
              onPressed: () => setState(() => _isSearchVisible = true),
            ),
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
            tooltip: 'Filter & Sort',
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Filter Tabs Bar: All, Expenses, Income
            _buildTabs(filterState.tab),

            // 2. Active Filter Chips Indicator Bar
            if (filterState.hasActiveAdvancedFilters)
              _buildActiveFiltersBar(filterState),

            // 3. Paginated Transactions List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.card,
                onRefresh: () async {
                  await ref.read(transactionsListControllerProvider.notifier).refresh();
                },
                child: transactionsStateAsync.when(
                  data: (state) {
                    if (state.items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No Transactions Found',
                              message: filterState.hasActiveAdvancedFilters
                                  ? 'No records match the current filters or search term.'
                                  : 'No activity found. Start recording expenses or income.',
                              actionLabel: 'Add Transaction',
                              onAction: () => _openAddTransaction(context, filterState.tab),
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
                              child: LoadingState(size: 24, message: 'Loading more...'),
                            ),
                          );
                        }

                        final item = state.items[index];
                        return _buildTransactionTile(context, item);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: LoadingState(message: 'Loading transactions...'),
                  ),
                  error: (error, _) => Center(
                    child: ErrorState(
                      message: 'Failed to load transactions. Pull down to retry.',
                      onRetry: () =>
                          ref.read(transactionsListControllerProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AppFloatingActionButton(
        label: filterState.tab == TransactionTab.income
            ? 'Add Income'
            : (filterState.tab == TransactionTab.expenses ? 'Add Expense' : 'Add New'),
        icon: Icons.add_rounded,
        onPressed: () => _openAddTransaction(context, filterState.tab),
      ),
    );
  }

  Widget _buildTabs(TransactionTab activeTab) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildTabChip('All', TransactionTab.all, activeTab)),
          const SizedBox(width: 8),
          Expanded(child: _buildTabChip('Expenses', TransactionTab.expenses, activeTab)),
          const SizedBox(width: 8),
          Expanded(child: _buildTabChip('Income', TransactionTab.income, activeTab)),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, TransactionTab tab, TransactionTab current) {
    final isSelected = tab == current;

    return ChoiceChip(
      label: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.card : AppColors.dark,
          ),
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        ref.read(transactionsFilterProvider.notifier).setTab(tab);
      },
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

  Widget _buildActiveFiltersBar(TransactionsFilterState filter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primaryContainer,
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              filter.search != null
                  ? 'Search: "${filter.search}"'
                  : 'Filtered & Sorted',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _searchController.clear();
              ref.read(transactionsFilterProvider.notifier).clearFilters();
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

  Widget _buildTransactionTile(BuildContext context, TransactionItem item) {
    final formattedAmount = item.amount % 1 == 0
        ? CurrencyFormatter.formatNoDecimals(item.amount, currency: item.currency)
        : CurrencyFormatter.format(item.amount, currency: item.currency);

    final displayDate = item.date.isNotEmpty
        ? (DateFormatter.parseIsoDate(item.date) != null
            ? DateFormatter.formatDisplay(DateFormatter.parseIsoDate(item.date)!)
            : item.date)
        : '';

    final isExpense = item.isExpense;

    return VintageCard(
      onTap: () => _openTransactionDetail(context, item),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Category Icon: Terracotta for expense, Olive for income
          CategoryIcon(
            iconKey: item.categoryName ?? (isExpense ? 'expense' : 'payments'),
            color: isExpense ? AppColors.terracotta : AppColors.olive,
            backgroundColor: isExpense ? AppColors.terracottaLight : AppColors.oliveLight,
            containerSize: 44,
            size: 20,
          ),
          const SizedBox(width: 14),

          // Title, Person & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
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
                    if (item.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (isExpense ? AppColors.terracotta : AppColors.olive)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.categoryName!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isExpense ? AppColors.terracotta : AppColors.olive,
                          ),
                        ),
                      ),
                    if (item.isShared != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (item.isShared! ? AppColors.primary : AppColors.mutedGold)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isShared! ? 'Shared' : 'Personal',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item.isShared! ? AppColors.primary : AppColors.mutedGold,
                          ),
                        ),
                      ),
                    if (item.personName != null && item.personName!.isNotEmpty)
                      Text(
                        '• ${item.personName!.split(' ').first}',
                        style: AppTypography.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Distinct Amount: -Terracotta for expense vs +Olive for income
          Text(
            isExpense ? '-$formattedAmount' : '+$formattedAmount',
            style: AppTypography.amountMedium.copyWith(
              color: isExpense ? AppColors.terracotta : AppColors.olive,
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
      builder: (_) => const _TransactionsFilterSheet(),
    );
  }
}

class _TransactionsFilterSheet extends ConsumerStatefulWidget {
  const _TransactionsFilterSheet();

  @override
  ConsumerState<_TransactionsFilterSheet> createState() => _TransactionsFilterSheetState();
}

class _TransactionsFilterSheetState extends ConsumerState<_TransactionsFilterSheet> {
  String? _tempCategoryId;
  String? _tempPersonId;
  String? _tempPaymentMethod;
  bool? _tempIsShared;
  DateTimeRange? _tempDateRange;
  late TransactionSortField _tempSortBy;
  late TransactionSortOrder _tempSortOrder;

  @override
  void initState() {
    super.initState();
    final current = ref.read(transactionsFilterProvider);
    _tempCategoryId = current.categoryId;
    _tempPersonId = current.personId;
    _tempPaymentMethod = current.paymentMethod;
    _tempIsShared = current.isShared;
    _tempSortBy = current.sortBy;
    _tempSortOrder = current.sortOrder;

    if (current.fromDate != null && current.toDate != null) {
      _tempDateRange = DateTimeRange(
        start: DateTime.tryParse(current.fromDate!) ?? DateTime.now(),
        end: DateTime.tryParse(current.toDate!) ?? DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(transactionsFilterProvider).tab;
    final categoryType = currentTab == TransactionTab.income ? 'INCOME' : null;
    final categoriesAsync = ref.watch(categoriesListProvider(categoryType));
    final membersAsync = ref.watch(familyRepositoryProvider).getFamilyMembers();

    final isIncomeTab = currentTab == TransactionTab.income;

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
                  'Filters & Sorting',
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
                      _tempPersonId = null;
                      _tempPaymentMethod = null;
                      _tempIsShared = null;
                      _tempDateRange = null;
                      _tempSortBy = TransactionSortField.date;
                      _tempSortOrder = TransactionSortOrder.desc;
                    });
                  },
                  child: const Text('Reset', style: TextStyle(color: AppColors.terracotta)),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // 1. Sort By & Order
            const Text('Sort By', style: AppTypography.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSortChip('Date', TransactionSortField.date),
                _buildSortChip('Amount', TransactionSortField.amount),
                _buildSortChip('Title', TransactionSortField.title),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Descending (Newest / Highest)'),
                  selected: _tempSortOrder == TransactionSortOrder.desc,
                  onSelected: (val) {
                    if (val) setState(() => _tempSortOrder = TransactionSortOrder.desc);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _tempSortOrder == TransactionSortOrder.desc ? AppColors.card : AppColors.dark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Ascending'),
                  selected: _tempSortOrder == TransactionSortOrder.asc,
                  onSelected: (val) {
                    if (val) setState(() => _tempSortOrder = TransactionSortOrder.asc);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _tempSortOrder == TransactionSortOrder.asc ? AppColors.card : AppColors.dark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Date Range Picker
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

            // 3. Category Filter
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
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.primary : AppColors.dark,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              loading: () => const LoadingState(size: 16),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // 4. Person Filter
            const Text('Person', style: AppTypography.labelSmall),
            const SizedBox(height: 8),
            FutureBuilder<List<FamilyMember>>(
              future: membersAsync,
              builder: (context, snap) {
                final members = snap.data ?? [];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: members.map((m) {
                    final isSel = _tempPersonId == m.userId;
                    return ChoiceChip(
                      label: Text(m.fullName ?? m.userId),
                      selected: isSel,
                      onSelected: (val) {
                        setState(() => _tempPersonId = val ? m.userId : null);
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

            // 5. Shared / Personal Filter (for Expenses & All)
            if (!isIncomeTab) ...[
              const Text('Shared / Personal', style: AppTypography.labelSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _tempIsShared == null,
                    onSelected: (val) {
                      if (val) setState(() => _tempIsShared = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Shared'),
                    selected: _tempIsShared == true,
                    onSelected: (val) {
                      setState(() => _tempIsShared = val ? true : null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Personal'),
                    selected: _tempIsShared == false,
                    onSelected: (val) {
                      setState(() => _tempIsShared = val ? false : null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Payment Method Filter
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
            ],

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
                  final notifier = ref.read(transactionsFilterProvider.notifier);
                  notifier.setCategory(_tempCategoryId);
                  notifier.setPerson(_tempPersonId);
                  notifier.setPaymentMethod(_tempPaymentMethod);
                  notifier.setIsShared(_tempIsShared);
                  notifier.setSorting(_tempSortBy, _tempSortOrder);
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

  Widget _buildSortChip(String label, TransactionSortField field) {
    final isSel = _tempSortBy == field;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (val) {
        if (val) setState(() => _tempSortBy = field);
      },
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: isSel ? AppColors.primary : AppColors.dark,
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
