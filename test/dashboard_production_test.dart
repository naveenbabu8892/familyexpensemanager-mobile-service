import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/widgets.dart';
import 'package:mobile/features/budgets/data/budget_repository_impl.dart';
import 'package:mobile/features/budgets/domain/budget.dart';
import 'package:mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/dashboard_charts_section.dart';
import 'package:mobile/features/dashboard/presentation/dashboard_controller.dart';
import 'package:mobile/features/dashboard/presentation/home_screen.dart';
import 'package:mobile/features/reports/domain/reports_models.dart';

void main() {
  group('Production Dashboard State & UI Tests', () {
    testWidgets('Displays Loading state with warm loading indicator', (tester) async {
      final completer = Completer<DashboardData>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardControllerProvider.overrideWith(() => _LoadingDashboardController(completer.future)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      expect(find.byType(LoadingState), findsOneWidget);
      expect(find.text('Loading your family finances...'), findsOneWidget);
    });

    testWidgets('Displays Error state and retries on press', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardControllerProvider.overrideWith(() => _ErrorDashboardController(() {
                  retried = true;
                })),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Network timeout. Could not connect to server.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });

    testWidgets('Displays Empty state when no data exists for selected period', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardControllerProvider.overrideWith(() => _EmptyDashboardController()),
            currentBudgetsProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.textContaining('No Data for'), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);
    });

    testWidgets('Displays Success state with real balance card, expense breakdowns, and charts',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardControllerProvider.overrideWith(() => _SuccessDashboardController()),
            currentBudgetsProvider.overrideWith((ref) async => [
                  const Budget(
                    id: 'b-grocery',
                    familyId: 'fam-1',
                    categoryId: 'cat-grocery',
                    categoryName: 'Grocery',
                    amount: 10000,
                    month: 10,
                    year: 2026,
                    createdBy: 'usr-1',
                    amountSpent: 7200,
                    remainingAmount: 2800,
                    percentageUsed: 72.0,
                  ),
                ]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MediaQuery(
              data: MediaQueryData(size: Size(400, 1800)),
              child: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top: Greeting & Month selector
      expect(find.text('Good evening, Raj'), findsOneWidget);
      expect(find.textContaining('October 2026'), findsWidgets);

      // Main balance card: ₹35,000, Income: ₹80,000, Expenses: ₹45,000
      expect(find.text('TOTAL BALANCE'), findsOneWidget);
      expect(find.text('₹35,000'), findsOneWidget);
      expect(find.text('Income'), findsWidgets);
      expect(find.text('₹80,000'), findsWidgets);
      expect(find.text('Expenses'), findsWidgets);
      expect(find.text('₹45,000'), findsWidgets);

      // Shared Expenses, My Expenses, Spouse Expenses
      expect(find.text('Shared'), findsOneWidget);
      expect(find.text('₹30,000'), findsOneWidget);
      expect(find.text('My Expenses'), findsWidgets);
      expect(find.text('₹25,000'), findsWidgets);
      expect(find.text('Spouse'), findsOneWidget);
      expect(find.text('₹20,000'), findsOneWidget);

      // Budget summary: Grocery ₹7,200 / ₹10,000 72%
      expect(find.text('Grocery'), findsWidgets);
      expect(find.text('₹7,200 spent'), findsOneWidget);
      expect(find.text('₹10,000 budget'), findsOneWidget);
      expect(find.text('72% used'), findsOneWidget);

      // Recent transactions
      await tester.scrollUntilVisible(find.text('Weekly Grocery Shopping'), 100);
      expect(find.text('Weekly Grocery Shopping'), findsOneWidget);
      expect(find.text('-₹2,450'), findsOneWidget);

      // Charts section
      await tester.scrollUntilVisible(find.text('Income vs Expense'), 100);
      expect(find.byType(DashboardChartsSection), findsOneWidget);
      expect(find.text('Income vs Expense'), findsOneWidget);
      expect(find.text('Husband vs Wife'), findsOneWidget);
      expect(find.text('Expense by Category'), findsOneWidget);
    });
  });
}

class _LoadingDashboardController extends DashboardController {
  final Future<DashboardData> pendingFuture;
  _LoadingDashboardController(this.pendingFuture);

  @override
  Future<DashboardData> build() async => pendingFuture;
}

class _ErrorDashboardController extends DashboardController {
  final VoidCallback onRetry;
  _ErrorDashboardController(this.onRetry);

  @override
  Future<DashboardData> build() async {
    throw Exception('Network timeout. Could not connect to server.');
  }

  @override
  Future<void> refresh() async {
    onRetry();
  }
}

class _EmptyDashboardController extends DashboardController {
  @override
  Future<DashboardData> build() async {
    return const DashboardData(
      summary: DashboardSummary(
        currency: 'INR',
        totalIncome: 0,
        totalExpenses: 0,
        remainingBalance: 0,
        sharedExpenses: 0,
        personalExpenses: 0,
        myExpenses: 0,
        spouseExpenses: 0,
        recentTransactions: [],
      ),
      categoryBreakdown: [],
      memberBreakdown: [],
    );
  }
}

class _SuccessDashboardController extends DashboardController {
  @override
  Future<DashboardData> build() async {
    return const DashboardData(
      summary: DashboardSummary(
        currency: 'INR',
        totalIncome: 80000,
        totalExpenses: 45000,
        remainingBalance: 35000,
        savingsRate: 43.75,
        sharedExpenses: 30000,
        personalExpenses: 15000,
        myExpenses: 25000,
        spouseExpenses: 20000,
        recentTransactions: [
          DashboardTransactionItem(
            id: 'tx-101',
            title: 'Weekly Grocery Shopping',
            type: 'expense',
            amount: 2450,
            currency: 'INR',
            date: '2026-10-05',
            categoryName: 'grocery',
            userName: 'Raj',
            isShared: true,
          ),
        ],
      ),
      categoryBreakdown: [
        CategoryReportItem(
          categoryId: 'cat-grocery',
          categoryName: 'Grocery',
          color: '#B86B4B',
          totalAmount: 18000,
          percentage: 40.0,
        ),
        CategoryReportItem(
          categoryId: 'cat-housing',
          categoryName: 'Housing',
          color: '#657153',
          totalAmount: 27000,
          percentage: 60.0,
        ),
      ],
      memberBreakdown: [
        MemberReportItem(
          memberId: 'usr-1',
          memberName: 'Raj',
          role: 'owner',
          totalSpent: 25000,
          percentage: 55.5,
        ),
        MemberReportItem(
          memberId: 'usr-2',
          memberName: 'Priya',
          role: 'member',
          totalSpent: 20000,
          percentage: 44.5,
        ),
      ],
    );
  }
}
