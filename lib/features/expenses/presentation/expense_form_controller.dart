import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../budgets/data/budget_repository_impl.dart';
import '../../budgets/presentation/budget_list_controller.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../data/expense_repository_impl.dart';
import '../domain/expense.dart';
import 'expense_list_controller.dart';

/// State representation for saving/updating an expense.
@immutable
class ExpenseFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const ExpenseFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  ExpenseFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ExpenseFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Controller responsible for Creating, Updating, and Deleting Expenses.
/// Orchestrates cross-feature invalidation (dashboard, budgets, list) without reloading the whole application.
class ExpenseFormController extends Notifier<ExpenseFormState> {
  @override
  ExpenseFormState build() => const ExpenseFormState();

  ExpenseRepository get _repository => ref.read(expenseRepositoryProvider);

  /// Create a new expense with validation
  Future<Expense?> createExpense({
    required double amount,
    required String categoryId,
    required String expenseDate,
    required String paidBy,
    required String paymentMethod,
    required String title,
    String? notes,
    required bool isShared,
  }) async {
    state = const ExpenseFormState(isLoading: true);

    try {
      final expense = await _repository.createExpense(
        title: title,
        amount: amount,
        categoryId: categoryId,
        expenseDate: expenseDate,
        paymentMethod: paymentMethod,
        description: notes,
        paidBy: paidBy,
        isShared: isShared,
      );

      _refreshRelatedData();

      state = const ExpenseFormState(isSuccess: true);
      return expense;
    } on ApiException catch (e) {
      state = ExpenseFormState(errorMessage: e.message);
      return null;
    } catch (e) {
      state = const ExpenseFormState(
        errorMessage: 'Failed to record expense. Please try again.',
      );
      return null;
    }
  }

  /// Update an existing expense
  Future<Expense?> updateExpense(
    String id, {
    required double amount,
    required String categoryId,
    required String expenseDate,
    required String paidBy,
    required String paymentMethod,
    required String title,
    String? notes,
    required bool isShared,
  }) async {
    state = const ExpenseFormState(isLoading: true);

    try {
      final updated = await _repository.updateExpense(
        id,
        title: title,
        amount: amount,
        categoryId: categoryId,
        expenseDate: expenseDate,
        paymentMethod: paymentMethod,
        description: notes,
        paidBy: paidBy,
        isShared: isShared,
      );

      _refreshRelatedData();

      state = const ExpenseFormState(isSuccess: true);
      return updated;
    } on ApiException catch (e) {
      state = ExpenseFormState(errorMessage: e.message);
      return null;
    } catch (e) {
      state = const ExpenseFormState(
        errorMessage: 'Failed to update expense. Please try again.',
      );
      return null;
    }
  }

  /// Delete an expense
  Future<bool> deleteExpense(String id) async {
    state = const ExpenseFormState(isLoading: true);
    try {
      await _repository.deleteExpense(id);
      _refreshRelatedData();
      state = const ExpenseFormState(isSuccess: true);
      return true;
    } catch (e) {
      state = const ExpenseFormState(
        errorMessage: 'Failed to delete expense. Please try again.',
      );
      return false;
    }
  }

  /// Invalidates related providers to refresh without restarting the app
  void _refreshRelatedData() {
    ref.invalidate(expenseListControllerProvider);
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(currentBudgetsProvider);
    ref.invalidate(budgetListControllerProvider);
    ref.invalidate(recentExpensesProvider);
  }

  void reset() {
    state = const ExpenseFormState();
  }
}

/// Provider for ExpenseFormController
final expenseFormControllerProvider =
    NotifierProvider<ExpenseFormController, ExpenseFormState>(() {
  return ExpenseFormController();
});
