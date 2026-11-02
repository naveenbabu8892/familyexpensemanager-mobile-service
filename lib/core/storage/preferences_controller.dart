import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported currencies
enum AppCurrency {
  inr('INR', 'Indian Rupee', '₹'),
  usd('USD', 'US Dollar', '\$'),
  eur('EUR', 'Euro', '€'),
  gbp('GBP', 'British Pound', '£');

  final String code;
  final String label;
  final String symbol;

  const AppCurrency(this.code, this.label, this.symbol);

  static AppCurrency fromCode(String code) {
    return AppCurrency.values.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => AppCurrency.inr,
    );
  }
}

/// Preferences state model
@immutable
class AppPreferencesState {
  final AppCurrency currency;
  final bool notificationsEnabled;
  final ThemeMode themeMode;

  const AppPreferencesState({
    this.currency = AppCurrency.inr,
    this.notificationsEnabled = true,
    this.themeMode = ThemeMode.system,
  });

  AppPreferencesState copyWith({
    AppCurrency? currency,
    bool? notificationsEnabled,
    ThemeMode? themeMode,
  }) {
    return AppPreferencesState(
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Preferences controller managing Currency, Notifications, and Theme.
class PreferencesController extends Notifier<AppPreferencesState> {
  static const String _keyCurrency = 'fem_pref_currency';
  static const String _keyNotifications = 'fem_pref_notifications';
  static const String _keyThemeMode = 'fem_pref_theme_mode';

  @override
  AppPreferencesState build() {
    _loadPreferences();
    return const AppPreferencesState();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyCode = prefs.getString(_keyCurrency) ?? 'INR';
      final notifications = prefs.getBool(_keyNotifications) ?? true;
      final themeStr = prefs.getString(_keyThemeMode) ?? 'system';

      ThemeMode themeMode = ThemeMode.system;
      if (themeStr == 'light') themeMode = ThemeMode.light;
      if (themeStr == 'dark') themeMode = ThemeMode.dark;

      state = AppPreferencesState(
        currency: AppCurrency.fromCode(currencyCode),
        notificationsEnabled: notifications,
        themeMode: themeMode,
      );
    } catch (_) {
      // Use defaults if SharedPreferences fails or is in test mode
    }
  }

  Future<void> setCurrency(AppCurrency currency) async {
    state = state.copyWith(currency: currency);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrency, currency.code);
    } catch (_) {}
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotifications, enabled);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'system';
      if (mode == ThemeMode.light) val = 'light';
      if (mode == ThemeMode.dark) val = 'dark';
      await prefs.setString(_keyThemeMode, val);
    } catch (_) {}
  }
}

/// Provider for app preferences
final preferencesControllerProvider =
    NotifierProvider<PreferencesController, AppPreferencesState>(() {
  return PreferencesController();
});
