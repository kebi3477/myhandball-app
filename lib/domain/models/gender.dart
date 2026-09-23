/// 리그 구분. API는 `"M"` / `"W"` 문자열을 쓴다
/// (`/api/schedule?gender=M`, `/api/ranking?gender=W`).
enum Gender {
  men('M', '남자부', '남성팀'),
  women('W', '여자부', '여성팀');

  const Gender(this.code, this.divisionLabel, this.teamLabel);

  /// API 쿼리 파라미터 값.
  final String code;

  /// 순위·기록 화면의 토글 라벨.
  final String divisionLabel;

  /// 온보딩 팀 선택의 토글 라벨.
  final String teamLabel;

  static Gender fromCode(String? code) =>
      code == 'W' ? Gender.women : Gender.men;
}
