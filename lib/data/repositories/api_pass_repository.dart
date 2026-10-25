import '../../core/utils/uuid.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/pass.dart';
import 'pass_repository.dart';

/// Leave, late-access and going-home calls on the backend. Leave and late
/// access are separate records there, so detail and cancel try one and then
/// the other.
class ApiPassRepository implements PassRepository {
  ApiPassRepository(this._api);

  static const _pageSize = 100;
  static const _maxPages = 10;

  final ApiClient _api;

  @override
  Future<List<Pass>> fetchPasses() async {
    final passes = <Pass>[];
    for (var page = 0; page < _maxPages; page++) {
      final body = await _api.getJson(
        '/me/passes',
        query: {'limit': '$_pageSize', 'offset': '${page * _pageSize}'},
      ) as Map<String, dynamic>;
      final items = body['items'] as List<dynamic>;
      passes.addAll(
        items.map((item) => Pass.fromBackendJson(item as Map<String, dynamic>)),
      );
      if (body['has_more'] != true || items.isEmpty) break;
    }
    return passes;
  }

  @override
  Future<Pass> fetchPass(String id) async {
    return Pass.fromBackendJson(
      await _tryBoth((base) => _api.getJson('$base/$id'))
          as Map<String, dynamic>,
    );
  }

  @override
  Future<PassQuota> fetchQuota() async {
    final body =
        await _api.getJson('/me/leave-allowance') as Map<String, dynamic>;
    return PassQuota(
      usedDays: (body['used_days'] as num).toInt(),
      totalDays: (body['total_days'] as num).toInt(),
    );
  }

  @override
  Future<Pass> requestLeave({
    required DateTime startsAt,
    required DateTime endsAt,
    required String reason,
    String? requestId,
  }) async {
    final body = await _api.postJson(
      '/leaves',
      body: {
        'request_id': requestId ?? newUuid(),
        'starts_at': toRfc3339(startsAt),
        'ends_at': toRfc3339(endsAt),
        'reason': reason.trim(),
      },
    ) as Map<String, dynamic>;
    return Pass.fromBackendJson(body);
  }

  @override
  Future<Pass> requestLateAccess({
    required LateDirection direction,
    required DateTime expectedAt,
    required String reason,
    String? requestId,
  }) async {
    final body = await _api.postJson(
      '/late-access-requests',
      body: {
        'request_id': requestId ?? newUuid(),
        'direction': direction.code,
        'expected_at': toRfc3339(expectedAt),
        'reason': reason.trim(),
      },
    ) as Map<String, dynamic>;
    return Pass.fromBackendJson(body);
  }

  @override
  Future<Pass> recordGoingHome({String? requestId}) async {
    final body = await _api.postJson(
      '/going-home',
      body: {'request_id': requestId ?? newUuid()},
    ) as Map<String, dynamic>;
    final declaredAt = DateTime.parse(body['declared_at'] as String).toLocal();
    return Pass(
      id: body['going_home_id'] as String,
      type: PassType.goingHome,
      status: PassStatus.approved,
      title: 'Going home',
      departureAt: declaredAt,
      submittedAt: declaredAt,
    );
  }

  @override
  Future<void> cancelPass(String passId) async {
    // The ordinary leave workflow is retired: /leaves/{id}/cancel always
    // answers 410 rather than 404, so it cannot be used to detect "not a
    // leave" here. Only late-access requests can still be cancelled.
    await _api.postJson('/late-access-requests/$passId/cancel');
  }

  /// Runs [call] against `/leaves`, and against `/late-access-requests` when
  /// the id is not a leave.
  Future<dynamic> _tryBoth(Future<dynamic> Function(String base) call) async {
    try {
      return await call('/leaves');
    } on ApiException catch (e) {
      if (!e.isNotFound) rethrow;
      return call('/late-access-requests');
    }
  }
}
