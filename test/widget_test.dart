import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/constants/environment.dart';
import 'package:mobile/core/utils/currency_formatter.dart';
import 'package:mobile/core/utils/date_formatter.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/budgets/domain/budget.dart';
import 'package:mobile/features/expenses/domain/expense.dart';
import 'package:mobile/features/family/domain/family.dart';

void main() {
  group('EnvironmentConfig Tests', () {
    test('Development environment defaults to local API endpoint', () {
      final config = EnvironmentConfig.fromDartDefines();
      expect(config.environment, AppEnvironment.development);
      expect(config.baseUrl, anyOf(contains(':8000'), contains('onrender.com')));
      expect(config.isDevelopment, isTrue);
      expect(config.isProduction, isFalse);
    });
  });

  group('Utility Formatters Tests', () {
    test('CurrencyFormatter formats amounts with standard currency symbols', () {
      expect(CurrencyFormatter.format(1250.50, currency: 'USD'), '\$1,250.50');
      expect(CurrencyFormatter.format('500.00', currency: 'EUR'), '€500.00');
      expect(CurrencyFormatter.format(0, currency: 'USD'), '\$0.00');
      expect(CurrencyFormatter.format(null, currency: 'USD'), '0.00');
    });

    test('CurrencyFormatter compact format works', () {
      expect(CurrencyFormatter.formatCompact(15000, currency: 'USD'), '\$15K');
    });

    test('DateFormatter formats display and month-year strings', () {
      final dt = DateTime(2026, 10, 5);
      expect(DateFormatter.formatDisplay(dt), 'Oct 05, 2026');
      expect(DateFormatter.formatMonthYear(10, 2026), 'October 2026');
      expect(DateFormatter.toIsoDate(dt), '2026-10-05');
      expect(DateFormatter.parseIsoDate('2026-10-05'), DateTime(2026, 10, 5));
    });
  });

  group('Domain Entities Serialization Tests', () {
    test('User entity parses correctly from JSON', () {
      final json = {
        'id': 'u-123',
        'full_name': 'Test User',
        'email': 'user@example.com',
        'is_active': true,
      };
      final user = User.fromJson(json);
      expect(user.id, 'u-123');
      expect(user.fullName, 'Test User');
      expect(user.email, 'user@example.com');
      expect(user.isActive, isTrue);
    });

    test('Family and FamilyMember entities parse correctly', () {
      final famJson = {
        'id': 'f-123',
        'name': 'The Smiths',
        'currency': 'USD',
        'created_by': 'u-123',
        'user_role': 'owner',
      };
      final family = Family.fromJson(famJson);
      expect(family.name, 'The Smiths');
      expect(family.userRole, 'owner');

      final memberJson = {
        'id': 'm-1',
        'family_id': 'f-123',
        'user_id': 'u-123',
        'role': 'owner',
      };
      final member = FamilyMember.fromJson(memberJson);
      expect(member.isOwner, isTrue);
    });

    test('Expense entity deserializes money as double', () {
      final expJson = {
        'id': 'e-1',
        'family_id': 'f-1',
        'created_by': 'u-1',
        'paid_by': 'u-1',
        'category_id': 'c-1',
        'amount': '145.80',
        'currency': 'USD',
        'expense_date': '2026-10-05',
        'payment_method': 'credit_card',
        'title': 'Groceries',
        'is_shared': true,
      };
      final exp = Expense.fromJson(expJson);
      expect(exp.amount, 145.80);
      expect(exp.title, 'Groceries');
      expect(exp.isShared, isTrue);
    });

    test('Budget entity deserializes calculated aggregations', () {
      final bgtJson = {
        'id': 'b-1',
        'family_id': 'f-1',
        'category_id': 'c-1',
        'amount': '600.00',
        'month': 10,
        'year': 2026,
        'amount_spent': '450.00',
        'remaining_amount': '150.00',
        'percentage_used': '75.0',
        'warning_status': 'warning_75',
      };
      final budget = Budget.fromJson(bgtJson);
      expect(budget.amount, 600.00);
      expect(budget.amountSpent, 450.00);
      expect(budget.remainingAmount, 150.00);
      expect(budget.percentageUsed, 75.0);
      expect(budget.warningStatus, 'warning_75');
    });
  });

  group('Application Initialization Smoke Tests', () {
    testWidgets('App boots with ProviderScope and displays Splash branding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: FamilyExpenseManagerApp(),
        ),
      );

      // Splash branding should be visible immediately
      expect(find.text('Family Expense Manager'), findsOneWidget);
      expect(find.text('Shared Finances. Simplified.'), findsOneWidget);

      // Advance timer past splash delay so pending timer completes cleanly
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    });
  });
}
