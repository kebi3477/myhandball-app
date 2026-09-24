import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 시안의 인라인 SVG 아이콘.
///
/// 시안은 아이콘을 전부 24x24 viewBox의 인라인 SVG로 그린다. Material 아이콘으로
/// 대신하면 획 두께와 모서리 처리가 미묘하게 달라 보여서, **원본 path를 그대로**
/// 옮겼다. 색만 `ColorFilter`로 입히므로 문자열은 상수로 남아 캐시된다.
///
/// 탭바·검색·체크 아이콘은 더 일찍 옮겨서 `nav_icons.dart`의 `CustomPainter`로
/// 있다. 새로 옮기는 건 이쪽에 모은다.
abstract final class MhIcons {
  /// 관심 선수 하트 (채움).
  static const heartFilled =
      '<path d="M12 20.5s-7.4-4.5-9.3-9.1C1.3 8 3.4 4.8 6.7 4.8c2 0 3.3 1.1 4.3 2.4 1-1.3 2.3-2.4 4.3-2.4 3.3 0 5.4 3.2 4 6.6-1.9 4.6-9.3 9.1-9.3 9.1z" fill="#000" stroke="#000" stroke-width="1.8" stroke-linejoin="round"></path>';

  /// 일정 목록 뷰 토글
  static const list =
      '<path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01" stroke="#000" stroke-width="2.4" stroke-linecap="round"></path>';

  /// 일정 달력 뷰 토글
  static const calendar =
      '<rect x="3" y="5" width="18" height="16" rx="2" stroke="#000" stroke-width="2.2"></rect><path d="M3 10h18M8 3v4M16 3v4" stroke="#000" stroke-width="2.2" stroke-linecap="round"></path>';

  /// 캘린더에 추가 (달력 + 더하기)
  static const calPlus =
      '<rect x="3" y="5" width="18" height="16" rx="2" stroke="#000" stroke-width="2"></rect><path d="M3 10h18M8 3v4M16 3v4M12 13v5M9.5 15.5h5" stroke="#000" stroke-width="2" stroke-linecap="round"></path>';

  /// 설정 톱니
  static const gear =
      '<path d="M12 15.5C13.933 15.5 15.5 13.933 15.5 12C15.5 10.067 13.933 8.5 12 8.5C10.067 8.5 8.5 10.067 8.5 12C8.5 13.933 10.067 15.5 12 15.5Z" stroke="#000" stroke-width="1.6"></path><path d="M19.4 13.5C19.47 13 19.5 12.5 19.5 12C19.5 11.5 19.47 11 19.4 10.5L21.4 8.95C21.6 8.8 21.65 8.53 21.52 8.31L19.62 4.99C19.5 4.77 19.23 4.68 19 4.76L16.65 5.7C16.19 5.35 15.69 5.06 15.15 4.84L14.8 2.34C14.77 2.1 14.56 1.92 14.31 1.92H10.51C10.26 1.92 10.05 2.1 10.02 2.34L9.67 4.84C9.13 5.06 8.63 5.36 8.17 5.7L5.82 4.76C5.59 4.67 5.32 4.77 5.2 4.99L3.3 8.31C3.17 8.53 3.22 8.8 3.42 8.95L5.42 10.5C5.35 11 5.32 11.5 5.32 12C5.32 12.5 5.35 13 5.42 13.5L3.42 15.05C3.22 15.2 3.17 15.47 3.3 15.69L5.2 19.01C5.32 19.23 5.59 19.32 5.82 19.24L8.17 18.3C8.63 18.65 9.13 18.94 9.67 19.16L10.02 21.66C10.05 21.9 10.26 22.08 10.51 22.08H14.31C14.56 22.08 14.77 21.9 14.8 21.66L15.15 19.16C15.69 18.94 16.19 18.64 16.65 18.3L19 19.24C19.23 19.33 19.5 19.23 19.62 19.01L21.52 15.69C21.65 15.47 21.6 15.2 21.4 15.05L19.4 13.5Z" stroke="#000" stroke-width="1.6" stroke-linejoin="round"></path>';

  /// 경기장 위치 핀
  static const pin =
      '<path d="M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21z" stroke="#000" stroke-width="2" stroke-linejoin="round"></path><circle cx="12" cy="9.5" r="2.5" fill="#000"></circle>';

  /// 가이드 레슨 완료 체크
  static const checkThick =
      '<path d="M5 12.5l4.5 4.5L19 7.5" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"></path>';

  /// 가이드 잠긴 레슨
  static const lock =
      '<rect x="5" y="10.5" width="14" height="10" rx="2.5" fill="#000"></rect><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5" stroke="#000" stroke-width="2.4"></path>';

