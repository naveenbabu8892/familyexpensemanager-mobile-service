import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/reports_models.dart';

/// Abstract contract for Reports repository.
abstract class ReportRepository {
  Future<List<MonthlyReportItem>> getMonthlyReport({int? year});
  Future<List<CategoryReportItem>> getCategoryReport({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
    String type = 'expense',
  });
  Future<CategoryReportResponse> getCategoryReportResponse({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
    String type = 'expense',
  });
  Future<List<MemberReportItem>> getMemberReport({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  });
  Future<MemberReportResponse> getMemberReportResponse({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  });
  Future<List<PaymentMethodReportItem>> getPaymentMethodReport({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  });
  Future<PaymentMethodReportResponse> getPaymentMethodReportResponse({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  });
}

/// Concrete implementation of [ReportRepository] consuming FastAPI endpoints.
class ReportRepositoryImpl implements ReportRepository {
  final ApiClient _apiClient;

  ReportRepositoryImpl(this._apiClient);

  @override
  Future<List<MonthlyReportItem>> getMonthlyReport({int? year}) async {
    final params = <String, dynamic>{};
    if (year != null) params['year'] = year;

    final response = await _apiClient.get(
      ApiEndpoints.reportMonthly,
      queryParameters: params.isNotEmpty ? params : null,
    );

    final dynamic data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data['months'] is List) {
      items = data['months'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      items = [];
    }

    return items
        .map((e) => MonthlyReportItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CategoryReportItem>> getCategoryReport({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
    String type = 'expense',
  }) async {
    final params = <String, dynamic>{'type': type};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final response = await _apiClient.get(
      ApiEndpoints.reportCategories,
      queryParameters: params,
    );

    final dynamic data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data['categories'] is List) {
      items = data['categories'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      items = [];
    }

    return items
        .map((e) => CategoryReportItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CategoryReportResponse> getCategoryReportResponse({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
    String type = 'expense',
  }) async {
    final params = <String, dynamic>{'type': type};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final response = await _apiClient.get(
      ApiEndpoints.reportCategories,
      queryParameters: params,
    );

    return CategoryReportResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<MemberReportItem>> getMemberReport({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  }) async {
    final params = <String, dynamic>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final response = await _apiClient.get(
      ApiEndpoints.reportMembers,
      queryParameters: params.isNotEmpty ? params : null,
    );

    final dynamic data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data['members'] is List) {
      items = data['members'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      items = [];
    }

    return items
        .map((e) => MemberReportItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MemberReportResponse> getMemberReportResponse({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  }) async {
    final params = <String, dynamic>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final response = await _apiClient.get(
      ApiEndpoints.reportMembers,
      queryParameters: params.isNotEmpty ? params : null,
    );

    return MemberReportResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<PaymentMethodReportItem>> getPaymentMethodReport({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  }) async {
    final params = <String, dynamic>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final response = await _apiClient.get(
      ApiEndpoints.reportPaymentMethods,
      queryParameters: params.isNotEmpty ? params : null,
    );

    final dynamic data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data['payment_methods'] is List) {
      items = data['payment_methods'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      items = [];
    }

    return items
        .map((e) => PaymentMethodReportItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PaymentMethodReportResponse> getPaymentMethodReportResponse({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  }) async {
    final params = <String, dynamic>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final response = await _apiClient.get(
      ApiEndpoints.reportPaymentMethods,
      queryParameters: params.isNotEmpty ? params : null,
    );

    return PaymentMethodReportResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Riverpod provider for [ReportRepository].
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.watch(apiClientProvider));
});
