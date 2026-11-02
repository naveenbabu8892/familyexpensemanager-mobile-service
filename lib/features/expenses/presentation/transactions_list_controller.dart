import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/expense_repository_impl.dart';
import '../domain/expense.dart';
import '../domain/transaction_item.dart';
import '../../income/data/income_repository_impl.dart';
import '../../income/domain/income.dart';

/// Scope tabs for Transactions screen:
/// - All
/// - Expenses
/// - Income
enum TransactionTab {
  all,
  expenses,
  income,
}

/// Sort fields supported by the backend:
enum TransactionSortField {
  date('date'),
  amount('amount'),
  title('title'),
  createdAt('created_at');

  final String value;
  const TransactionSortField(this.value);
}

/// Sort order:
enum TransactionSortOrder {
  desc('desc'),
  asc('asc');

  final String value;
  const TransactionSortOrder(this.value);
}

/// Comprehensive filter and sorting state for the unified Transactions screen.
@immutable
class TransactionsFilterState {
  final TransactionTab tab;
  final String? search;
  final String? categoryId;
  final String? personId;
  final String? fromDate;
  final String? toDate;
  final String? paymentMethod;
  final bool? isShared;
  final TransactionSortField sortBy;
  final TransactionSortOrder sortOrder;

  const TransactionsFilterState({
    this.tab = TransactionTab.all,
    this.search,
    this.categoryId,
    this.personId,
    this.fromDate,
    this.toDate,
    this.paymentMethod,
    this.isShared,
    this.sortBy = TransactionSortField.date,
    this.sortOrder = TransactionSortOrder.desc,
  });

