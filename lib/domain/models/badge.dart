import 'package:flutter/material.dart';

/// MY "내 배지"의 배지 종류. **순서가 화면 순서다.**
enum MhBadgeKind {
  winFairy('승리 요정', MhBadgeTarget.attendance),
  predictor('예측 고수', MhBadgeTarget.prediction),
  graduate('입문 수료', MhBadgeTarget.guide);

  const MhBadgeKind(this.label, this.target);

  final String label;

  /// 카드를 눌렀을 때 갈 곳.
  final MhBadgeTarget target;

  MhBadgeStyle get style => switch (this) {
        MhBadgeKind.winFairy => MhBadgeStyle.winFairy,
        MhBadgeKind.predictor => MhBadgeStyle.predictor,
        MhBadgeKind.graduate => MhBadgeStyle.graduate,
      };
}

enum MhBadgeTarget { attendance, prediction, guide }

/// 배지 한 종류의 색과 문양.
///
/// 메달은 **원 2겹(바깥 r26 + 테두리 3, 안쪽 r19) + 리본 2개 + 가운데 문양**
/// 이다. 가이드 화면 메달에 있는 곡선 장식은 배지에 없다.
class MhBadgeStyle {
  const MhBadgeStyle({
    required this.coin,
    required this.inner,
    required this.rim,
    required this.ribbonLeft,
    required this.ribbonRight,
    required this.cardBg,
    required this.nameColor,
    required this.accent,
    required this.glyph,
    this.glyphStrokeWidth = 0,
  });

  /// 바깥 원과 그 테두리, 안쪽 원. SVG에 그대로 넣는 문자열이다.
  final String coin;
  final String inner;
  final String rim;
  final String ribbonLeft;
  final String ribbonRight;

  /// 획득했을 때의 카드 배경·이름색.
  final Color cardBg;
  final Color nameColor;

  /// 진행바 채움에 쓰는 대표색.
  final Color accent;

  /// 메달 가운데 문양. 좌표계는 `0 0 60 72`, 안쪽 원의 중심이 (30, 28)이다.
  final String glyph;

  /// 0이면 채워 그리고(하트·별), 값이 있으면 선으로만 그린다(체크).
  final double glyphStrokeWidth;

  bool get glyphFilled => glyphStrokeWidth == 0;

  static const _heart =
      'M30 38.4c-6.8-4.5-10.4-8.3-10.4-12.2a5.4 5.4 0 019.6-3.4l.8 1 .8-1a5.4 '
      '5.4 0 019.6 3.4c0 3.9-3.6 7.7-10.4 12.2z';
  static const _check = 'M21 28l6.5 6.5L40 21';
  static const _star =
      'M30 17 l3.2 6.6 7.2.9-5.3 5 1.4 7.1-6.5-3.6-6.5 3.6 1.4-7.1-5.3-5 7.2-.9z';

  static const winFairy = MhBadgeStyle(
    coin: '#FF7FA6',
    inner: '#FF9DBB',
    rim: '#D63D72',
    ribbonLeft: '#C2185B',
    ribbonRight: '#E5487D',
    cardBg: Color(0xFFFFE6EE),
    nameColor: Color(0xFF8A1C45),
    accent: Color(0xFFE5487D),
    glyph: _heart,
  );

  static const predictor = MhBadgeStyle(
    coin: '#0068FF',
    inner: '#3D8BFF',
    rim: '#0050C8',
    ribbonLeft: '#003C99',
    ribbonRight: '#0050C8',
    cardBg: Color(0xFFE3EEFF),
    nameColor: Color(0xFF00347F),
    accent: Color(0xFF0068FF),
    glyph: _check,
    glyphStrokeWidth: 4.5,
  );

  static const graduate = MhBadgeStyle(
    coin: '#FFC800',
    inner: '#FFD43B',
    rim: '#D9A400',
    ribbonLeft: '#0050C8',
    ribbonRight: '#0068FF',
    cardBg: Color(0xFFFFF4CC),
    nameColor: Color(0xFF6B4500),
    accent: Color(0xFFFFC800),
    glyph: _star,
  );
}

/// 배지 하나의 지금 상태. `BadgeService`가 만든다.
class MhBadge {
  const MhBadge({
    required this.kind,
    required this.earned,
    required this.ratio,
    required this.subtitle,
  });

  final MhBadgeKind kind;
  final bool earned;

  /// 진행바 비율. 0~1.
  final double ratio;

  /// 이름 밑 한 줄. 획득 전후 문구가 다르다.
  final String subtitle;

  String get name => kind.label;
  MhBadgeStyle get style => kind.style;

  /// 헤더 오른쪽의 `1/3 획득`.
  static String countLabel(List<MhBadge> badges) =>
      '${badges.where((b) => b.earned).length}/${badges.length} 획득';
}
