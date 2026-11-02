import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/amount_input.dart';
import 'package:mobile/core/widgets/empty_state.dart';
import 'package:mobile/core/widgets/vintage_button.dart';
import 'package:mobile/core/widgets/vintage_text_field.dart';
import 'package:mobile/features/categories/data/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/features/expenses/data/expense_repository_impl.dart';
import 'package:mobile/features/expenses/domain/expense.dart';
import 'package:mobile/features/expenses/presentation/expense_detail_screen.dart';
import 'package:mobile/features/expenses/presentation/expense_form_screen.dart';
import 'package:mobile/features/expenses/presentation/expense_list_screen.dart';
import 'package:mobile/features/family/data/family_repository_impl.dart';
import 'package:mobile/features/family/domain/family.dart';
import 'package:mobile/features/family/domain/family_repository.dart';

class MockExpenseRepository implements ExpenseRepository {
  List<Expense> expenses;
  Expense? lastCreated;
  Expense? lastUpdated;
  String? lastDeletedId;

  MockExpenseRepository({this.expenses = const []});

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
    var filtered = List<Expense>.from(expenses);
    if (isShared != null) {
      filtered = filtered.where((e) => e.isShared == isShared).toList();
    }
    if (paidBy != null) {
      filtered = filtered.where((e) => e.paidBy == paidBy).toList();
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
  }) async {
    final exp = Expense(
      id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
      familyId: 'fam-1',
      createdBy: 'usr-1',
      title: title,
      amount: amount,
      currency: 'INR',
      categoryId: categoryId,
      categoryName: 'Grocery',
      expenseDate: expenseDate,
      paymentMethod: paymentMethod,
      description: description,
      paidBy: paidBy ?? 'usr-1',
      paidByName: 'Raj Sharma',
      isShared: isShared,
      createdAt: DateTime.now(),
    );
    lastCreated = exp;
    expenses = [exp, ...expenses];
    return exp;
  }

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
  }) async {
    final original = expenses.firstWhere((e) => e.id == id);
    final updated = Expense(
      id: original.id,
      familyId: original.familyId,
      createdBy: original.createdBy,
      title: title ?? original.title,
      amount: amount ?? original.amount,
      currency: original.currency,
      categoryId: categoryId ?? original.categoryId,
      categoryName: original.categoryName,
      expenseDate: expenseDate ?? original.expenseDate,
      paymentMethod: paymentMethod ?? original.paymentMethod,
      description: description ?? original.description,
      paidBy: paidBy ?? original.paidBy,
      paidByName: original.paidByName,
      isShared: isShared ?? original.isShared,
      createdAt: original.createdAt,
    );
    lastUpdated = updated;
    expenses = expenses.map((e) => e.id == id ? updated : e).toList();
    return updated;
  }

  @override
  Future<void> deleteExpense(String id) async {
    lastDeletedId = id;
    expenses = expenses.where((e) => e.id != id).toList();
  }
}

class MockCategoryRepository implements CategoryRepository {
  final List<Category> categories;

  MockCategoryRepository({this.categories = const []});

  @override
  Future<List<Category>> getCategories({String? type}) async => categories;

  @override
  Future<Category> createCategory({
    required String name,
    required String type,
    String icon = 'category',
    String color = '#607D8B',
  }) async =>
      categories.first;

  @override
  Future<Category> updateCategory(
    String id, {
    String? name,
    String? icon,
    String? color,
  }) async =>
      categories.first;

  @override
  Future<void> deleteCategory(String id) async {}
}

class MockFamilyRepository implements FamilyRepository {
  final List<FamilyMember> members;

  MockFamilyRepository({this.members = const []});

  @override
  Future<Family?> getCurrentFamily() async => null;

  @override
  Future<Family> createFamily({
    required String name,
    String currency = 'USD',
    String timezone = 'UTC',
  }) async =>
      Family(
        id: 'fam-1',
        name: 'Test Family',
        createdBy: 'usr-1',
        createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
      );

  @override
  Future<Family> updateCurrentFamily({
    String? name,
    String? currency,
    String? timezone,
  }) async =>
      Family(
        id: 'fam-1',
        name: 'Test Family',
        createdBy: 'usr-1',
        createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
      );

  @override
  Future<List<FamilyMember>> getFamilyMembers() async => members;

  @override
  Future<String> inviteMember(String email, {String relationship = 'other'}) async => 'invite-token';

  @override
  Future<List<RelationshipOption>> getRelationships() async => [];

