import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/budget_repository_impl.dart';
import '../domain/budget.dart';

/// Month-Year selection state for Budgets screen.
@immutable
class BudgetPeriodState {
  final int month;
  final int year;

  const BudgetPeriodState({
    required this.month,
    required this.year,
  });

  BudgetPeriodState copyWith({int? month, int? year}) {
    return BudgetPeriodState(
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  BudgetPeriodState previousMonth() {
    if (month == 1) {
      return BudgetPeriodState(month: 12, year: year - 1);
    }
    return BudgetPeriodState(month: month - 1, year: year);
  }

  BudgetPeriodState nextMonth() {
    if (month == 12) {
      return BudgetPeriodState(month: 1, year: year + 1);
    }
    return BudgetPeriodState(month: month + 1, year: year);
  }
}

/// Notifier managing selected month and year for budget display.
class BudgetPeriodNotifier extends Notifier<BudgetPeriodState> {
  final int? initialMonth;
  final int? initialYear;

  BudgetPeriodNotifier({this.initialMonth, this.initialYear});

  @override
  BudgetPeriodState build() {
    final now = DateTime.now();
    return BudgetPeriodState(
      month: initialMonth ?? now.month,
      year: initialYear ?? now.year,
    );
  }

  void setPeriod(int month, int year) {
    state = BudgetPeriodState(month: month, year: year);
  }

  void previous() {
    state = state.previousMonth();
  }

  void next() {
    state = state.nextMonth();
  }
}

/// Provider for BudgetPeriodState.
final budgetPeriodProvider =
    NotifierProvider<BudgetPeriodNotifier, BudgetPeriodState>(() {
  return BudgetPeriodNotifier();
});

/// AsyncNotifier managing list of budgets for the currently selected period.
class BudgetListController extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    final period = ref.watch(budgetPeriodProvider);
    return _fetchBudgets(period.month, period.year);
  }

  Future<List<Budget>> _fetchBudgets(int month, int year) async {
    final repository = ref.read(budgetRepositoryProvider);
    return repository.getBudgets(month: month, year: year);
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final period = ref.read(budgetPeriodProvider);
      return _fetchBudgets(period.month, period.year);
    });
  }

  /// Delete budget with server call and local state update
  Future<bool> deleteBudget(String id) async {
    try {
      final repository = ref.read(budgetRepositoryProvider);
      await repository.deleteBudget(id);
      
      final currentList = state.value ?? [];
      state = AsyncValue.data(currentList.where((b) => b.id != id).toList());
      
      // Also invalidate currentBudgetsProvider to refresh dashboard summaries
      ref.invalidate(currentBudgetsProvider);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for BudgetListController.
final budgetListControllerProvider =
    AsyncNotifierProvider<BudgetListController, List<Budget>>(() {
  return BudgetListController();
});
