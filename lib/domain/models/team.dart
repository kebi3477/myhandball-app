import 'gender.dart';

/// 팀. API `/api/team`의 `TeamItem`, `/api/schedule`의 `TeamInfo`에 대응한다.
class Team {
  const Team({
    required this.name,
    this.logoUrl,
    this.gender = Gender.men,
    this.teamNum,
  });

  final String name;

  /// 연맹 사이트 절대 URL. 없을 수 있다.
  final String? logoUrl;

  final Gender gender;

  /// `/api/team`이 주는 팀 번호.
  final int? teamNum;

  @override
  bool operator ==(Object other) =>
      other is Team && other.name == name && other.gender == gender;

  @override
  int get hashCode => Object.hash(name, gender);
}
