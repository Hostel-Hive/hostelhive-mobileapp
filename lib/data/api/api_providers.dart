import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../repositories/session_store.dart';
import 'api_client.dart';
import 'firebase_auth_service.dart';

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SecureSessionStore();
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService(
    apiKey: ref.watch(appConfigProvider).firebaseApiKey,
    store: ref.watch(sessionStoreProvider),
    client: ref.watch(httpClientProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    client: ref.watch(httpClientProvider),
    tokens: ref.watch(firebaseAuthServiceProvider),
  );
});
