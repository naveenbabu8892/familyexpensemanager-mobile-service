import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../budgets/data/budget_repository_impl.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../data/expense_repository_impl.dart';
import '../domain/expense.dart';

/// Filter tab options for the expense list:
/// - All
/// - Shared
/// - My Expenses
/// - Spouse Expenses
enum ExpenseFilterTab {
  all,
  shared,
  myExpenses,
  spouseExpenses,
}

/// Filter state parameters for querying expenses.
@immutable
class ExpenseFilterState {
  final ExpenseFilterTab tab;
  final String? categoryId;
  final String? fromDate;
  final String? toDate;
  final String? paidBy;
  final String? paymentMethod;
  final String? search;

  const ExpenseFilterState({
    this.tab = ExpenseFilterTab.all,
    this.categoryId,
    this.fromDate,
    this.toDate,
    this.paidBy,
    this.paymentMethod,
    this.search,
  });

  ExpenseFilterState copyWith({
    ExpenseFilterTab? tab,
    String? Function()? categoryId,
    String? Function()? fromDate,
    String? Function()? toDate,
    String? Function()? paidBy,
    String? Function()? paymentMethod,
    String? Function()? search,
  }) {
    return ExpenseFilterState(
      tab: tab ?? this.tab,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      fromDate: fromDate != null ? fromDate() : this.fromDate,
      toDate: toDate != null ? toDate() : this.toDate,
      paidBy: paidBy != null ? paidBy() : this.paidBy,
      paymentMethod: paymentMethod != null ? paymentMethod() : this.paymentMethod,
      search: search != null ? search() : this.search,
    );
  }

  bool get hasActiveAdvancedFilters =>
      categoryId != null ||
      fromDate != null ||
      toDate != null ||
      paidBy != null ||
      paymentMethod != null;
}

/// Notifier for ExpenseFilterState
class ExpenseFilterNotifier extends Notifier<ExpenseFilterState> {
  @override
  ExpenseFilterState build() => const ExpenseFilterState();

  void setTab(ExpenseFilterTab tab) {
    state = state.copyWith(tab: tab);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: () => categoryId);
  }

  void setDateRange(String? fromDate, String? toDate) {
    state = state.copyWith(
      fromDate: () => fromDate,
      toDate: () => toDate,
    );
  }

  void setPaidBy(String? paidBy) {
    state = state.copyWith(paidBy: () => paidBy);
  }

  void setPaymentMethod(String? paymentMethod) {
    state = state.copyWith(paymentMethod: () => paymentMethod);
  }

  void setSearch(String? search) {
    state = state.copyWith(search: () => search);
  }

  void clearFilters() {
    state = ExpenseFilterState(tab: state.tab);
  }
}

/// Provider for expense filter state
final expenseFilterProvider =
    NotifierProvider<ExpenseFilterNotifier, ExpenseFilterState>(() {
  return ExpenseFilterNotifier();
});

/// Paginated Expense List state model
class ExpenseListState {
  final List<Expense> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const ExpenseListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  ExpenseListState copyWith({
    List<Expense>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ExpenseListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// AsyncNotifier managing expense list fetching, tab switching, and infinite scroll pagination.
class ExpenseListController extends AsyncNotifier<ExpenseListState> {
  static const int _pageSize = 20;

  @override
  Future<ExpenseListState> build() async {
    final filters = ref.watch(expenseFilterProvider);
    return _fetchPage(1, filters);
  }

  Future<ExpenseListState> _fetchPage(int page, ExpenseFilterState filters) async {
    final repo = ref.read(expenseRepositoryProvider);
    final authState = ref.read(authStateProvider);
    final currentUserId = authState.user?.id;

    bool? isShared;
    String? paidBy = filters.paidBy;

    switch (filters.tab) {
      case ExpenseFilterTab.all:
        isShared = null;
        break;
      case ExpenseFilterTab.shared:
        isShared = true;
        break;
      case ExpenseFilterTab.myExpenses:
        if (currentUserId != null) {
          paidBy = currentUserId;
        }
        break;
      case ExpenseFilterTab.spouseExpenses:
        // When viewing spouse expenses, if user is not the payer
        break;
    }

    final items = await repo.getExpenses(
      page: page,
      pageSize: _pageSize,
      categoryId: filters.categoryId,
      fromDate: filters.fromDate,
      toDate: filters.toDate,
      paidBy: paidBy,
      paymentMethod: filters.paymentMethod,
      search: filters.search,
      isShared: isShared,
    );

    // Filter in-memory for spouseExpenses tab if paidBy filter wasn't set directly
    List<Expense> filteredItems = items;
    if (filters.tab == ExpenseFilterTab.spouseExpenses && currentUserId != null) {
      filteredItems = items.where((e) => e.paidBy != currentUserId).toList();
    }

    return ExpenseListState(
      items: filteredItems,
      page: page,
      hasMore: items.length >= _pageSize,
      isLoadingMore: false,
    );
  }

  /// Load next page for infinite scrolling
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final filters = ref.read(expenseFilterProvider);
      final nextPage = current.page + 1;
      final nextPageData = await _fetchPage(nextPage, filters);

      state = AsyncValue.data(
        current.copyWith(
          items: [...current.items, ...nextPageData.items],
          page: nextPage,
          hasMore: nextPageData.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      // Retain existing items but reset loading more flag
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
      debugPrint('Error loading more expenses: $e\n$st');
    }
  }

  /// Pull-to-refresh or explicit refresh
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final filters = ref.read(expenseFilterProvider);
      return _fetchPage(1, filters);
    });
  }

  /// Delete an expense item, remove it optimistically/locally, and trigger dashboard & budget refresh
  Future<bool> deleteExpense(String expenseId) async {
    final repo = ref.read(expenseRepositoryProvider);
    try {
      await repo.deleteExpense(expenseId);

      // Invalidate dashboard and budget caches without reloading the app
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(currentBudgetsProvider);

      final current = state.value;
      if (current != null) {
        state = AsyncValue.data(
          current.copyWith(
            items: current.items.where((e) => e.id != expenseId).toList(),
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      return false;
    }
  }
}

/// Riverpod provider for ExpenseListController
final expenseListControllerProvider =
    AsyncNotifierProvider<ExpenseListController, ExpenseListState>(() {
  return ExpenseListController();
});
