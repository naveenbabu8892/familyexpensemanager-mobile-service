import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/empty_state.dart';
import 'package:mobile/features/reports/data/report_repository_impl.dart';
import 'package:mobile/features/reports/domain/reports_models.dart';
import 'package:mobile/features/reports/presentation/reports_screen.dart';

class MockReportRepositoryForReports implements ReportRepository {
  List<MonthlyReportItem> monthlyReport;
  CategoryReportResponse categoryReport;
  MemberReportResponse memberReport;
  PaymentMethodReportResponse paymentMethodReport;

  int getMonthlyCount = 0;
  int getCategoriesCount = 0;
  int getMembersCount = 0;
  int getPaymentMethodsCount = 0;

  MockReportRepositoryForReports({
    required this.monthlyReport,
    required this.categoryReport,
    required this.memberReport,
    required this.paymentMethodReport,
  });

  @override
  Future<List<MonthlyReportItem>> getMonthlyReport({int? year}) async {
    getMonthlyCount++;
    return monthlyReport;
  }

  @override
  Future<List<CategoryReportItem>> getCategoryReport({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
    String type = 'expense',
  }) async {
    getCategoriesCount++;
    return categoryReport.categories;
  }

  @override
  Future<CategoryReportResponse> getCategoryReportResponse({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
    String type = 'expense',
  }) async {
    getCategoriesCount++;
    return categoryReport;
  }

  @override
  Future<List<MemberReportItem>> getMemberReport({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  }) async {
    getMembersCount++;
    return memberReport.members;
  }

  @override
  Future<MemberReportResponse> getMemberReportResponse({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  }) async {
    getMembersCount++;
    return memberReport;
  }

  @override
  Future<List<PaymentMethodReportItem>> getPaymentMethodReport({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  }) async {
    getPaymentMethodsCount++;
    return paymentMethodReport.paymentMethods;
  }

  @override
  Future<PaymentMethodReportResponse> getPaymentMethodReportResponse({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  }) async {
    getPaymentMethodsCount++;
    return paymentMethodReport;
  }
}

