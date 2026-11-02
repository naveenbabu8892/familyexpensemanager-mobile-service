import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../data/budget_repository_impl.dart';
import '../domain/budget.dart';
import 'budget_list_controller.dart';

/// Form submission state for adding or editing budgets.
@immutable
class BudgetFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const BudgetFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  BudgetFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return BudgetFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Controller managing Budget creation and editing.
class BudgetFormController extends Notifier<BudgetFormState> {
  @override
  BudgetFormState build() => const BudgetFormState();

  BudgetRepository get _repository => ref.read(budgetRepositoryProvider);

  /// Create a new monthly budget
  Future<Budget?> createBudget({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    state = const BudgetFormState(isLoading: true);

    try {
      final budget = await _repository.createBudget(
        categoryId: categoryId,
        amount: amount,
        month: month,
        year: year,
      );

      _refreshRelatedData();
      state = const BudgetFormState(isSuccess: true);
      return budget;
    } on ApiException catch (e) {
      state = BudgetFormState(errorMessage: e.message);
      return null;
    } catch (e) {
      state = const BudgetFormState(
        errorMessage: 'Failed to create budget. Please try again.',
      );
      return null;
    }
  }

  /// Update an existing budget
  Future<Budget?> updateBudget(
    String id, {
    required double amount,
    int? month,
    int? year,
    String? categoryId,
  }) async {
    state = const BudgetFormState(isLoading: true);

    try {
      final updated = await _repository.updateBudget(
        id,
        amount: amount,
        month: month,
        year: year,
        categoryId: categoryId,
      );

      _refreshRelatedData();
      state = const BudgetFormState(isSuccess: true);
      return updated;
    } on ApiException catch (e) {
      state = BudgetFormState(errorMessage: e.message);
      return null;
    } catch (e) {
      state = const BudgetFormState(
        errorMessage: 'Failed to update budget. Please try again.',
      );
      return null;
    }
  }

  /// Invalidate related data so dashboard & budget lists stay in sync
  void _refreshRelatedData() {
    ref.invalidate(budgetListControllerProvider);
    ref.invalidate(currentBudgetsProvider);
    ref.invalidate(dashboardControllerProvider);
  }

  void reset() {
    state = const BudgetFormState();
  }
}

/// Provider for BudgetFormController.
final budgetFormControllerProvider =
    NotifierProvider<BudgetFormController, BudgetFormState>(() {
  return BudgetFormController();
});
