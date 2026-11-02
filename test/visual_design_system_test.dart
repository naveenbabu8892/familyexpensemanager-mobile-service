import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/widgets.dart';
import 'package:mobile/features/budgets/data/budget_repository_impl.dart';
import 'package:mobile/features/budgets/domain/budget.dart';
import 'package:mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/dashboard_controller.dart';
import 'package:mobile/features/dashboard/presentation/home_screen.dart';

final _testDashboardData = DashboardData(
  summary: const DashboardSummary(
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
        id: 'tx-1',
        title: 'Grocery',
        type: 'expense',
        amount: 2450,
        currency: 'INR',
        date: '2026-10-05',
        categoryName: 'grocery',
        userName: 'Raj',
        isShared: true,
      ),
      DashboardTransactionItem(
        id: 'tx-2',
        title: 'Electricity',
        type: 'expense',
        amount: 1820,
        currency: 'INR',
        date: '2026-10-04',
        categoryName: 'electricity',
        userName: 'Priya',
        isShared: true,
      ),
      DashboardTransactionItem(
        id: 'tx-3',
        title: 'Restaurant',
        type: 'expense',
        amount: 950,
        currency: 'INR',
        date: '2026-10-02',
        categoryName: 'dining',
        userName: 'Raj',
        isShared: false,
      ),
    ],
  ),
);

Widget _wrapWithTheme(
  Widget child, {
  Size size = const Size(400, 800),
}) {
  return ProviderScope(
    overrides: [
      dashboardControllerProvider.overrideWith(() => _MockDashboardController()),
      currentBudgetsProvider.overrideWith((ref) async => const [
        Budget(
          id: 'b-1',
          familyId: 'fam-1',
          categoryId: 'cat-1',
          categoryName: 'Grocery & Essentials',
          amount: 22000,
          month: 10,
          year: 2026,
          createdBy: 'usr-1',
          amountSpent: 18500,
          remainingAmount: 3500,
          percentageUsed: 84.0,
        ),
        Budget(
          id: 'b-2',
          familyId: 'fam-1',
          categoryId: 'cat-2',
          categoryName: 'Dining & Cafes',
          amount: 9000,
          month: 10,
          year: 2026,
          createdBy: 'usr-1',
          amountSpent: 8200,
          remainingAmount: 800,
          percentageUsed: 91.0,
        ),
      ]),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: child),
      ),
    ),
  );
}

class _MockDashboardController extends DashboardController {
  @override
  Future<DashboardData> build() async => _testDashboardData;
}

