import 'package:flutter/material.dart';

import 'tokens.dart';

/// 시안이 쓰는 폰트 패밀리. `assets/fonts/`에 Pretendard 5종을 번들한다.
const kFontFamily = 'Pretendard';

/// 시안의 스코어 숫자는 `font-family: Impact, Pretendard, sans-serif`다.
/// iOS/Android에는 Impact가 없어 실제로는 Pretendard로 떨어지므로,
/// 가장 무거운 웨이트로 대신한다.
const kScoreFontWeight = FontWeight.w800;

ThemeData buildMhTheme(MhPalette palette) {
  final base = palette.isDark ? ThemeData.dark() : ThemeData.light();

  return base.copyWith(
    scaffoldBackgroundColor: palette.bg,
    canvasColor: palette.bg,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    extensions: [palette],
    colorScheme: base.colorScheme.copyWith(
      primary: MhColors.brand,
      surface: palette.card,
      onSurface: palette.text,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: kFontFamily,
      bodyColor: palette.text,
      displayColor: palette.text,
    ),
  );
}

extension MhThemeX on BuildContext {
  /// `context.mh.text` 처럼 시안의 `c.*`를 그대로 쓴다.
  MhPalette get mh => Theme.of(this).extension<MhPalette>() ?? MhPalette.dark;
}

/// 시안에서 반복되는 텍스트 스타일.
///
/// 시안은 px 단위 인라인 스타일이라 의미 있는 이름이 없다. 여기서는
/// `사이즈/웨이트` 조합에 쓰임새 이름을 붙여 재사용한다.
abstract final class MhText {
  static const _f = kFontFamily;

  /// 섹션 제목 — `16px/700`
  static TextStyle sectionTitle(Color c) => TextStyle(
        fontFamily: _f,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: c,
        height: 1.4,
      );

  /// 온보딩 큰 제목 — `24px/700`, line-height 40
  static TextStyle onboardTitle(Color c) => TextStyle(
        fontFamily: _f,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: c,
        height: 40 / 24,
      );

  /// 온보딩 질문 — `20px/700`, line-height 32
  static TextStyle onboardQuestion(Color c) => TextStyle(
        fontFamily: _f,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: c,
        height: 32 / 20,
      );

  /// 카드 안 팀 이름 — `14px/600`
  static TextStyle teamName(Color c) => TextStyle(
        fontFamily: _f,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: c,
        height: 1.4,
      );

  /// 스코어 — `36px`, Impact 대체
  static TextStyle score(Color c, {double size = 36}) => TextStyle(
        fontFamily: _f,
        fontSize: size,
        fontWeight: kScoreFontWeight,
        color: c,
        height: 1,
        letterSpacing: -0.5,
      );

  /// 메타/보조 — `12px/500`
  static TextStyle meta(Color c) => TextStyle(
        fontFamily: _f,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: c,
        height: 1.4,
      );

  /// 더 작은 보조 — `11px/400`
  static TextStyle caption(Color c) => TextStyle(
        fontFamily: _f,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: c,
        height: 1.45,
      );

  /// 칩/배지 — `10px/600`
  static TextStyle chip(Color c) => TextStyle(
        fontFamily: _f,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: c,
        height: 1.4,
      );

  static TextStyle custom({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: _f,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}
