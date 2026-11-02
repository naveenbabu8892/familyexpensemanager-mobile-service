import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_floating_action_button.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/vintage_card.dart';
import '../../categories/data/category_repository_impl.dart';
import '../../family/data/family_repository_impl.dart';
import '../../family/domain/family.dart';
import '../domain/income.dart';
import 'income_detail_screen.dart';
import 'income_form_screen.dart';
import 'income_list_controller.dart';

/// Screen displaying paginated Income records with filter tabs and advanced filter sheet.
class IncomeListScreen extends ConsumerStatefulWidget {
  const IncomeListScreen({super.key});

  @override
  ConsumerState<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends ConsumerState<IncomeListScreen> {
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
      ref.read(incomeListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openAddIncome(BuildContext context) async {
    final result = await Navigator.of(context).push<Income>(
      MaterialPageRoute(
        builder: (_) => const IncomeFormScreen(),
      ),
    );
    if (result != null && mounted) {
      ref.read(incomeListControllerProvider.notifier).refresh();
    }
  }

  Future<void> _openIncomeDetail(BuildContext context, Income income) async {
    final deletedOrUpdated = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => IncomeDetailScreen(
          incomeId: income.id,
          initialIncome: income,
        ),
      ),
    );
    if (deletedOrUpdated != null && mounted) {
      ref.read(incomeListControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeStateAsync = ref.watch(incomeListControllerProvider);
    final filterState = ref.watch(incomeFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Income'),
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
            tooltip: 'Filter Income',
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Filter Tabs Bar: All, My Income, Spouse Income
            _buildFilterTabs(filterState.tab),

            // 2. Active Filter Chips Indicator
            if (filterState.hasActiveAdvancedFilters)
              _buildActiveFiltersBar(filterState),

            // 3. Paginated Income List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.card,
                onRefresh: () async {
                  await ref.read(incomeListControllerProvider.notifier).refresh();
                },
                child: incomeStateAsync.when(
                  data: (state) {
                    if (state.items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: EmptyState(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'No Income Found',
                              message: filterState.hasActiveAdvancedFilters
                                  ? 'No income entries match the selected filters.'
                                  : 'Start recording your salary and earnings to manage family finances.',
                              actionLabel: 'Add Income',
                              onAction: () => _openAddIncome(context),
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
                              child: LoadingState(size: 24, message: 'Loading more income...'),
                            ),
                          );
                        }

                        final income = state.items[index];
                        return _buildIncomeTile(context, income);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: LoadingState(message: 'Loading income entries...'),
                  ),
                  error: (error, _) => Center(
                    child: ErrorState(
                      message: 'Failed to load income entries. Please try again.',
                      onRetry: () =>
                          ref.read(incomeListControllerProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AppFloatingActionButton(
        label: 'Add Income',
        icon: Icons.add_rounded,
        onPressed: () => _openAddIncome(context),
      ),
    );
  }

  Widget _buildFilterTabs(IncomeFilterTab activeTab) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabChip('All', IncomeFilterTab.all, activeTab),
            const SizedBox(width: 8),
            _buildTabChip('My Income', IncomeFilterTab.myIncome, activeTab),
            const SizedBox(width: 8),
            _buildTabChip('Spouse Income', IncomeFilterTab.spouseIncome, activeTab),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, IncomeFilterTab tab, IncomeFilterTab current) {
    final isSelected = tab == current;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(incomeFilterProvider.notifier).setTab(tab);
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

  Widget _buildActiveFiltersBar(IncomeFilterState filter) {
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
              ref.read(incomeFilterProvider.notifier).clearFilters();
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

  Widget _buildIncomeTile(BuildContext context, Income income) {
    final formattedAmount = income.amount % 1 == 0
        ? CurrencyFormatter.formatNoDecimals(income.amount, currency: income.currency)
        : CurrencyFormatter.format(income.amount, currency: income.currency);
    final displayDate = income.incomeDate.isNotEmpty
        ? (DateFormatter.parseIsoDate(income.incomeDate) != null
            ? DateFormatter.formatDisplay(DateFormatter.parseIsoDate(income.incomeDate)!)
            : income.incomeDate)
        : '';

    return VintageCard(
      onTap: () => _openIncomeDetail(context, income),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CategoryIcon(
            iconKey: income.categoryName ?? 'payments',
            color: AppColors.olive,
            backgroundColor: AppColors.oliveLight,
            containerSize: 44,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income.title,
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
                    if (income.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.oliveLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          income.categoryName!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.olive,
                          ),
                        ),
                      ),
                    if (income.receivedByName != null && income.receivedByName!.isNotEmpty)
                      Text(
                        '• ${income.receivedByName!.split(' ').first}',
                        style: AppTypography.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '+$formattedAmount',
            style: AppTypography.amountMedium.copyWith(
              color: AppColors.olive,
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
      builder: (_) => const _IncomeFilterSheet(),
    );
  }
}

class _IncomeFilterSheet extends ConsumerStatefulWidget {
  const _IncomeFilterSheet();

  @override
  ConsumerState<_IncomeFilterSheet> createState() => _IncomeFilterSheetState();
}

class _IncomeFilterSheetState extends ConsumerState<_IncomeFilterSheet> {
  String? _tempCategoryId;
  String? _tempReceivedById;
  DateTimeRange? _tempDateRange;

  @override
  void initState() {
    super.initState();
    final current = ref.read(incomeFilterProvider);
    _tempCategoryId = current.categoryId;
    _tempReceivedById = current.receivedBy;
    if (current.fromDate != null && current.toDate != null) {
      _tempDateRange = DateTimeRange(
        start: DateTime.tryParse(current.fromDate!) ?? DateTime.now(),
        end: DateTime.tryParse(current.toDate!) ?? DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider('INCOME'));
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
                  'Filter Income',
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
                      _tempReceivedById = null;
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
                    selectedColor: AppColors.oliveLight,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.olive : AppColors.dark,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              loading: () => const LoadingState(size: 16),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // Received By Member
            const Text('Received By', style: AppTypography.labelSmall),
            const SizedBox(height: 8),
            FutureBuilder<List<FamilyMember>>(
              future: membersAsync,
              builder: (context, snap) {
                final members = snap.data ?? [];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: members.map((m) {
                    final isSel = _tempReceivedById == m.userId;
                    return ChoiceChip(
                      label: Text(m.fullName ?? m.userId),
                      selected: isSel,
                      onSelected: (val) {
                        setState(() => _tempReceivedById = val ? m.userId : null);
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
                  final notifier = ref.read(incomeFilterProvider.notifier);
                  notifier.setCategory(_tempCategoryId);
                  notifier.setReceivedBy(_tempReceivedById);
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
