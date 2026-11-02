import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/income.dart';

/// Abstract contract for Income management repository.
abstract class IncomeRepository {
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
  });

  Future<Income> getIncomeById(String id);

  Future<Income> createIncome({
    required String title,
    required double amount,
    required String categoryId,
    required String incomeDate,
    String? description,
    String? receivedBy,
  });

  Future<Income> updateIncome(
    String id, {
    String? title,
    double? amount,
    String? categoryId,
    String? incomeDate,
    String? description,
    String? receivedBy,
  });

  Future<void> deleteIncome(String id);
}

/// Concrete implementation of [IncomeRepository] consuming FastAPI endpoints.
class IncomeRepositoryImpl implements IncomeRepository {
  final ApiClient _apiClient;

  IncomeRepositoryImpl(this._apiClient);

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
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (categoryId != null) params['category_id'] = categoryId;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (receivedBy != null) params['received_by'] = receivedBy;
    if (search != null) params['search'] = search;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;

    final response = await _apiClient.get(
      ApiEndpoints.income,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List? ?? [];
    return items.map((e) => Income.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Income> getIncomeById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.incomeDetail(id));
    return Income.fromJson(response.data as Map<String, dynamic>);
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
    final payload = <String, dynamic>{
      'title': title.trim(),
      'amount': amount.toStringAsFixed(2),
      'category_id': categoryId,
      'income_date': incomeDate,
      'description': description?.trim(),
    };
    if (receivedBy != null) payload['received_by'] = receivedBy;

    final response = await _apiClient.post(
      ApiEndpoints.income,
      data: payload,
    );
    return Income.fromJson(response.data as Map<String, dynamic>);
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
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title.trim();
    if (amount != null) payload['amount'] = amount.toStringAsFixed(2);
    if (categoryId != null) payload['category_id'] = categoryId;
    if (incomeDate != null) payload['income_date'] = incomeDate;
    if (description != null) payload['description'] = description.trim();
    if (receivedBy != null) payload['received_by'] = receivedBy;

    final response = await _apiClient.put(
      ApiEndpoints.incomeDetail(id),
      data: payload,
    );
    return Income.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteIncome(String id) async {
    await _apiClient.delete(ApiEndpoints.incomeDetail(id));
  }
}

/// Riverpod provider for [IncomeRepository].
final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IncomeRepositoryImpl(ref.watch(apiClientProvider));
});
