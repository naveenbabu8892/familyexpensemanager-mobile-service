import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/empty_state.dart';
import 'package:mobile/features/budgets/data/budget_repository_impl.dart';
import 'package:mobile/features/budgets/domain/budget.dart';
import 'package:mobile/features/budgets/presentation/budget_list_controller.dart';
import 'package:mobile/features/budgets/presentation/budgets_screen.dart';
import 'package:mobile/features/categories/data/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/category.dart';

class MockBudgetRepositoryForScreen implements BudgetRepository {
  List<Budget> budgets;
  int getBudgetsCallCount = 0;
  Budget? lastCreated;
  Budget? lastUpdated;
  String? lastDeletedId;

  MockBudgetRepositoryForScreen({this.budgets = const []});

  @override
  Future<List<Budget>> getBudgets({int? month, int? year}) async {
    getBudgetsCallCount++;
    return budgets.where((b) {
      if (month != null && b.month != month) return false;
      if (year != null && b.year != year) return false;
      return true;
    }).toList();
  }

  @override
  Future<Budget> getBudgetById(String id) async {
    return budgets.firstWhere((b) => b.id == id);
  }

  @override
  Future<Budget> createBudget({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final b = Budget(
      id: 'b-${DateTime.now().millisecondsSinceEpoch}',
      familyId: 'fam-1',
      categoryId: categoryId,
      categoryName: categoryId == 'cat-groceries' ? 'Grocery' : 'Dining Out',
      amount: amount,
      month: month,
      year: year,
      createdBy: 'usr-1',
      amountSpent: 0,
      remainingAmount: amount,
      percentageUsed: 0,
    );
    lastCreated = b;
    budgets = [...budgets, b];
    return b;
  }

  @override
  Future<Budget> updateBudget(
    String id, {
    double? amount,
    int? month,
    int? year,
    String? categoryId,
  }) async {
    final original = budgets.firstWhere((b) => b.id == id);
    final updated = Budget(
      id: original.id,
      familyId: original.familyId,
      categoryId: categoryId ?? original.categoryId,
      categoryName: original.categoryName,
      amount: amount ?? original.amount,
      month: month ?? original.month,
      year: year ?? original.year,
      createdBy: original.createdBy,
      amountSpent: original.amountSpent,
      remainingAmount: (amount ?? original.amount) - original.amountSpent,
      percentageUsed: ((original.amountSpent / (amount ?? original.amount)) * 100),
    );
    lastUpdated = updated;
    budgets = budgets.map((b) => b.id == id ? updated : b).toList();
    return updated;
  }

  @override
  Future<void> deleteBudget(String id) async {
    lastDeletedId = id;
    budgets = budgets.where((b) => b.id != id).toList();
  }
}

class MockCategoryRepositoryForBudgets implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({String? type}) async {
    return [
      const Category(
        id: 'cat-groceries',
        familyId: 'fam-1',
        name: 'Grocery',
        icon: 'groceries',
        color: '#D47355',
        type: 'EXPENSE',
      ),
      const Category(
        id: 'cat-dining',
        familyId: 'fam-1',
        name: 'Dining Out',
        icon: 'restaurant',
        color: '#B79B62',
        type: 'EXPENSE',
      ),
    ];
  }

  @override
  Future<Category> createCategory({
    required String name,
    required String type,
    String icon = 'category',
    String color = '#607D8B',
  }) async =>
      throw UnimplementedError();

