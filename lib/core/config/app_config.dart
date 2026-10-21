import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time settings, passed with `--dart-define`:
///
///     flutter run \
///       --dart-define=API_BASE_URL=https://example.invalid/api/v1 \
///       --dart-define=FIREBASE_API_KEY=your-web-api-key
///
/// Without them the app runs on the built-in demo data.
class AppConfig {
  const AppConfig({this.apiBaseUrl = '', this.firebaseApiKey = ''});

  factory AppConfig.fromEnvironment() => const AppConfig(
    apiBaseUrl: String.fromEnvironment('API_BASE_URL'),
    firebaseApiKey: String.fromEnvironment('FIREBASE_API_KEY'),
  );

  final String apiBaseUrl;
  final String firebaseApiKey;

  /// True when both the backend address and the sign-in key are set.
  bool get useBackend => apiBaseUrl.isNotEmpty && firebaseApiKey.isNotEmpty;
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
