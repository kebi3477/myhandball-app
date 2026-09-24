import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/models/nickname.dart';

/// 닉네임 규칙은 온보딩과 MY 두 군데에서 쓴다. 한쪽만 통과하는 값이
/// 생기면 "온보딩은 됐는데 저장이 안 되는" 상태가 된다.
void main() {
  test('한글 두 글자부터 통과한다', () {
    expect(Nickname.isValid('가'), isFalse);
    expect(Nickname.isValid('호크'), isTrue);
  });

  test('한글은 한 글자를 1로 센다', () {
    // 열 글자는 되고 열한 글자는 안 된다. `length`(UTF-16)로 세면
    // 경계가 어긋난다.
    expect(Nickname.isValid('가나다라마바사아자차'), isTrue);
    expect(Nickname.isValid('가나다라마바사아자차카'), isFalse);
  });

  test('공백·특수문자·이모지는 막는다', () {
    expect(Nickname.isValid('호크 스'), isFalse);
    expect(Nickname.isValid('호크스!'), isFalse);
    expect(Nickname.isValid('호크스🏐'), isFalse);
  });

  test('영문·숫자 조합은 통과한다', () {
    expect(Nickname.isValid('SK2026'), isTrue);
  });

  test('앞뒤 공백은 떼고 본다', () {
    expect(Nickname.normalize('  호크스 '), '호크스');
    expect(Nickname.isValid('  호크스 '), isTrue);
  });

  test('빈 값에는 오류 문구를 내지 않는다', () {
    // 첫 글자를 치기도 전에 빨간 글씨가 뜨면 혼난 것처럼 보인다.
    expect(Nickname.validate(''), isNull);
    expect(Nickname.validate('가'), isNotNull);
  });

  test('추천은 항상 규칙을 통과한다', () {
    for (var seed = 0; seed < 200; seed++) {
      final value = Nickname.suggest(seed);
      expect(Nickname.isValid(value), isTrue, reason: '$seed → $value');
    }
  });
}
