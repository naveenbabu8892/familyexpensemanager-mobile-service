import 'package:intl/intl.dart';

/// Formatter for dates and ISO-8601 timestamps.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _shortMonthFormat = DateFormat('MMM');

  /// Example: 'Oct 05, 2026'
  static String formatDisplay(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _displayFormat.format(dateTime);
  }

  /// Example: 'October 2026'
  static String formatMonthYear(int month, int year) {
    final dt = DateTime(year, month);
    return _monthYearFormat.format(dt);
  }

  /// Example: '2026-10-05'
  static String toIsoDate(DateTime dateTime) {
    return _isoDateFormat.format(dateTime);
  }

  /// Parse backend date string (e.g. '2026-10-05') into DateTime
  static DateTime? parseIsoDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Example: 'Oct'
  static String getMonthShort(int month) {
    final dt = DateTime(2026, month);
    return _shortMonthFormat.format(dt);
  }
}
