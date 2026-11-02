import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/storage/preferences_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/pwa_responsive_wrapper.dart';
import 'router.dart';

/// Root Application Widget configuring MaterialApp with GoRouter and Material 3 theme.
class FamilyExpenseManagerApp extends ConsumerWidget {
  const FamilyExpenseManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final preferences = ref.watch(preferencesControllerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: preferences.themeMode,
      routerConfig: router,
      builder: (context, child) {
        return PwaResponsiveWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
