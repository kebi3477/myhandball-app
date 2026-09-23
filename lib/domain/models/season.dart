/// 조회 시즌.
///
/// API는 **시작 연도 문자열**을 받는다 (`/api/schedule?season=2025`).
/// 라벨은 v1 웹의 `SEASON_LABELS`를 그대로 옮겼다.
class Season {
  const Season(this.year, this.label);

  /// API 쿼리에 그대로 들어가는 값. 예: `"2025"`
  final String year;

  /// 사람이 보는 이름. 예: `25-26`
  final String label;

  static const all = <Season>[
    Season('2025', '25-26'),
    Season('2024', '24-25'),
    Season('2023', '23-24'),
    Season('2022', '22-23'),
    Season('2021', '21-22'),
  ];

  static const latest = Season('2025', '25-26');

  static Season fromYear(String year) =>
      all.firstWhere((s) => s.year == year, orElse: () => latest);

  @override
  bool operator ==(Object other) => other is Season && other.year == year;

  @override
  int get hashCode => year.hashCode;
}
