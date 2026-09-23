import 'team.dart';

/// 팀 순위 한 줄. API `/api/ranking`의 `RankItem`에 대응한다.
///
/// 현재 UI(홈 시상대 + 리스트)는 `rank`/`team`/`points`만 쓰지만, API는
/// 승·무·패·득실차·최근 5경기까지 준다. 분석 탭을 만들 때 채운다.
class RankRow {
  const RankRow({
    required this.rank,
    required this.team,
    required this.points,
    this.played = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.last5 = const [],
  });

  final int rank;
  final Team team;
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;

  /// `W` / `L` / `D`
  final List<String> last5;

  int get goalDiff => goalsFor - goalsAgainst;
}
