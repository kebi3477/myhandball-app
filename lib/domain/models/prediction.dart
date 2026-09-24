import '../number_format.dart';
import 'gender.dart';

/// 승부예측 랭킹에 쓰는 프로필. `GET/PUT /api/profile`.
///
/// 회원가입이 아니다. **닉네임과 응원팀만** 서버에 두고, 기기는 익명
/// `X-Device-Id`로 구분한다.
class PredictionProfile {
  const PredictionProfile({
    required this.nickname,
    required this.teamNum,
    required this.teamName,
    required this.gender,
    this.teamLogoUrl,
    this.createdAt,
  });

  final String nickname;
  final int teamNum;
  final String teamName;
  final Gender gender;
  final String? teamLogoUrl;
  final DateTime? createdAt;

  /// `2026.09 가입`
  String? get joinedLabel {
    final at = createdAt?.toLocal();
    if (at == null) return null;
    return '${at.year}.${at.month.toString().padLeft(2, '0')}';
  }
}

/// 적중률 랭킹 한 줄.
class LeaderboardRow {
  const LeaderboardRow({
    required this.rank,
    required this.nickname,
    required this.teamName,
    required this.settled,
    required this.hits,
    required this.rate,
    required this.isMe,
    this.teamLogoUrl,
  });

  final int rank;
  final String nickname;
  final String teamName;

  /// 적중 여부가 정해진 참여 수. 랭킹 자격(10경기)의 기준이다.
  final int settled;
  final int hits;

  /// 0~100. `54.5`처럼 소수가 올 수 있다.
  final double rate;

  final bool isMe;
  final String? teamLogoUrl;

  /// `75%` / `54.5%` — 정수면 소수점을 떼고 쓴다.
  String get rateLabel =>
      rate == rate.roundToDouble() ? '${rate.round()}%' : '$rate%';

  /// `9 / 12`
  String get recordLabel => '$hits / $settled';
}

/// 랭킹 범위. 시안의 "전체" / "내 팀 팬".
enum LeaderboardScope {
  all('전체', 'all'),
  team('내 팀 팬', 'team');

  const LeaderboardScope(this.label, this.code);

  final String label;
  final String code;
}

/// `GET /api/prediction/leaderboard`.
class Leaderboard {
  const Leaderboard({
    required this.scope,
    required this.minSettled,
    required this.total,
    required this.rows,
    this.me,
    this.meHint,
    this.meTopPercent,
  });

  const Leaderboard.empty()
      : scope = LeaderboardScope.all,
        minSettled = 10,
        total = 0,
        rows = const [],
        me = null,
        meHint = null,
        meTopPercent = null;

  final LeaderboardScope scope;

  /// 랭킹에 오르는 데 필요한 확정 경기 수.
  final int minSettled;

  /// 조건을 만족하는 전체 참여자 수.
  final int total;

  final List<LeaderboardRow> rows;

  /// 내가 [rows] 안에 있어도 서버가 채워 준다.
  final LeaderboardRow? me;

  /// 내가 랭킹에 없는 이유. 그대로 띄운다.
  final String? meHint;

  /// `전체 상위 12%`의 12. **범위가 팀이어도 전체 기준**이다.
  final int? meTopPercent;

  /// 시안 `pv.rankAll` — `2위` 또는 `-`.
  String get myRankLabel => me == null ? '-' : '${me!.rank}위';

  /// 시안 `pv.rankSub`.
  String get myRankSub {
    final percent = meTopPercent;
    if (me == null || percent == null) return '랭킹 밖';
    return '전체 상위 $percent%';
  }

  /// `1,240` — 시안 `pv.total`.
  String get totalLabel => formatThousands(total);

  /// 내 줄이 목록에 안 보여서 따로 붙여야 하는지.
  bool get pinsMe =>
      me != null && !rows.any((r) => r.isMe);
}

/// 팬덤 적중률 한 줄. 사용자 평균이 아니라 **경기 수 가중 평균**이다.
class FandomRow {
  const FandomRow({
    required this.rank,
    required this.teamNum,
    required this.teamName,
    required this.fans,
    required this.rate,
    this.teamLogoUrl,
  });

  final int rank;
  final int teamNum;
  final String teamName;

  /// 랭킹 자격을 갖춘 팬 수. 0이면 아직 집계할 게 없다.
  final int fans;

  /// 0~100.
  final double rate;

  final String? teamLogoUrl;

  String get rateLabel =>
      rate == rate.roundToDouble() ? '${rate.round()}%' : '$rate%';
}

/// `GET /api/prediction/my` — 내 예측 집계와 최근 목록.
class MyPredictions {
  const MyPredictions({
    required this.count,
    required this.settled,
    required this.hits,
    required this.rate,
    required this.items,
  });

  const MyPredictions.empty()
      : count = 0,
        settled = 0,
        hits = 0,
        rate = 0,
        items = const [];

  /// 결과를 기다리는 것까지 포함한 전체 참여 수.
  final int count;

  /// 적중 여부가 정해진 수. **적중률의 분모다.**
  final int settled;
  final int hits;
  final double rate;

  final List<MyPredictionItem> items;

  /// 시안 `pv.rate` — 확정된 게 없으면 `-`.
  String get rateLabel {
    if (settled == 0) return '-';
    return rate == rate.roundToDouble() ? '${rate.round()}%' : '$rate%';
  }

  /// 시안 `pv.rec` — `9 / 12`
  String get recordLabel => '$hits / $settled';
}

class MyPredictionItem {
  const MyPredictionItem({
    required this.matchSeq,
    required this.homeName,
    required this.awayName,
    required this.pick,
    required this.settled,
    required this.hit,
    this.startsAt,
    this.scoreText,
  });

  final int matchSeq;
  final String homeName;
  final String awayName;

  /// `home` / `draw` / `away`.
  final String pick;

  final bool settled;
  final bool hit;
  final DateTime? startsAt;
  final String? scoreText;

  String get matchLabel => '$homeName vs $awayName';

  /// 시안 `내 예측: SK호크스 승`
  String get pickLabel => switch (pick) {
        'home' => '$homeName 승',
        'away' => '$awayName 승',
        _ => '무승부',
      };

  /// 시안 칩 — `적중` / `실패` / `대기`
  String get chipLabel => settled ? (hit ? '적중' : '실패') : '대기';

  /// `11.30`
  String get dateLabel {
    final at = startsAt?.toLocal();
    if (at == null) return '';
    return '${at.month.toString().padLeft(2, '0')}.'
        '${at.day.toString().padLeft(2, '0')}';
  }
}
