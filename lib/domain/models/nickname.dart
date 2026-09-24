/// 시안 온보딩 5스텝·MY 프로필의 닉네임 규칙.
///
/// 시안의 placeholder가 `2~10자 · 한글, 영문, 숫자`다. 검사를 온보딩과 MY
/// 두 군데에서 하므로 규칙을 여기 한 곳에 둔다 — 한쪽만 고치면 온보딩은
/// 통과했는데 MY에서는 저장이 안 되는 상태가 된다.
///
/// **서버도 같은 값을 검사한다** (`PUT /api/profile` — 2자 미만 400,
/// 공백·특수문자 400, 중복 409). 여기서 통과시킨 값이 서버에서 막히면
/// 사용자는 이유 없이 거절당한 것처럼 보이므로 규칙을 맞춰 둔다.
/// **중복만은 여기서 알 수 없다** — 서버의 409를 받아 문구로 바꾼다.
abstract final class Nickname {
  static const minLength = 2;
  static const maxLength = 10;

  /// 완성형 한글, 영문, 숫자만. 공백·이모지·특수문자는 막는다.
  ///
  /// **자음·모음 단독(`ㄱ`, `ㅏ`)은 뺀다.** 시안이 `공백·자음 단독 불가`로
  /// 적어 뒀고, 서버도 완성형만 받는다.
  static final _allowed = RegExp(r'^[가-힣a-zA-Z0-9]+$');

  /// 시안 `NICK_BANNED` — 운영자를 사칭하는 이름.
  static const banned = ['운영자', '관리자', 'admin', '핸드볼연맹', '마이핸드볼'];

  static bool _isBanned(String value) {
    final lower = value.toLowerCase();
    return banned.any((w) => lower.contains(w.toLowerCase()));
  }

  /// 입력값을 저장 형태로 다듬는다. 앞뒤 공백만 떼고 대소문자는 그대로 둔다.
  static String normalize(String raw) => raw.trim();

  /// 통과하면 `null`, 아니면 사용자에게 보여줄 한 줄.
  ///
  /// 빈 값은 "아직 안 썼다"는 뜻이라 오류 문구를 내지 않는다. 버튼이
  /// 흐려져 있는 것으로 충분하고, 첫 글자를 치기도 전에 빨간 글씨가 뜨면
  /// 혼난 것처럼 보인다.
  static String? validate(String raw) {
    final value = normalize(raw);
    if (value.isEmpty) return null;
    if (value.characters < minLength) return '$minLength자 이상 입력해 주세요';
    if (value.characters > maxLength) return '$maxLength자까지 쓸 수 있어요';
    if (!_allowed.hasMatch(value)) return '한글, 영문, 숫자만 쓸 수 있어요';
    if (_isBanned(value)) return '사용할 수 없는 단어가 들어 있어요';
    return null;
  }

  static bool isValid(String raw) {
    final value = normalize(raw);
    return value.isNotEmpty &&
        value.characters >= minLength &&
        value.characters <= maxLength &&
        _allowed.hasMatch(value) &&
        !_isBanned(value);
  }

  /// 시안의 "추천" 버튼. 형용사 + 명사 + 두 자리 숫자.
  ///
  /// 서버에 물어보지 않으므로 이미 쓰는 이름이 나올 수 있다. 숫자를 붙이는
  /// 건 그 확률을 낮추려는 것이고, 중복 자체는 저장할 때 409로 걸러진다.
  static String suggest([int? seed]) {
    final n = seed ?? DateTime.now().microsecondsSinceEpoch;
    final adjective = _adjectives[n % _adjectives.length];
    final noun = _nouns[(n ~/ _adjectives.length) % _nouns.length];
    final number = (n ~/ 7) % 100;
    final candidate = '$adjective$noun$number';
    // 조합이 10자를 넘으면 숫자를 뗀다. 규칙을 어기는 추천은 내지 않는다.
    return isValid(candidate) ? candidate : '$adjective$noun';
  }

  static const _adjectives = [
    '날쌘',
    '든든한',
    '용감한',
    '조용한',
    '성실한',
    '유쾌한',
    '진심인',
    '따뜻한',
  ];

  static const _nouns = [
    '피벗',
    '윙어',
    '골키퍼',
    '백코트',
    '관중',
    '응원단',
    '해설가',
    '단골',
  ];
}

extension on String {
  /// 한글 한 글자를 1로 센다. `length`는 UTF-16 단위라 이모지에서 어긋나는데,
  /// 이모지는 [Nickname._allowed]가 막으므로 여기서는 결과가 같다 —
  /// 그래도 세는 의도를 이름으로 남겨 둔다.
  int get characters => runes.length;
}
