import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/expense.dart';

/// Abstract contract for Expense management repository.
abstract class ExpenseRepository {
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
  });

  Future<Expense> getExpenseById(String id);

  Future<Expense> createExpense({
    required String title,
    required double amount,
    required String categoryId,
    required String expenseDate,
    String paymentMethod = 'credit_card',
    String? description,
    String? paidBy,
    bool isShared = true,
  });

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
  });

  Future<void> deleteExpense(String id);
}

/// Concrete implementation of [ExpenseRepository] consuming FastAPI endpoints.
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ApiClient _apiClient;

  ExpenseRepositoryImpl(this._apiClient);

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
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (categoryId != null) params['category_id'] = categoryId;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (paidBy != null) params['paid_by'] = paidBy;
    if (search != null) params['search'] = search;
    if (paymentMethod != null) params['payment_method'] = paymentMethod;
    if (isShared != null) params['is_shared'] = isShared;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;

    final response = await _apiClient.get(
      ApiEndpoints.expenses,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List? ?? [];
    return items.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.expenseDetail(id));
    return Expense.fromJson(response.data as Map<String, dynamic>);
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
    final payload = <String, dynamic>{
      'title': title.trim(),
      'amount': amount.toStringAsFixed(2),
      'category_id': categoryId,
      'expense_date': expenseDate,
      'payment_method': paymentMethod,
      'description': description?.trim(),
      'is_shared': isShared,
    };
    if (paidBy != null && paidBy.isNotEmpty) {
      payload['paid_by'] = paidBy;
    }

    final response = await _apiClient.post(
      ApiEndpoints.expenses,
      data: payload,
    );
    return Expense.fromJson(response.data as Map<String, dynamic>);
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
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title.trim();
    if (amount != null) payload['amount'] = amount.toStringAsFixed(2);
    if (categoryId != null) payload['category_id'] = categoryId;
    if (expenseDate != null) payload['expense_date'] = expenseDate;
    if (paymentMethod != null) payload['payment_method'] = paymentMethod;
    if (description != null) payload['description'] = description.trim();
    if (paidBy != null) payload['paid_by'] = paidBy;
    if (isShared != null) payload['is_shared'] = isShared;

    final response = await _apiClient.put(
      ApiEndpoints.expenseDetail(id),
      data: payload,
    );
    return Expense.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _apiClient.delete(ApiEndpoints.expenseDetail(id));
  }
}

/// Riverpod provider for [ExpenseRepository].
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(ref.watch(apiClientProvider));
});

/// Riverpod FutureProvider for recent expenses.
final recentExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  return ref.watch(expenseRepositoryProvider).getExpenses(pageSize: 5);
});