void main() {
  late MockReportRepositoryForReports mockRepo;

  final sampleCategories = const CategoryReportResponse(
    fromDate: '2026-10-01',
    toDate: '2026-10-31',
    currency: 'INR',
    type: 'expense',
    totalAmount: 45000,
    categories: [
      CategoryReportItem(
        categoryId: 'cat-grocery',
        categoryName: 'Grocery',
        color: '#B86B4B',
        totalAmount: 20000,
        percentage: 44.4,
        transactionCount: 8,
      ),
      CategoryReportItem(
        categoryId: 'cat-housing',
        categoryName: 'Housing',
        color: '#657153',
        totalAmount: 25000,
        percentage: 55.6,
        transactionCount: 2,
      ),
    ],
  );

  final sampleMembers = const MemberReportResponse(
    fromDate: '2026-10-01',
    toDate: '2026-10-31',
    currency: 'INR',
    totalExpenses: 45000,
    totalIncome: 80000,
    sharedExpenses: 30000,
    personalExpenses: 15000,
    members: [
      MemberReportItem(
        memberId: 'usr-husband',
        memberName: 'Raj',
        role: 'owner',
        totalSpent: 27000,
        percentage: 60.0,
        sharedExpenses: 18000,
        personalExpenses: 9000,
        incomeEarned: 50000,
      ),
      MemberReportItem(
        memberId: 'usr-wife',
        memberName: 'Priya',
        role: 'member',
        totalSpent: 18000,
        percentage: 40.0,
        sharedExpenses: 12000,
        personalExpenses: 6000,
        incomeEarned: 30000,
      ),
    ],
  );

  final sampleMonthly = const [
    MonthlyReportItem(
      month: 9,
      monthName: 'September',
      year: 2026,
      income: 75000,
      expense: 42000,
      savings: 33000,
      savingsRate: 44.0,
    ),
    MonthlyReportItem(
      month: 10,
      monthName: 'October',
      year: 2026,
      income: 80000,
      expense: 45000,
      savings: 35000,
      savingsRate: 43.8,
    ),
  ];

  final samplePaymentMethods = const PaymentMethodReportResponse(
    fromDate: '2026-10-01',
    toDate: '2026-10-31',
    currency: 'INR',
    totalAmount: 45000,
    paymentMethods: [
      PaymentMethodReportItem(
        paymentMethod: 'upi',
        amount: 25000,
        percentage: 55.6,
        transactionCount: 14,
      ),
      PaymentMethodReportItem(
        paymentMethod: 'credit_card',
        amount: 20000,
        percentage: 44.4,
        transactionCount: 4,
      ),
    ],
  );

  setUp(() {
    mockRepo = MockReportRepositoryForReports(
      categoryReport: sampleCategories,
      memberReport: sampleMembers,
      monthlyReport: sampleMonthly,
      paymentMethodReport: samplePaymentMethods,
    );
  });

  Widget createReportsTestWidget({List<dynamic> extraOverrides = const []}) {
    return ProviderScope(
      overrides: [
        reportRepositoryProvider.overrideWithValue(mockRepo),
        ...extraOverrides.cast(),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ReportsScreen(),
      ),
    );
  }

  group('Reports Screen Comprehensive Tests', () {
    testWidgets('1. Displays filter chips for Current Month, Previous Month, and Custom Range',
        (tester) async {
      await tester.pumpWidget(createReportsTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Current Month'), findsOneWidget);
      expect(find.text('Previous Month'), findsOneWidget);
      expect(find.textContaining('Custom Range'), findsOneWidget);
    });

    testWidgets('2. Displays Category report with Donut chart and authoritative totals',
        (tester) async {
      await tester.pumpWidget(createReportsTestWidget());
      await tester.pumpAndSettle();

      // Check authoritative total
      expect(find.text('TOTAL SPENT'), findsOneWidget);
      expect(find.text('₹45,000'), findsOneWidget);

      // Scroll down to detailed list
      await tester.drag(find.text('TOTAL SPENT'), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Grocery'), findsWidgets);
      expect(find.text('₹20,000'), findsOneWidget);
      expect(find.text('Housing'), findsWidgets);
      expect(find.text('₹25,000'), findsOneWidget);
    });

    testWidgets('3. Switches to Members tab and renders Husband vs Wife bar chart comparison',
        (tester) async {
      await tester.pumpWidget(createReportsTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Members' tab
      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();

      expect(find.text('Husband vs Wife'), findsOneWidget);
      expect(find.text('Raj'), findsWidgets);
      expect(find.text('Priya'), findsWidgets);
      expect(find.textContaining('60%'), findsWidgets);
      expect(find.textContaining('40%'), findsWidgets);
      expect(find.text('Shared Expenses'), findsOneWidget);
      expect(find.text('Personal Expenses'), findsOneWidget);
    });

    testWidgets('4. Switches to Monthly Trend tab and renders Income vs Expense and monthly trend',
        (tester) async {
      await tester.pumpWidget(createReportsTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Monthly Trend' tab
      await tester.tap(find.text('Monthly Trend'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Income vs Expense'), findsOneWidget);
      expect(find.text('Annual Cashflow'), findsOneWidget);
      expect(find.text('Monthly Trend'), findsWidgets);
      expect(find.text('September'), findsOneWidget);
      expect(find.text('October'), findsOneWidget);
    });

    testWidgets('5. Switches to Payment Methods tab and renders instruments distribution',
        (tester) async {
      await tester.pumpWidget(createReportsTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Payment Methods' tab
      await tester.tap(find.text('Payment Methods'));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL BY INSTRUMENT'), findsOneWidget);
      expect(find.text('UPI'), findsOneWidget);
      expect(find.text('Credit Card'), findsOneWidget);
      expect(find.textContaining('55.6%'), findsOneWidget);
      expect(find.textContaining('44.4%'), findsOneWidget);
    });

    testWidgets('6. Switching filter to Previous Month re-queries backend APIs',
        (tester) async {
      await tester.pumpWidget(createReportsTestWidget());
      await tester.pumpAndSettle();

      final initialCount = mockRepo.getCategoriesCount;

      // Tap 'Previous Month'
      await tester.tap(find.text('Previous Month'));
      await tester.pumpAndSettle();

      expect(mockRepo.getCategoriesCount, greaterThan(initialCount));
    });

    testWidgets('7. Displays Empty State when reports return empty data',
        (tester) async {
      mockRepo = MockReportRepositoryForReports(
        categoryReport: const CategoryReportResponse(
          fromDate: '2026-10-01',
          toDate: '2026-10-31',
          currency: 'INR',
          totalAmount: 0,
          categories: [],
        ),
        memberReport: const MemberReportResponse(
          fromDate: '2026-10-01',
          toDate: '2026-10-31',
          currency: 'INR',
          totalExpenses: 0,
          totalIncome: 0,
          sharedExpenses: 0,
          personalExpenses: 0,
          members: [],
        ),
        monthlyReport: [],
        paymentMethodReport: const PaymentMethodReportResponse(
          fromDate: '2026-10-01',
          toDate: '2026-10-31',
          currency: 'INR',
          totalAmount: 0,
          paymentMethods: [],
        ),
      );

      await tester.pumpWidget(createReportsTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.textContaining('No Data for'), findsOneWidget);
    });
  });
}
