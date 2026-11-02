import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../reports/data/report_repository_impl.dart';
import '../../reports/domain/reports_models.dart';
import '../data/dashboard_repository_impl.dart';
import '../domain/dashboard_summary.dart';

/// Month & Year selection model for Dashboard filtering.
class DashboardMonthYear {
  final int month;
  final int year;

  const DashboardMonthYear({required this.month, required this.year});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardMonthYear &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => month.hashCode ^ year.hashCode;
}

/// Selected month and year notifier for the dashboard.
class DashboardSelectedDateNotifier extends Notifier<DashboardMonthYear> {
  @override
  DashboardMonthYear build() {
    return const DashboardMonthYear(month: 10, year: 2026);
  }

  void setDate(int month, int year) {
    state = DashboardMonthYear(month: month, year: year);
  }
}

/// Selected month and year provider for the dashboard.
/// Defaults to October 2026.
final dashboardSelectedDateProvider =
    NotifierProvider<DashboardSelectedDateNotifier, DashboardMonthYear>(() {
  return DashboardSelectedDateNotifier();
});

/// Consolidated dashboard data state model combining summary,
/// category distribution, and member contributions for charts.
class DashboardData {
  final DashboardSummary summary;
  final List<CategoryReportItem> categoryBreakdown;
  final List<MemberReportItem> memberBreakdown;

  const DashboardData({
    required this.summary,
    this.categoryBreakdown = const [],
    this.memberBreakdown = const [],
  });
}

/// Riverpod AsyncNotifier managing the dashboard data fetching, refresh, and state.
class DashboardController extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    final selectedDate = ref.watch(dashboardSelectedDateProvider);
    return _fetchDashboardData(selectedDate);
  }

  Future<DashboardData> _fetchDashboardData(DashboardMonthYear date) async {
    final dashboardRepo = ref.read(dashboardRepositoryProvider);
    final reportRepo = ref.read(reportRepositoryProvider);

    // Fetch dashboard summary
    final summary = await dashboardRepo.getDashboardSummary(
      month: date.month,
      year: date.year,
    );

    // Fetch category breakdown for Expense by Category chart
    List<CategoryReportItem> categories = [];
    try {
      categories = await reportRepo.getCategoryReport(
        month: date.month,
        year: date.year,
        type: 'expense',
      );
    } catch (e) {
      debugPrint('Optional category report load note: $e');
    }

    // Fetch member breakdown for Husband vs Wife chart
    List<MemberReportItem> members = [];
    try {
      members = await reportRepo.getMemberReport(
        month: date.month,
        year: date.year,
      );
    } catch (e) {
      debugPrint('Optional member report load note: $e');
    }

    return DashboardData(
      summary: summary,
      categoryBreakdown: categories,
      memberBreakdown: members,
    );
  }

  /// Change selected month and trigger a reload.
  void selectMonthYear(int month, int year) {
    ref.read(dashboardSelectedDateProvider.notifier).setDate(month, year);
  }

  /// Refreshes dashboard data (e.g. from pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final selectedDate = ref.read(dashboardSelectedDateProvider);
      return _fetchDashboardData(selectedDate);
    });
  }
}

/// Riverpod provider for DashboardController.
final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardData>(() {
  return DashboardController();
});
