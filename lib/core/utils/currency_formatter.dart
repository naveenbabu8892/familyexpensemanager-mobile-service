import 'package:intl/intl.dart';

/// Formatter for monetary amounts and currency representation.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats amount into standard currency display.
  /// Example: format(1234.5, currency: 'USD') -> '$1,234.50'
  static String format(
    dynamic amount, {
    String currency = 'USD',
    String? locale,
  }) {
    if (amount == null) return '0.00';
    final numericAmount = _parseToDouble(amount);

    final symbol = _resolveSymbol(currency);
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 2,
    );

    return formatter.format(numericAmount);
  }

  /// Formats amount without decimal places when amount is a whole number or as requested.
  /// Example: formatNoDecimals(35000, currency: 'INR') -> '₹35,000'
  static String formatNoDecimals(
    dynamic amount, {
      String currency = 'INR',
      String? locale,
  }) {
    if (amount == null) return '0';
    final numericAmount = _parseToDouble(amount);
    final symbol = _resolveSymbol(currency);
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(numericAmount);
  }

  /// Compact format for dashboard cards.
  /// Example: 12500 -> '$12.5K'
  static String formatCompact(
    dynamic amount, {
    String currency = 'USD',
  }) {
    if (amount == null) return '0';
    final numericAmount = _parseToDouble(amount);
    final symbol = _resolveSymbol(currency);

    final formatter = NumberFormat.compact();
    return '$symbol${formatter.format(numericAmount)}';
  }

  static double _parseToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _resolveSymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      default:
        return '$currency ';
    }
  }
}