  /// 별
  static const star =
      '<path d="M12 3l2.6 5.5 6 .7-4.4 4.1 1.2 5.9L12 16.3 6.6 19.2l1.2-5.9L3.4 9.2l6-.7L12 3z" stroke="#000" stroke-width="1.7" stroke-linejoin="round"></path>';

  /// 아래 꺾쇠 (월 선택 칩)
  static const chevDown =
      '<path d="M6 9l6 6 6-6" stroke="#000" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"></path>';

  /// 왼쪽 꺾쇠
  static const chevLeft =
      '<path d="M15 5l-7 7 7 7" stroke="#000" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"></path>';

  /// 오른쪽 꺾쇠
  static const chevRight =
      '<path d="M9 5l7 7-7 7" stroke="#000" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"></path>';

  /// 선수 비교 배지
  static const shield =
      '<path d="M12 3l8.5 6.2-3.2 10H6.7L3.5 9.2z" stroke="#000" stroke-width="2" stroke-linejoin="round"></path><path d="M12 8l4 3-1.5 4.5h-5L8 11z" fill="#000"></path>';


  /// 검색 (입력창 안, stroke 2)
  static const searchSmall =
      '<circle cx="11" cy="11" r="7" stroke="#000" stroke-width="2"></circle>'
      '<path d="M16.5 16.5L21 21" stroke="#000" stroke-width="2" '
      'stroke-linecap="round"></path>';

  /// 검색 결과 없음 — 돋보기 안에 빼기.
  static const searchOff =
      '<circle cx="11" cy="11" r="7" stroke="#000" stroke-width="1.7"></circle>'
      '<path d="M16.5 16.5L21 21M8.5 11h5" stroke="#000" stroke-width="1.7" '
      'stroke-linecap="round"></path>';

  /// 승부 예측 안내. **시안에 대응 아이콘이 없다** — 직관 안내(핀)와 짝을
  /// 맞추려고 시안의 획 문법으로 그렸다.
  static const checkCircle =
      '<circle cx="12" cy="12" r="9" stroke="#000" stroke-width="1.8"></circle>'
      '<path d="M8.2 12.2l2.6 2.6 5-5.4" stroke="#000" stroke-width="2" '
      'stroke-linecap="round" stroke-linejoin="round"></path>';

  /// 서버 오류. 시안의 `errIconPath`는 잘린 스크립트에 있어 확인하지 못했다.
  /// 시안과 같은 획 문법(24x24, stroke 1.7~2, round cap)으로 맞춰 그린다.
  static const alert =
      '<path d="M12 8v5M12 16.5h.01M10.3 3.9L2.4 17.6A2 2 0 0 0 4.1 20.6h15.8'
      'a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z" stroke="#000" '
      'stroke-width="2" stroke-linecap="round" stroke-linejoin="round"></path>';

  /// 오프라인
  static const wifiOff =
      '<path d="M2 8.5a15 15 0 0 1 20 0M5.5 12a10 10 0 0 1 13 0M9 15.5a5 5 0 0 1 6 0M12 19h.01M3 3l18 18" stroke="#000" stroke-width="2" stroke-linecap="round"></path>';

  /// 응원글 `⋯` 메뉴. 시안은 r1.8 점 세 개다.
  static const more =
      '<circle cx="5" cy="12" r="1.8" fill="#000"></circle>'
      '<circle cx="12" cy="12" r="1.8" fill="#000"></circle>'
      '<circle cx="19" cy="12" r="1.8" fill="#000"></circle>';

  /// 삭제 — 휴지통.
  static const trash =
      '<path d="M4 7h16M10 4h4M9 7v12M15 7v12M6 7l1 13h10l1-13" stroke="#000" '
      'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"></path>';

  /// 신고 — 깃발.
  static const flag =
      '<path d="M5 21V4M5 5h12l-2.5 4L17 13H5" stroke="#000" '
      'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"></path>';

  /// 차단 — 금지.
  static const ban =
      '<circle cx="12" cy="12" r="8.5" stroke="#000" stroke-width="1.8"></circle>'
      '<path d="M6.2 6.2l11.6 11.6" stroke="#000" stroke-width="1.8" '
      'stroke-linecap="round"></path>';

  /// 관심 선수 하트 (테두리). 시안은 같은 path에 fill만 none이다.
  static const heart =
      '<path d="M12 20.5s-7.4-4.5-9.3-9.1C1.3 8 3.4 4.8 6.7 4.8c2 0 3.3 1.1 4.3 2.4 1-1.3 2.3-2.4 4.3-2.4 3.3 0 5.4 3.2 4 6.6-1.9 4.6-9.3 9.1-9.3 9.1z" fill="none" stroke="#000" stroke-width="1.8" stroke-linejoin="round"></path>';
}

/// [MhIcons]의 path를 그린다.
class MhIcon extends StatelessWidget {
  const MhIcon(
    this.icon, {
    super.key,
    required this.size,
    required this.color,
  });

