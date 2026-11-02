import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/income_repository_impl.dart';
import '../domain/income.dart';

/// Scope filter tabs for Income list:
/// - All
/// - My Income
/// - Spouse Income
enum IncomeFilterTab {
  all,
  myIncome,
  spouseIncome,
}

/// Filter state parameters for querying income.
@immutable
class IncomeFilterState {
  final IncomeFilterTab tab;
  final String? categoryId;
  final String? fromDate;
  final String? toDate;
  final String? receivedBy;
  final String? search;

  const IncomeFilterState({
    this.tab = IncomeFilterTab.all,
    this.categoryId,
    this.fromDate,
    this.toDate,
    this.receivedBy,
    this.search,
  });

  IncomeFilterState copyWith({
    IncomeFilterTab? tab,
    String? Function()? categoryId,
    String? Function()? fromDate,
    String? Function()? toDate,
    String? Function()? receivedBy,
    String? Function()? search,
  }) {
    return IncomeFilterState(
      tab: tab ?? this.tab,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      fromDate: fromDate != null ? fromDate() : this.fromDate,
      toDate: toDate != null ? toDate() : this.toDate,
      receivedBy: receivedBy != null ? receivedBy() : this.receivedBy,
      search: search != null ? search() : this.search,
    );
  }

  bool get hasActiveAdvancedFilters =>
      categoryId != null ||
      fromDate != null ||
      toDate != null ||
      receivedBy != null;
}

/// Notifier managing income filters.
class IncomeFilterNotifier extends Notifier<IncomeFilterState> {
  @override
  IncomeFilterState build() => const IncomeFilterState();

  void setTab(IncomeFilterTab tab) {
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

  void setReceivedBy(String? receivedBy) {
    state = state.copyWith(receivedBy: () => receivedBy);
  }

  void setSearch(String? search) {
    state = state.copyWith(search: () => search);
  }

  void clearFilters() {
    state = IncomeFilterState(tab: state.tab);
  }
}

/// Provider for income filter state.
final incomeFilterProvider =
    NotifierProvider<IncomeFilterNotifier, IncomeFilterState>(() {
  return IncomeFilterNotifier();
});

/// Paginated Income List state model.
class IncomeListState {
  final List<Income> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const IncomeListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  IncomeListState copyWith({
    List<Income>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return IncomeListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// AsyncNotifier managing income list pagination, tab switching, and infinite scrolling.
class IncomeListController extends AsyncNotifier<IncomeListState> {
  static const int _pageSize = 20;

  @override
  Future<IncomeListState> build() async {
    final filters = ref.watch(incomeFilterProvider);
    return _fetchPage(1, filters);
  }

  Future<IncomeListState> _fetchPage(int page, IncomeFilterState filters) async {
    final repo = ref.read(incomeRepositoryProvider);
    final authState = ref.read(authStateProvider);
    final currentUserId = authState.user?.id;

    String? receivedBy = filters.receivedBy;

    switch (filters.tab) {
      case IncomeFilterTab.all:
        break;
      case IncomeFilterTab.myIncome:
        if (currentUserId != null) {
          receivedBy = currentUserId;
        }
        break;
      case IncomeFilterTab.spouseIncome:
        // Will be filtered in-memory below if not explicitly selected
        break;
    }

    final items = await repo.getIncomes(
      page: page,
      pageSize: _pageSize,
      categoryId: filters.categoryId,
      fromDate: filters.fromDate,
      toDate: filters.toDate,
      receivedBy: receivedBy,
      search: filters.search,
    );

    List<Income> filteredItems = items;
    if (filters.tab == IncomeFilterTab.spouseIncome && currentUserId != null) {
      filteredItems = items.where((e) => e.receivedBy != currentUserId && e.userId != currentUserId).toList();
    }

    return IncomeListState(
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
      final filters = ref.read(incomeFilterProvider);
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
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
      debugPrint('Error loading more income: $e\n$st');
    }
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final filters = ref.read(incomeFilterProvider);
      return _fetchPage(1, filters);
    });
  }

  /// Optimistically remove item from list on delete
  void removeItemLocally(String id) {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          items: current.items.where((e) => e.id != id).toList(),
        ),
      );
    }
  }
}

/// Provider for IncomeListController
final incomeListControllerProvider =
    AsyncNotifierProvider<IncomeListController, IncomeListState>(() {
  return IncomeListController();
});
