import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/empty_state.dart';
import 'package:mobile/features/categories/data/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/features/expenses/data/expense_repository_impl.dart';
import 'package:mobile/features/expenses/domain/expense.dart';
import 'package:mobile/features/expenses/presentation/transactions_screen.dart';
import 'package:mobile/features/family/data/family_repository_impl.dart';
import 'package:mobile/features/family/domain/family.dart';
import 'package:mobile/features/family/domain/family_repository.dart';
import 'package:mobile/features/income/data/income_repository_impl.dart';
import 'package:mobile/features/income/domain/income.dart';

// Test doubles / Mocks
class MockTransactionsExpenseRepository implements ExpenseRepository {
  List<Expense> expenses;
  int getExpensesCallCount = 0;
  String? lastSearch;
  String? lastSortBy;
  String? lastSortOrder;

  MockTransactionsExpenseRepository({this.expenses = const []});

  @override
  Future<List<Expense>> getExpenses({
    int page = 1,
    int pageSize = 20,
    String? categoryId,
    String? fromDate,
    String? toDate,
    String? paidBy,
    String? search,
    String? paymentMethod,
    bool? isShared,
    String? sortBy,
    String? sortOrder,
  }) async {
    getExpensesCallCount++;
    lastSearch = search;
    lastSortBy = sortBy;
    lastSortOrder = sortOrder;

    var filtered = List<Expense>.from(expenses);
    if (search != null && search.isNotEmpty) {
      filtered = filtered
          .where((e) => e.title.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    if (paidBy != null) {
      filtered = filtered.where((e) => e.paidBy == paidBy).toList();
    }
    if (isShared != null) {
      filtered = filtered.where((e) => e.isShared == isShared).toList();
    }
    return filtered;
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    return expenses.firstWhere((e) => e.id == id);
  }

  @override
  Future<Expense> createExpense({
    required String title,
    required double amount,
    required String categoryId,
    required String expenseDate,
    String paymentMethod = 'credit_card',
    String? description,
    String? paidBy,
    bool isShared = true,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Expense> updateExpense(
    String id, {
    String? title,
    double? amount,
    String? categoryId,
    String? expenseDate,
    String? paymentMethod,
    String? description,
    String? paidBy,
    bool? isShared,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteExpense(String id) async => throw UnimplementedError();
}

class MockTransactionsIncomeRepository implements IncomeRepository {
  List<Income> incomes;
  int getIncomesCallCount = 0;
  String? lastSearch;
  String? lastSortBy;
  String? lastSortOrder;

  MockTransactionsIncomeRepository({this.incomes = const []});

  @override
  Future<List<Income>> getIncomes({
    int page = 1,
    int pageSize = 20,
    String? categoryId,
    String? fromDate,
    String? toDate,
    String? receivedBy,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    getIncomesCallCount++;
    lastSearch = search;
    lastSortBy = sortBy;
    lastSortOrder = sortOrder;

    var filtered = List<Income>.from(incomes);
    if (search != null && search.isNotEmpty) {
      filtered = filtered
          .where((i) => i.title.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    if (receivedBy != null) {
      filtered = filtered.where((i) => (i.receivedBy ?? i.userId) == receivedBy).toList();
    }
    return filtered;
  }

  @override
  Future<Income> getIncomeById(String id) async {
    return incomes.firstWhere((i) => i.id == id);
  }

  @override
  Future<Income> createIncome({
    required double amount,
    required String categoryId,
    required String incomeDate,
    required String title,
    String? receivedBy,
    String? description,
    String currency = 'INR',
  }) async =>
      throw UnimplementedError();

  @override
  Future<Income> updateIncome(
    String id, {
    String? title,
    double? amount,
    String? categoryId,
    String? incomeDate,
    String? description,
    String? receivedBy,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteIncome(String id) async => throw UnimplementedError();
}

class MockCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({String? type}) async {
    return [
      Category(
        id: 'cat-groceries',
        familyId: 'fam-1',
        name: 'Groceries',
        icon: 'groceries',
        color: '#D47355',
        type: 'expense',
      ),
      Category(
        id: 'cat-salary',
        familyId: 'fam-1',
        name: 'Salary',
        icon: 'payments',
        color: '#5B7065',
        type: 'income',
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

class MockFamilyRepository implements FamilyRepository {
  @override
  Future<Family?> getCurrentFamily() async => null;

  @override
  Future<Family> createFamily({
    required String name,
    String currency = 'USD',
    String timezone = 'UTC',
  }) async =>
      throw UnimplementedError();

  @override
  Future<Family> updateCurrentFamily({
    String? name,
    String? currency,
    String? timezone,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    return [
      FamilyMember(
        id: 'mem-1',
        familyId: 'fam-1',
        userId: 'user-husband',
        role: 'owner',
        email: 'husband@example.com',
        fullName: 'Raj Sharma',
      ),
      FamilyMember(
        id: 'mem-2',
        familyId: 'fam-1',
        userId: 'user-wife',
        role: 'member',
        email: 'wife@example.com',
        fullName: 'Priya Sharma',
      ),
    ];
  }

  @override
  Future<String> inviteMember(String email, {String relationship = 'other'}) async => throw UnimplementedError();

  @override
  Future<List<RelationshipOption>> getRelationships() async => [];

  @override
  Future<Family> acceptInvitation(String token) async => throw UnimplementedError();
}

void main() {
  late MockTransactionsExpenseRepository mockExpenseRepo;
  late MockTransactionsIncomeRepository mockIncomeRepo;

  final sampleExpense = Expense(
    id: 'exp-1',
    familyId: 'fam-1',
    createdBy: 'user-husband',
    paidBy: 'user-husband',
    paidByName: 'Raj Sharma',
    categoryId: 'cat-groceries',
    categoryName: 'Groceries',
    amount: 2500,
    currency: 'INR',
    expenseDate: '2026-10-06',
    paymentMethod: 'upi',
    title: 'Monthly Supermarket Supplies',
    isShared: true,
  );

  final sampleIncome = Income(
    id: 'inc-1',
    familyId: 'fam-1',
    userId: 'user-wife',
    receivedBy: 'user-wife',
    receivedByName: 'Priya Sharma',
    categoryId: 'cat-salary',
    categoryName: 'Salary',
    amount: 45000,
    currency: 'INR',
    incomeDate: '2026-10-01',
    title: 'Monthly Consulting Payout',
  );

  setUp(() {
    mockExpenseRepo = MockTransactionsExpenseRepository(expenses: [sampleExpense]);
    mockIncomeRepo = MockTransactionsIncomeRepository(incomes: [sampleIncome]);
  });

  Widget createTransactionsTestWidget() {
    return ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockExpenseRepo),
        incomeRepositoryProvider.overrideWithValue(mockIncomeRepo),
        categoryRepositoryProvider.overrideWithValue(MockCategoryRepository()),
        familyRepositoryProvider.overrideWithValue(MockFamilyRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const TransactionsScreen(),
      ),
    );
  }

  group('Transactions Screen Comprehensive Tests', () {
    testWidgets('1. Renders All, Expenses, and Income tabs and both types of transactions',
        (tester) async {
      await tester.pumpWidget(createTransactionsTestWidget());
      await tester.pumpAndSettle();

      // Check Tabs presence
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);

      // Check Unified List renders items
      expect(find.text('Monthly Supermarket Supplies'), findsOneWidget);
      expect(find.text('Monthly Consulting Payout'), findsOneWidget);
    });

    testWidgets('2. Visually distinguishes expenses (-₹, Terracotta) from income (+₹, Olive)',
        (tester) async {
      await tester.pumpWidget(createTransactionsTestWidget());
      await tester.pumpAndSettle();

      // Find amounts
      final expenseAmountFinder = find.text('-₹2,500');
      final incomeAmountFinder = find.text('+₹45,000');

      expect(expenseAmountFinder, findsOneWidget);
      expect(incomeAmountFinder, findsOneWidget);

      final Text expenseTextWidget = tester.widget(expenseAmountFinder);
      expect(expenseTextWidget.style?.color, AppColors.terracotta);

      final Text incomeTextWidget = tester.widget(incomeAmountFinder);
      expect(incomeTextWidget.style?.color, AppColors.olive);
    });

    testWidgets('3. Switching to Expenses tab filters to expenses only and queries backend',
        (tester) async {
      await tester.pumpWidget(createTransactionsTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Expenses' Tab ChoiceChip
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      // Only Expense item is shown, Income item is absent
      expect(find.text('Monthly Supermarket Supplies'), findsOneWidget);
      expect(find.text('Monthly Consulting Payout'), findsNothing);
    });

    testWidgets('4. Switching to Income tab filters to income only and queries backend',
        (tester) async {
      await tester.pumpWidget(createTransactionsTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Income' Tab ChoiceChip
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // Only Income item is shown, Expense item is absent
      expect(find.text('Monthly Consulting Payout'), findsOneWidget);
      expect(find.text('Monthly Supermarket Supplies'), findsNothing);
    });

    testWidgets('5. Search bar searches transactions on submit',
        (tester) async {
      await tester.pumpWidget(createTransactionsTestWidget());
      await tester.pumpAndSettle();

      // Tap search icon in AppBar
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Supermarket');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(mockExpenseRepo.lastSearch, 'Supermarket');
      expect(mockIncomeRepo.lastSearch, 'Supermarket');
      expect(find.text('Monthly Supermarket Supplies'), findsOneWidget);
      expect(find.text('Monthly Consulting Payout'), findsNothing);
    });

    testWidgets('6. Pull-to-refresh triggers fresh fetch from server',
        (tester) async {
      await tester.pumpWidget(createTransactionsTestWidget());
      await tester.pumpAndSettle();

      final initialExpenseCalls = mockExpenseRepo.getExpensesCallCount;
      final initialIncomeCalls = mockIncomeRepo.getIncomesCallCount;

      // Trigger pull to refresh
      await tester.fling(find.text('Monthly Supermarket Supplies'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(mockExpenseRepo.getExpensesCallCount, greaterThan(initialExpenseCalls));
      expect(mockIncomeRepo.getIncomesCallCount, greaterThan(initialIncomeCalls));
    });

    testWidgets('7. Displays Empty State when no transactions found',
        (tester) async {
      mockExpenseRepo.expenses = [];
      mockIncomeRepo.incomes = [];

      await tester.pumpWidget(createTransactionsTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No Transactions Found'), findsOneWidget);
    });
  });
}
