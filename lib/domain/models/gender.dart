/// 리그 구분. API는 `"M"` / `"W"` 문자열을 쓴다
/// (`/api/schedule?gender=M`, `/api/ranking?gender=W`).
enum Gender {
  men('M', '남자부', '남성팀', '남자팀'),
  women('W', '여자부', '여성팀', '여자팀');

  const Gender(this.code, this.divisionLabel, this.teamLabel, this.pickerLabel);

  /// API 쿼리 파라미터 값.
  final String code;

  /// 순위·기록 화면의 토글 라벨.
  final String divisionLabel;

  /// 온보딩 팀 선택의 토글 라벨.
  final String teamLabel;

  /// 마이팀 변경 시트의 알약 라벨.
  ///
  /// 시안이 온보딩(`남성팀`)과 시트(`남자팀`)에서 다른 말을 쓴다. 하나로
  /// 합치면 둘 중 한쪽이 시안과 어긋나므로 따로 둔다.
  final String pickerLabel;

  static Gender fromCode(String? code) =>
      code == 'W' ? Gender.women : Gender.men;
}
