import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/api/api_providers.dart';
import '../../../data/repositories/qr_repository.dart';

final qrRepositoryProvider = Provider<QrRepository>((ref) {
  return QrRepository(ref.watch(apiClientProvider));
});

/// The backend QR image, or null when the demo data is used. Dropped when the
/// screen closes so another student never sees it.
final qrImageProvider = FutureProvider.autoDispose<Uint8List?>((ref) async {
  if (!ref.watch(appConfigProvider).useBackend) return null;
  return ref.watch(qrRepositoryProvider).fetchQr();
});
