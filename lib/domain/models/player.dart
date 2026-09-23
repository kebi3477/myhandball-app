/// 선수. 분석 탭의 선수 카드와 선수 비교에서 쓴다.
///
/// `GET /api/player`에 대응한다. 이적·은퇴한 선수는 배번과 포지션이 없어서
/// 둘 다 nullable이다 (`../myhandball-api/docs/api-tasks/07-후속-작업.md` C절).
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.teamName,
    required this.number,
    required this.position,
    required this.statLine,
    this.teamLogoUrl,
    this.goals,
  });

  final String id;
  final String name;
  final String teamName;

  /// 등번호. 시안에서 카드에 44px로 크게 들어간다.
  /// 현재 로스터에 없는 선수(이적·은퇴)는 `null`이다.
  final int? number;

  /// LW / LB / CB / RB / RW / PV / GK. 로스터에 없으면 `null`.
  final String? position;

  /// 카드에 찍는 배번 문구. 없으면 시안의 빈 자리(`-`).
  String get numberText => number?.toString() ?? '-';

  /// 포지션 뱃지 문구.
  String get positionText => position ?? '-';

  /// 카드 아래 한 줄 요약. 예: `142골 · 32AS`
  final String statLine;

  final String? teamLogoUrl;

  /// 시즌 득점. `/api/player`의 `stats.goals`.
  ///
  /// MY 화면의 "주요 선수"가 이걸로 줄을 세운다. 팀 상세의 선수 명단처럼
  /// 기록 없이 만든 [Player]는 `null`이다.
  final int? goals;

  /// 포지션 전체 이름 (팀 상세의 주요 선수 목록에서 쓴다).
  String get positionFull => switch (position) {
        null => '-',
        'LW' => '레프트윙',
        'RW' => '라이트윙',
        'LB' => '레프트백',
        'RB' => '라이트백',
        'CB' => '센터백',
        'PV' => '피벗',
        'GK' => '골키퍼',
        _ => position!,
      };
}
