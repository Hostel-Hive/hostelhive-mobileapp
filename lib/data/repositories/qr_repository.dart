import 'dart:typed_data';

import '../api/api_client.dart';

/// Downloads the student's own QR code image (`GET /me/qr`).
class QrRepository {
  QrRepository(this._api);

  final ApiClient _api;

  Future<Uint8List> fetchQr() => _api.getBytes('/me/qr');
}
