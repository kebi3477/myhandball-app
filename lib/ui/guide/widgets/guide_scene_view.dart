import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/guide_lesson.dart';
import '../../core/themes/theme.dart';

/// 레슨 스텝의 삽화.
///
/// 시안은 씬마다 320x180 인라인 SVG에 `@keyframes`를 걸어 둔다
/// (`ghHop`, `ghRing`, `ghShot7`, `ghSave`, `ghCard`, `ghBench` 등).
/// 여기서는 같은 타이밍과 같은 움직임을 `CustomPainter`로 다시 그린다 —
/// **벡터 아트 자체는 단순화했다.** 원본 그대로 쓰려면 씬별 SVG를
/// 디자인 파일에서 추출해 `flutter_svg` + 애니메이션으로 바꿔야 한다.
class GuideSceneView extends StatefulWidget {
  const GuideSceneView({super.key, required this.scene});

  final GuideScene scene;

  /// 시안 삽화 박스: 배경 #F4F8FF, 테두리 2px #DCE8FF, radius 20.
  static const boxBackground = Color(0xFFF4F8FF);
  static const boxBorder = Color(0xFFDCE8FF);
  static const courtFill = Color(0xFFDCE8FF);

  @override
  State<GuideSceneView> createState() => _GuideSceneViewState();
}

