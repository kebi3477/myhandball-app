import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/gender.dart';
import '../../domain/models/team.dart';
import '../services/handball_api_service.dart';
import 'schedule_repository.dart' show handballApiServiceProvider;

/// 팀 목록의 source of truth. `/api/team`에 대응한다.
///
/// 기존 API가 팀 목록을 Redis에 24시간 캐시하므로, 클라이언트도 세션 동안은
/// 다시 받을 이유가 없다.
class TeamRepository {
  TeamRepository(this._service);

  final HandballApiService _service;

  final _cache = <Gender, List<Team>>{};

  Future<List<Team>> getTeams(Gender gender,
      {bool forceRefresh = false}) async {
    final hit = _cache[gender];
    if (!forceRefresh && hit != null) return hit;
    try {
      final teams = await _service.fetchTeams(gender);
      _cache[gender] = teams;
      return teams;
    } on Exception {
      if (hit != null) return hit;
      rethrow;
    }
  }
}

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(ref.watch(handballApiServiceProvider)),
);
