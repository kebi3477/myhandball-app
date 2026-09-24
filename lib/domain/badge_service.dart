import 'models/badge.dart';

/// 배지 획득 판정을 한곳에 모은다.
///
/// 시안의 `buildBadges`(`spec/logic.js`)를 그대로 옮긴 것이다.
/// **조건과 획득일은 나중에 서버 기준으로 바뀐다.** 그때 갈아끼울 자리를
/// 하나로 두려고 계산을 화면에서 떼어 놨다.
class BadgeService {
  const BadgeService();

  /// 승리 요정이 열리기까지 필요한 **응원 경기** 수.
  static const winFairyGames = 3;

  /// 예측 고수 목표 적중 수.
  static const predictorHits = 10;

  /// 입문 수료에 필요한 레슨 수.
  static const guideLessons = 5;

  /// 배지 세 개를 순서대로 만든다. 순서는 고정이다.
  ///
  /// [attendanceWins] · [attendanceDraws] · [attendanceLosses]는 **마이팀이
  /// 뛴** 직관 경기만 센다. 마이팀이 안 뛴 경기는 시안에서 "관람"이라
  /// 부르고 어디에도 들어가지 않는다.
  List<MhBadge> evaluate({
    required int guideDone,
    required DateTime? guideCompletedAt,
    required int attendanceWins,
    required int attendanceDraws,
    required int attendanceLosses,
    required int teamWins,
    required int teamDraws,
    required int teamLosses,
    required int predictionHits,
  }) =>
      [
        _winFairy(
          wins: attendanceWins,
          draws: attendanceDraws,
          losses: attendanceLosses,
          teamWins: teamWins,
          teamDraws: teamDraws,
          teamLosses: teamLosses,
        ),
        _predictor(predictionHits),
        _graduate(guideDone, guideCompletedAt),
      ];

  /// 승리 요정 — 내가 간 날 팀이 더 잘했는지.
  ///
  /// **무승부도 분모에 넣는다** (시안 `attDecided = aw + ad + al`).
  /// 팀 승률도 같은 방식으로 승·무·패를 다 세므로 두 숫자가 나란히 선다.
  ///
  /// 차이는 **각각 반올림한 뒤에** 뺀다. 시안이 `attRateN - teamRateN`으로
  /// 정수끼리 빼서, 먼저 빼고 반올림하면 1%p씩 어긋난다.
  MhBadge _winFairy({
    required int wins,
    required int draws,
    required int losses,
    required int teamWins,
    required int teamDraws,
    required int teamLosses,
  }) {
    final played = wins + draws + losses;
    final teamPlayed = teamWins + teamDraws + teamLosses;

    final mine = played == 0 ? null : (wins * 100 / played).round();
    final theirs =
        teamPlayed == 0 ? 0 : (teamWins * 100 / teamPlayed).round();
    final diff = mine == null ? 0 : mine - theirs;

    final earned = played >= winFairyGames && diff > 0;

    return MhBadge(
      kind: MhBadgeKind.winFairy,
      earned: earned,
      ratio: (played / winFairyGames).clamp(0.0, 1.0),
      subtitle: earned
          ? '내가 가면 승률 +$diff%p'
          : (played < winFairyGames
              ? '응원 경기 $played/$winFairyGames'
              : '직관 승률이 팀보다 높으면'),
    );
  }

  MhBadge _predictor(int hits) {
    final earned = hits >= predictorHits;
    return MhBadge(
      kind: MhBadgeKind.predictor,
      earned: earned,
      ratio: (hits / predictorHits).clamp(0.0, 1.0),
      subtitle: earned
          ? '적중 $hits회 달성'
          : '적중 ${hits.clamp(0, predictorHits)}/$predictorHits',
    );
  }

  MhBadge _graduate(int done, DateTime? completedAt) {
    final earned = done >= guideLessons;
    return MhBadge(
      kind: MhBadgeKind.graduate,
      earned: earned,
      ratio: (done / guideLessons).clamp(0.0, 1.0),
      subtitle: earned
          // 수료일을 저장하기 전에 이미 끝낸 사용자가 있다. 시안도 그때는
          // 날짜 대신 다른 문구를 쓴다.
          ? (completedAt == null ? '가이드 완료' : '${_date(completedAt)} 수료')
          : '레슨 $done/$guideLessons',
    );
  }

  /// `2026.09.24`
  static String _date(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${at.year}.${two(at.month)}.${two(at.day)}';
  }
}
