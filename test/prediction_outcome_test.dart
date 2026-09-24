import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/models/game.dart';
import 'package:myhandball/domain/models/game_detail.dart';
import 'package:myhandball/domain/models/team.dart';

/// 예측 적중 판정.
///
/// MY의 적중률과 "예측 고수" 배지, 승부예측 탭의 기록이 **같은 규칙**을
/// 써야 한다. 한때 MY만 점수가 없는 경기를 0:0으로 봐서 "무승부" 예측을
/// 적중으로 셌다.
void main() {
  Game game({int? home, int? away, GameStatus status = GameStatus.finished}) =>
      Game(
        id: 'g1',
        home: const Team(name: 'SK호크스'),
        away: const Team(name: '두산'),
        status: status,
        meta: '11.09',
        scoreHome: home,
        scoreAway: away,
      );

  test('끝난 경기만 판정한다', () {
    final pre = PredictionOutcome.of(
        game(status: GameStatus.pre), PredictionPick.home);
    expect(pre.settled, isFalse);
    expect(pre.hit, isFalse);
  });

  test('점수가 없으면 끝난 경기라도 판정하지 않는다', () {
    // `?? 0`으로 0:0을 만들면 무승부 예측이 적중으로 세어진다.
    final outcome = PredictionOutcome.of(game(), PredictionPick.draw);
    expect(outcome.settled, isFalse);
    expect(outcome.hit, isFalse);
  });

  test('홈 승·원정 승·무승부를 가린다', () {
    final homeWin = game(home: 28, away: 26);
    expect(PredictionOutcome.of(homeWin, PredictionPick.home).hit, isTrue);
    expect(PredictionOutcome.of(homeWin, PredictionPick.away).hit, isFalse);

    final awayWin = game(home: 24, away: 30);
    expect(PredictionOutcome.of(awayWin, PredictionPick.away).hit, isTrue);

    final draw = game(home: 27, away: 27);
    expect(PredictionOutcome.of(draw, PredictionPick.draw).hit, isTrue);
    expect(PredictionOutcome.of(draw, PredictionPick.home).hit, isFalse);
  });

  test('한쪽 점수만 있으면 판정하지 않는다', () {
    final half = game(home: 28);
    expect(PredictionOutcome.of(half, PredictionPick.home).settled, isFalse);
  });
}
