/// 천 단위 쉼표. `1234` → `1,234`
///
/// 시안이 `toLocaleString()`으로 찍는 자리에 쓴다. `intl`을 넣지 않은 건
/// 이 한 가지 때문이고, 두 군데(MVP 총 투표 수·랭킹 참여자 수)에서 쓰므로
/// 한 곳에 둔다.
String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