  TransactionsFilterState copyWith({
    TransactionTab? tab,
    String? Function()? search,
    String? Function()? categoryId,
    String? Function()? personId,
    String? Function()? fromDate,
    String? Function()? toDate,
    String? Function()? paymentMethod,
    bool? Function()? isShared,
    TransactionSortField? sortBy,
    TransactionSortOrder? sortOrder,
  }) {
    return TransactionsFilterState(
      tab: tab ?? this.tab,
      search: search != null ? search() : this.search,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      personId: personId != null ? personId() : this.personId,
      fromDate: fromDate != null ? fromDate() : this.fromDate,
      toDate: toDate != null ? toDate() : this.toDate,
      paymentMethod: paymentMethod != null ? paymentMethod() : this.paymentMethod,
      isShared: isShared != null ? isShared() : this.isShared,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  bool get hasActiveAdvancedFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      categoryId != null ||
      personId != null ||
      fromDate != null ||
      toDate != null ||
      paymentMethod != null ||
      isShared != null ||
      sortBy != TransactionSortField.date ||
      sortOrder != TransactionSortOrder.desc;
}

/// Notifier managing transactions filters and search query.
class TransactionsFilterNotifier extends Notifier<TransactionsFilterState> {
  @override
  TransactionsFilterState build() => const TransactionsFilterState();

  void setTab(TransactionTab tab) {
    state = state.copyWith(tab: tab);
  }

  void setSearch(String? search) {
    state = state.copyWith(search: () => (search == null || search.trim().isEmpty) ? null : search.trim());
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: () => categoryId);
  }

  void setPerson(String? personId) {
    state = state.copyWith(personId: () => personId);
  }

  void setDateRange(String? fromDate, String? toDate) {
    state = state.copyWith(
      fromDate: () => fromDate,
      toDate: () => toDate,
    );
  }

  void setPaymentMethod(String? paymentMethod) {
    state = state.copyWith(paymentMethod: () => paymentMethod);
  }

  void setIsShared(bool? isShared) {
    state = state.copyWith(isShared: () => isShared);
  }

  void setSorting(TransactionSortField sortBy, TransactionSortOrder sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
  }

  void clearFilters() {
    state = TransactionsFilterState(tab: state.tab);
  }
}

/// Riverpod provider for TransactionsFilterState.
final transactionsFilterProvider =
    NotifierProvider<TransactionsFilterNotifier, TransactionsFilterState>(() {
  return TransactionsFilterNotifier();
});

/// Paginated Transactions List state model.
class TransactionsListState {
  final List<TransactionItem> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const TransactionsListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  TransactionsListState copyWith({
    List<TransactionItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TransactionsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// AsyncNotifier managing unified server-side paginated transactions.
class TransactionsListController extends AsyncNotifier<TransactionsListState> {
  static const int _pageSize = 20;

  @override
  Future<TransactionsListState> build() async {
    final filters = ref.watch(transactionsFilterProvider);
    return _fetchPage(1, filters);
  }

  Future<TransactionsListState> _fetchPage(int page, TransactionsFilterState filters) async {
    final expenseRepo = ref.read(expenseRepositoryProvider);
    final incomeRepo = ref.read(incomeRepositoryProvider);

    // Map sort field to backend schema
    final expenseSortBy = switch (filters.sortBy) {
      TransactionSortField.date => 'expense_date',
      TransactionSortField.amount => 'amount',
      TransactionSortField.title => 'title',
      TransactionSortField.createdAt => 'created_at',
    };

    final incomeSortBy = switch (filters.sortBy) {
      TransactionSortField.date => 'income_date',
      TransactionSortField.amount => 'amount',
      TransactionSortField.title => 'title',
      TransactionSortField.createdAt => 'created_at',
    };

    final sortOrder = filters.sortOrder.value;

    List<TransactionItem> pageItems = [];
    bool hasMore = false;

    if (filters.tab == TransactionTab.expenses) {
      // 1. Expenses tab: Query backend /expenses directly
      final expenses = await expenseRepo.getExpenses(
        page: page,
        pageSize: _pageSize,
        categoryId: filters.categoryId,
        fromDate: filters.fromDate,
        toDate: filters.toDate,
        paidBy: filters.personId,
        paymentMethod: filters.paymentMethod,
        isShared: filters.isShared,
        search: filters.search,
        sortBy: expenseSortBy,
        sortOrder: sortOrder,
      );
      pageItems = expenses.map((e) => TransactionItem.fromExpense(e)).toList();
      hasMore = expenses.length >= _pageSize;
    } else if (filters.tab == TransactionTab.income) {
      // 2. Income tab: Query backend /income directly (paymentMethod & isShared ignored)
      if (filters.paymentMethod != null || filters.isShared != null) {
        // Income doesn't have payment method or isShared filters
        pageItems = [];
        hasMore = false;
      } else {
        final incomes = await incomeRepo.getIncomes(
          page: page,
          pageSize: _pageSize,
          categoryId: filters.categoryId,
          fromDate: filters.fromDate,
          toDate: filters.toDate,
          receivedBy: filters.personId,
          search: filters.search,
          sortBy: incomeSortBy,
          sortOrder: sortOrder,
        );
        pageItems = incomes.map((i) => TransactionItem.fromIncome(i)).toList();
        hasMore = incomes.length >= _pageSize;
      }
    } else {
      // 3. All tab: Unified query across both endpoints with per-page limit
      final expenseFuture = expenseRepo.getExpenses(
        page: page,
        pageSize: _pageSize,
        categoryId: filters.categoryId,
        fromDate: filters.fromDate,
        toDate: filters.toDate,
        paidBy: filters.personId,
        paymentMethod: filters.paymentMethod,
        isShared: filters.isShared,
        search: filters.search,
        sortBy: expenseSortBy,
        sortOrder: sortOrder,
      );

      final shouldFetchIncome = filters.paymentMethod == null && filters.isShared == null;
      final incomeFuture = shouldFetchIncome
          ? incomeRepo.getIncomes(
              page: page,
              pageSize: _pageSize,
              categoryId: filters.categoryId,
              fromDate: filters.fromDate,
              toDate: filters.toDate,
              receivedBy: filters.personId,
              search: filters.search,
              sortBy: incomeSortBy,
              sortOrder: sortOrder,
            )
          : Future.value(<Income>[]);

      final results = await Future.wait([expenseFuture, incomeFuture]);
      final expenses = results[0] as List<Expense>;
      final incomes = results[1] as List<Income>;

      final combined = [
        ...expenses.map((e) => TransactionItem.fromExpense(e)),
        ...incomes.map((i) => TransactionItem.fromIncome(i)),
      ];

      // Sort merged page according to selected sorting
      combined.sort((a, b) {
        int cmp = 0;
        switch (filters.sortBy) {
          case TransactionSortField.date:
            cmp = a.date.compareTo(b.date);
            break;
          case TransactionSortField.amount:
            cmp = a.amount.compareTo(b.amount);
            break;
          case TransactionSortField.title:
            cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
            break;
          case TransactionSortField.createdAt:
            final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
            cmp = aTime.compareTo(bTime);
            break;
        }
        return filters.sortOrder == TransactionSortOrder.asc ? cmp : -cmp;
      });

      pageItems = combined;
      hasMore = expenses.length >= _pageSize || incomes.length >= _pageSize;
    }

    return TransactionsListState(
      items: pageItems,
      page: page,
      hasMore: hasMore,
      isLoadingMore: false,
    );
  }

  /// Load next page for infinite scrolling
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final filters = ref.read(transactionsFilterProvider);
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
      debugPrint('Error loading more transactions: $e\n$st');
    }
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final filters = ref.read(transactionsFilterProvider);
      return _fetchPage(1, filters);
    });
  }

  /// Remove item optimistically on delete
  void removeItemLocally(String id) {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          items: current.items.where((t) => t.id != id).toList(),
        ),
      );
    }
  }
}

/// Provider for TransactionsListController
final transactionsListControllerProvider =
    AsyncNotifierProvider<TransactionsListController, TransactionsListState>(() {
  return TransactionsListController();
});
