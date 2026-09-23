/// 시즌 TOP5 기록 카테고리.
enum StatCategory {
  goals('득점', '골'),
  assists('어시스트', '개'),
  saves('선방', '개');

  const StatCategory(this.label, this.unit);

  final String label;
  final String unit;
}

/// 선수 기록 한 줄.
///
/// **대응하는 API 엔드포인트가 아직 없다.** 현재 백엔드는 schedule / ranking /
/// team / welcome 넷뿐이라, 선수 기록은 신규 작업이 필요하다.
/// `docs/api-requests/`에 요청서를 쓰고 진행한다.
class PlayerStat {
  const PlayerStat({
    required this.rank,
    required this.name,
    required this.teamName,
    required this.position,
    required this.value,
    this.isEstimated = false,
    this.logoUrl,
  });

  final int rank;
  final String name;
  final String teamName;

  /// LW / LB / CB / RB / RW / PV / GK
  final String position;

  final String value;

  /// 시안의 `추정` 배지 — 집계가 확정되지 않은 값.
  final bool isEstimated;

  final String? logoUrl;
}
