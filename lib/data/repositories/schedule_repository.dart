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

/// 데이터 소스. `API_BASE_URL`이 주입돼 있으면 실제 API를 친다.
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://localhost:3000
/// ```
///
/// 비어 있으면 목업으로 떨어진다. 디자인만 확인할 때와 서버가 죽었을 때
/// 앱을 열어 볼 수 있어야 해서 이 갈림길을 남겨 둔다.
final handballApiServiceProvider = Provider<HandballApiService>((ref) {
  if (AppConfig.apiBaseUrl.isEmpty) return const MockHandballApiService();

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
