import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/dashboard_summary.dart';

/// Abstract contract for Dashboard repository.
abstract class DashboardRepository {
  Future<DashboardSummary> getDashboardSummary({
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  });
}

/// Concrete implementation of [DashboardRepository] consuming FastAPI endpoints.
class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepositoryImpl(this._apiClient);

  @override
  Future<DashboardSummary> getDashboardSummary({
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
      ApiEndpoints.dashboard,
      queryParameters: params.isNotEmpty ? params : null,
    );
    return DashboardSummary.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Riverpod provider for [DashboardRepository].
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(apiClientProvider));
});

/// Riverpod FutureProvider for dashboard data.
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getDashboardSummary();
});
