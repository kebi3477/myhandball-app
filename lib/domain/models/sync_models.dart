import 'gender.dart';

/// `GET/PUT /api/progress/guide` — 입문 가이드 진행도.
///
/// **줄지 않는다.** 서버가 더 큰 `doneCount`를 갖고 있으면 저장 요청을
/// 무시하고 큰 값을 돌려준다. 기기를 바꿔 0에서 시작해도 이미 딴
/// 「입문 수료」 배지가 사라지지 않게 하려는 규칙이다.
class GuideProgress {
  const GuideProgress({required this.doneCount, this.completedAt});

  final int doneCount;

  /// 5개를 다 채운 시각. 수료한 적이 없으면 `null`.
  final DateTime? completedAt;
}

/// `GET /api/season` — 시즌 상태를 서버가 판정해서 준다.
///
/// 앱도 `Season.current`로 같은 계산을 하지만, **개막·종료 시각은 연맹
/// 일정에서만 나온다.** 비시즌 카드의 D-day가 이 값에 달려 있다.
class SeasonStatus {
  const SeasonStatus({
    required this.season,
    required this.gender,
    required this.isOffseason,
    this.opensAt,
    this.closesAt,
    this.nextSeason,
    this.nextOpensAt,
  });

  /// 시작 연도 문자열. `"2025"` = 25-26 시즌.
  final String season;
  final Gender gender;

  final bool isOffseason;

  final DateTime? opensAt;
  final DateTime? closesAt;

  final String? nextSeason;

  /// 다음 시즌 개막 시각. **연맹이 발표하기 전에는 `null`이고, 서버는
  /// 추정해서 채우지 않는다.** 없으면 앱도 D-day를 만들지 않는다.
  final DateTime? nextOpensAt;
}
