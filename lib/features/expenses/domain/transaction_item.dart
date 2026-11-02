import 'package:flutter/foundation.dart';
import 'expense.dart';
import '../../income/domain/income.dart';

enum TransactionType {
  expense,
  income,
}

/// Unified display entity for the All / Expenses / Income Transactions screen.
@immutable
class TransactionItem {
  final String id;
  final TransactionType type;
  final String title;
  final double amount;
  final String currency;
  final String date; // YYYY-MM-DD
  final String? categoryId;
  final String? categoryName;
  final String? personId;
  final String? personName;
  final String? paymentMethod;
  final bool? isShared;
  final String? notes;
  final DateTime? createdAt;
  final dynamic rawEntity;

  const TransactionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    this.currency = 'INR',
    required this.date,
    this.categoryId,
    this.categoryName,
    this.personId,
    this.personName,
    this.paymentMethod,
    this.isShared,
    this.notes,
    this.createdAt,
    this.rawEntity,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  factory TransactionItem.fromExpense(Expense e) {
    return TransactionItem(
      id: e.id,
      type: TransactionType.expense,
      title: e.title,
      amount: e.amount,
      currency: e.currency,
      date: e.expenseDate,
      categoryId: e.categoryId,
      categoryName: e.categoryName,
      personId: e.paidBy,
      personName: e.paidByName,
      paymentMethod: e.paymentMethod,
      isShared: e.isShared,
      notes: e.description,
      createdAt: e.createdAt,
      rawEntity: e,
    );
  }

  factory TransactionItem.fromIncome(Income i) {
    return TransactionItem(
      id: i.id,
      type: TransactionType.income,
      title: i.title,
      amount: i.amount,
      currency: i.currency,
      date: i.incomeDate,
      categoryId: i.categoryId,
      categoryName: i.categoryName,
      personId: i.receivedBy ?? i.userId,
      personName: i.receivedByName,
      paymentMethod: null,
      isShared: null,
      notes: i.description,
      createdAt: i.createdAt,
      rawEntity: i,
    );
  }
}
