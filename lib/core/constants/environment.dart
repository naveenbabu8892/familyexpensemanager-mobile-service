/// Deployment environments supported by the application.
enum AppEnvironment {
  development,
  staging,
  production,
}

/// Central environment configuration for API endpoints and timeouts.
/// Does not hardcode URLs in UI or repositories.
class EnvironmentConfig {
  final AppEnvironment environment;
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  const EnvironmentConfig({
    required this.environment,
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
  });

  /// Factory resolving current environment from `--dart-define=ENVIRONMENT=...`
  /// Defaults to [AppEnvironment.development] for local Android emulator testing.
  factory EnvironmentConfig.fromDartDefines() {
    const envString = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    final env = AppEnvironment.values.firstWhere(
      (e) => e.name.toLowerCase() == envString.toLowerCase(),
      orElse: () => AppEnvironment.development,
    );

    // Allow overriding BASE_URL directly via --dart-define=BASE_URL=...
    const customBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: '');
    if (customBaseUrl.isNotEmpty) {
      return EnvironmentConfig(
        environment: env,
        baseUrl: customBaseUrl,
      );
    }

    switch (env) {
      case AppEnvironment.development:
        return const EnvironmentConfig(
          environment: AppEnvironment.development,
          // 10.0.2.2 maps to host localhost from the Android emulator
          baseUrl: 'https://familyexpensemanager-backend-service.onrender.com/api/v1',
        );
      case AppEnvironment.staging:
        return const EnvironmentConfig(
          environment: AppEnvironment.staging,
          baseUrl: 'https://familyexpensemanager-backend-service.onrender.com/api/v1',
        );
      case AppEnvironment.production:
        return const EnvironmentConfig(
          environment: AppEnvironment.production,
          baseUrl: 'https://familyexpensemanager-backend-service.onrender.com/api/v1',
        );
    }
  }

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;
}
