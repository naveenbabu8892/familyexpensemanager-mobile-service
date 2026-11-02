import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_endpoints.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/budgets/data/budget_repository_impl.dart';
import 'package:mobile/features/categories/data/category_repository_impl.dart';
import 'package:mobile/features/dashboard/data/dashboard_repository_impl.dart';
import 'package:mobile/features/expenses/data/expense_repository_impl.dart';
import 'package:mobile/features/family/data/family_repository_impl.dart';
import 'package:mobile/features/income/data/income_repository_impl.dart';
import 'package:mobile/features/profile/data/user_repository_impl.dart';
import 'package:mobile/features/reports/data/report_repository_impl.dart';

class InMemorySecureStorage extends SecureStorageService {
  final Map<String, String> data = {};

  @override
  Future<String?> getAccessToken() async => data[AppConstants.keyAccessToken];

  @override
  Future<void> setAccessToken(String token) async => data[AppConstants.keyAccessToken] = token;

  @override
  Future<String?> getRefreshToken() async => data[AppConstants.keyRefreshToken];

  @override
  Future<void> setRefreshToken(String token) async => data[AppConstants.keyRefreshToken] = token;

  @override
  Future<String?> getActiveFamilyId() async => data[AppConstants.keyFamilyId];

  @override
  Future<void> setActiveFamilyId(String familyId) async => data[AppConstants.keyFamilyId] = familyId;

  @override
  Future<void> clearAuthSession() async => data.clear();

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

ResponseBody jsonResponse(dynamic data, int statusCode, {Map<String, List<String>>? headers}) {
  final h = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
    ...?headers,
  };
  final body = data is String ? data : jsonEncode(data);
  return ResponseBody.fromString(body, statusCode, headers: h);
}

class MockHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late ApiClient apiClient;
  late InMemorySecureStorage storage;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:8000/api/v1'));
    apiClient = ApiClient(dio);
    storage = InMemorySecureStorage();
  });

  group('1. AuthRepository Tests', () {
    test('register and login persist tokens and return AuthTokens', () async {
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        return jsonResponse(
          {
            'access_token': 'jwt_access_123',
            'refresh_token': 'jwt_refresh_456',
            'token_type': 'bearer',
            'expires_in': 1800,
          },
          200,
        );
      });

      final authRepo = AuthRepositoryImpl(apiClient: apiClient, storage: storage);

      final tokens = await authRepo.login(email: 'raj@example.com', password: 'password123');
      expect(tokens.accessToken, 'jwt_access_123');
      expect(await storage.getAccessToken(), 'jwt_access_123');
      expect(await storage.getRefreshToken(), 'jwt_refresh_456');
    });

    test('logout clears secure storage', () async {
      await storage.setAccessToken('old_token');
      await storage.setRefreshToken('old_refresh');

      dio.httpClientAdapter = MockHttpAdapter((options) async {
        return jsonResponse({'message': 'Logged out'}, 200);
      });

      final authRepo = AuthRepositoryImpl(apiClient: apiClient, storage: storage);
      await authRepo.logout();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });

  group('2. UserRepository Tests', () {
    test('getCurrentUser and updateCurrentUser return mapped User entity', () async {
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        if (options.method == 'GET') {
          return jsonResponse(
            {
              'id': 'usr-1',
              'email': 'raj@example.com',
              'full_name': 'Raj Sharma',
              'phone': '+919876543210',
              'is_active': true,
              'created_at': '2026-10-01T10:00:00Z',
            },
            200,
          );
        } else {
          return jsonResponse(
            {
              'id': 'usr-1',
              'email': 'raj@example.com',
              'full_name': 'Raj S. Sharma',
              'phone': '+919876543210',
              'is_active': true,
              'created_at': '2026-10-01T10:00:00Z',
            },
            200,
          );
        }
      });

      final userRepo = UserRepositoryImpl(apiClient);

      final user = await userRepo.getCurrentUser();
      expect(user.fullName, 'Raj Sharma');

      final updated = await userRepo.updateCurrentUser(fullName: 'Raj S. Sharma');
      expect(updated.fullName, 'Raj S. Sharma');
    });
  });

  group('3. FamilyRepository Tests', () {
    test('getCurrentFamily, createFamily, inviteMember, and getMembers', () async {
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.familyCurrent)) {
          return jsonResponse(
            {
              'id': 'fam-1',
              'name': 'The Sharma Family',
              'currency': 'INR',
              'timezone': 'Asia/Kolkata',
              'created_at': '2026-10-01T10:00:00Z',
            },
            200,
          );
        }
        if (options.path.endsWith(ApiEndpoints.familyInvite)) {
          return jsonResponse({'token': 'invite-token-xyz'}, 200);
        }
        if (options.path.endsWith(ApiEndpoints.familyMembers)) {
          return jsonResponse(
            [
              {
                'id': 'mem-1',
                'family_id': 'fam-1',
                'user_id': 'usr-1',
                'full_name': 'Raj Sharma',
                'email': 'raj@example.com',
                'role': 'OWNER',
                'joined_at': '2026-10-01T10:00:00Z',
              }
            ],
            200,
          );
        }
        return jsonResponse('', 400);
      });

      final familyRepo = FamilyRepositoryImpl(apiClient: apiClient, storage: storage);

      final family = await familyRepo.getCurrentFamily();
      expect(family?.name, 'The Sharma Family');
      expect(await storage.getActiveFamilyId(), 'fam-1');

      final token = await familyRepo.inviteMember('priya@example.com');
      expect(token, 'invite-token-xyz');

      final members = await familyRepo.getFamilyMembers();
      expect(members.length, 1);
      expect(members.first.fullName, 'Raj Sharma');
    });
  });

  group('4. CategoryRepository Tests', () {
    test('getCategories, createCategory, and deleteCategory', () async {
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        if (options.method == 'GET') {
          return jsonResponse(
            [
              {
                'id': 'cat-1',
                'name': 'Grocery',
                'type': 'EXPENSE',
                'icon': 'shopping_basket',
                'color': '#B86B4B',
                'is_default': true,
              }
            ],
            200,
          );
        }
        if (options.method == 'POST') {
          return jsonResponse(
            {
              'id': 'cat-2',
              'name': 'Salary',
              'type': 'INCOME',
              'icon': 'payments',
              'color': '#657153',
              'is_default': false,
            },
            201,
          );
        }
        if (options.method == 'DELETE') {
          return ResponseBody.fromString('', 204);
        }
        return jsonResponse('', 400);
      });

      final catRepo = CategoryRepositoryImpl(apiClient);

      final list = await catRepo.getCategories(type: 'EXPENSE');
      expect(list.length, 1);
      expect(list.first.name, 'Grocery');

      final created = await catRepo.createCategory(
        name: 'Salary',
        type: 'INCOME',
        icon: 'payments',
      );
      expect(created.name, 'Salary');

      await catRepo.deleteCategory('cat-1');
    });
  });

  group('5. ExpenseRepository Tests', () {
    test('getExpenses, getExpenseById, createExpense, and deleteExpense', () async {
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        if (options.method == 'GET' && options.path == ApiEndpoints.expenses) {
          return jsonResponse(
            {
              'items': [
                {
                  'id': 'exp-1',
                  'title': 'Weekly Grocery',
                  'amount': '2450.00',
                  'currency': 'INR',
                  'category_id': 'cat-1',
                  'expense_date': '2026-10-05',
                  'payment_method': 'upi',
                  'is_shared': true,
                  'paid_by': 'usr-1',
                  'created_at': '2026-10-05T10:00:00Z',
                }
              ],
              'total': 1,
              'page': 1,
              'page_size': 20,
            },
            200,
          );
        }
        if (options.method == 'POST') {
          return jsonResponse(
            {
              'id': 'exp-2',
              'title': 'Electricity Bill',
              'amount': '1820.00',
              'currency': 'INR',
              'category_id': 'cat-2',
              'expense_date': '2026-10-04',
              'payment_method': 'net_banking',
              'is_shared': true,
              'paid_by': 'usr-1',
              'created_at': '2026-10-04T10:00:00Z',
            },
            201,
          );
        }
        if (options.method == 'DELETE') {
          return ResponseBody.fromString('', 204);
        }
        return jsonResponse('', 400);
      });

      final expRepo = ExpenseRepositoryImpl(apiClient);

      final expenses = await expRepo.getExpenses();
      expect(expenses.length, 1);
      expect(expenses.first.title, 'Weekly Grocery');
      expect(expenses.first.amount, 2450.0);

      final created = await expRepo.createExpense(
        title: 'Electricity Bill',
        amount: 1820.0,
        categoryId: 'cat-2',
        expenseDate: '2026-10-04',
      );
      expect(created.amount, 1820.0);

      await expRepo.deleteExpense('exp-1');
    });
  });

  group('6. IncomeRepository Tests', () {
    test('getIncomes, createIncome, and deleteIncome', () async {
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        if (options.method == 'GET' && options.path == ApiEndpoints.income) {
          return jsonResponse(
            {
              'items': [
                {
                  'id': 'inc-1',
                  'title': 'Tech Consulting',
                  'amount': '80000.00',
                  'currency': 'INR',
                  'category_id': 'cat-salary',
                  'income_date': '2026-10-01',
                  'received_by': 'usr-1',
                  'created_at': '2026-10-01T10:00:00Z',
                }
              ],
              'total': 1,
              'page': 1,
              'page_size': 20,
            },
            200,
          );
        }
        if (options.method == 'POST') {
          return jsonResponse(
            {
              'id': 'inc-2',
              'title': 'Freelance Project',
              'amount': '25000.00',
              'currency': 'INR',
              'category_id': 'cat-freelance',
              'income_date': '2026-10-03',
              'received_by': 'usr-1',
              'created_at': '2026-10-03T10:00:00Z',
            },
            201,
          );
        }
        if (options.method == 'DELETE') {
          return ResponseBody.fromString('', 204);
        }
        return jsonResponse('', 400);
      });

      final incRepo = IncomeRepositoryImpl(apiClient);

      final incomes = await incRepo.getIncomes();
      expect(incomes.length, 1);
      expect(incomes.first.amount, 80000.0);

      final created = await incRepo.createIncome(
        title: 'Freelance Project',
        amount: 25000.0,
        categoryId: 'cat-freelance',
        incomeDate: '2026-10-03',
      );
      expect(created.amount, 25000.0);

      await incRepo.deleteIncome('inc-1');
    });
  });

  group('7. BudgetRepository Tests', () {
    test('getBudgets, createBudget, updateBudget, and deleteBudget', () async {
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        if (options.method == 'GET') {
          return jsonResponse(
            [
              {
                'id': 'bud-1',
                'category_id': 'cat-grocery',
                'category_name': 'Grocery',
                'amount': '20000.00',
                'spent_amount': '15000.00',
                'remaining_amount': '5000.00',
                'percentage_used': 75.0,
                'month': 10,
                'year': 2026,
              }
            ],
            200,
          );
        }
        if (options.method == 'POST') {
          return jsonResponse(
            {
              'id': 'bud-2',
              'category_id': 'cat-dining',
              'amount': '8000.00',
              'spent_amount': '0.00',
              'remaining_amount': '8000.00',
              'percentage_used': 0.0,
              'month': 10,
              'year': 2026,
            },
            201,
          );
        }
        if (options.method == 'PUT') {
          return jsonResponse(
            {
              'id': 'bud-1',
              'category_id': 'cat-grocery',
              'amount': '25000.00',
              'spent_amount': '15000.00',
              'remaining_amount': '10000.00',
              'percentage_used': 60.0,
              'month': 10,
              'year': 2026,
            },
            200,
          );
        }
        if (options.method == 'DELETE') {
          return ResponseBody.fromString('', 204);
        }
        return jsonResponse('', 400);
      });

      final budgetRepo = BudgetRepositoryImpl(apiClient);

      final list = await budgetRepo.getBudgets(month: 10, year: 2026);
      expect(list.length, 1);
      expect(list.first.amount, 20000.0);
      expect(list.first.spentAmount, 15000.0);

      final created = await budgetRepo.createBudget(
        categoryId: 'cat-dining',
        amount: 8000.0,
        month: 10,
        year: 2026,
      );
      expect(created.amount, 8000.0);

      final updated = await budgetRepo.updateBudget('bud-1', amount: 25000.0);
      expect(updated.amount, 25000.0);

      await budgetRepo.deleteBudget('bud-1');
    });
  });

  group('8. DashboardRepository Tests', () {
    test('getDashboardSummary deserializes dashboard response payload', () async {
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        return jsonResponse(
          {
            'currency': 'INR',
            'total_income': '80000.00',
            'total_expenses': '45000.00',
            'remaining_balance': '35000.00',
            'shared_expenses': '30000.00',
            'personal_expenses': '15000.00',
            'my_expenses': '25000.00',
            'spouse_expenses': '20000.00',
            'recent_transactions': [
              {
                'id': 'tx-1',
                'title': 'Grocery',
                'type': 'expense',
                'amount': '2450.00',
                'currency': 'INR',
                'date': '2026-10-05',
                'category_name': 'Grocery',
                'is_shared': true,
              }
            ],
          },
          200,
        );
      });

      final dashRepo = DashboardRepositoryImpl(apiClient);
      final summary = await dashRepo.getDashboardSummary();

      expect(summary.totalIncome, 80000.0);
      expect(summary.totalExpenses, 45000.0);
      expect(summary.remainingBalance, 35000.0);
      expect(summary.recentTransactions.length, 1);
      expect(summary.recentTransactions.first.title, 'Grocery');
    });
  });

  group('9. ReportRepository Tests', () {
    test('getMonthlyReport, getCategoryReport, getMemberReport, and getPaymentMethodReport', () async {
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        if (options.path.endsWith(ApiEndpoints.reportMonthly)) {
          return jsonResponse(
            {
              'year': 2026,
              'months': [
                {
                  'month': 10,
                  'month_name': 'October',
                  'year': 2026,
                  'income': '80000.00',
                  'expenses': '45000.00',
                  'net_savings': '35000.00',
                  'savings_rate': '43.75',
                }
              ]
            },
            200,
          );
        }
        if (options.path.endsWith(ApiEndpoints.reportCategories)) {
          return jsonResponse(
            {
              'categories': [
                {
                  'category_id': 'cat-1',
                  'category_name': 'Grocery',
                  'amount': '15000.00',
                  'percentage': '33.33',
                  'transaction_count': 5,
                }
              ]
            },
            200,
          );
        }
        if (options.path.endsWith(ApiEndpoints.reportMembers)) {
          return jsonResponse(
            {
              'members': [
                {
                  'user_id': 'usr-1',
                  'user_name': 'Raj Sharma',
                  'total_paid': '25000.00',
                  'percentage_of_total': '55.55',
                  'personal_expenses': '5000.00',
                  'shared_expenses': '20000.00',
                  'income_earned': '80000.00',
                }
              ]
            },
            200,
          );
        }
        if (options.path.endsWith(ApiEndpoints.reportPaymentMethods)) {
          return jsonResponse(
            {
              'payment_methods': [
                {
                  'payment_method': 'credit_card',
                  'amount': '30000.00',
                  'percentage': '66.67',
                  'transaction_count': 12,
                }
              ]
            },
            200,
          );
        }
        return jsonResponse('', 400);
      });

      final reportRepo = ReportRepositoryImpl(apiClient);

      final monthly = await reportRepo.getMonthlyReport(year: 2026);
      expect(monthly.length, 1);
      expect(monthly.first.income, 80000.0);
      expect(monthly.first.monthName, 'October');

      final categories = await reportRepo.getCategoryReport();
      expect(categories.length, 1);
      expect(categories.first.categoryName, 'Grocery');

      final members = await reportRepo.getMemberReport();
      expect(members.length, 1);
      expect(members.first.memberName, 'Raj Sharma');

      final paymentMethods = await reportRepo.getPaymentMethodReport();
      expect(paymentMethods.length, 1);
      expect(paymentMethods.first.paymentMethod, 'credit_card');
    });
  });
}
