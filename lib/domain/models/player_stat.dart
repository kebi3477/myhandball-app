/// 시즌 TOP5 기록 카테고리.
enum StatCategory {
  goals('득점', '골'),
  assists('어시스트', '개'),
  saves('선방', '개');

  const StatCategory(this.label, this.unit);

  final String label;
  final String unit;
}

/// 선수 기록 한 줄. `GET /api/player/ranking`에 대응한다.
class PlayerStat {
  const PlayerStat({
    required this.rank,
    required this.name,
    required this.teamName,
    required this.position,
    required this.value,
    this.unit = '',
    this.isEstimated = false,
    this.logoUrl,
  });

  final int rank;
  final String name;
  final String teamName;

  /// LW / LB / CB / RB / RW / PV / GK
  final String position;

  /// **숫자만.** 단위는 [unit]에 따로 둔다 — 시안이 단위를 더 작은 글자로
  /// 그린다. 값에 단위를 붙여 두면 `166골골`처럼 두 번 찍힌다.
  final String value;

  /// 원본 단위. 카테고리마다 다르다 (`골` `개` `회` `%` `P`).
  ///
  /// [StatCategory.unit]을 쓰면 안 된다 — 선방은 앱 enum이 `개`인데 API는
  /// `회`를 준다. 서버가 주는 값을 그대로 쓴다.
  final String unit;

  /// 시안의 `추정` 배지 — 집계가 확정되지 않은 값.
  final bool isEstimated;

  final String? logoUrl;
}