void main() {
  group('Visual Design System - 16 Reusable Widgets', () {
    testWidgets('1. VintageCard renders with content and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          VintageCard(
            onTap: () => tapped = true,
            child: const Text('Vintage Card Content'),
          ),
        ),
      );

      expect(find.text('Vintage Card Content'), findsOneWidget);
      await tester.tap(find.text('Vintage Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('2. VintageButton renders label and icon, reacts to taps', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          VintageButton(
            text: 'Save Transaction',
            icon: Icons.check,
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.text('Save Transaction'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.byType(VintageButton));
      expect(pressed, isTrue);
    });

    testWidgets('3. VintageOutlinedButton renders and handles tap', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          VintageOutlinedButton(
            text: 'Cancel',
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.byType(VintageOutlinedButton));
      expect(pressed, isTrue);
    });

    testWidgets('4. VintageTextField renders label, hint, and accepts text', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrapWithTheme(
          VintageTextField(
            label: 'Transaction Title',
            hint: 'e.g. Weekly Grocery',
            controller: controller,
          ),
        ),
      );

      expect(find.text('Transaction Title'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Monthly Groceries');
      expect(controller.text, 'Monthly Groceries');
    });

    testWidgets('5. AmountInput formats and displays currency input', (tester) async {
      final controller = TextEditingController(text: '1250');
      await tester.pumpWidget(
        _wrapWithTheme(
          AmountInput(
            controller: controller,
            currencySymbol: '₹',
          ),
        ),
      );

      expect(find.text('₹'), findsOneWidget);
      expect(find.text('1250'), findsOneWidget);
    });

    testWidgets('6. CategoryIcon displays assigned icon with tint', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const CategoryIcon(
            iconKey: 'grocery',
            backgroundColor: AppColors.primaryLight,
            color: AppColors.primary,
          ),
        ),
      );

      expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
    });

    testWidgets('7. CategoryCard renders label and selection state', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          CategoryCard(
            title: 'Groceries',
            iconKey: 'grocery',
            isSelected: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Groceries'), findsOneWidget);
      await tester.tap(find.text('Groceries'));
      expect(tapped, isTrue);
    });

    testWidgets('8. TransactionTile displays title, amount, subtitle, and badge', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const TransactionTile(
            title: 'Grocery Store',
            category: 'grocery',
            date: 'Today',
            amount: '₹2,450',
            isExpense: true,
            payer: 'Raj',
          ),
        ),
      );

      expect(find.text('Grocery Store'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('-₹2,450'), findsOneWidget);
      expect(find.text('• Raj'), findsOneWidget);
    });

    testWidgets('9. SummaryCard renders label, formatted amount, and accent', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const SummaryCard(
            label: 'Total Expenses',
            amount: '₹45,000',
            icon: Icons.arrow_upward_rounded,
            accentColor: AppColors.terracotta,
          ),
        ),
      );

      expect(find.text('Total Expenses'), findsOneWidget);
      expect(find.text('₹45,000'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets('10. BudgetProgressCard renders category, amounts, and warning indicator', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const BudgetProgressCard(
            categoryName: 'Dining',
            spentAmount: '₹8,500',
            totalBudget: '₹10,000',
            percentage: 85.0,
          ),
        ),
      );

      expect(find.text('Dining'), findsOneWidget);
      expect(find.textContaining('85% used'), findsOneWidget);
      expect(find.text('₹8,500 spent'), findsOneWidget);
      expect(find.text('₹10,000 budget'), findsOneWidget);
    });

    testWidgets('11. EmptyState displays title, message, and action button', (tester) async {
      var triggered = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          EmptyState(
            title: 'No Transactions Yet',
            message: 'Tap the button below to add your first expense.',
            actionLabel: 'Add Expense',
            onAction: () => triggered = true,
          ),
        ),
      );

      expect(find.text('No Transactions Yet'), findsOneWidget);
      expect(find.text('Tap the button below to add your first expense.'), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);
      await tester.tap(find.text('Add Expense'));
      expect(triggered, isTrue);
    });

    testWidgets('12. LoadingState renders message and indicator', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const LoadingState(message: 'Loading financial records...'),
        ),
      );

      expect(find.text('Loading financial records...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('13. ErrorState displays error title, message, and retry button', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          ErrorState(
            message: 'Unable to sync records.',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Unable to Load'), findsOneWidget);
      expect(find.text('Unable to sync records.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });

    testWidgets('14. SectionHeader renders title and optional action', (tester) async {
      var actionFired = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          SectionHeader(
            title: 'Recent Transactions',
            actionText: 'See All',
            onAction: () => actionFired = true,
          ),
        ),
      );

      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      await tester.tap(find.text('See All'));
      expect(actionFired, isTrue);
    });

    testWidgets('15. AppBottomNavigation switches indices on tap', (tester) async {
      int activeIndex = 0;
      await tester.pumpWidget(
        _wrapWithTheme(
          StatefulBuilder(
            builder: (context, setState) {
              return AppBottomNavigation(
                currentIndex: activeIndex,
                onIndexChanged: (i) => setState(() => activeIndex = i),
                items: const [
                  AppNavigationItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  AppNavigationItem(
                    icon: Icons.receipt_outlined,
                    selectedIcon: Icons.receipt_rounded,
                    label: 'Activity',
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      await tester.tap(find.text('Activity'));
      await tester.pump();
      expect(activeIndex, 1);
    });

    testWidgets('16. AppFloatingActionButton renders and triggers callback', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          AppFloatingActionButton(
            label: 'Add Expense',
            icon: Icons.add_rounded,
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      await tester.tap(find.byType(AppFloatingActionButton));
      expect(pressed, isTrue);
    });
  });

  group('Dashboard Mockup Presentation & Responsiveness', () {
    testWidgets('Renders exact dashboard mockup data', (tester) async {
      await tester.pumpWidget(_wrapWithTheme(const HomeScreen(), size: const Size(400, 1600)));
      await tester.pumpAndSettle();

      // Header greeting & date
      expect(find.text('Good evening, Raj'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);

      // Hero Total Balance
      expect(find.text('TOTAL BALANCE'), findsOneWidget);
      expect(find.text('₹35,000'), findsOneWidget);

      // Income & Expense summary cards
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('₹80,000'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('₹45,000'), findsOneWidget);

      // Recent Transactions section
      await tester.scrollUntilVisible(find.text('Grocery'), 100);
      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('Grocery'), findsOneWidget);
      expect(find.text('-₹2,450'), findsOneWidget);

      expect(find.text('Electricity'), findsOneWidget);
      expect(find.text('-₹1,820'), findsOneWidget);

      expect(find.text('Restaurant'), findsOneWidget);
      expect(find.text('-₹950'), findsOneWidget);
    });

    testWidgets('Renders properly on small Android device (<360px width)', (tester) async {
      // Small screen: 320x640
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapWithTheme(const HomeScreen(), size: const Size(320, 640)));
      await tester.pumpAndSettle();

      expect(find.text('Good evening, Raj'), findsOneWidget);
      expect(find.text('₹35,000'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Grocery'), 100);
      expect(find.text('Grocery'), findsOneWidget);
    });

    testWidgets('Renders properly on large Android device (>480px width)', (tester) async {
      // Large screen: 600x900
      tester.view.physicalSize = const Size(600 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapWithTheme(const HomeScreen(), size: const Size(600, 900)));
      await tester.pumpAndSettle();

      expect(find.text('Good evening, Raj'), findsOneWidget);
      expect(find.text('₹35,000'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Grocery'), 100);
      expect(find.text('Grocery'), findsOneWidget);
    });
  });
}