  @override
  Future<Category> updateCategory(
    String id, {
    String? name,
    String? icon,
    String? color,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) async => throw UnimplementedError();
}

void main() {
  late MockBudgetRepositoryForScreen mockRepo;

  // Setup sample budgets with distinct statuses (Healthy, 75%, 90%, Exceeded)
  final healthyBudget = const Budget(
    id: 'b-healthy',
    familyId: 'fam-1',
    categoryId: 'cat-groceries',
    categoryName: 'Grocery',
    categoryIcon: 'groceries',
    amount: 10000,
    month: 10,
    year: 2026,
    createdBy: 'usr-1',
    amountSpent: 7200,
    remainingAmount: 2800,
    percentageUsed: 72.0,
  );

  final goldBudget = const Budget(
    id: 'b-gold',
    familyId: 'fam-1',
    categoryId: 'cat-dining',
    categoryName: 'Dining Out',
    categoryIcon: 'restaurant',
    amount: 5000,
    month: 10,
    year: 2026,
    createdBy: 'usr-1',
    amountSpent: 3800,
    remainingAmount: 1200,
    percentageUsed: 76.0,
  );

  final terracottaBudget = const Budget(
    id: 'b-terra',
    familyId: 'fam-1',
    categoryId: 'cat-entertainment',
    categoryName: 'Entertainment',
    categoryIcon: 'movie',
    amount: 3000,
    month: 10,
    year: 2026,
    createdBy: 'usr-1',
    amountSpent: 2750,
    remainingAmount: 250,
    percentageUsed: 91.6,
  );

  final exceededBudget = const Budget(
    id: 'b-exceeded',
    familyId: 'fam-1',
    categoryId: 'cat-shopping',
    categoryName: 'Shopping',
    categoryIcon: 'shopping_bag',
    amount: 4000,
    month: 10,
    year: 2026,
    createdBy: 'usr-1',
    amountSpent: 4800,
    remainingAmount: -800,
    percentageUsed: 120.0,
  );

  setUp(() {
    mockRepo = MockBudgetRepositoryForScreen(
      budgets: [healthyBudget, goldBudget, terracottaBudget, exceededBudget],
    );
  });

  Widget createBudgetsTestWidget({List<dynamic> extraOverrides = const []}) {
    return ProviderScope(
      overrides: [
        budgetRepositoryProvider.overrideWithValue(mockRepo),
        categoryRepositoryProvider.overrideWithValue(MockCategoryRepositoryForBudgets()),
        ...extraOverrides.cast(),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const BudgetsScreen(),
      ),
    );
  }

  group('Budgets Screen Comprehensive Tests', () {
    testWidgets('1. Displays Monthly budget list, Category, Budget, Spent, Remaining, Percentage',
        (tester) async {
      await tester.pumpWidget(createBudgetsTestWidget(
        extraOverrides: [
          budgetPeriodProvider.overrideWith(
            () => BudgetPeriodNotifier(initialMonth: 10, initialYear: 2026),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Check Category names in visible viewport
      expect(find.text('Grocery'), findsOneWidget);
      expect(find.text('Dining Out'), findsOneWidget);

      // Check Example: Grocery: ₹7,200 / ₹10,000, 72%
      expect(find.text('₹7,200 / ₹10,000'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('₹2,800'), findsOneWidget); // Remaining

      // Scroll down to see remaining categories
      await tester.scrollUntilVisible(find.text('Entertainment'), 200);
      expect(find.text('Entertainment'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Shopping'), 200);
      expect(find.text('Shopping'), findsOneWidget);
    });

    testWidgets('2. Correct status colors: Olive healthy, Gold ~75%, Terracotta ~90%, Dark red/brown exceeded',
        (tester) async {
      // Check statusColor getters directly
      expect(healthyBudget.statusColor, AppColors.olive);
      expect(goldBudget.statusColor, AppColors.mutedGold);
      expect(terracottaBudget.statusColor, AppColors.terracotta);
      expect(exceededBudget.statusColor, AppColors.exceeded);

      await tester.pumpWidget(createBudgetsTestWidget(
        extraOverrides: [
          budgetPeriodProvider.overrideWith(
            () => BudgetPeriodNotifier(initialMonth: 10, initialYear: 2026),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Check visible badges
      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Near Limit'), 200);
      expect(find.text('Near Limit'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Shopping'), 200);
      expect(find.text('Exceeded'), findsWidgets);
    });

    testWidgets('3. Month selector switches periods and triggers repository query',
        (tester) async {
      await tester.pumpWidget(createBudgetsTestWidget(
        extraOverrides: [
          budgetPeriodProvider.overrideWith(
            () => BudgetPeriodNotifier(initialMonth: 10, initialYear: 2026),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);

      // Tap next month icon
      await tester.tap(find.byTooltip('Next Month'));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);
      // No budgets for November 2026 in mock -> Empty State
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.textContaining('No Budgets for November 2026'), findsOneWidget);
    });

    testWidgets('4. Add Budget dialog allows selecting Category, Month, Year, Amount and saves',
        (tester) async {
      await tester.pumpWidget(createBudgetsTestWidget(
        extraOverrides: [
          budgetPeriodProvider.overrideWith(
            () => BudgetPeriodNotifier(initialMonth: 10, initialYear: 2026),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Tap 'Add Budget' Floating Action Button
      await tester.tap(find.text('Add Budget'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Add Monthly Budget'), findsOneWidget);
      expect(find.text('BUDGET AMOUNT'), findsOneWidget);

      // Select Category
      await tester.tap(find.text('Select Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grocery').last);
      await tester.pumpAndSettle();

      // Enter Amount
      await tester.enterText(find.byType(TextField).first, '8500');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Create Budget'));
      await tester.pumpAndSettle();

      // Verify dialog closed and budget created
      expect(find.text('Add Monthly Budget'), findsNothing);
      expect(mockRepo.lastCreated, isNotNull);
      expect(mockRepo.lastCreated!.amount, 8500.0);
      expect(mockRepo.lastCreated!.month, 10);
      expect(mockRepo.lastCreated!.year, 2026);
    });

    testWidgets('5. Delete Budget opens confirmation and deletes on confirm',
        (tester) async {
      await tester.pumpWidget(createBudgetsTestWidget(
        extraOverrides: [
          budgetPeriodProvider.overrideWith(
            () => BudgetPeriodNotifier(initialMonth: 10, initialYear: 2026),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Tap context menu on first budget card
      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();

      // Tap 'Delete Budget'
      await tester.tap(find.text('Delete Budget'));
      await tester.pumpAndSettle();

      // Confirmation dialog shown
      expect(find.text('Delete Budget?'), findsOneWidget);

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastDeletedId, 'b-healthy');
      expect(find.text('Budget deleted successfully'), findsOneWidget);
    });
  });
}
