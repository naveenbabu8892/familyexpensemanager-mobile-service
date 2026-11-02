import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../budgets/data/budget_repository_impl.dart';
import '../../budgets/domain/budget.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_charts_section.dart';
import 'dashboard_controller.dart';

/// Production Dashboard Screen connected to FastAPI backend.
/// Supports Loading, Error, Empty, and Success states, pull-to-refresh,
/// real month filtering, responsive layout, and vintage color palette.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardControllerProvider);
    final selectedDate = ref.watch(dashboardSelectedDateProvider);
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.fullName.isNotEmpty == true
        ? authState.user!.fullName.split(' ').first
        : 'Raj';
    final familyName = authState.family?.name.isNotEmpty == true
        ? authState.family!.name
        : 'The Sharma Family';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 360;
            final horizontalPadding = isSmallScreen ? 14.0 : 18.0;

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              onRefresh: () async {
                await ref.read(dashboardControllerProvider.notifier).refresh();
                ref.invalidate(currentBudgetsProvider);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // 1. Editorial Header Bar & Month Selector
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16.0,
                        horizontalPadding,
                        12.0,
                      ),
                      child: _buildHeader(
                        context,
                        ref,
                        userName: userName,
                        familyName: familyName,
                        selectedDate: selectedDate,
                      ),
                    ),
                  ),

                  // 2. Main Content based on AsyncValue states
                  ...dashboardAsync.when(
                    data: (dashboardData) => _buildSuccessContent(
                      context,
                      ref,
                      constraints,
                      horizontalPadding,
                      dashboardData,
                      selectedDate,
                    ),
                    loading: () => [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: LoadingState(
                            message: 'Loading your family finances...',
                          ),
                        ),
                      ),
                    ],
                    error: (error, _) => [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: ErrorState(
                            message: error.toString().replaceFirst('Exception: ', ''),
                            onRetry: () => ref.read(dashboardControllerProvider.notifier).refresh(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Greeting & Profile Header with Month Selector
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref, {
    required String userName,
    required String familyName,
    required DashboardMonthYear selectedDate,
  }) {
    final monthYearLabel = DateFormatter.formatMonthYear(
      selectedDate.month,
      selectedDate.year,
    );

    // User specified greeting: "Good evening, Raj"
    final greetingText = 'Good evening, $userName';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingText,
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: () => _showMonthPicker(context, ref, selectedDate),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '$monthYearLabel • $familyName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: AppColors.cardShadow,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.dark,
              size: 22,
            ),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ),
      ],
    );
  }

  /// Month & Year Picker Dialog
  Future<void> _showMonthPicker(
    BuildContext context,
    WidgetRef ref,
    DashboardMonthYear current,
  ) async {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    int chosenYear = current.year;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                        onPressed: () {
                          setSheetState(() => chosenYear--);
                        },
                      ),
                      Text(
                        '$chosenYear',
                        style: AppTypography.headingMedium.copyWith(color: AppColors.dark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                        onPressed: () {
                          setSheetState(() => chosenYear++);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthNum = index + 1;
                      final isSelected =
                          monthNum == current.month && chosenYear == current.year;

                      return InkWell(
                        onTap: () {
                          ref
                              .read(dashboardControllerProvider.notifier)
                              .selectMonthYear(monthNum, chosenYear);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            months[index].substring(0, 3),
                            style: TextStyle(
                              color: isSelected ? AppColors.card : AppColors.dark,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds Success Content Slivers
  List<Widget> _buildSuccessContent(
    BuildContext context,
    WidgetRef ref,
    BoxConstraints constraints,
    double horizontalPadding,
    DashboardData data,
    DashboardMonthYear selectedDate,
  ) {
    final summary = data.summary;
    final currency = summary.currency;
    final budgetsAsync = ref.watch(currentBudgetsProvider);
    final monthYearLabel = DateFormatter.formatMonthYear(
      selectedDate.month,
      selectedDate.year,
    );

    // Empty state if total income, total expenses, budgets, and transactions are all 0/empty
    final isCompletelyEmpty = summary.totalIncome == 0 &&
        summary.totalExpenses == 0 &&
        summary.recentTransactions.isEmpty &&
        (summary.budgetStatus == null || summary.budgetStatus!.activeBudgetsCount == 0);

    if (isCompletelyEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No Data for $monthYearLabel',
              message:
                  'Start managing your family finances by adding your first expense or setting up a budget.',
              actionLabel: 'Add Expense',
              onAction: () => context.push('/transactions'),
            ),
          ),
        ),
      ];
    }

    return [
      // 1. Hero Total Balance Card (Total Balance, Income, Expenses)
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 6.0,
          ),
          child: _buildBalanceHeroCard(context, constraints, summary),
        ),
      ),

      // 2. Personal vs Shared Expenses Split Cards (Shared, My, Spouse Expenses)
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8.0,
          ),
          child: _buildExpenseBreakdownCards(summary),
        ),
      ),

      // 3. Quick Action Buttons Row
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 10.0,
          ),
          child: _buildQuickActionsRow(context, constraints),
        ),
      ),

      // 4. Budget Summary Section Header
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12.0,
            horizontalPadding,
            4.0,
          ),
          child: SectionHeader(
            title: 'Budget Allocation',
            subtitle: monthYearLabel,
            actionText: 'Manage',
            onAction: () => context.push('/budgets'),
          ),
        ),
      ),

      // 5. Budget Summary Cards
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 6.0,
          ),
          child: _buildBudgetSummarySection(
            budgetsAsync: budgetsAsync,
            summary: summary,
            currency: currency,
          ),
        ),
      ),

      // 6. Recent Transactions Section Header
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16.0,
            horizontalPadding,
            4.0,
          ),
          child: SectionHeader(
            title: 'Recent Transactions',
            actionText: 'View All',
            onAction: () => context.push('/transactions'),
          ),
        ),
      ),

      // 7. Recent Transactions List
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            4.0,
            horizontalPadding,
            12.0,
          ),
          child: _buildRecentTransactionsCard(summary.recentTransactions, currency),
        ),
      ),

      // 8. Visual Charts Section Header
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16.0,
            horizontalPadding,
            4.0,
          ),
          child: SectionHeader(
            title: 'Financial Analytics',
            subtitle: 'Vintage Insights',
            actionText: 'Full Reports',
            onAction: () => context.push('/reports'),
          ),
        ),
      ),

      // 9. Charts Section (Expense by Category, Husband vs Wife, Income vs Expense)
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            6.0,
            horizontalPadding,
            28.0,
          ),
          child: DashboardChartsSection(
            categories: data.categoryBreakdown,
            members: data.memberBreakdown,
            totalIncome: summary.totalIncome,
            totalExpenses: summary.totalExpenses,
            myExpenses: summary.myExpenses,
            spouseExpenses: summary.spouseExpenses,
            currency: currency,
          ),
        ),
      ),
    ];
  }

  /// Warm Ivory Hero Balance Card with prominent serif typography
  Widget _buildBalanceHeroCard(
    BuildContext context,
    BoxConstraints constraints,
    DashboardSummary summary,
  ) {
    final isCompact = constraints.maxWidth < 360;
    final balanceText = _formatMoney(summary.remainingBalance, summary.currency);
    final incomeText = _formatMoney(summary.totalIncome, summary.currency);
    final expenseText = _formatMoney(summary.totalExpenses, summary.currency);

    return VintageCard(
      padding: EdgeInsets.all(isCompact ? 14 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'TOTAL BALANCE',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: AppColors.mutedGold),
                    SizedBox(width: 5),
                    Text(
                      'Shared Vault',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Hero Prominent Amount
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              balanceText,
              style: AppTypography.amountHero,
            ),
          ),
          const SizedBox(height: 20),

          // Divider with vintage ornament line
          Container(
            height: 1,
            color: AppColors.borderLight,
          ),
          const SizedBox(height: 16),

          // Income and Expense Dual Indicators
          Row(
            children: [
              // Income Pill
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.oliveLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        size: 18,
                        color: AppColors.olive,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              incomeText,
                              style: AppTypography.amountMedium.copyWith(
                                color: AppColors.olive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 36,
                width: 1,
                color: AppColors.borderLight,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),

              // Expense Pill
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.terracottaLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: AppColors.terracotta,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expenses',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              expenseText,
                              style: AppTypography.amountMedium.copyWith(
                                color: AppColors.terracotta,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shared Expenses, My Expenses, Spouse Expenses Cards
  Widget _buildExpenseBreakdownCards(DashboardSummary summary) {
    final currency = summary.currency;

    return Row(
      children: [
        // Shared Expenses Card
        Expanded(
          child: _buildMiniStatCard(
            label: 'Shared',
            amount: _formatMoney(summary.sharedExpenses, currency),
            accentColor: AppColors.primary,
            bgColor: AppColors.primaryLight,
            icon: Icons.people_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),

        // My Expenses Card
        Expanded(
          child: _buildMiniStatCard(
            label: 'My Expenses',
            amount: _formatMoney(summary.myExpenses, currency),
            accentColor: AppColors.terracotta,
            bgColor: AppColors.terracottaLight,
            icon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),

        // Spouse Expenses Card
        Expanded(
          child: _buildMiniStatCard(
            label: 'Spouse',
            amount: _formatMoney(summary.spouseExpenses, currency),
            accentColor: AppColors.mutedGold,
            bgColor: AppColors.goldLight,
            icon: Icons.favorite_border_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required String label,
    required String amount,
    required Color accentColor,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: AppTypography.amountSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Action Buttons
  Widget _buildQuickActionsRow(BuildContext context, BoxConstraints constraints) {
    return Row(
      children: [
        Expanded(
          child: _buildActionItem(
            icon: Icons.add_rounded,
            label: 'Add Expense',
            accentColor: AppColors.terracotta,
            bgColor: AppColors.terracottaLight,
            onTap: () => context.push('/transactions'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionItem(
            icon: Icons.payments_outlined,
            label: 'Add Income',
            accentColor: AppColors.olive,
            bgColor: AppColors.oliveLight,
            onTap: () => context.push('/transactions'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionItem(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Set Budget',
            accentColor: AppColors.primary,
            bgColor: AppColors.primaryLight,
            onTap: () => context.push('/budgets'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color accentColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Budget Summary Section
  Widget _buildBudgetSummarySection({
    required AsyncValue<List<Budget>> budgetsAsync,
    required DashboardSummary summary,
    required String currency,
  }) {
    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) {
          // If no specific category budgets exist, display consolidated budget status from summary
          final bs = summary.budgetStatus;
          if (bs != null && bs.totalBudget > 0) {
            return BudgetProgressCard(
              categoryName: 'Consolidated Budget',
              spentAmount: _formatMoney(bs.totalSpent, currency),
              totalBudget: _formatMoney(bs.totalBudget, currency),
              percentage: bs.percentageUsed,
              warningBadge: '${bs.percentageUsed.toStringAsFixed(0)}% used',
            );
          }
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pie_chart_outline_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No active budgets found for this month.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            for (int i = 0; i < budgets.take(3).length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              BudgetProgressCard(
                categoryName: budgets[i].categoryName ?? 'Category',
                spentAmount: _formatMoney(budgets[i].amountSpent, currency),
                totalBudget: _formatMoney(budgets[i].amount, currency),
                percentage: budgets[i].percentageUsed,
                warningBadge: '${budgets[i].percentageUsed.toStringAsFixed(0)}% used',
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: AppLoadingIndicator(),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Recent Transactions Card
  Widget _buildRecentTransactionsCard(
    List<DashboardTransactionItem> transactions,
    String currency,
  ) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            'No recent transactions.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return VintageCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < transactions.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 70, endIndent: 16),
            TransactionTile(
              title: transactions[i].title,
              category: transactions[i].categoryName ??
                  transactions[i].categoryIcon ??
                  'other',
              date: _formatTxDate(transactions[i].date),
              amount: _formatMoney(transactions[i].amount, currency),
              isExpense: transactions[i].isExpense,
              isShared: transactions[i].isShared ?? true,
              payer: transactions[i].userName.isNotEmpty
                  ? transactions[i].userName.split(' ').first
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  /// Formats currency with or without decimals based on amount
  static String _formatMoney(double amount, String currency) {
    if (amount % 1 == 0) {
      return CurrencyFormatter.formatNoDecimals(amount, currency: currency);
    }
    return CurrencyFormatter.format(amount, currency: currency);
  }

  /// Formats date display for transaction items
  static String _formatTxDate(String isoDate) {
    final parsed = DateFormatter.parseIsoDate(isoDate);
    if (parsed == null) return isoDate;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(parsed.year, parsed.month, parsed.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    return DateFormatter.formatDisplay(parsed);
  }
}
