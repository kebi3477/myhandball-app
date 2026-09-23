/// 선수의 한 시즌(또는 통산) 기록. API `PlayerSeasonStats`.
///
/// 목록(`/api/player`)에도 통째로 들어 있어서 선수 비교·정렬이 이 값을 쓴다.
/// 다만 **`games`는 목록에 없다** — 원본 기록실에 경기 수가 없어서 상세
/// (`/api/player/:playerSeq`)에서만 채워진다.
class PlayerSeasonSummary {
  const PlayerSeasonSummary({
    this.games,
    this.goals = 0,
    this.shots = 0,
    this.goalRate,
    this.assists = 0,
    this.steals = 0,
    this.blocks = 0,
    this.turnovers = 0,
    this.saves,
    this.saveRate,
    this.playMinutes,
  });

  final int? games;
  final int goals;
  final int shots;

  /// 슛 성공률(%). 시도가 없으면 null.
  final double? goalRate;

  final int assists;
  final int steals;
  final int blocks;
  final int turnovers;

  /// 골키퍼만. 필드 선수는 null.
  final int? saves;
  final double? saveRate;

  /// 출전 시간(분). 원본은 `"1140:05"`(분:초).
  final int? playMinutes;

  bool get isKeeper => saves != null;

  /// 수비 기여. 레이더 축에 쓴다.
  int get defense => steals + blocks;

  /// 카드 아래 한 줄. 골키퍼는 선방이 의미 있고 나머지는 득점·어시스트다.
  String get line =>
      isKeeper ? '선방 $saves' : '$goals골 · ${assists}AS';

  /// 선수 요약 시트의 4칸. 골키퍼는 보여줄 값이 다르다.
  List<(String, String)> get summaryCells => isKeeper
      ? [
          ('경기', _int(games)),
          ('선방', _int(saves)),
          ('방어율', _percent(saveRate)),
          ('스틸', '$steals'),
        ]
      : [
          ('경기', _int(games)),
          ('득점', '$goals'),
          ('어시스트', '$assists'),
          ('성공률', _percent(goalRate)),
        ];

  static String _int(int? v) => v?.toString() ?? '-';

  static String _percent(double? v) =>
      v == null ? '-' : '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}%';

  /// `"1140:05"` → 1140
  static int? minutesFromLabel(String? label) {
    if (label == null) return null;
    final head = label.split(':').first;
    return int.tryParse(head);
  }
}

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
    this.photoUrl,
    this.stats,
    this.playerSeq,
  });

  final String id;
  final String name;
  final String teamName;

  /// 등번호. 시안에서 카드에 44px로 크게 들어간다.
  /// 현재 로스터에 없는 선수(이적·은퇴)는 `null`이다.
  final int? number;

  /// LW / LB / CB / RB / RW / PV / GK. 로스터에 없으면 `null`.
  final String? position;

  /// 카드 아래 한 줄 요약. 예: `142골 · 32AS`
  final String statLine;

  final String? teamLogoUrl;
  final String? photoUrl;

  /// 시즌 기록. 팀 상세의 선수 명단처럼 기록 없이 만든 경우 `null`.
  final PlayerSeasonSummary? stats;

  /// 연맹 선수 번호. 상세(`/api/player/:playerSeq`)를 받을 때 쓴다.
  final int? playerSeq;

  /// 카드에 찍는 배번 문구. 없으면 시안의 빈 자리(`-`).
  String get numberText => number?.toString() ?? '-';

  /// 포지션 뱃지 문구.
  String get positionText => position ?? '-';

  /// 시즌 득점. MY 화면의 "주요 선수"가 이걸로 줄을 세운다.
  int? get goals => stats?.goals;

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

/// 시즌별 기록 한 줄. 선수 상세의 "시즌별 기록" 표.
class PlayerSeasonRow {
  const PlayerSeasonRow({
    required this.season,
    required this.postseason,
    required this.stats,
  });

  /// `"2025-2026"`
  final String season;

  /// 챔피언결정전 등 포스트시즌 행인지.
  final bool postseason;

  final PlayerSeasonSummary stats;
}

/// 선수 상세. `GET /api/player/:playerSeq`.
///
/// 목록에 없는 프로필(생년월일·키·몸무게·출신교)과 통산·시즌별 기록이 있다.
class PlayerDetail {
  const PlayerDetail({
    required this.player,
    required this.career,
    required this.seasons,
    this.nameEn,
    this.birthLabel,
    this.heightCm,
    this.weightKg,
    this.school,
  });

  final Player player;

  /// 정규리그 통산.
  final PlayerSeasonSummary career;

  /// 시즌별 기록. 최신이 앞.
  final List<PlayerSeasonRow> seasons;

  final String? nameEn;
  final String? birthLabel;
  final int? heightCm;
  final int? weightKg;
  final String? school;

  /// 그 시즌의 정규리그 기록.
  ///
  /// **행 순서를 믿으면 안 된다.** 원본이 아직 일정도 없는 다음 시즌 행을
  /// 맨 앞에 두는 경우가 있어서(2026-2027 · 1경기), 앱이 보고 있는 시즌을
  /// 명시적으로 찾는다. 없으면 가장 최근 정규리그, 그것도 없으면 통산.
  PlayerSeasonSummary statsForSeason(String startYear) {
    for (final row in seasons) {
      if (!row.postseason && row.season.startsWith(startYear)) {
        return row.stats;
      }
    }
    for (final row in seasons) {
      if (!row.postseason) return row.stats;
    }
    return career;
  }

  /// 키·몸무게처럼 있을 때만 보여줄 항목들.
  List<(String, String)> get profileFacts => [
        if (birthLabel case final v?) ('생년월일', v),
        if (heightCm case final v?)
          ('신체', weightKg == null ? '${v}cm' : '${v}cm · ${weightKg}kg'),
        if (school case final v?) ('출신교', v),
      ];
}
