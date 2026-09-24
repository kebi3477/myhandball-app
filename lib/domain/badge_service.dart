import 'models/badge.dart';

/// 배지 획득 판정을 한곳에 모은다.
///
/// 시안의 `buildBadges`(`spec/logic.js`)를 옮긴 것이다. **승리 요정만
/// 조건이 다르다** — 아래 [_winFairy] 주석 참조.
///
/// **조건과 획득일은 나중에 서버 기준으로 바뀐다.** 그때 갈아끼울 자리를
/// 하나로 두려고 계산을 화면에서 떼어 놨다.
class BadgeService {
  const BadgeService();

  /// 승리 요정이 열리기까지 필요한 **직관 승리** 수.
  static const winFairyWins = 3;

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

  /// 승리 요정 — 내가 간 경기에서 마이팀이 이긴 횟수.
  ///
  /// **시안(`spec/badges.md`)과 일부러 다르다.** 시안은 "응원 경기 3회 +
  /// 직관 승률 > 팀 시즌 승률"인데, 그러면 **팀이 전승일 때 영영 안 열린다**
  /// — 내 직관 승률도 100%라 차이가 0이다. 잘하는 팀을 응원할수록 불리한
  /// 조건이라 2026-09-24에 사용자가 "승리 횟수"로 바꿨다.
  ///
  /// 승률 차이는 조건에서 빠졌지만, **양수일 때만** 획득 문구에 남긴다.
  /// 0이나 음수면 "+0%p"처럼 읽혀서 무슨 말인지 알 수 없다.
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

    // 차이는 **각각 반올림한 뒤에** 뺀다. 먼저 빼고 반올림하면 1%p 어긋난다.
    final mine = played == 0 ? 0 : (wins * 100 / played).round();
    final theirs =
        teamPlayed == 0 ? 0 : (teamWins * 100 / teamPlayed).round();
    final diff = mine - theirs;

    final earned = wins >= winFairyWins;

    return MhBadge(
      kind: MhBadgeKind.winFairy,
      earned: earned,
      ratio: (wins / winFairyWins).clamp(0.0, 1.0),
      subtitle: earned
          ? (diff > 0 ? '내가 가면 승률 +$diff%p' : '직관 $wins승 달성')
          : '승리 $wins/$winFairyWins',
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