class _GuideSceneViewState extends State<GuideSceneView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _durationFor(widget.scene),
  )..repeat();

  static Duration _durationFor(GuideScene scene) => switch (scene) {
        // 시안 keyframe 길이를 그대로 따른다.
        GuideScene.steps3 => const Duration(seconds: 3),
        GuideScene.sec3 => const Duration(seconds: 3),
        GuideScene.seven => const Duration(milliseconds: 2400),
        GuideScene.goalkeeper => const Duration(milliseconds: 2400),
        GuideScene.cards => const Duration(milliseconds: 2200),
        GuideScene.twoMinutes => const Duration(milliseconds: 2600),
        GuideScene.win => const Duration(milliseconds: 2600),
        _ => const Duration(milliseconds: 2000),
      };

  @override
  void didUpdateWidget(GuideSceneView old) {
    super.didUpdateWidget(old);
    if (old.scene != widget.scene) {
      _c
        ..duration = _durationFor(widget.scene)
        ..forward(from: 0)
        ..repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GuideSceneView.boxBackground,
        border: Border.all(color: GuideSceneView.boxBorder, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AspectRatio(
        aspectRatio: 320 / 180,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _ScenePainter(scene: widget.scene, t: _c.value),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.scene, required this.t});

  final GuideScene scene;

  /// 0~1 반복.
  final double t;

  static const _brand = Color(0xFF0068FF);
  static const _ball = Color(0xFFFFD43B);
  static const _ink = Color(0xFF111111);
  static const _red = Color(0xFFE5484D);
  static const _yellow = Color(0xFFFFC800);

  @override
  void paint(Canvas canvas, Size size) {
    // 원본 SVG와 같은 320x180 좌표계에서 그린다.
    canvas.scale(size.width / 320, size.height / 180);
    switch (scene) {
      case GuideScene.intro:
        _court(canvas);
        _team(canvas, left: true, color: _brand);
        _team(canvas, left: false, color: const Color(0xFFFF7A45));
        _label(canvas, '7 vs 7', const Offset(160, 168));
      case GuideScene.time:
        _text(canvas, '30 + 30', const Offset(160, 60), 40, FontWeight.w900);
        _text(canvas, '전반 · 후반', const Offset(160, 96), 16, FontWeight.w700,
            color: _brand);
        _progress(canvas, 30, 118, 260, t);
        _label(canvas, '쉬는 시간 10분', const Offset(160, 156));
      case GuideScene.win:
        _court(canvas);
        _goal(canvas, right: true);
        // ghShotWin: 0~55% 이동, 이후 사라짐
        final p = (t / 0.55).clamp(0.0, 1.0);
        if (t < 0.56) {
          canvas.drawCircle(Offset(90 + 172 * p, 92), 9, Paint()..color = _ball);
        } else {
          _text(canvas, 'GOAL!', const Offset(160, 60), 30, FontWeight.w900,
              color: _brand);
        }
      case GuideScene.court:
        _court(canvas);
        _goalArea(canvas);
        // ghZone: 반투명 구역이 깜빡인다
        final alpha = 0.35 + 0.5 * (0.5 - 0.5 * math.cos(2 * math.pi * t));
        canvas.drawPath(
          _areaPath(),
          Paint()..color = _brand.withValues(alpha: alpha * 0.45),
        );
        _label(canvas, '6m · 골키퍼만', const Offset(160, 168));
      case GuideScene.positions:
        _court(canvas);
        const spots = {
          'LW': Offset(60, 44),
          'LB': Offset(110, 62),
          'CB': Offset(160, 92),
          'RB': Offset(110, 122),
          'RW': Offset(60, 140),
          'PV': Offset(212, 92),
          'GK': Offset(280, 92),
        };
        var i = 0;
        for (final entry in spots.entries) {
          // 하나씩 차례로 나타난다
          final appear = ((t * spots.length) - i).clamp(0.0, 1.0);
          if (appear > 0) {
            canvas.drawCircle(entry.value, 15 * appear,
                Paint()..color = entry.key == 'GK' ? _ball : _brand);
            _text(canvas, entry.key, entry.value.translate(0, 4), 10,
                FontWeight.w800,
                color: entry.key == 'GK' ? _ink : Colors.white);
          }
          i++;
        }
      case GuideScene.steps3:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(4, 60, 312, 80), const Radius.circular(12)),
          Paint()..color = GuideSceneView.courtFill,
        );
        // ghHop: 3번 나눠 뛴다
        final stepIndex = (t * 4).floor().clamp(0, 3);
        final x = 60.0 + stepIndex * 46;
        canvas.drawCircle(Offset(x, 100), 16, Paint()..color = _brand);
        canvas.drawCircle(Offset(x + 18, 86), 8, Paint()..color = _ball);
        for (var s = 1; s <= 3; s++) {
          final shown = stepIndex >= s;
          _text(canvas, '$s', Offset(60.0 + s * 46, 136), 14, FontWeight.w900,
              color: shown ? _brand : const Color(0xFFBBCBE8));
        }
        _label(canvas, '최대 3걸음', const Offset(160, 168));
      case GuideScene.sec3:
        // ghRing: stroke-dashoffset 으로 원이 줄어든다
        const c = Offset(160, 92);
        canvas.drawCircle(
            c,
            42,
            Paint()
              ..color = const Color(0xFFE5ECF7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 10);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: 42),
          -math.pi / 2,
          2 * math.pi * (1 - t),
          false,
          Paint()
            ..color = _brand
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round,
        );
        // ghN3 → ghN2 → ghN1
        final count = 3 - (t * 3).floor().clamp(0, 2);
        _text(canvas, '$count', c.translate(0, 14), 44, FontWeight.w900);
        _label(canvas, '공을 들고 최대 3초', const Offset(160, 168));
      case GuideScene.seven:
        _court(canvas);
        _goal(canvas, right: true);
        canvas.drawCircle(const Offset(150, 92), 16, Paint()..color = _brand);
        // ghShot7
        if (t < 0.61) {
          final p = ((t - 0.2) / 0.4).clamp(0.0, 1.0);
          canvas.drawCircle(Offset(168 + 62 * p, 92 - 14 * p), 8,
              Paint()..color = _ball);
        }
        _dashedLine(canvas, 150);
        _label(canvas, '7m 드로', const Offset(160, 168));
      case GuideScene.goalkeeper:
        _court(canvas);
        _goal(canvas, right: true);
        // ghSave: 공이 날아가다 골키퍼 손에 튕긴다
        final p = (t / 0.75).clamp(0.0, 1.0);
        final flying = t < 0.75;
        canvas.drawCircle(
          flying
              ? Offset(90 + 128 * p, 92 - 12 * p)
              : const Offset(206, 38),
          8,
          Paint()..color = _ball.withValues(alpha: flying ? 1 : 0.35),
        );
        // 골키퍼
        final reach = math.sin(math.pi * t.clamp(0.4, 1.0));
        canvas.drawCircle(Offset(248, 92 - 16 * reach), 18,
            Paint()..color = const Color(0xFFFF7A45));
        _label(canvas, '골키퍼 선방', const Offset(160, 168));
      case GuideScene.cards:
        // ghCard: 카드가 튀어 오르며 등장
        final pop = Curves.easeOutBack.transform((t / 0.4).clamp(0.0, 1.0));
        _card(canvas, const Offset(160, 84), _yellow, pop);
        _label(canvas, '경고 = 옐로카드', const Offset(160, 156));
      case GuideScene.twoMinutes:
        _court(canvas, height: 130);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(100, 144, 120, 30), const Radius.circular(8)),
          Paint()..color = GuideSceneView.courtFill,
        );
        // ghBench: 선수가 코트에서 벤치로 내려간다
        final p = Curves.easeInOut.transform(
            ((t - 0.25) / 0.45).clamp(0.0, 1.0));
        canvas.drawCircle(
            Offset(160, 70 + 78 * p), 16, Paint()..color = _red);
        _text(canvas, "2'", const Offset(160, 40), 26, FontWeight.w900,
            color: _red);
        _label(canvas, '2분 퇴장', const Offset(160, 168));
    }
  }

  // ── 조각들 ─────────────────────────────────────────────
  void _court(Canvas canvas, {double height = 172}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 4, 312, height), const Radius.circular(10)),
      Paint()..color = GuideSceneView.courtFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 4, 312, height), const Radius.circular(10)),
      Paint()
        ..color = _brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(160, 4),
      Offset(160, 4 + height),
      Paint()
        ..color = _brand.withValues(alpha: 0.4)
        ..strokeWidth = 2,
    );
  }

  Path _areaPath() => Path()
    ..addArc(Rect.fromCircle(center: const Offset(316, 92), radius: 52),
        math.pi / 2, math.pi);

  void _goalArea(Canvas canvas) {
    canvas.drawPath(
      _areaPath(),
      Paint()
        ..color = _brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _goal(Canvas canvas, {required bool right}) {
    final x = right ? 300.0 : 6.0;
    canvas.drawRect(
      Rect.fromLTWH(x, 66, 14, 52),
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _team(Canvas canvas, {required bool left, required Color color}) {
    final xs = left ? [50.0, 86.0, 122.0] : [198.0, 234.0, 270.0];
    for (var i = 0; i < xs.length; i++) {
      for (var j = 0; j < 2; j++) {
        // 살짝 흔들리게
        final dy = 3 * math.sin(2 * math.pi * (t + (i + j) * 0.12));
        canvas.drawCircle(
            Offset(xs[i], 62 + j * 56 + dy), 12, Paint()..color = color);
      }
    }
    canvas.drawCircle(Offset(left ? 24 : 296, 92), 12,
        Paint()..color = color.withValues(alpha: 0.55));
  }

  void _dashedLine(Canvas canvas, double x) {
    final p = Paint()
      ..color = _brand
      ..strokeWidth = 2;
    for (var y = 30.0; y < 156; y += 12) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 6), p);
    }
  }

  void _card(Canvas canvas, Offset center, Color color, double pop) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pop.clamp(0.1, 1.2));
    canvas.rotate(-0.12 * (1 - pop));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-26, -36, 52, 72), const Radius.circular(6)),
      Paint()..color = color,
    );
    canvas.restore();
  }

  void _progress(Canvas canvas, double x, double y, double w, double t) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, 10), const Radius.circular(5)),
      Paint()..color = const Color(0xFFCBDCF7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w * t, 10), const Radius.circular(5)),
      Paint()..color = _brand,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    FontWeight weight, {
    Color color = _ink,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: MhText.custom(size: size, weight: weight, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _label(Canvas canvas, String text, Offset center) =>
      _text(canvas, text, center, 13, FontWeight.w700, color: _brand);

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.t != t || old.scene != scene;
}
