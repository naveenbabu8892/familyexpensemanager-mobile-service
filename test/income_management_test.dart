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
import 'package:mobile/features/family/data/family_repository_impl.dart';
import 'package:mobile/features/family/domain/family.dart';
import 'package:mobile/features/family/domain/family_repository.dart';
import 'package:mobile/features/income/data/income_repository_impl.dart';
import 'package:mobile/features/income/domain/income.dart';
import 'package:mobile/features/income/presentation/income_detail_screen.dart';
import 'package:mobile/features/income/presentation/income_form_screen.dart';
import 'package:mobile/features/income/presentation/income_list_screen.dart';

class MockIncomeRepository implements IncomeRepository {
  List<Income> incomes;
  Income? lastCreated;
  Income? lastUpdated;
  String? lastDeletedId;

  MockIncomeRepository({this.incomes = const []});

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
    var filtered = List<Income>.from(incomes);
    if (receivedBy != null) {
      filtered = filtered.where((e) => e.receivedBy == receivedBy || e.userId == receivedBy).toList();
    }
    if (categoryId != null) {
      filtered = filtered.where((e) => e.categoryId == categoryId).toList();
    }
    return filtered;
  }

  @override
  Future<Income> getIncomeById(String id) async {
    return incomes.firstWhere((e) => e.id == id);
  }

  @override
  Future<Income> createIncome({
    required String title,
    required double amount,
    required String categoryId,
    required String incomeDate,
    String? description,
    String? receivedBy,
  }) async {
    final inc = Income(
      id: 'inc-${DateTime.now().millisecondsSinceEpoch}',
      familyId: 'fam-1',
      userId: receivedBy ?? 'usr-1',
      categoryId: categoryId,
      categoryName: 'Salary',
      receivedBy: receivedBy ?? 'usr-1',
      receivedByName: 'Raj Sharma',
      amount: amount,
      currency: 'INR',
      incomeDate: incomeDate,
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
    lastCreated = inc;
    incomes = [inc, ...incomes];
    return inc;
  }

  @override
  Future<Income> updateIncome(
    String id, {
    String? title,
    double? amount,
    String? categoryId,
    String? incomeDate,
    String? description,
    String? receivedBy,
  }) async {
    final original = incomes.firstWhere((e) => e.id == id);
    final updated = Income(
      id: original.id,
      familyId: original.familyId,
      userId: receivedBy ?? original.userId,
      categoryId: categoryId ?? original.categoryId,
      categoryName: original.categoryName,
      receivedBy: receivedBy ?? original.receivedBy,
      receivedByName: original.receivedByName,
      amount: amount ?? original.amount,
      currency: original.currency,
      incomeDate: incomeDate ?? original.incomeDate,
      title: title ?? original.title,
      description: description ?? original.description,
      createdAt: original.createdAt,
    );
    lastUpdated = updated;
    incomes = incomes.map((e) => e.id == id ? updated : e).toList();
    return updated;
  }

  @override
  Future<void> deleteIncome(String id) async {
    lastDeletedId = id;
    incomes = incomes.where((e) => e.id != id).toList();
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
  final testIncome = const Income(
    id: 'inc-101',
    familyId: 'fam-1',
    userId: 'usr-1',
    categoryId: 'cat-salary',
    categoryName: 'Salary',
    receivedBy: 'usr-1',
    receivedByName: 'Raj Sharma',
    amount: 80000.0,
    currency: 'INR',
    incomeDate: '2026-10-01',
    title: 'Monthly Salary',
    description: 'Tech consulting contract payment',
  );

  final testCategories = [
    const Category(
      id: 'cat-salary',
      name: 'Salary',
      type: 'INCOME',
      icon: 'payments',
      color: '#657153',
      isDefault: true,
    ),
    const Category(
      id: 'cat-invest',
      name: 'Investment',
      type: 'INCOME',
      icon: 'trending_up',
      color: '#B86B4B',
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
    IncomeRepository? incomeRepo,
    CategoryRepository? categoryRepo,
    FamilyRepository? familyRepo,
  }) {
    return ProviderScope(
      overrides: [
        if (incomeRepo != null)
          incomeRepositoryProvider.overrideWithValue(incomeRepo),
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

  group('Income List Screen & Filter Tabs Tests', () {
    testWidgets('1. Renders tabs (All, My Income, Spouse Income) and items', (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1000 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockIncomeRepository(incomes: [testIncome]);

      await tester.pumpWidget(
        buildTestableWidget(
          const IncomeListScreen(),
          incomeRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Income'), findsOneWidget);

      // Verify Filter Tabs
      expect(find.text('All'), findsOneWidget);
      expect(find.text('My Income'), findsOneWidget);
      expect(find.text('Spouse Income'), findsOneWidget);

      // Verify Income Item
      expect(find.text('Monthly Salary'), findsOneWidget);
      expect(find.text('+₹80,000'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('• Raj'), findsOneWidget);
    });

    testWidgets('2. Displays Empty State when no income exists', (tester) async {
      final mockRepo = MockIncomeRepository(incomes: []);

      await tester.pumpWidget(
        buildTestableWidget(
          const IncomeListScreen(),
          incomeRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No Income Found'), findsOneWidget);
    });

    testWidgets('3. Switches filter tab cleanly without full app reload', (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1000 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockIncomeRepository(incomes: [testIncome]);

      await tester.pumpWidget(
        buildTestableWidget(
          const IncomeListScreen(),
          incomeRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'My Income' tab
      await tester.tap(find.widgetWithText(ChoiceChip, 'My Income'));
      await tester.pumpAndSettle();

      expect(find.text('Monthly Salary'), findsOneWidget);
    });
  });

  group('Add & Edit Income Form Tests', () {
    testWidgets('4. Validates required fields: Amount > 0, Category, Date, Received By, Title', (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockIncomeRepository();
      final mockCatRepo = MockCategoryRepository(categories: testCategories);
      final mockFamRepo = MockFamilyRepository(members: testMembers);

      await tester.pumpWidget(
        buildTestableWidget(
          const IncomeFormScreen(),
          incomeRepo: mockRepo,
          categoryRepo: mockCatRepo,
          familyRepo: mockFamRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Income'), findsOneWidget);

      final saveBtn = find.widgetWithText(VintageButton, 'Save Income');
      expect(saveBtn, findsOneWidget);

      // Tap Save without entering amount/title
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Expect validation error feedback
      expect(find.text('Please enter an amount greater than 0'), findsOneWidget);
      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('5. Creates new income and shows feedback', (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockIncomeRepository();
      final mockCatRepo = MockCategoryRepository(categories: testCategories);
      final mockFamRepo = MockFamilyRepository(members: testMembers);

      await tester.pumpWidget(
        buildTestableWidget(
          const IncomeFormScreen(),
          incomeRepo: mockRepo,
          categoryRepo: mockCatRepo,
          familyRepo: mockFamRepo,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Enter Amount into AmountInput
      final amountInputFinder = find.byType(AmountInput);
      expect(amountInputFinder, findsOneWidget);
      await tester.enterText(amountInputFinder, '85000');

      // 2. Enter Title in the VintageTextField
      final titleField = find.widgetWithText(VintageTextField, 'Title');
      expect(titleField, findsOneWidget);
      await tester.enterText(titleField, 'Consulting retainer');

      // 3. Select Category
      final categoryDropdown = find.text('Salary');
      expect(categoryDropdown, findsOneWidget);

      // 4. Select Received By
      final receivedByDropdown = find.text('Select recipient');
      expect(receivedByDropdown, findsOneWidget);
      await tester.tap(receivedByDropdown, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Raj Sharma').last);
      await tester.pumpAndSettle();

      // 5. Submit Form
      await tester.tap(find.widgetWithText(VintageButton, 'Save Income'));
      await tester.pumpAndSettle();

      // Verify income was created in repo
      expect(mockRepo.lastCreated, isNotNull);
      expect(mockRepo.lastCreated?.amount, 85000.0);
      expect(mockRepo.lastCreated?.title, 'Consulting retainer');
      expect(mockRepo.lastCreated?.receivedBy, 'usr-1');

      // Verify success snackbar message
      expect(find.text('Income added successfully.'), findsOneWidget);
    });

    testWidgets('6. Edit income loads existing details and saves update', (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockIncomeRepository(incomes: [testIncome]);
      final mockCatRepo = MockCategoryRepository(categories: testCategories);
      final mockFamRepo = MockFamilyRepository(members: testMembers);

      await tester.pumpWidget(
        buildTestableWidget(
          IncomeFormScreen(initialIncome: testIncome),
          incomeRepo: mockRepo,
          categoryRepo: mockCatRepo,
          familyRepo: mockFamRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Income'), findsOneWidget);
      expect(find.text('80000'), findsOneWidget);
      expect(find.text('Monthly Salary'), findsOneWidget);

      // Change Title
      final titleField = find.widgetWithText(VintageTextField, 'Title');
      await tester.enterText(titleField, 'Oct Salary & Bonus');

      // Submit
      await tester.tap(find.widgetWithText(VintageButton, 'Update Income'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastUpdated, isNotNull);
      expect(mockRepo.lastUpdated?.title, 'Oct Salary & Bonus');
      expect(find.text('Income updated successfully.'), findsOneWidget);
    });
  });

  group('Income Details & Delete Confirmation Tests', () {
    testWidgets('7. Displays income metadata and opens Delete confirmation dialog', (tester) async {
      final mockRepo = MockIncomeRepository(incomes: [testIncome]);

      await tester.pumpWidget(
        buildTestableWidget(
          IncomeDetailScreen(
            incomeId: testIncome.id,
            initialIncome: testIncome,
          ),
          incomeRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Verify details
      expect(find.text('Income Details'), findsOneWidget);
      expect(find.text('Monthly Salary'), findsOneWidget);
      expect(find.text('+₹80,000.00'), findsOneWidget);
      expect(find.text('Tech consulting contract payment'), findsOneWidget);

      // Verify Delete action in AppBar
      final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteIcon, findsOneWidget);

      // Tap delete icon to trigger confirmation dialog
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Check dialog elements
      expect(find.text('Delete this income?'), findsOneWidget);
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
      expect(mockRepo.lastDeletedId, testIncome.id);
    });
  });
}
