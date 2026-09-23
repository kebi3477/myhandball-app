import 'package:flutter/material.dart';

/// 시안의 `c.*` 테마 객체를 그대로 옮긴 팔레트.
///
/// 키 이름은 `MyHandball v2.dc.html`에서 쓰는 것과 1:1로 맞춘다
/// (bg / card / border / borderSubtle / text / textSub / textMuted /
///  textFaint / textNeutral / statusText / statusBorder).
@immutable
class MhPalette extends ThemeExtension<MhPalette> {
  const MhPalette({
    required this.bg,
    required this.card,
    required this.border,
    required this.borderSubtle,
    required this.text,
    required this.textSub,
    required this.textMuted,
    required this.textFaint,
    required this.textNeutral,
    required this.isDark,
  });

  final Color bg;
  final Color card;
  final Color border;
  final Color borderSubtle;
  final Color text;
  final Color textSub;
  final Color textMuted;
  final Color textFaint;
  final Color textNeutral;
  final bool isDark;

  /// 시안 기본값. `theme: 'dark'`로 시작한다.
  static const dark = MhPalette(
    bg: Color(0xFF111111),
    card: Color(0xFF222222),
    border: Color(0xFF333333),
    borderSubtle: Color(0xFF2A2A2A),
    text: Color(0xFFFFFFFF),
    textSub: Color(0xFF808080),
    textMuted: Color(0xFF7C7C7C),
    textFaint: Color(0xFF6D6D6D),
    textNeutral: Color(0xFFAFAFAF),
    isDark: true,
  );

  static const light = MhPalette(
    bg: Color(0xFFFFFFFF),
    card: Color(0xFFF7F8FA),
    border: Color(0xFFEBEBEB),
    borderSubtle: Color(0xFFF2F2F2),
    text: Color(0xFF111111),
    textSub: Color(0xFF6D6D6D),
    textMuted: Color(0xFF7C7C7C),
    textFaint: Color(0xFFAFAFAF),
    textNeutral: Color(0xFF494949),
    isDark: false,
  );

  @override
  MhPalette copyWith({
    Color? bg,
    Color? card,
    Color? border,
    Color? borderSubtle,
    Color? text,
    Color? textSub,
    Color? textMuted,
    Color? textFaint,
    Color? textNeutral,
    bool? isDark,
  }) {
    return MhPalette(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      text: text ?? this.text,
      textSub: textSub ?? this.textSub,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      textNeutral: textNeutral ?? this.textNeutral,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  MhPalette lerp(ThemeExtension<MhPalette>? other, double t) {
    if (other is! MhPalette) return this;
    return MhPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSub: Color.lerp(textSub, other.textSub, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      textNeutral: Color.lerp(textNeutral, other.textNeutral, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// 테마와 무관하게 고정인 브랜드 색.
abstract final class MhColors {
  static const brand = Color(0xFF0068FF);

  /// 가이드 배너의 아래쪽 하드 섀도 (`box-shadow: 0 4px 0 #0050C8`).
  static const brandShadow = Color(0xFF0050C8);

  /// 온보딩 카드 배경 — 다크 전용 리터럴.
  static const onboardCard = Color(0xFF222222);
  static const onboardBorder = Color(0xFF333333);
  static const onboardTrack = Color(0xFF333333);

  /// 가이드 배너 마스코트/진행바.
  static const guideYellow = Color(0xFFFFD43B);

  static const live = Color(0xFFFF3B30);
  static const closed = Color(0xFF8A8A8A);
  static const offlineBar = Color(0xFF3A3A3A);

  /// 팀 로고 배지는 라이트/다크 모두 흰 바탕이다.
  static const logoBg = Color(0xFFFFFFFF);
}

/// `figassets/fig-tokens.css`의 spacing 스케일.
abstract final class MhSpacing {
  static const xs2 = 4.0;
  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 32.0;
  static const xl = 40.0;

  /// 화면 좌우 기본 거터. 시안 전역이 `padding: 0 24px`.
  static const gutter = 24.0;
}

abstract final class MhRadius {
  static const card = 20.0;
  static const chip = 16.0;
  static const pill = 40.0;
  static const button = 10.0;
  static const listItem = 18.0;
}

abstract final class MhSizes {
  /// 시안 하단 탭바 높이 (safe area 별도).
  static const navBar = 84.0;
  static const navItem = 68.0;
  static const header = 66.0;
}
