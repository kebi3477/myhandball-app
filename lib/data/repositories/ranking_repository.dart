import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/gender.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_stat.dart';
import '../../domain/models/rank_row.dart';
import '../services/handball_api_service.dart';
import 'schedule_repository.dart' show handballApiServiceProvider;

/// 팀 순위와 선수 기록의 source of truth.
///
/// `/api/ranking`과 `/api/player/ranking`에 대응한다.
class RankingRepository {
  RankingRepository(this._service);

  final HandballApiService _service;

  final _rankingCache = <Gender, List<RankRow>>{};
  final _statCache = <(Gender, StatCategory), List<PlayerStat>>{};

  Future<List<RankRow>> getRanking(Gender gender,
      {bool forceRefresh = false}) async {
    final hit = _rankingCache[gender];
    if (!forceRefresh && hit != null) return hit;
    try {
      final rows = await _service.fetchRanking(gender);
      _rankingCache[gender] = rows;
      return rows;
    } on Exception {
      if (hit != null) return hit;
      rethrow;
    }
  }

  Future<List<PlayerStat>> getTopPlayers(
    Gender gender,
    StatCategory category, {
    bool forceRefresh = false,
  }) async {
    final key = (gender, category);
    final hit = _statCache[key];
    if (!forceRefresh && hit != null) return hit;
    try {
      final rows = await _service.fetchTopPlayers(gender, category);
      _statCache[key] = rows;
      return rows;
    } on Exception {
      if (hit != null) return hit;
      rethrow;
    }
  }
}

/// 선수 명단. 순위와 성격이 달라 저장소를 나눈다.
class PlayerRepository {
  PlayerRepository(this._service);

  final HandballApiService _service;

  final _cache = <Gender, List<Player>>{};

  Future<List<Player>> getPlayers(Gender gender,
      {bool forceRefresh = false}) async {
    final hit = _cache[gender];
    if (!forceRefresh && hit != null) return hit;
    try {
      final players = await _service.fetchPlayers(gender);
      _cache[gender] = players;
      return players;
    } on Exception {
      if (hit != null) return hit;
      rethrow;
    }
  }
}

final playerRepositoryProvider = Provider<PlayerRepository>(
  (ref) => PlayerRepository(ref.watch(handballApiServiceProvider)),
);

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => RankingRepository(ref.watch(handballApiServiceProvider)),
);
