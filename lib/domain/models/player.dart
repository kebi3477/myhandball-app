/// 선수. 분석 탭의 선수 카드와 선수 비교에서 쓴다.
///
/// **대응하는 API 엔드포인트가 아직 없다.** 현재 백엔드는 schedule / ranking /
/// team / welcome 넷뿐이라 선수 명단은 신규 작업이 필요하다.
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.teamName,
    required this.number,
    required this.position,
    required this.statLine,
    this.teamLogoUrl,
  });

  final String id;
  final String name;
  final String teamName;

  /// 등번호. 시안에서 카드에 44px로 크게 들어간다.
  final int number;

  /// LW / LB / CB / RB / RW / PV / GK
  final String position;

  /// 카드 아래 한 줄 요약. 예: `142골 · 32AS`
  final String statLine;

  final String? teamLogoUrl;

  /// 포지션 전체 이름 (팀 상세의 주요 선수 목록에서 쓴다).
  String get positionFull => switch (position) {
        'LW' => '레프트윙',
        'RW' => '라이트윙',
        'LB' => '레프트백',
        'RB' => '라이트백',
        'CB' => '센터백',
        'PV' => '피벗',
        'GK' => '골키퍼',
        _ => position,
      };
}
