import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/domain/models/player_stat.dart';
import 'package:myhandball/ui/home/view_models/home_view_model.dart';

/// 비시즌 "가까운 경기" 카드.
///
/// **연맹이 다음 시즌 일정을 올리기 전에는 개막일을 알 수 없다.** 그래도
/// 개막 달은 정해져 있어서(남자부 11월, 여자부 1월) 달까지는 말한다.
/// 날짜를 지어내면 카운트다운이 통째로 틀린 채로 비시즌 내내 떠 있게 된다.
void main() {
  HomeState state({
    Gender openingGender = Gender.men,
    bool notificationsOn = true,
    DateTime? opensAt,
  }) =>
      HomeState(
        games: const [],
        ranking: const [],
        topPlayers: const [],
        gender: Gender.men,
        category: StatCategory.goals,
        openingGender: openingGender,
        notificationsOn: notificationsOn,
        nextSeasonOpensAt: opensAt,
      );

  test('개막 달은 부마다 다르다', () {
    expect(state().openingMonth, 11);
    expect(state(openingGender: Gender.women).openingMonth, 1);
  });

  test('개막일을 알면 날짜를 그대로 적는다', () {
    final s = state(opensAt: DateTime(2026, 11, 14));
    expect(s.offseasonNote, '11월 14일(토) 개막 예정이에요');
  });

  test('개막일을 모르면 일정이 나오면 알리겠다고 한다', () {
    expect(state().offseasonNote, '일정이 나오면 알려드릴게요');
  });

  test('알림이 꺼져 있으면 알리겠다고 약속하지 않는다', () {
    // 못 지킬 약속이다.
    expect(state(notificationsOn: false).offseasonNote,
        '개막 일정 발표 전이에요');
  });

  test('개막일을 알면 알림이 꺼져 있어도 날짜를 적는다', () {
    // 이 문구에는 약속이 없다.
    final s = state(notificationsOn: false, opensAt: DateTime(2026, 11, 14));
    expect(s.offseasonNote, contains('11월 14일'));
  });

  test('개막 달에 들어서면 이번 달로 바뀐다', () {
    // 남자부는 11월, 여자부는 1월에만 이 분기가 나온다.
    final men = state();
    expect(men.isOpeningMonthAt(DateTime(2026, 10, 31)), isFalse);
    expect(men.isOpeningMonthAt(DateTime(2026, 11, 1)), isTrue);

    final women = state(openingGender: Gender.women);
    expect(women.isOpeningMonthAt(DateTime(2026, 11, 1)), isFalse);
    expect(women.isOpeningMonthAt(DateTime(2027, 1, 20)), isTrue);
  });

  test('지난 개막일은 D-day로 치지 않는다', () {
    // 연맹이 옛 일정을 남겨 둔 경우. 음수 D-day를 띄우면 안 된다.
    final s = state(opensAt: DateTime(2020, 11, 14));
    expect(s.daysToOpening, isNull);
  });
}
