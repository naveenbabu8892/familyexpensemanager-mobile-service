import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/reports_models.dart';
import 'reports_controller.dart';

/// Complete Reports Screen consuming FastAPI endpoints:
/// - Monthly report (Monthly trends & savings)
/// - Category report (Pie / Donut distribution)
/// - Member report (Husband vs Wife comparison)
/// - Payment method report (Instruments breakdown)
/// Filters:
/// - Current month
/// - Previous month
/// - Custom date range
/// Charts:
/// - Pie / Donut category chart
/// - Husband vs Wife bar chart
/// - Income vs Expense comparison
/// - Monthly trend timeline
/// States:
/// - Loading
/// - Empty
/// - Error
/// - Success
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(reportsFilterProvider);
    final reportsAsync = ref.watch(reportsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(reportsControllerProvider.notifier).refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.dark,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Members'),
            Tab(text: 'Monthly Trend'),
            Tab(text: 'Payment Methods'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Period Filter Selector Bar
            _buildFilterBar(context, filterState),

            // 2. Report Content Tabs
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.card,
                onRefresh: () async {
                  await ref.read(reportsControllerProvider.notifier).refresh();
                },
                child: reportsAsync.when(
                  data: (data) {
                    if (data.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: EmptyState(
                              icon: Icons.query_stats_rounded,
                              title: 'No Data for ${filterState.label}',
                              message:
                                  'There are no transactions recorded for the selected period.',
                              actionLabel: 'Refresh',
                              onAction: () =>
                                  ref.read(reportsControllerProvider.notifier).refresh(),
                            ),
                          ),
                        ],
                      );
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCategoryReportTab(data),
                        _buildMemberReportTab(data),
                        _buildMonthlyReportTab(data),
                        _buildPaymentMethodTab(data),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: LoadingState(message: 'Generating financial reports...'),
                  ),
                  error: (error, _) => Center(
                    child: ErrorState(
                      message: 'Failed to generate reports. Pull down to retry.',
                      onRetry: () =>
                          ref.read(reportsControllerProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Filter Bar (Current Month, Previous Month, Custom Range)
  // ==========================================
  Widget _buildFilterBar(BuildContext context, ReportsFilterState filter) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Current Month'),
              selected: filter.filterType == ReportFilterType.currentMonth,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.background,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filter.filterType == ReportFilterType.currentMonth
                    ? Colors.white
                    : AppColors.dark,
              ),
              onSelected: (_) {
                ref.read(reportsFilterProvider.notifier).selectCurrentMonth();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Previous Month'),
              selected: filter.filterType == ReportFilterType.previousMonth,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.background,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filter.filterType == ReportFilterType.previousMonth
                    ? Colors.white
                    : AppColors.dark,
              ),
              onSelected: (_) {
                ref.read(reportsFilterProvider.notifier).selectPreviousMonth();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    filter.filterType == ReportFilterType.customRange
                        ? filter.label
                        : 'Custom Range',
                  ),
                ],
              ),
              selected: filter.filterType == ReportFilterType.customRange,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.background,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filter.filterType == ReportFilterType.customRange
                    ? Colors.white
                    : AppColors.dark,
              ),
              onSelected: (_) => _pickCustomDateRange(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(reportsFilterProvider.notifier)
          .selectCustomRange(picked.start, picked.end);
    }
  }

  // ==========================================
  // Tab 1: Category Report (Pie / Donut Chart)
  // ==========================================
  Widget _buildCategoryReportTab(ReportsData data) {
    final report = data.categoryReport;
    final categories = report.categories;
    final totalAmount = report.totalAmount;
    final currency = report.currency;

    if (categories.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          EmptyState(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No Category Breakdown',
            message: 'No recorded category spending for the selected period.',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Authoritative Total Summary Card
        VintageCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL SPENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatNoDecimals(totalAmount, currency: currency),
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.terracotta,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${categories.length} Categories',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pie / Donut Chart Card
        VintageCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Category Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.terracottaLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Donut Chart',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Donut Chart Graphic & Center Total
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(200, 200),
                        painter: _VintageDonutChartPainter(categories: categories),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Top Category',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            categories.first.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                          Text(
                            '${categories.first.percentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.terracotta,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Segmented Proportional Line Indicator
              _buildProportionalSegmentsBar(categories),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Detailed List of Categories
        const Text(
          'Breakdown Details',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 10),

        ...categories.map((cat) {
          final color = _resolveCategoryColor(cat.color, cat.categoryName);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VintageCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.categoryName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark,
                          ),
                        ),
                        if (cat.transactionCount > 0)
                          Text(
                            '${cat.transactionCount} transactions',
                            style: AppTypography.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        cat.totalAmount % 1 == 0
                            ? CurrencyFormatter.formatNoDecimals(cat.totalAmount, currency: currency)
                            : CurrencyFormatter.format(cat.totalAmount, currency: currency),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        '${cat.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // Tab 2: Member Report (Husband vs Wife Bar Chart)
  // ==========================================
  Widget _buildMemberReportTab(ReportsData data) {
    final report = data.memberReport;
    final members = report.members;
    final totalExpenses = report.totalExpenses;
    final currency = report.currency;

    if (members.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No Member Data',
            message: 'No family member contributions found for this period.',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Husband vs Wife Comparison Bar Chart Card
        VintageCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Husband vs Wife',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Comparison Bar Chart',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Relative comparison bars
              for (int i = 0; i < members.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _buildMemberBar(
                  member: members[i],
                  totalExpenses: totalExpenses,
                  currency: currency,
                  color: i == 0 ? AppColors.primary : AppColors.mutedGold,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Shared vs Personal Breakdown Card
        VintageCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shared vs Personal Spending',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn(
                    'Shared Expenses',
                    CurrencyFormatter.format(report.sharedExpenses, currency: currency),
                    AppColors.mutedGold,
                  ),
                  _buildStatColumn(
                    'Personal Expenses',
                    CurrencyFormatter.format(report.personalExpenses, currency: currency),
                    AppColors.terracotta,
                  ),
                  _buildStatColumn(
                    'Total Paid',
                    CurrencyFormatter.format(totalExpenses, currency: currency),
                    AppColors.dark,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Individual Member Detail Cards
        const Text(
          'Individual Member Cards',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 10),

        ...members.map((member) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: VintageCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryContainer,
                            child: Text(
                              member.memberName.isNotEmpty
                                  ? member.memberName[0].toUpperCase()
                                  : 'M',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.memberName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark,
                                ),
                              ),
                              Row(
                                children: [
                                  if (member.relationshipLabel.isNotEmpty) ...[
                                    Text(
                                      member.relationshipLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('•', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    member.role.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${member.percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Spent: ${CurrencyFormatter.format(member.totalSpent, currency: currency)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (member.incomeEarned > 0)
                        Text(
                          'Income: +${CurrencyFormatter.format(member.incomeEarned, currency: currency)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.olive,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMemberBar({
    required MemberReportItem member,
    required double totalExpenses,
    required String currency,
    required Color color,
  }) {
    final ratio = totalExpenses > 0
        ? (member.totalSpent / totalExpenses).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              member.memberName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            Text(
              '${CurrencyFormatter.format(member.totalSpent, currency: currency)} (${member.percentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 12,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Tab 3: Monthly Report (Income vs Expense & Monthly Trend)
  // ==========================================
  Widget _buildMonthlyReportTab(ReportsData data) {
    final months = data.monthlyReport;
    final currentYear = data.filters.year ?? DateTime.now().year;

    // Filter to months with activity or show whole calendar
    final activeMonths = months.where((m) => m.income > 0 || m.expense > 0).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Income vs Expense Summary Card
        VintageCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Income vs Expense ($currentYear)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.oliveLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Annual Cashflow',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.olive,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Cumulative Income vs Cumulative Expense
              Builder(
                builder: (context) {
                  final cumIncome = months.fold<double>(0.0, (s, m) => s + m.income);
                  final cumExpenses = months.fold<double>(0.0, (s, m) => s + m.expense);
                  final maxVal = math.max(cumIncome, cumExpenses);
                  final incRatio = maxVal > 0 ? (cumIncome / maxVal).clamp(0.0, 1.0) : 0.0;
                  final expRatio = maxVal > 0 ? (cumExpenses / maxVal).clamp(0.0, 1.0) : 0.0;

                  return Column(
                    children: [
                      _buildCashflowBarRow(
                        label: 'Annual Income',
                        amount: CurrencyFormatter.format(cumIncome),
                        ratio: incRatio,
                        color: AppColors.olive,
                        icon: Icons.trending_up_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildCashflowBarRow(
                        label: 'Annual Expenses',
                        amount: CurrencyFormatter.format(cumExpenses),
                        ratio: expRatio,
                        color: AppColors.terracotta,
                        icon: Icons.trending_down_rounded,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Monthly Trend Timeline Chart
        VintageCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Trend',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 16),

              // Interactive / readable trend list with bars
              if (activeMonths.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No transaction activity found for this year.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ...activeMonths.map((m) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              m.monthName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark,
                              ),
                            ),
                            Text(
                              'Savings: ${CurrencyFormatter.format(m.savings)} (${m.savingsRate.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: m.savings >= 0 ? AppColors.olive : AppColors.exceeded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (m.expense / (m.income > 0 ? m.income : m.expense))
                                      .clamp(0.0, 1.0),
                                  minHeight: 7,
                                  backgroundColor: AppColors.oliveLight,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppColors.terracotta),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Exp: ${CurrencyFormatter.format(m.expense)}',
                              style: AppTypography.bodySmall,
                            ),
                            Text(
                              'Inc: ${CurrencyFormatter.format(m.income)}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCashflowBarRow({
    required String label,
    required String amount,
    required double ratio,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Tab 4: Payment Method Report
  // ==========================================
  Widget _buildPaymentMethodTab(ReportsData data) {
    final report = data.paymentMethodReport;
    final methods = report.paymentMethods;
    final totalAmount = report.totalAmount;
    final currency = report.currency;

    if (methods.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          EmptyState(
            icon: Icons.credit_card_outlined,
            title: 'No Payment Method Data',
            message: 'No payment method transactions recorded for this period.',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        VintageCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL BY INSTRUMENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(totalAmount, currency: currency),
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${methods.length} Methods',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Breakdown List
        const Text(
          'Instruments Distribution',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 10),

        ...methods.map((pm) {
          final ratio = totalAmount > 0
              ? (pm.amount / totalAmount).clamp(0.0, 1.0)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: VintageCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _resolvePaymentIcon(pm.paymentMethod),
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatPaymentMethodName(pm.paymentMethod),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${pm.percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: AppColors.borderLight,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${pm.transactionCount} transactions',
                        style: AppTypography.bodySmall,
                      ),
                      Text(
                        CurrencyFormatter.format(pm.amount, currency: currency),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // Visual Helpers
  // ==========================================
  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProportionalSegmentsBar(List<CategoryReportItem> categories) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: categories.map((cat) {
            final flexVal = math.max(1, (cat.percentage * 10).round());
            final color = _resolveCategoryColor(cat.color, cat.categoryName);
            return Expanded(
              flex: flexVal,
              child: Container(color: color),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _resolveCategoryColor(String hexOrKey, String name) {
    if (hexOrKey.startsWith('#')) {
      final hex = hexOrKey.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      }
    }
    final palette = [
      AppColors.terracotta,
      AppColors.olive,
      AppColors.mutedGold,
      AppColors.primary,
      const Color(0xFF8B5E3C),
      const Color(0xFF6B7280),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }

  IconData _resolvePaymentIcon(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('upi')) return Icons.account_balance_wallet_outlined;
    if (lower.contains('card') || lower.contains('credit') || lower.contains('debit')) {
      return Icons.credit_card_outlined;
    }
    if (lower.contains('cash')) return Icons.payments_outlined;
    if (lower.contains('bank') || lower.contains('transfer')) {
      return Icons.account_balance_outlined;
    }
    return Icons.wallet_outlined;
  }

  String _formatPaymentMethodName(String method) {
    final lower = method.toLowerCase().replaceAll('_', ' ');
    if (lower.contains('upi')) return 'UPI';
    if (lower.contains('credit card')) return 'Credit Card';
    if (lower.contains('debit card')) return 'Debit Card';
    if (lower.contains('cash')) return 'Cash';
    if (lower.contains('bank transfer')) return 'Bank Transfer';
    return method.toUpperCase();
  }
}

/// Custom Donut Chart Painter respecting the Vintage Palette and guaranteeing readable segments.
class _VintageDonutChartPainter extends CustomPainter {
  final List<CategoryReportItem> categories;

  _VintageDonutChartPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    const strokeWidth = 26.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;

    for (final cat in categories) {
      final sweepAngle = (cat.percentage / 100.0) * (2 * math.pi);
      paint.color = _parseColor(cat.color, cat.categoryName);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  Color _parseColor(String hexOrKey, String name) {
    if (hexOrKey.startsWith('#')) {
      final hex = hexOrKey.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      }
    }
    final palette = [
      AppColors.terracotta,
      AppColors.olive,
      AppColors.mutedGold,
      AppColors.primary,
      const Color(0xFF8B5E3C),
      const Color(0xFF6B7280),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }

  @override
  bool shouldRepaint(covariant _VintageDonutChartPainter oldDelegate) =>
      oldDelegate.categories != categories;
}
