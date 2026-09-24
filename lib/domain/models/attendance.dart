import 'game.dart';
import 'team.dart';

/// 마이팀 기준 직관 결과.
enum AttendanceResult {
  win('승'),
  draw('무'),
  loss('패'),

  /// 점수가 없는 경기(연기·미기록). 승률 계산에서 뺀다.
  unknown('-');

  const AttendanceResult(this.label);

  final String label;
}

/// 직관 일지 한 줄. 기기에 저장된 경기 id(`mh_attended`)를 실제 경기로
/// 되살린 것이다.
///
/// **서버에 없다.** 앱을 지우면 같이 사라진다 — 기록을 살리려면 서버에
/// 직관 목록 API가 필요하다.
class AttendanceEntry {
  const AttendanceEntry({required this.game, required this.result});

  final Game game;
  final AttendanceResult result;

  DateTime? get at => game.startsAt;

  /// 시안 `a.match` — `SK호크스 vs 두산`
  String get matchLabel => '${game.home.name} vs ${game.away.name}';

  String get venue => game.venue ?? '경기장';

  /// 시안 `a.score` — `28:26`
  String get scoreLabel => '${game.scoreHomeText}:${game.scoreAwayText}';

  /// 마이팀 기준 결과를 매긴다. 마이팀이 안 뛴 경기면 [AttendanceResult.unknown].
  static AttendanceResult resultFor(Game game, Team? myTeam) {
    final home = game.scoreHome;
    final away = game.scoreAway;
    if (home == null || away == null || myTeam == null) {
      return AttendanceResult.unknown;
    }
    final isHome = game.home.name == myTeam.name;
    final isAway = game.away.name == myTeam.name;
    if (!isHome && !isAway) return AttendanceResult.unknown;

    final mine = isHome ? home : away;
    final theirs = isHome ? away : home;
    if (mine > theirs) return AttendanceResult.win;
    if (mine < theirs) return AttendanceResult.loss;
    return AttendanceResult.draw;
  }
}

/// 시안 "경기장 도장깨기" 한 칸.
///
/// 시즌 일정에 나오는 경기장을 전부 깔아 두고, 다녀온 곳에 도장을 찍는다.
/// 안 가본 곳도 흐리게 보여주는 게 핵심이다 — 목표가 보여야 깨러 간다.
class VenueStamp {
  const VenueStamp({
    required this.venue,
    required this.times,
    this.logoUrl,
  });

  final String venue;

  /// 다녀온 횟수. 0이면 아직 안 가본 곳.
  final int times;

  /// 그 경기장을 홈으로 쓰는 팀의 로고.
  final String? logoUrl;

  bool get visited => times > 0;
}
