import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/budget.dart';

/// Abstract contract for Budget repository.
abstract class BudgetRepository {
  Future<List<Budget>> getBudgets({int? month, int? year});
  Future<Budget> getBudgetById(String id);
  Future<Budget> createBudget({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  });
  Future<Budget> updateBudget(
    String id, {
    double? amount,
    int? month,
    int? year,
    String? categoryId,
  });
  Future<void> deleteBudget(String id);
}

/// Concrete implementation of [BudgetRepository] consuming FastAPI endpoints.
class BudgetRepositoryImpl implements BudgetRepository {
  final ApiClient _apiClient;

  BudgetRepositoryImpl(this._apiClient);

  @override
  Future<List<Budget>> getBudgets({int? month, int? year}) async {
    final now = DateTime.now();
    final response = await _apiClient.get(
      ApiEndpoints.budgets,
      queryParameters: {
        'month': month ?? now.month,
        'year': year ?? now.year,
      },
    );

    final list = response.data as List;
    return list.map((e) => Budget.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Budget> getBudgetById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.budgetDetail(id));
    return Budget.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Budget> createBudget({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.budgets,
      data: {
        'category_id': categoryId,
        'amount': amount.toStringAsFixed(2),
        'month': month,
        'year': year,
      },
    );
    return Budget.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Budget> updateBudget(
    String id, {
    double? amount,
    int? month,
    int? year,
    String? categoryId,
  }) async {
    final Map<String, dynamic> data = {};
    if (amount != null) data['amount'] = amount.toStringAsFixed(2);
    if (month != null) data['month'] = month;
    if (year != null) data['year'] = year;
    if (categoryId != null) data['category_id'] = categoryId;

    final response = await _apiClient.put(
      ApiEndpoints.budgetDetail(id),
      data: data,
    );
    return Budget.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _apiClient.delete(ApiEndpoints.budgetDetail(id));
  }
}

/// Riverpod provider for [BudgetRepository].
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(ref.watch(apiClientProvider));
});

/// Riverpod FutureProvider for current month budgets.
final currentBudgetsProvider = FutureProvider<List<Budget>>((ref) async {
  return ref.watch(budgetRepositoryProvider).getBudgets();
});
