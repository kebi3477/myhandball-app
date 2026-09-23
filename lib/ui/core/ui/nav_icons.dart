import 'package:flutter/material.dart';

/// 시안 하단 탭바의 아이콘 4종.
///
/// `MyHandball v2.dc.html`의 인라인 SVG(24x24 viewBox)를 그대로 옮겼다.
/// 홈·일정 아이콘은 내부를 배경색으로 파내는 구조라 `bg`를 함께 받는다.
enum MhNavIcon { home, schedule, stat, my }

class MhNavIconPainter extends CustomPainter {
  const MhNavIconPainter({
    required this.icon,
    required this.color,
    required this.bg,
  });

  final MhNavIcon icon;
  final Color color;
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    // 원본 viewBox는 24x24.
    canvas.scale(size.width / 24, size.height / 24);
    final fg = Paint()..color = color;
    final cut = Paint()..color = bg;

    switch (icon) {
      case MhNavIcon.home:
        // M22 8V22H2V8L12 1L22 8Z
        final roof = Path()
          ..moveTo(22, 8)
          ..lineTo(22, 22)
          ..lineTo(2, 22)
          ..lineTo(2, 8)
          ..lineTo(12, 1)
          ..close();
        canvas.drawPath(roof, fg);
        // M10 22V15C10 13.9 10.9 13 12 13C13.1 13 14 13.9 14 15V22
        final door = Path()
          ..moveTo(10, 22)
          ..lineTo(10, 15)
          ..cubicTo(10, 13.9, 10.9, 13, 12, 13)
          ..cubicTo(13.1, 13, 14, 13.9, 14, 15)
          ..lineTo(14, 22)
          ..close();
        canvas.drawPath(door, cut);

      case MhNavIcon.schedule:
        // 본체 M21 8H3V23H21V8Z
        canvas.drawRect(const Rect.fromLTWH(3, 8, 18, 15), fg);
        // 고리 두 개 M6 4V0 / M17 4V0 (stroke-width 2)
        final ring = Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(const Offset(6, 4), const Offset(6, 0), ring);
        canvas.drawLine(const Offset(17, 4), const Offset(17, 0), ring);
        // 상단 바 — 좌우 끝이 완전히 둥근 pill
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 4, 24, 4),
            const Radius.circular(2),
          ),
          fg,
        );
        // 배경색으로 파낸 두 줄
        canvas.drawRect(const Rect.fromLTWH(6, 11, 12, 2), cut);
        canvas.drawRect(const Rect.fromLTWH(6, 15, 9, 2), cut);

      case MhNavIcon.stat:
        for (final r in const [
          Rect.fromLTWH(3, 12, 4, 9),
          Rect.fromLTWH(10, 6, 4, 15),
          Rect.fromLTWH(17, 2, 4, 19),
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(1)),
            fg,
          );
        }

      case MhNavIcon.my:
        canvas.drawCircle(const Offset(12, 8), 4, fg);
        // M4 21C4 16.5817 7.58172 13 12 13C16.4183 13 20 16.5817 20 21
        final body = Path()
          ..moveTo(4, 21)
          ..cubicTo(4, 16.5817, 7.58172, 13, 12, 13)
          ..cubicTo(16.4183, 13, 20, 16.5817, 20, 21)
          ..close();
        canvas.drawPath(body, fg);
    }
  }

  @override
  bool shouldRepaint(MhNavIconPainter old) =>
      old.icon != icon || old.color != color || old.bg != bg;
}

/// 헤더 검색 아이콘 — `circle(11,11,r7) + M16.5 16.5L21 21`, stroke 1.8
class MhSearchIconPainter extends CustomPainter {
  const MhSearchIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(11, 11), 7, p);
    canvas.drawLine(const Offset(16.5, 16.5), const Offset(21, 21), p);
  }

  @override
  bool shouldRepaint(MhSearchIconPainter old) => old.color != color;
}

/// 팀 선택 체크 — `M1 2.5L4.5 6L10 1`, stroke 2, 11x7 viewBox
class MhCheckIconPainter extends CustomPainter {
  const MhCheckIconPainter({this.color = Colors.white});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 11, size.height / 7);
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(1, 2.5)
        ..lineTo(4.5, 6)
        ..lineTo(10, 1),
      p,
    );
  }

  @override
  bool shouldRepaint(MhCheckIconPainter old) => old.color != color;
}

/// 온보딩 뒤로가기 — `M15 18L9 12L15 6`, stroke 2
class MhChevronLeftPainter extends CustomPainter {
  const MhChevronLeftPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(15, 18)
        ..lineTo(9, 12)
        ..lineTo(15, 6),
      p,
    );
  }

  @override
  bool shouldRepaint(MhChevronLeftPainter old) => old.color != color;
}