  final String icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // **Center가 꼭 있어야 한다.** `SizedBox(width: 48, height: 36, child: ...)`
    // 처럼 부모가 크기를 꽉 조이면 SvgPicture는 자기 width/height를 버리고
    // 그 크기로 늘어난다 — 18로 부른 아이콘이 36으로 그려진다.
    // Center가 tight 제약을 loose로 바꿔 주므로 안쪽 SizedBox가 size를 지킨다.
    // Material의 `Icon`은 글리프라 이 문제가 없어서, 갈아끼운 뒤에야 드러났다.
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.string(
          '<svg xmlns="http://www.w3.org/2000/svg" width="$size" '
          'height="$size" viewBox="0 0 24 24" fill="none">$icon</svg>',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}

/// 가이드 수료 메달. 시안 60x72 SVG를 그대로 쓴다.
///
/// 색이 여러 개라 [MhIcon]처럼 한 색으로 칠할 수 없어 따로 둔다.
/// 메달 색 한 벌.
class MhMedalColors {
  const MhMedalColors({
    required this.ribbonLeft,
    required this.ribbonRight,
    required this.rim,
    required this.outer,
    required this.inner,
    this.glyphStrokeWidth = 0,
  });

  /// 가이드 화면 메달의 금색 한 벌.
  static const gold = MhMedalColors(
    ribbonLeft: '#0050C8',
    ribbonRight: '#0068FF',
    rim: '#D9A400',
    outer: '#FFC800',
    inner: '#FFD43B',
  );

  final String ribbonLeft;
  final String ribbonRight;

  /// 바깥 원의 테두리.
  final String rim;

  /// 바깥 원 / 안쪽 원.
  final String outer;
  final String inner;

  /// 0이면 문양을 흰색으로 채우고, 값이 있으면 그 두께의 흰 선으로 그린다.
  final double glyphStrokeWidth;
}

/// 리본 달린 메달. 가이드 수료와 MY 배지가 같이 쓴다.
class MhMedal extends StatelessWidget {
  const MhMedal({
    super.key,
    this.size = 44,
    this.glyph = star,
    this.colors = MhMedalColors.gold,
    this.arcs = true,
  });

  final double size;

  /// 메달 안에 그릴 문양. 좌표계는 `0 0 60 72`, 안쪽 원의 중심이 (30, 28)이다.
  final String glyph;

  final MhMedalColors colors;

  /// 원을 가로지르는 곡선 장식 두 줄.
  ///
  /// **MY의 "내 배지"에는 없다.** 시안에서 가이드 경로·완료 화면의 메달에만
  /// 그려져 있다. 기본값이 `true`인 건 가이드 쪽이 원래 그랬기 때문이다.
  final bool arcs;

  /// 기본 문양 — 수료 메달의 별.
  static const star =
      'M30 17 l3.2 6.6 7.2.9-5.3 5 1.4 7.1-6.5-3.6-6.5 3.6 1.4-7.1-5.3-5 7.2-.9z';

  String get _glyphPath {
    final filled = colors.glyphStrokeWidth == 0;
    return '<path d="$glyph" fill="${filled ? '#fff' : 'none'}" '
        'stroke="${filled ? colors.rim : '#fff'}" '
        'stroke-width="${filled ? 1.2 : colors.glyphStrokeWidth}" '
        'stroke-linecap="round" stroke-linejoin="round"/>';
  }

  String get _body =>
      '<path d="M18 40 L10 70 L22 64 L28 72 L32 44 Z" fill="${colors.ribbonLeft}"/>'
      '<path d="M42 40 L50 70 L38 64 L32 72 L28 44 Z" fill="${colors.ribbonRight}"/>'
      '<circle cx="30" cy="28" r="26" fill="${colors.outer}" '
      'stroke="${colors.rim}" stroke-width="3"/>'
      '<circle cx="30" cy="28" r="19" fill="${colors.inner}"/>'
      '${arcs ? _arcs : ''}$_glyphPath';

  static const _arcs =
      '<path d="M13 25 C22 31, 38 31, 47 25" stroke="#E0A800" stroke-width="2.5" fill="none" stroke-linecap="round"/>'
      '<path d="M30 9 C24 18, 24 38, 30 47" stroke="#E0A800" stroke-width="2.5" fill="none" stroke-linecap="round"/>';

  @override
  Widget build(BuildContext context) {
    // [MhIcon]과 같은 이유로 Center + SizedBox로 크기를 지킨다.
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: size,
        height: size * 72 / 60,
        child: SvgPicture.string(
          '<svg xmlns="http://www.w3.org/2000/svg" width="$size" '
          'height="${size * 72 / 60}" viewBox="0 0 60 72">$_body</svg>',
          width: size,
          height: size * 72 / 60,
        ),
      ),
    );
  }
}
