import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/report_repository_impl.dart';
import '../domain/reports_models.dart';

/// Supported filter periods for Reports:
/// - Current Month
/// - Previous Month
/// - Custom Date Range
enum ReportFilterType {
  currentMonth,
  previousMonth,
  customRange,
}

/// Comprehensive filter state for Reports.
@immutable
class ReportsFilterState {
  final ReportFilterType filterType;
  final int? month;
  final int? year;
  final String? fromDate; // YYYY-MM-DD
  final String? toDate;   // YYYY-MM-DD
  final String categoryType; // 'expense' or 'income'

  const ReportsFilterState({
    this.filterType = ReportFilterType.currentMonth,
    this.month,
    this.year,
    this.fromDate,
    this.toDate,
    this.categoryType = 'expense',
  });

  ReportsFilterState copyWith({
    ReportFilterType? filterType,
    int? month,
    int? year,
    String? fromDate,
    String? toDate,
    String? categoryType,
  }) {
    return ReportsFilterState(
      filterType: filterType ?? this.filterType,
      month: month ?? this.month,
      year: year ?? this.year,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      categoryType: categoryType ?? this.categoryType,
    );
  }

  String get label {
    final now = DateTime.now();
    switch (filterType) {
      case ReportFilterType.currentMonth:
        final m = month ?? now.month;
        final y = year ?? now.year;
        final dt = DateTime(y, m);
        return DateFormat('MMMM yyyy').format(dt);
      case ReportFilterType.previousMonth:
        final m = month ?? (now.month == 1 ? 12 : now.month - 1);
        final y = year ?? (now.month == 1 ? now.year - 1 : now.year);
        final dt = DateTime(y, m);
        return DateFormat('MMMM yyyy').format(dt);
      case ReportFilterType.customRange:
        if (fromDate != null && toDate != null) {
          return '$fromDate to $toDate';
        }
        return 'Custom Range';
    }
  }
}

/// Filter Notifier for Reports.
class ReportsFilterNotifier extends Notifier<ReportsFilterState> {
  @override
  ReportsFilterState build() {
    final now = DateTime.now();
    return ReportsFilterState(
      filterType: ReportFilterType.currentMonth,
      month: now.month,
      year: now.year,
    );
  }

  void selectCurrentMonth() {
    final now = DateTime.now();
    state = ReportsFilterState(
      filterType: ReportFilterType.currentMonth,
      month: now.month,
      year: now.year,
      categoryType: state.categoryType,
    );
  }

  void selectPreviousMonth() {
    final now = DateTime.now();
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    state = ReportsFilterState(
      filterType: ReportFilterType.previousMonth,
      month: prevMonth,
      year: prevYear,
      categoryType: state.categoryType,
    );
  }

  void selectCustomRange(DateTime start, DateTime end) {
    final fmt = DateFormat('yyyy-MM-dd');
    state = ReportsFilterState(
      filterType: ReportFilterType.customRange,
      fromDate: fmt.format(start),
      toDate: fmt.format(end),
      categoryType: state.categoryType,
    );
  }

  void setCategoryType(String type) {
    state = state.copyWith(categoryType: type);
  }
}

/// Provider for ReportsFilterState.
final reportsFilterProvider =
    NotifierProvider<ReportsFilterNotifier, ReportsFilterState>(() {
  return ReportsFilterNotifier();
});

/// Consolidated payload containing all 4 reports fetched from authoritative backend.
@immutable
class ReportsData {
  final List<MonthlyReportItem> monthlyReport;
  final CategoryReportResponse categoryReport;
  final MemberReportResponse memberReport;
  final PaymentMethodReportResponse paymentMethodReport;
  final ReportsFilterState filters;

  const ReportsData({
    required this.monthlyReport,
    required this.categoryReport,
    required this.memberReport,
    required this.paymentMethodReport,
    required this.filters,
  });

  bool get isEmpty =>
      categoryReport.categories.isEmpty &&
      memberReport.members.isEmpty &&
      paymentMethodReport.paymentMethods.isEmpty &&
      monthlyReport.every((m) => m.income == 0 && m.expense == 0);
}

/// Controller managing reports fetching across all endpoints.
class ReportsController extends AsyncNotifier<ReportsData> {
  @override
  Future<ReportsData> build() async {
    final filters = ref.watch(reportsFilterProvider);
    return _fetchReports(filters);
  }

  Future<ReportsData> _fetchReports(ReportsFilterState filters) async {
    final repo = ref.read(reportRepositoryProvider);

    int? month;
    int? year;
    String? fromDate;
    String? toDate;

    if (filters.filterType == ReportFilterType.customRange) {
      fromDate = filters.fromDate;
      toDate = filters.toDate;
    } else {
      month = filters.month;
      year = filters.year;
    }

    final targetYear = year ?? DateTime.now().year;

    // Fetch in parallel using authoritative FastAPI endpoints
    final monthlyFuture = repo.getMonthlyReport(year: targetYear);
    final categoryFuture = repo.getCategoryReportResponse(
      fromDate: fromDate,
      toDate: toDate,
      month: month,
      year: year,
      type: filters.categoryType,
    );
    final memberFuture = repo.getMemberReportResponse(
      fromDate: fromDate,
      toDate: toDate,
      month: month,
      year: year,
    );
    final paymentFuture = repo.getPaymentMethodReportResponse(
      fromDate: fromDate,
      toDate: toDate,
      month: month,
      year: year,
    );

    final results = await Future.wait([
      monthlyFuture,
      categoryFuture,
      memberFuture,
      paymentFuture,
    ]);

    return ReportsData(
      monthlyReport: results[0] as List<MonthlyReportItem>,
      categoryReport: results[1] as CategoryReportResponse,
      memberReport: results[2] as MemberReportResponse,
      paymentMethodReport: results[3] as PaymentMethodReportResponse,
      filters: filters,
    );
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final filters = ref.read(reportsFilterProvider);
      return _fetchReports(filters);
    });
  }
}

/// Provider for ReportsController.
final reportsControllerProvider =
    AsyncNotifierProvider<ReportsController, ReportsData>(() {
  return ReportsController();
});
