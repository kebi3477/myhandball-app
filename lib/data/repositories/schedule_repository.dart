import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../domain/models/game.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/schedule_day.dart';
import '../services/api_client.dart';
import '../services/handball_api_service.dart';
import '../services/http_handball_api_service.dart';
import '../services/mock_handball_api_service.dart';
import 'preferences_repository.dart';

/// 데이터 소스. **기본은 운영 서버**([AppConfig.apiBaseUrl])다.
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://localhost:3000  # 로컬 API
/// flutter run --dart-define=MH_USE_MOCK=true                    # 목업
/// ```
///
/// 목업은 서버가 죽었을 때나 디자인만 볼 때 쓴다. 예전에는 URL이 비면
/// 목업으로 떨어졌는데, 그러면 dart-define을 빠뜨린 배포본이 목업을 싣는다.
final handballApiServiceProvider = Provider<HandballApiService>((ref) {
  if (AppConfig.useMock || AppConfig.apiBaseUrl.isEmpty) {
    return const MockHandballApiService();
  }

  final prefs = ref.watch(preferencesRepositoryProvider);
  final client = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    deviceId: prefs.deviceId,
  );
  ref.onDispose(client.close);

  return HttpHandballApiService(
    client: client,
    // 설정에서 바뀌면 다음 호출부터 반영된다. 화면이 새로 요청할 때
    // 현재 값을 읽도록 콜백으로 넘긴다.
    gender: () => prefs.preferredGender,
    season: () => prefs.season.year,
  );
});

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
  final _seasonCache = <String, List<ScheduleDay>>{};
  final _seasonMonths = <String, List<DateTime>>{};

  /// 시즌이 바뀌면(설정 > 시즌) 캐시가 통째로 무효다.
  ///
  /// 예전에는 키에 시즌이 없어서 시즌을 바꿔도 이전 시즌 일정이 그대로
  /// 보였다. 키에 넣어 구분한다.
  String _key(Gender gender, String season) => '${gender.code}-$season';

  /// 월 단위 일정. 같은 (부, 시즌, 연월)은 세션 동안 다시 받지 않는다.
  Future<List<ScheduleDay>> getMonthlySchedule(
    Gender gender,
    String season,
    DateTime month, {
    bool forceRefresh = false,
  }) async {
    final key = '${_key(gender, season)}-${month.year}-${month.month}';
    final hit = _monthCache[key];
    if (!forceRefresh && hit != null) return hit;
    try {
      final days =
          await _service.fetchMonthlySchedule(gender, month, season: season);
      _monthCache[key] = days;
      return days;
    } on Exception {
      if (hit != null) return hit;
      rethrow;
    }
  }

  /// 시즌 전체 일정. 월을 빼고 한 번 받는다.
  ///
  /// 일정 탭이 시작 달을 고르고 MY 화면이 마이팀 경기를 모으는 데 쓴다.
  /// 둘 다 "이번 달"만 보면 비시즌에 빈 화면이 된다.
  Future<List<ScheduleDay>> getSeasonSchedule(
    Gender gender,
    String season, {
    bool forceRefresh = false,
  }) async {
    final key = _key(gender, season);
    final hit = _seasonCache[key];
    if (!forceRefresh && hit != null) return hit;
    try {
      final days = await _service.fetchSeasonSchedule(gender, season: season);
      return _seasonCache[key] = days;
    } on Exception {
      if (hit != null) return hit;
      rethrow;
    }
  }

  /// 그 시즌에 **경기가 있는 달**만 이른 순서로.
  Future<List<DateTime>> getSeasonMonths(Gender gender, String season) async {
    final key = _key(gender, season);
    final hit = _seasonMonths[key];
    if (hit != null) return hit;

    final List<ScheduleDay> days;
    try {
      days = await getSeasonSchedule(gender, season);
    } on Exception {
      return const [];
    }

    final months = <DateTime>{};
    for (final day in days) {
      if (day.games.isEmpty) continue;
      final d = day.date;
      if (d != null) months.add(DateTime(d.year, d.month));
    }
    final sorted = months.toList()..sort();
    return _seasonMonths[key] = sorted;
  }

  /// 오늘에 가장 가까운, 경기가 있는 달.
  ///
  /// 시즌 안이면 그 달, 시즌이 아직이면 개막 달, 끝났으면 마지막 달이다.
  /// 비시즌에 일정 탭을 열었을 때 빈 달 대신 방금 끝난 시즌의 마지막 달을
  /// 보여주려는 것이다.
  Future<DateTime> getFocusMonth(
    Gender gender,
    String season, {
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final thisMonth = DateTime(today.year, today.month);
    final months = await getSeasonMonths(gender, season);
    if (months.isEmpty) return thisMonth;
    if (months.contains(thisMonth)) return thisMonth;

    final upcoming = months.where((m) => m.isAfter(thisMonth));
    if (upcoming.isNotEmpty) return upcoming.first;
    return months.last;
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
