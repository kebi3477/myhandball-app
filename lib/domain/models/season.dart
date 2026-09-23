/// 조회 시즌.
///
/// API는 **시작 연도 문자열**을 받는다 (`/api/schedule?season=2025`).
/// 라벨은 v1 웹의 `SEASON_LABELS`를 그대로 옮겼다.
class Season {
  const Season(this.year, this.label);

  /// 시작 연도로 만든다. `2025` → `25-26`
  factory Season.ofYear(int startYear) {
    final a = (startYear % 100).toString().padLeft(2, '0');
    final b = ((startYear + 1) % 100).toString().padLeft(2, '0');
    return Season('$startYear', '$a-$b');
  }

  /// API 쿼리에 그대로 들어가는 값. 예: `"2025"`
  final String year;

  /// 사람이 보는 이름. 예: `25-26`
  final String label;

  int get startYear => int.tryParse(year) ?? _currentStartYear();

  /// H리그는 **11월에 개막해서 이듬해 봄에 끝난다** (여자부는 1월 개막).
  ///
  /// 그래서 시즌은 11월에 넘어간다:
  ///
  /// - 2025.11 ~ 2026.10 → `2025` (25-26)
  /// - 2024.11 ~ 2025.10 → `2024` (24-25)
  ///
  /// 비시즌(5~10월)에는 **직전에 끝난 시즌**을 본다. 개막 전에 빈 화면을
  /// 보여주는 것보다 방금 끝난 시즌을 보여주는 쪽이 맞다.
  static int _currentStartYear([DateTime? now]) {
    final d = now ?? DateTime.now();
    return d.month >= _seasonOpensInMonth ? d.year : d.year - 1;
  }

  static const _seasonOpensInMonth = 11;

  /// 오늘 기준 시즌. 앱의 기본값이다.
  static Season get current => Season.ofYear(_currentStartYear());

  /// 테스트용 — 기준 시각을 넣어 계산한다.
  static Season at(DateTime now) => Season.ofYear(_currentStartYear(now));

  /// 시즌 선택기에 띄울 목록. 현재 시즌부터 과거로 5개.
  ///
  /// 예전에는 `2025`~`2021`이 하드코딩돼 있어서 해가 바뀌면 손으로 고쳐야
  /// 했다. 이제 [current]에서 만든다.
  static List<Season> get all => [
        for (var i = 0; i < 5; i++) Season.ofYear(_currentStartYear() - i),
      ];

  static Season fromYear(String year) {
    final parsed = int.tryParse(year);
    return parsed == null ? current : Season.ofYear(parsed);
  }

  @override
  bool operator ==(Object other) => other is Season && other.year == year;

  @override
  int get hashCode => year.hashCode;

  @override
  String toString() => 'Season($year, $label)';
}
