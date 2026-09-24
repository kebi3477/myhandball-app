import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/ranking_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../domain/models/attendance.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/rank_row.dart';
import '../../../domain/models/team.dart';

/// 홈 "직관" 탭의 상태.
///
/// **전부 기기에 있는 값으로 만든다.** 직관 여부는 `mh_attended`,
/// 나머지는 시즌 일정과 순위에서 계산한다. 서버에 직관 API가 없어서
/// 앱을 지우면 기록도 같이 사라진다.
class AttendanceState {
  const AttendanceState({
    required this.team,
    required this.seasonLabel,
    required this.entries,
    required this.stamps,
    required this.upcoming,
    required this.candidates,
    required this.teamRank,
  });

  final Team? team;

  /// `25-26 시즌 나의 직관`
  final String seasonLabel;

  /// 최근 경기가 위로 오게 정렬돼 있다.
  final List<AttendanceEntry> entries;

  final List<VenueStamp> stamps;

  /// 시안 "다음 직관 어때요?" — 마이팀의 다가오는 경기.
  final List<Game> upcoming;

  /// 기록 추가 시트에 올릴 후보 — 이미 끝났고 아직 기록 안 한 마이팀 경기.
  final List<Game> candidates;

  final RankRow? teamRank;

  bool get isEmpty => entries.isEmpty;

  int get count => entries.length;

  /// 승패가 확정된 경기만 승률에 넣는다.
  List<AttendanceEntry> get _decided =>
      entries.where((e) => e.result != AttendanceResult.unknown).toList();

  int get wins => _decided.where((e) => e.result == AttendanceResult.win).length;
  int get draws =>
      _decided.where((e) => e.result == AttendanceResult.draw).length;
  int get losses =>
      _decided.where((e) => e.result == AttendanceResult.loss).length;

  /// 시안 `av.wdl` — `3·1·2`
  String get wdlLabel => '$wins·$draws·$losses';

  /// 시안 `av.rate` — 직관 승률.
  String get rateLabel {
    if (_decided.isEmpty) return '-';
    return '${(wins * 100 / _decided.length).round()}%';
  }

  /// 시안 `av.teamRate` — 팀의 시즌 승률. 내가 간 날이 특별했는지 비교하는
  /// 기준선이다. 이게 없으면 직관 승률 숫자만으로는 아무 의미가 없다.
  String get teamRateLabel {
    final r = teamRank;
    if (r == null || r.played == 0) return '-';
    return '${(r.wins * 100 / r.played).round()}%';
  }

  /// 시안 `av.cheerLine` — 큰 숫자 밑의 한 줄.
  String get cheerLine {
    if (team == null) return '마이팀을 정하면 직관 기록이 쌓여요';
    if (entries.isEmpty) return '첫 직관을 기록해 보세요';
    final venues = stamps.where((s) => s.visited).length;
    return '$venues개 경기장에서 ${team!.name}을 응원했어요';
  }

  /// 시안 `av.stampCount` — `4/8`
  String get stampCountLabel =>
      '${stamps.where((s) => s.visited).length}/${stamps.length}';
}

class AttendanceViewModel extends AsyncNotifier<AttendanceState> {
  /// 시안 "다음 직관 어때요?"가 보여주는 경기 수.
  static const _upcomingCount = 2;

  @override
  Future<AttendanceState> build() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final team = prefs.myTeam;
    final gender = team?.gender ?? prefs.preferredGender;
    final season = prefs.season;

    final days = await ref
        .read(scheduleRepositoryProvider)
        .getSeasonSchedule(gender, season.year);
    final all = [for (final d in days) ...d.games];

    final mine = team == null
        ? <Game>[]
        : all
            .where((g) => g.home.name == team.name || g.away.name == team.name)
            .toList()
      ..sort(_byStart);

    final entries = [
      for (final g in mine)
        if (prefs.didAttend(g.id))
          AttendanceEntry(
            game: g,
            result: AttendanceEntry.resultFor(g, team),
          ),
    ].reversed.toList();

    RankRow? rank;
    if (team != null) {
      try {
        final ranking =
            await ref.read(rankingRepositoryProvider).getRanking(gender);
        for (final r in ranking) {
          if (r.team.name == team.name) rank = r;
        }
      } on Exception {
        // 순위를 못 받아도 직관 기록은 보여준다. 비교선만 빠진다.
        rank = null;
      }
    }

    return AttendanceState(
      team: team,
      seasonLabel: '${season.label} 시즌 나의 직관',
      entries: entries,
      stamps: _stamps(mine, prefs),
      upcoming: mine
          .where((g) => g.status != GameStatus.finished)
          .take(_upcomingCount)
          .toList(),
      candidates: mine.reversed
          .where((g) => g.status == GameStatus.finished && !prefs.didAttend(g.id))
          .toList(),
      teamRank: rank,
    );
  }

  /// 시즌 일정에 나오는 경기장을 모아 도장판을 만든다.
  ///
  /// **안 가본 곳도 남긴다.** 다녀온 곳만 보여주면 "도장깨기"가 아니라
  /// 그냥 방문 목록이 된다. 순서는 다녀온 곳 → 많이 간 순 → 이름순이라
  /// 채운 칸이 위로 모인다.
  static List<VenueStamp> _stamps(List<Game> games, PreferencesRepository prefs) {
    final times = <String, int>{};
    final logos = <String, String?>{};

    for (final g in games) {
      final venue = g.venue;
      if (venue == null || venue.isEmpty) continue;
      times[venue] ??= 0;
      // 로고는 그 경기장을 홈으로 쓰는 팀 것이다.
      logos[venue] ??= g.home.logoUrl;
      if (prefs.didAttend(g.id)) times[venue] = times[venue]! + 1;
    }

    final stamps = [
      for (final entry in times.entries)
        VenueStamp(
          venue: entry.key,
          times: entry.value,
          logoUrl: logos[entry.key],
        ),
    ]..sort((a, b) {
        if (a.visited != b.visited) return a.visited ? -1 : 1;
        if (a.times != b.times) return b.times.compareTo(a.times);
        return a.venue.compareTo(b.venue);
      });
    return stamps;
  }

  static int _byStart(Game a, Game b) {
    final x = a.startsAt, y = b.startsAt;
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }

  /// 기록 추가 시트에서 경기를 고르거나, 일지에서 다시 눌러 뺄 때.
  Future<void> toggle(String gameId) async {
    await ref.read(preferencesRepositoryProvider).toggleAttended(gameId);
    state = await AsyncValue.guard(build);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<AttendanceState>().copyWithPrevious(state);
    state = await AsyncValue.guard(build);
  }
}

final attendanceViewModelProvider =
    AsyncNotifierProvider<AttendanceViewModel, AttendanceState>(
  AttendanceViewModel.new,
);