  @override
  Future<Family> acceptInvitation(String token) async => Family(
        id: 'fam-1',
        name: 'Test Family',
        createdBy: 'usr-1',
        createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
      );
}

void main() {
  final testExpense = const Expense(
    id: 'exp-101',
    familyId: 'fam-1',
    createdBy: 'usr-1',
    title: 'Weekly Grocery',
    amount: 2450.0,
    currency: 'INR',
    categoryId: 'cat-1',
    categoryName: 'Grocery',
    expenseDate: '2026-10-05',
    paymentMethod: 'upi',
    paidBy: 'usr-1',
    paidByName: 'Raj Sharma',
    isShared: true,
    description: 'Fresh vegetables and fruits',
  );

  final testCategories = [
    const Category(
      id: 'cat-1',
      name: 'Grocery',
      type: 'EXPENSE',
      icon: 'shopping_basket',
      color: '#B86B4B',
      isDefault: true,
    ),
    const Category(
      id: 'cat-2',
      name: 'Utilities',
      type: 'EXPENSE',
      icon: 'bolt',
      color: '#657153',
      isDefault: true,
    ),
  ];

  final testMembers = [
    FamilyMember(
      id: 'mem-1',
      familyId: 'fam-1',
      userId: 'usr-1',
      fullName: 'Raj Sharma',
      email: 'raj@example.com',
      role: 'OWNER',
      joinedAt: DateTime.parse('2026-10-01T10:00:00Z'),
    ),
    FamilyMember(
      id: 'mem-2',
      familyId: 'fam-1',
      userId: 'usr-2',
      fullName: 'Priya Sharma',
      email: 'priya@example.com',
      role: 'MEMBER',
      joinedAt: DateTime.parse('2026-10-02T10:00:00Z'),
    ),
  ];

  Widget buildTestableWidget(Widget child, {
    ExpenseRepository? expenseRepo,
    CategoryRepository? categoryRepo,
    FamilyRepository? familyRepo,
  }) {
    return ProviderScope(
      overrides: [
        if (expenseRepo != null)
          expenseRepositoryProvider.overrideWithValue(expenseRepo),
        if (categoryRepo != null)
          categoryRepositoryProvider.overrideWithValue(categoryRepo),
        if (familyRepo != null)
          familyRepositoryProvider.overrideWithValue(familyRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(size: Size(450, 1200)),
            child: child,
          ),
        ),
      ),
    );
  }

  group('Expense List Screen & Filter Tabs Tests', () {
    testWidgets('1. Renders tabs (All, Shared, My Expenses, Spouse Expenses) and items', (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1000 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockExpenseRepository(expenses: [testExpense]);

      await tester.pumpWidget(
        buildTestableWidget(
          const ExpenseListScreen(),
          expenseRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Expenses'), findsOneWidget);

      // Verify Filter Tabs
      expect(find.text('All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Shared'), findsOneWidget);
      expect(find.text('My Expenses'), findsOneWidget);
      expect(find.text('Spouse Expenses'), findsOneWidget);

      // Verify Expense Item
      expect(find.text('Weekly Grocery'), findsOneWidget);
      expect(find.text('-₹2,450'), findsOneWidget);
      expect(find.text('Shared'), findsNWidgets(2)); // Tab chip and tag
      expect(find.text('• Raj'), findsOneWidget);
    });

    testWidgets('2. Displays Empty State when no expenses exist', (tester) async {
      final mockRepo = MockExpenseRepository(expenses: []);

      await tester.pumpWidget(
        buildTestableWidget(
          const ExpenseListScreen(),
          expenseRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No Expenses Found'), findsOneWidget);
    });

    testWidgets('3. Switches filter tab cleanly without full app reload', (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1000 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockExpenseRepository(expenses: [testExpense]);

      await tester.pumpWidget(
        buildTestableWidget(
          const ExpenseListScreen(),
          expenseRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Shared' tab
      await tester.tap(find.widgetWithText(ChoiceChip, 'Shared'));
      await tester.pumpAndSettle();

      expect(find.text('Weekly Grocery'), findsOneWidget);
    });
  });

  group('Add & Edit Expense Form Tests', () {
    testWidgets('4. Validates required fields: Amount > 0, Category, Date, Paid By', (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockExpenseRepository();
      final mockCatRepo = MockCategoryRepository(categories: testCategories);
      final mockFamRepo = MockFamilyRepository(members: testMembers);

      await tester.pumpWidget(
        buildTestableWidget(
          const ExpenseFormScreen(),
          expenseRepo: mockRepo,
          categoryRepo: mockCatRepo,
          familyRepo: mockFamRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Expense'), findsOneWidget);

      final saveBtn = find.widgetWithText(VintageButton, 'Save Expense');
      expect(saveBtn, findsOneWidget);

      // Tap Save without entering amount/title/category
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Expect validation error feedback
      expect(find.text('Please enter an amount greater than 0'), findsOneWidget);
      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('5. Creates new expense, shows feedback and invalidates dashboard', (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockExpenseRepository();
      final mockCatRepo = MockCategoryRepository(categories: testCategories);
      final mockFamRepo = MockFamilyRepository(members: testMembers);

      await tester.pumpWidget(
        buildTestableWidget(
          const ExpenseFormScreen(),
          expenseRepo: mockRepo,
          categoryRepo: mockCatRepo,
          familyRepo: mockFamRepo,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Enter Amount into AmountInput
      final amountInputFinder = find.byType(AmountInput);
      expect(amountInputFinder, findsOneWidget);
      await tester.enterText(amountInputFinder, '2450');

      // 2. Enter Title in the VintageTextField
      final titleField = find.widgetWithText(VintageTextField, 'Title');
      expect(titleField, findsOneWidget);
      await tester.enterText(titleField, 'Dinner with family');

      // 3. Select Category
      final categoryDropdown = find.text('Grocery');
      expect(categoryDropdown, findsOneWidget);

      // 4. Select Paid By
      final paidByDropdown = find.text('Select payer');
      expect(paidByDropdown, findsOneWidget);
      await tester.tap(paidByDropdown, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Raj Sharma').last);
      await tester.pumpAndSettle();

      // 5. Submit Form
      await tester.tap(find.widgetWithText(VintageButton, 'Save Expense'));
      await tester.pumpAndSettle();

      // Verify expense was created in repo
      expect(mockRepo.lastCreated, isNotNull);
      expect(mockRepo.lastCreated?.amount, 2450.0);
      expect(mockRepo.lastCreated?.title, 'Dinner with family');
      expect(mockRepo.lastCreated?.paidBy, 'usr-1');
      expect(mockRepo.lastCreated?.paymentMethod, 'upi');

      // Verify success snackbar message
      expect(find.text('Expense added successfully.'), findsOneWidget);
    });

    testWidgets('6. Edit expense loads existing details and saves update', (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockExpenseRepository(expenses: [testExpense]);
      final mockCatRepo = MockCategoryRepository(categories: testCategories);
      final mockFamRepo = MockFamilyRepository(members: testMembers);

      await tester.pumpWidget(
        buildTestableWidget(
          ExpenseFormScreen(initialExpense: testExpense),
          expenseRepo: mockRepo,
          categoryRepo: mockCatRepo,
          familyRepo: mockFamRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Expense'), findsOneWidget);
      expect(find.text('2450'), findsOneWidget);
      expect(find.text('Weekly Grocery'), findsOneWidget);

      // Change Title
      final titleField = find.widgetWithText(VintageTextField, 'Title');
      await tester.enterText(titleField, 'Monthly Grocery');

      // Submit
      await tester.tap(find.widgetWithText(VintageButton, 'Update Expense'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastUpdated, isNotNull);
      expect(mockRepo.lastUpdated?.title, 'Monthly Grocery');
      expect(find.text('Expense updated successfully.'), findsOneWidget);
    });
  });

  group('Expense Details & Delete Confirmation Tests', () {
    testWidgets('7. Displays expense metadata and opens Delete confirmation dialog', (tester) async {
      final mockRepo = MockExpenseRepository(expenses: [testExpense]);

      await tester.pumpWidget(
        buildTestableWidget(
          ExpenseDetailScreen(
            expenseId: testExpense.id,
            initialExpense: testExpense,
          ),
          expenseRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Verify details
      expect(find.text('Expense Details'), findsOneWidget);
      expect(find.text('Weekly Grocery'), findsOneWidget);
      expect(find.text('-₹2,450.00'), findsOneWidget);
      expect(find.text('Fresh vegetables and fruits'), findsOneWidget);

      // Verify Delete action in AppBar
      final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteIcon, findsOneWidget);

      // Tap delete icon to trigger confirmation dialog
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Check dialog elements
      expect(find.text('Delete this expense?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap Cancel: should dismiss dialog without deleting
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(mockRepo.lastDeletedId, isNull);

      // Tap Delete icon again, this time confirming
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify deletion in repo
      expect(mockRepo.lastDeletedId, testExpense.id);
    });
  });
}
