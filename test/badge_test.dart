import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/models/badge.dart';

/// 배지는 기기에 쌓인 값으로 센다. 조건이 틀리면 못 딴 배지가 켜지거나
/// 딴 배지가 안 켜지는데, 화면만 봐서는 규칙이 틀린 건지 데이터가 없는
/// 건지 구분이 안 된다.
void main() {
  List<MhBadge> evaluate({
    int guideDone = 0,
    int attended = 0,
    int venues = 0,
    int hits = 0,
  }) =>
      MhBadges.evaluate(
        guideDone: guideDone,
        attended: attended,
        venues: venues,
        predictionHits: hits,
      );

  MhBadge find(List<MhBadge> badges, String id) =>
      badges.firstWhere((b) => b.spec.id == id);

  test('아무것도 안 했으면 하나도 없다', () {
    final badges = evaluate();
    expect(badges.every((b) => !b.earned), isTrue);
    expect(MhBadges.countLabel(badges), '0/${badges.length}');
  });

  test('가이드를 다 끝내야 수료 배지가 켜진다', () {
    expect(find(evaluate(guideDone: 4), 'guide').earned, isFalse);
    expect(find(evaluate(guideDone: 5), 'guide').earned, isTrue);
  });

  test('직관 1경기는 첫 직관만, 5경기면 둘 다 켜진다', () {
    final one = evaluate(attended: 1);
    expect(find(one, 'first_attend').earned, isTrue);
    expect(find(one, 'attend_5').earned, isFalse);

    final five = evaluate(attended: 5);
    expect(find(five, 'first_attend').earned, isTrue);
    expect(find(five, 'attend_5').earned, isTrue);
  });

  test('못 딴 배지는 진행도를 분수로 보여준다', () {
    expect(find(evaluate(guideDone: 3), 'guide').subtitle, '3/5 레슨');
    expect(find(evaluate(guideDone: 3), 'guide').ratio, closeTo(0.6, 0.001));
  });

  test('딴 배지는 분수 대신 문구를 보여준다', () {
    expect(find(evaluate(guideDone: 5), 'guide').subtitle, '수료 완료');
  });

  test('목표를 넘어도 진행바가 1을 안 넘는다', () {
    // 적중 25회여도 막대가 튀어나오면 안 된다.
    expect(find(evaluate(hits: 25), 'hit_10').ratio, 1.0);
  });

  test('경기장은 중복을 뺀 곳 수로 센다', () {
    // 같은 곳을 열 번 가도 1곳이다 — 호출부가 Set으로 넘긴다.
    expect(find(evaluate(venues: 2), 'venue_3').earned, isFalse);
    expect(find(evaluate(venues: 3), 'venue_3').earned, isTrue);
  });
}
