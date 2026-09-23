import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/game.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/schedule_day.dart';
import '../services/handball_api_service.dart';
import '../services/mock_handball_api_service.dart';

final handballApiServiceProvider = Provider<HandballApiService>(
  (_) => const MockHandballApiService(),
);

/// 경기 일정의 source of truth.
///
/// 마지막 성공 응답을 들고 있다가, 이후 요청이 실패하면 그걸 돌려준다.
/// 서버가 죽어도 홈 화면이 비지 않게 하려는 것 — 자체 호스팅 서버가
/// 내려간 전력이 있어서 이 동작이 필요하다 (`CLAUDE.md` 서버 상태 참조).
class ScheduleRepository {
  ScheduleRepository(this._service);

  final HandballApiService _service;

  List<Game>? _cached;

  /// 마지막으로 성공한 응답. 화면이 "오프라인 표시"를 띄울 때 쓴다.
  List<Game>? get cached => _cached;

  final _monthCache = <String, List<ScheduleDay>>{};

  /// 월 단위 일정. 같은 (부, 연월)은 세션 동안 다시 받지 않는다.
  Future<List<ScheduleDay>> getMonthlySchedule(
    Gender gender,
    DateTime month, {
    bool forceRefresh = false,
  }) async {
    final key = '${gender.code}-${month.year}-${month.month}';
    final hit = _monthCache[key];
    if (!forceRefresh && hit != null) return hit;
    try {
      final days = await _service.fetchMonthlySchedule(gender, month);
      _monthCache[key] = days;
      return days;
    } on Exception {
      if (hit != null) return hit;
      rethrow;
    }
  }

  Future<List<Game>> getUpcomingGames({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;
    try {
      final games = await _service.fetchUpcomingGames();
      _cached = games;
      return games;
    } on Exception {
      if (_cached != null) return _cached!;
      rethrow;
    }
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(ref.watch(handballApiServiceProvider)),
);
