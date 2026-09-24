import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/models/prediction.dart';

LeaderboardRow _row(int rank, {bool isMe = false, double rate = 70}) =>
    LeaderboardRow(
      rank: rank,
      nickname: '유저$rank',
      teamName: 'SK호크스',
      settled: 12,
      hits: 9,
      rate: rate,
      isMe: isMe,
    );

void main() {
  test('적중률이 정수면 소수점을 떼고 쓴다', () {
    // 서버는 `54.5`처럼 소수를 준다. `70.0%`로 찍히면 안 된다.
    expect(_row(1, rate: 70).rateLabel, '70%');
    expect(_row(1, rate: 54.5).rateLabel, '54.5%');
  });

  test('내 줄이 목록에 있으면 아래에 또 붙이지 않는다', () {
    // 서버는 내가 rows 안에 있어도 me를 채워 준다. 그대로 그리면
    // 같은 줄이 두 번 나온다.
    final board = Leaderboard(
      scope: LeaderboardScope.all,
      minSettled: 10,
      total: 3,
      rows: [_row(1), _row(2, isMe: true), _row(3)],
      me: _row(2, isMe: true),
      meTopPercent: 67,
    );
    expect(board.pinsMe, isFalse);
  });

  test('내 줄이 10위 밖이면 따로 붙인다', () {
    final board = Leaderboard(
      scope: LeaderboardScope.all,
      minSettled: 10,
      total: 140,
      rows: [_row(1), _row(2)],
      me: _row(38, isMe: true),
      meTopPercent: 28,
    );
    expect(board.pinsMe, isTrue);
    expect(board.myRankLabel, '38위');
    expect(board.myRankSub, '전체 상위 28%');
  });

  test('랭킹 밖이면 등수를 지어내지 않는다', () {
    const board = Leaderboard.empty();
    expect(board.myRankLabel, '-');
    expect(board.myRankSub, '랭킹 밖');
  });

  test('참여자 수에 천 단위 쉼표를 넣는다', () {
    const board = Leaderboard(
      scope: LeaderboardScope.all,
      minSettled: 10,
      total: 1240,
      rows: [],
    );
    expect(board.totalLabel, '1,240');
  });

  test('확정 경기가 없으면 적중률이 -다', () {
    // 0/0을 0%로 쓰면 "다 틀렸다"로 읽힌다.
    const mine = MyPredictions.empty();
    expect(mine.rateLabel, '-');

    const waiting =
        MyPredictions(count: 3, settled: 0, hits: 0, rate: 0, items: []);
    expect(waiting.rateLabel, '-');
  });

  test('예측 한 줄의 칩은 확정 여부부터 본다', () {
    const pending = MyPredictionItem(
      matchSeq: 1,
      homeName: 'SK호크스',
      awayName: '두산',
      pick: 'home',
      settled: false,
      hit: false,
    );
    expect(pending.chipLabel, '대기');
    expect(pending.pickLabel, 'SK호크스 승');
    expect(pending.matchLabel, 'SK호크스 vs 두산');
  });
}
