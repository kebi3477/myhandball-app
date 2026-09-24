import 'models/badge.dart';

/// 배지 획득 판정을 한곳에 모은다.
///
/// **조건과 획득일은 나중에 서버 기준으로 바뀐다.** 그때 갈아끼울 자리를
/// 하나로 두려고 계산을 화면에서 떼어 놨다. 지금은 기기에 쌓인 값
/// (가이드 진행도·직관 기록·예측 적중)으로만 센다.
class BadgeService {
  const BadgeService();

  /// 승리 요정이 열리기까지 필요한 **승패가 난** 직관 경기 수.
  static const winFairyGames = 3;

  /// 예측 고수 목표 적중 수.
  static const predictorHits = 10;

  /// 입문 수료에 필요한 레슨 수.
  static const guideLessons = 5;

  /// 배지 세 개를 순서대로 만든다. 순서는 고정이다.
  List<MhBadge> evaluate({
    required int guideDone,
    required DateTime? guideCompletedAt,
    required int attendanceWins,
    required int attendanceLosses,
    required int teamWins,
    required int teamLosses,
    required int predictionHits,
  }) =>
      [
        _winFairy(
          wins: attendanceWins,
          losses: attendanceLosses,
          teamWins: teamWins,
          teamLosses: teamLosses,
        ),
        _predictor(predictionHits),
        _graduate(guideDone, guideCompletedAt),
      ];

  /// 승리 요정 — 내가 간 날 팀이 더 잘했는지.
  ///
  /// **무승부와 "관람"(마이팀이 안 뛰었거나 점수가 없는 경기)은 뺀다.**
  /// 팀 승률도 같은 방식으로 승·패만 세야 두 숫자를 나란히 놓을 수 있다.
  /// 한쪽만 무승부를 분모에 넣으면 비교가 성립하지 않는다.
  MhBadge _winFairy({
    required int wins,
    required int losses,
    required int teamWins,
    required int teamLosses,
  }) {
    final decided = wins + losses;
    final teamDecided = teamWins + teamLosses;

    final mine = decided == 0 ? 0.0 : wins * 100 / decided;
    final theirs = teamDecided == 0 ? 0.0 : teamWins * 100 / teamDecided;
    final gap = mine - theirs;

    final enough = decided >= winFairyGames;
    final earned = enough && teamDecided > 0 && gap > 0;

    return MhBadge(
      kind: MhBadgeKind.winFairy,
      earned: earned,
      // 경기 수는 채웠는데 승률이 모자란 경우에도 막대는 꽉 찬다 —
      // 셀 수 있는 조건은 이미 다 채웠고, 남은 건 문구가 설명한다.
      ratio: (decided / winFairyGames).clamp(0.0, 1.0),
      subtitle: earned
          ? '내가 가면 승률 +${gap.round()}%p'
          : (enough
              ? '직관 승률이 팀보다 높으면'
              : '응원 경기 $decided/$winFairyGames'),
    );
  }

  MhBadge _predictor(int hits) {
    final earned = hits >= predictorHits;
    return MhBadge(
      kind: MhBadgeKind.predictor,
      earned: earned,
      ratio: (hits / predictorHits).clamp(0.0, 1.0),
      subtitle: earned ? '적중 $hits회 달성' : '적중 $hits/$predictorHits',
    );
  }

  MhBadge _graduate(int done, DateTime? completedAt) {
    final earned = done >= guideLessons;
    return MhBadge(
      kind: MhBadgeKind.graduate,
      earned: earned,
      ratio: (done / guideLessons).clamp(0.0, 1.0),
      subtitle: earned
          // 수료일을 모르는 채로 이미 수료한 사용자가 있다 — 날짜를
          // 저장하기 전에 끝낸 경우다. 그때는 날짜 없이 적는다.
          ? (completedAt == null ? '수료' : '${_date(completedAt)} 수료')
          : '레슨 $done/$guideLessons',
    );
  }

  /// `2026.09.24`
  static String _date(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${at.year}.${two(at.month)}.${two(at.day)}';
  }
}
