import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/models/game.dart';
import 'package:myhandball/domain/models/team.dart';

/// MY의 "다음 경기" 칩과 직관 탭의 날짜 칸이 같은 값을 쓴다.
///
/// 예전에는 MY가 `'다음 경기'`만 돌려주는 자리표시였다 — 목업이 시각
/// 문자열만 줘서 미뤄 뒀는데, 실제 API는 `startsAt`을 준다.
void main() {
  Game game(DateTime? at) => Game(
        id: 'g1',
        home: const Team(name: 'SK호크스'),
        away: const Team(name: '두산'),
        status: GameStatus.pre,
        meta: '11.09',
        startsAt: at,
      );

  DateTime days(int n) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: n));
  }

  test('남은 날을 센다', () {
    expect(game(days(5)).ddayLabel, 'D-5');
    expect(game(days(1)).ddayLabel, 'D-1');
  });

  test('당일은 D-DAY다', () {
    // 오늘 안이면 시각이 지났어도 D-DAY다.
    expect(game(days(0)).ddayLabel, 'D-DAY');
  });

  test('지난 경기는 D+로 센다', () {
    expect(game(days(-3)).ddayLabel, 'D+3');
  });

  test('시작 시각을 모르면 null이다', () {
    // 화면이 각자 대체 문구를 고른다.
    expect(game(null).ddayLabel, isNull);
  });
}
