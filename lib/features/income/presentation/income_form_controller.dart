import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../reports/data/report_repository_impl.dart';
import '../data/income_repository_impl.dart';
import '../domain/income.dart';
import 'income_list_controller.dart';

/// State representation for saving/updating/deleting an income entry.
@immutable
class IncomeFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const IncomeFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  IncomeFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return IncomeFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Controller responsible for Creating, Updating, and Deleting Income records.
/// Automatically orchestrates invalidation across Income list, Dashboard, and Reports
/// without reloading the entire application.
class IncomeFormController extends Notifier<IncomeFormState> {
  @override
  IncomeFormState build() => const IncomeFormState();

  IncomeRepository get _repository => ref.read(incomeRepositoryProvider);

  /// Create a new income entry
  Future<Income?> createIncome({
    required double amount,
    required String categoryId,
    required String incomeDate,
    required String receivedBy,
    required String title,
    String? notes,
  }) async {
    state = const IncomeFormState(isLoading: true);

    try {
      final income = await _repository.createIncome(
        title: title,
        amount: amount,
        categoryId: categoryId,
        incomeDate: incomeDate,
        receivedBy: receivedBy,
        description: notes,
      );

      _refreshRelatedData();

      state = const IncomeFormState(isSuccess: true);
      return income;
    } on ApiException catch (e) {
      state = IncomeFormState(errorMessage: e.message);
      return null;
    } catch (e) {
      state = const IncomeFormState(
        errorMessage: 'Failed to record income. Please check your connection and try again.',
      );
      return null;
    }
  }

  /// Update an existing income entry
  Future<Income?> updateIncome(
    String id, {
    required double amount,
    required String categoryId,
    required String incomeDate,
    required String receivedBy,
    required String title,
    String? notes,
  }) async {
    state = const IncomeFormState(isLoading: true);

    try {
      final updated = await _repository.updateIncome(
        id,
        title: title,
        amount: amount,
        categoryId: categoryId,
        incomeDate: incomeDate,
        receivedBy: receivedBy,
        description: notes,
      );

      _refreshRelatedData();

      state = const IncomeFormState(isSuccess: true);
      return updated;
    } on ApiException catch (e) {
      state = IncomeFormState(errorMessage: e.message);
      return null;
    } catch (e) {
      state = const IncomeFormState(
        errorMessage: 'Failed to update income. Please check your connection and try again.',
      );
      return null;
    }
  }

  /// Delete an income entry
  Future<bool> deleteIncome(String id) async {
    state = const IncomeFormState(isLoading: true);
    try {
      await _repository.deleteIncome(id);

      // Invalidate list locally and refresh downstream caches
      ref.read(incomeListControllerProvider.notifier).removeItemLocally(id);
      _refreshRelatedData();

      state = const IncomeFormState(isSuccess: true);
      return true;
    } on ApiException catch (e) {
      state = IncomeFormState(errorMessage: e.message);
      return false;
    } catch (e) {
      state = const IncomeFormState(
        errorMessage: 'Failed to delete income. Please try again.',
      );
      return false;
    }
  }

  /// Refreshes income list, dashboard, and reports without restarting the whole app
  void _refreshRelatedData() {
    ref.invalidate(incomeListControllerProvider);
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(reportRepositoryProvider);
  }

  void reset() {
    state = const IncomeFormState();
  }
}

/// Provider for IncomeFormController
final incomeFormControllerProvider =
    NotifierProvider<IncomeFormController, IncomeFormState>(() {
  return IncomeFormController();
});
