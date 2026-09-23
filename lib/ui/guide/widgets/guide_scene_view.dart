import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/guide_lesson.dart';

/// 레슨 스텝의 삽화.
///
/// 시안은 씬마다 320x180 인라인 SVG에 CSS `@keyframes`를 걸어 둔다.
/// **좌표·색·글자 크기는 원본 SVG에서 그대로 옮겼고**, 애니메이션은 같은
/// 키프레임을 `CustomPainter`에서 다시 계산한다.
///
/// 원본 애니메이션은 두 종류다:
///
/// - `infinite` — 계속 도는 것 (공이 날아가고, 구역이 깜빡이고)
/// - 1회성 등장 (`ghPop`, `ghCard`, `ghFill`) — CSS `fill-mode: both`라
///   끝난 자리에 멈춘다
///
/// 그래서 컨트롤러를 둘 둔다. 하나로 합쳐 반복시키면 등장 애니메이션이
/// 주기마다 다시 튀어나와 깜빡이는 것처럼 보인다.
class GuideSceneView extends StatefulWidget {
  const GuideSceneView({super.key, required this.scene});

  final GuideScene scene;

  /// 시안 삽화 박스: `background:#F4F8FF; border:2px solid #DCE8FF`
  static const boxBackground = Color(0xFFF4F8FF);
  static const boxBorder = Color(0xFFDCE8FF);

  /// 계속 도는 애니메이션의 한 주기(초). 없으면 반복하지 않는다.
  ///
  /// 코트 씬은 구역 깜빡임(1.6초)과 선수 이동(2.8초)의 주기가 달라서
  /// 최소공배수인 11.2초를 한 바퀴로 잡고 각자 위상을 계산한다.
  static const _loopSeconds = <GuideScene, double>{
    GuideScene.win: 2.6,
    GuideScene.court: 11.2,
    GuideScene.steps3: 3,
    GuideScene.sec3: 3,
    GuideScene.seven: 2.4,
    GuideScene.goalkeeper: 2.4,
    GuideScene.twoMinutes: 3,
  };

  /// 1회성 등장이 다 끝나는 시각(초).
  static const _introSeconds = <GuideScene, double>{
    GuideScene.intro: 2.5,
    GuideScene.time: 3.6,
    GuideScene.positions: 2.8,
    GuideScene.cards: 1.9,
    GuideScene.seven: 0.9,
  };

  @override
  State<GuideSceneView> createState() => _GuideSceneViewState();
}

class _GuideSceneViewState extends State<GuideSceneView>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this);
  late final AnimationController _entrance = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final loop = GuideSceneView._loopSeconds[widget.scene] ?? 0;
    if (loop > 0) {
      _loop
        ..duration = _toDuration(loop)
        ..repeat();
    } else {
      _loop.stop();
    }

    final intro = GuideSceneView._introSeconds[widget.scene] ?? 0.5;
    _entrance
      ..duration = _toDuration(intro)
      ..forward(from: 0);
  }

  static Duration _toDuration(double seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  @override
  void didUpdateWidget(GuideSceneView old) {
    super.didUpdateWidget(old);
    if (old.scene != widget.scene) _start();
  }

  @override
  void dispose() {
    _loop.dispose();
    _entrance.dispose();
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
          animation: Listenable.merge([_loop, _entrance]),
          builder: (_, _) => CustomPaint(
            painter: _ScenePainter(
              scene: widget.scene,
              loop: _loop.value *
                  (GuideSceneView._loopSeconds[widget.scene] ?? 0),
              entrance: _entrance.value *
                  (GuideSceneView._introSeconds[widget.scene] ?? 0.5),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// 원본 SVG의 색.
abstract final class _C {
  static const brand = Color(0xFF0068FF);
  static const brandDark = Color(0xFF0050C8);
  static const court = Color(0xFFDCE8FF);
  static const goalArea = Color(0xFFBFD5FF);
  static const ink = Color(0xFF111111);
  static const ball = Color(0xFFFFD43B);
  static const ballEdge = Color(0xFFE0A800);
  static const away = Color(0xFFFF7A45);
  static const keeper = Color(0xFF12B886);
  static const red = Color(0xFFE5484D);
  static const track = Color(0xFFE5ECF7);
  static const grey = Color(0xFF9AA3B2);
  static const greyText = Color(0xFF6B7383);
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.scene,
    required this.loop,
    required this.entrance,
  });

  final GuideScene scene;

  /// 반복 애니메이션의 경과 시간(초). 주기마다 0으로 돌아온다.
  final double loop;

  /// 등장 애니메이션의 경과 시간(초). 끝나면 그 값에 머문다.
  final double entrance;

  @override
  void paint(Canvas canvas, Size size) {
    // 원본 SVG와 같은 320x180 좌표계에서 그린다.
    canvas.save();
    canvas.scale(size.width / 320, size.height / 180);
    switch (scene) {
      case GuideScene.intro:
        _intro(canvas);
      case GuideScene.time:
        _time(canvas);
      case GuideScene.win:
        _win(canvas);
      case GuideScene.court:
        _court(canvas);
      case GuideScene.positions:
        _positions(canvas);
      case GuideScene.steps3:
        _steps3(canvas);
      case GuideScene.sec3:
        _sec3(canvas);
      case GuideScene.seven:
        _seven(canvas);
      case GuideScene.goalkeeper:
        _goalkeeper(canvas);
      case GuideScene.cards:
        _cards(canvas);
      case GuideScene.twoMinutes:
        _twoMinutes(canvas);
    }
    canvas.restore();
  }

  // --- 씬 ---

  /// 7 vs 7. 선수들이 순서대로 튀어나오고 마지막에 라벨이 뜬다.
  void _intro(Canvas c) {
    _courtBox(c, centerLine: true, leftArea: true, rightArea: true);

    const home = [
      Offset(40, 40),
      Offset(40, 140),
      Offset(80, 60),
      Offset(80, 120),
      Offset(110, 90),
      Offset(130, 40),
    ];
    const away = [
      Offset(280, 40),
      Offset(280, 140),
      Offset(240, 60),
      Offset(240, 120),
      Offset(210, 90),
      Offset(190, 140),
    ];

    for (var i = 0; i < home.length; i++) {
      _popped(c, home[i], 0.12 * i, () => _player(c, home[i], _C.brand));
    }
    _popped(c, const Offset(16, 90), 0.72,
        () => _player(c, const Offset(16, 90), _C.keeper));

    for (var i = 0; i < away.length; i++) {
      _popped(c, away[i], 0.9 + 0.12 * i, () => _player(c, away[i], _C.away));
    }
    _popped(c, const Offset(304, 90), 1.62,
        () => _player(c, const Offset(304, 90), _C.keeper));

    _popped(c, const Offset(160, 90), 1.9, () {
      _roundRect(c, const Rect.fromLTWH(118, 72, 84, 36), 18, _C.ink);
      _text(c, '7 vs 7', 160, 96,
          size: 18, weight: FontWeight.w900, color: Colors.white);
    }, duration: 0.6);
  }

  /// 60분 = 전반 30 + 후반 30, 사이에 휴식 10분.
  void _time(Canvas c) {
    _text(c, '60분', 160, 46,
        size: 40, weight: FontWeight.w900, color: _C.ink);

    void half(double x, Color fill, String label, double labelX, double delay) {
      final rect = Rect.fromLTWH(x, 72, 124, 28);
      _roundRect(c, rect, 14, _C.track);
      // ghFill — 왼쪽을 축으로 가로로 차오른다.
      final p = _eased(entrance, delay, 1.4, Curves.easeOut);
      if (p > 0) {
        c.save();
        c.clipRect(Rect.fromLTWH(x, 72, 124 * p, 28));
        _roundRect(c, rect, 14, fill);
        c.restore();
      }
      _text(c, label, labelX, 91,
          size: 12, weight: FontWeight.w800, color: Colors.white);
    }

    half(30, _C.brand, '전반 30분', 92, 0.3);
    half(166, _C.away, '후반 30분', 228, 2.2);

    _popped(c, const Offset(160, 129), 1.8, () {
      const rect = Rect.fromLTWH(122, 116, 76, 26);
      _roundRect(c, rect, 13, Colors.white);
      _roundRect(c, rect, 13, _C.ink, stroke: 2);
      _text(c, '휴식 10분', 160, 133,
          size: 11, weight: FontWeight.w800, color: _C.ink);
    });
  }

  /// 슛이 골대로 날아가 스코어가 0:0에서 1:0이 된다.
  void _win(Canvas c) {
    _courtBox(c, rightArea: true);
    _popped(c, const Offset(130, 90), 0,
        () => _player(c, const Offset(130, 90), _C.brand));

    // ghShotWin — 15%까지 대기, 55%에 172px 이동, 그 뒤 사라진다.
    final p = _phase(loop, 2.6);
    if (p < 0.56) {
      final move = _range(p, 0.15, 0.55);
      _ball(c, Offset(142 + 172 * move, 86));
    }

    _roundRect(c, const Rect.fromLTWH(120, 14, 80, 34), 10, _C.ink);
    // ghHide / ghShow — 55%를 경계로 점수가 바뀐다.
    if (p < 0.57) {
      _text(c, '0 : 0', 160, 38,
          size: 20, weight: FontWeight.w900, color: Colors.white);
    } else {
      _text(c, '1 : 0', 160, 38,
          size: 20, weight: FontWeight.w900, color: _C.ball);
      _text(c, 'GOAL!', 262, 160,
          size: 16, weight: FontWeight.w900, color: _C.brand);
    }
  }

  /// 6m 골 에어리어는 골키퍼만. 공격수는 선 앞에서 멈춘다.
  void _court(Canvas c) {
    _courtBox(c, centerLine: true, leftArea: true, rightArea: true);

    // ghZone — 1.6초 주기로 구역이 깜빡인다.
    final zone = 0.35 + 0.5 * (0.5 - 0.5 * math.cos(2 * math.pi * _phase(loop, 1.6)));
    final paint = Paint()..color = _C.ball.withValues(alpha: zone);
    c.drawPath(_areaPath(left: true), paint);
    c.drawPath(_areaPath(left: false), paint);

    _player(c, const Offset(302, 90), _C.keeper, label: 'GK');

    // ghWalkStop — 10%까지 대기, 55%에 78px 이동해 멈춘다.
    final p = _phase(loop, 2.8);
    _player(c, Offset(178 + 78 * _range(p, 0.10, 0.55), 90), _C.brand);

    if (p >= 0.58) {
      _roundRect(c, const Rect.fromLTWH(222, 54, 46, 22), 11, _C.red);
      _text(c, 'STOP', 245, 69,
          size: 11, weight: FontWeight.w900, color: Colors.white);
    }

    _text(c, '6m 골 에어리어', 290, 170,
        size: 10, weight: FontWeight.w800, color: _C.brandDark);
  }

  /// 포지션 7개가 차례로 자리를 잡는다.
  void _positions(Canvas c) {
    _courtBox(c, rightArea: true);

    const spots = [
      (Offset(250, 26), 'LW'),
      (Offset(196, 52), 'LB'),
      (Offset(176, 90), 'CB'),
      (Offset(196, 128), 'RB'),
      (Offset(250, 154), 'RW'),
      (Offset(262, 90), 'PV'),
    ];
    for (var i = 0; i < spots.length; i++) {
      final (at, label) = spots[i];
      _popped(c, at, 0.35 * i, () => _player(c, at, _C.brand, label: label));
    }
    _popped(c, const Offset(304, 90), 2.2,
        () => _player(c, const Offset(304, 90), _C.keeper, label: 'GK'));
  }

  /// 공을 잡고 3걸음까지. 발자국이 하나씩 찍힌다.
  void _steps3(Canvas c) {
    _roundRect(c, const Rect.fromLTWH(4, 60, 312, 80), 12, _C.court);

    final p = _phase(loop, 3);
    const steps = [
      (Offset(90, 126), 150.0, '1', 0.25),
      (Offset(136, 112), 98.0, '2', 0.50),
      (Offset(182, 126), 150.0, '3', 0.75),
    ];
    for (final (at, textY, label, show) in steps) {
      if (p < show) continue;
      c.drawOval(
        Rect.fromCenter(center: at, width: 14, height: 8),
        Paint()..color = _C.brandDark.withValues(alpha: 0.5),
      );
      _text(c, label, at.dx, textY,
          size: 14, weight: FontWeight.w900, color: _C.brand);
    }

    // ghHop — 세 번에 나눠 46px씩 뛴다.
    final hop = _steps(p, const [
      (0.08, 0.0),
      (0.25, 46.0),
      (0.33, 46.0),
      (0.50, 92.0),
      (0.58, 92.0),
      (0.75, 138.0),
    ]);
    c.drawCircle(Offset(44 + hop, 100), 13,
        Paint()..color = _C.brand);
    c.drawCircle(Offset(44 + hop, 100), 13,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    _ball(c, Offset(54 + hop, 90));

    if (p >= 0.75) {
      _roundRect(c, const Rect.fromLTWH(226, 24, 84, 26), 13, _C.ink);
      _text(c, '여기까지 OK!', 268, 41,
          size: 11, weight: FontWeight.w800, color: Colors.white);
    }
  }

  /// 공을 들고 3초. 링이 줄어들며 3 → 2 → 1.
  void _sec3(Canvas c) {
    const center = Offset(160, 92);
    const radius = 42.0;

    c.drawCircle(
      center,
      radius,
      Paint()
        ..color = _C.track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    // ghRing — dashoffset이 둘레만큼 흐르면서 링이 줄어든다.
    final p = _phase(loop, 3);
    final sweep = (1 - p) * 2 * math.pi;
    if (sweep > 0) {
      c.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = _C.brand
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }

    final count = p < 0.33 ? '3' : (p < 0.66 ? '2' : '1');
    _text(c, count, 160, 106,
        size: 40, weight: FontWeight.w900, color: _C.ink);

    // ghWiggle — 1초 주기로 ±7도 흔들린다. 그룹 기준점은 (250, 105).
    final angle = 7 * math.sin(2 * math.pi * _phase(loop, 1)) * math.pi / 180;
    c.save();
    c.translate(250, 105);
    c.rotate(angle);
    c.translate(-250, -105);
    _player(c, const Offset(248, 92), _C.brand, radius: 13, strokeWidth: 3);
    _ball(c, const Offset(258, 80));
    c.restore();

    _text(c, '초 안에 패스!', 72, 98,
        size: 12, weight: FontWeight.w800, color: _C.greyText);
  }

  /// 7m 드로 — 골키퍼와 1대1.
  void _seven(Canvas c) {
    _courtBox(c, rightArea: true);

    c.drawLine(
      const Offset(246, 82),
      const Offset(246, 98),
      Paint()
        ..color = _C.ink
        ..strokeWidth = 3,
    );
    _text(c, '7m', 246, 74,
        size: 10, weight: FontWeight.w900, color: _C.ink);

    _player(c, const Offset(236, 90), _C.brand);

    // ghShot7 — 20%까지 대기, 60%에 (62, -14) 이동 후 사라진다.
    final p = _phase(loop, 2.4);
    if (p < 0.61) {
      final m = _range(p, 0.20, 0.60);
      _ball(c, Offset(246 + 62 * m, 86 - 14 * m));
    }

    // ghSway — 1.2초 주기로 위아래 16px.
    final sway = -16 * math.cos(2 * math.pi * _phase(loop, 1.2));
    _player(c, Offset(302, 90 + sway), _C.keeper, label: 'GK');

    _popped(c, const Offset(85, 34), 0.3, () {
      _roundRect(c, const Rect.fromLTWH(30, 20, 110, 28), 14, _C.ink);
      _text(c, '1 vs 1 찬스!', 85, 38,
          size: 12, weight: FontWeight.w800, color: Colors.white);
    });
  }

  /// 골키퍼가 슛을 쳐낸다.
  void _goalkeeper(Canvas c) {
    _courtBox(c, rightArea: true);
    _player(c, const Offset(170, 110), _C.away);

    // ghSave — 날아가다 45%에 막히고 튕겨 나가며 사라진다.
    final p = _phase(loop, 2.4);
    final (dx, dy, alpha) = _save(p);
    if (alpha > 0) _ball(c, Offset(180 + dx, 106 + dy), opacity: alpha);

    // ghSway — 2.4초 주기.
    final sway = -16 * math.cos(2 * math.pi * p);
    _player(c, Offset(300, 96 + sway), _C.keeper, label: 'GK');

    if (p >= 0.58) {
      _text(c, 'SAVE!', 236, 36,
          size: 16, weight: FontWeight.w900, color: _C.keeper);
    }
  }

  /// 경고 · 2분 퇴장 · 실격 카드가 차례로 날아든다.
  void _cards(Canvas c) {
    void card(double x, Color fill, String label, double delay,
        {String? big}) {
      final t = _eased(entrance, delay, 0.7, Curves.easeOutBack);
      if (t <= 0) return;
      // ghCard — 아래에서 회전하며 올라온다.
      final (ty, rot, scale) = _cardMotion(t);
      c.save();
      final center = Offset(x + 26, 70);
      c.translate(center.dx, center.dy);
      c.rotate(rot * math.pi / 180);
      c.scale(scale);
      c.translate(-center.dx, -center.dy);
      c.translate(0, ty);

      final rect = Rect.fromLTWH(x, 34, 52, 72);
      _roundRect(c, rect, 8, fill);
      _roundRect(c, rect, 8, _C.ink, stroke: 2.5);
      if (big != null) {
        _text(c, big, x + 26, 80,
            size: 22, weight: FontWeight.w900, color: _C.ink);
      }
      _text(c, label, x + 26, 130,
          size: 13, weight: FontWeight.w800, color: _C.ink);
      c.restore();
    }

    card(34, _C.ball, '경고', 0);
    card(134, Colors.white, '2분 퇴장', 0.6, big: "2'");
    card(234, _C.red, '실격', 1.2);

    final dashes = Path()
      ..moveTo(96, 70)
      ..lineTo(120, 70)
      ..moveTo(200, 70)
      ..lineTo(224, 70);
    _dashed(
      c,
      dashes,
      Paint()
        ..color = _C.grey
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
      on: 3,
      off: 5,
    );
  }

  /// 2분 퇴장 — 한 명이 벤치로 빠져 6 vs 7이 된다.
  void _twoMinutes(Canvas c) {
    _roundRect(c, const Rect.fromLTWH(4, 4, 312, 130), 10, _C.court);
    _roundRect(c, const Rect.fromLTWH(4, 4, 312, 130), 10, _C.brand, stroke: 2);

    const bench = Rect.fromLTWH(100, 146, 120, 30);
    _roundRect(c, bench, 8, _C.track);
    _dashed(
      c,
      Path()..addRRect(RRect.fromRectAndRadius(bench, const Radius.circular(8))),
      Paint()
        ..color = _C.grey
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
      on: 4,
      off: 3,
    );
    _text(c, '벤치', 160, 166,
        size: 10, weight: FontWeight.w800, color: _C.greyText);

    for (final at in const [
      Offset(60, 36),
      Offset(60, 104),
      Offset(120, 50),
      Offset(120, 90),
      Offset(200, 36),
      Offset(250, 104),
    ]) {
      _player(c, at, _C.brand);
    }

    // ghBench — 25%까지 머물다 70%에 벤치(아래 78px)로 내려간다.
    final p = _phase(loop, 3);
    _player(c, Offset(160, 82 + 78 * _range(p, 0.25, 0.70)), _C.grey);

    if (p >= 0.58) {
      _roundRect(c, const Rect.fromLTWH(226, 20, 80, 30), 15, _C.ink);
      _text(c, '6 vs 7', 266, 40,
          size: 14, weight: FontWeight.w900, color: _C.ball);
    }

    _text(c, '2:00', 44, 160,
        size: 18, weight: FontWeight.w900, color: _C.red);
  }

  // --- 공통 도형 ---

  /// 코트 바탕 + (선택) 중앙선 · 골 에어리어 · 골대.
  void _courtBox(
    Canvas c, {
    bool centerLine = false,
    bool leftArea = false,
    bool rightArea = false,
  }) {
    const rect = Rect.fromLTWH(4, 4, 312, 172);
    _roundRect(c, rect, 10, _C.court);
    _roundRect(c, rect, 10, _C.brand, stroke: 2);

    if (centerLine) {
      _dashed(
        c,
        Path()
          ..moveTo(160, 4)
          ..lineTo(160, 176),
        Paint()
          ..color = _C.brand
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
        on: 4,
        off: 4,
      );
    }

    void area(bool left) {
      final path = _areaPath(left: left);
      c.drawPath(path, Paint()..color = _C.goalArea);
      c.drawPath(
        path,
        Paint()
          ..color = _C.brand
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      // 골대 기둥
      _roundRect(
        c,
        Rect.fromLTWH(left ? 0 : 314, 72, 6, 36),
        2,
        _C.ink,
      );
    }

    if (leftArea) area(true);
    if (rightArea) area(false);
  }

  /// 시안: `M4 42 A50 50 0 0 1 4 138` / `M316 42 A50 50 0 0 0 316 138`
  Path _areaPath({required bool left}) {
    final x = left ? 4.0 : 316.0;
    return Path()
      ..moveTo(x, 42)
      ..arcToPoint(
        Offset(x, 138),
        radius: const Radius.circular(50),
        clockwise: left,
      )
      ..close();
  }

  void _player(
    Canvas c,
    Offset at,
    Color color, {
    String? label,
    double radius = 10,
    double strokeWidth = 2.5,
    double opacity = 1,
  }) {
    c.drawCircle(at, radius,
        Paint()..color = color.withValues(alpha: opacity));
    c.drawCircle(
      at,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    if (label != null) {
      _text(c, label, at.dx, at.dy + 3.5,
          size: 8,
          weight: FontWeight.w800,
          color: Colors.white,
          opacity: opacity);
    }
  }

  void _ball(Canvas c, Offset at, {double radius = 6, double opacity = 1}) {
    c.drawCircle(at, radius,
        Paint()..color = _C.ball.withValues(alpha: opacity));
    c.drawCircle(
      at,
      radius,
      Paint()
        ..color = _C.ballEdge.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _roundRect(Canvas c, Rect rect, double radius, Color color,
      {double? stroke}) {
    final paint = Paint()..color = color;
    if (stroke != null) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
    }
    c.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
  }

  /// SVG `<text>`는 **y가 베이스라인**이고 `text-anchor`로 가로를 맞춘다.
  void _text(
    Canvas c,
    String text,
    double x,
    double baselineY, {
    required double size,
    required FontWeight weight,
    required Color color,
    double opacity = 1,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: size,
          fontWeight: weight,
          color: color.withValues(alpha: color.a * opacity),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 시안의 `<text>`는 전부 text-anchor:middle 이다.
    final baseline =
        painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    painter.paint(
        c, Offset(x - painter.width / 2, baselineY - baseline));
  }

  void _dashed(Canvas c, Path path, Paint paint,
      {required double on, required double off}) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + on, metric.length);
        c.drawPath(metric.extractPath(distance, end), paint);
        distance = end + off;
      }
    }
  }

  // --- 애니메이션 계산 ---

  /// 주기 안의 위치(0~1).
  double _phase(double elapsed, double period) =>
      period <= 0 ? 0 : (elapsed % period) / period;

  /// `from`~`to` 구간을 0~1로 편다. 구간 밖은 0 또는 1.
  double _range(double p, double from, double to) =>
      ((p - from) / (to - from)).clamp(0.0, 1.0);

  /// `delay` 뒤 `duration` 동안 0~1. CSS `fill-mode: both`처럼 끝에 머문다.
  double _eased(double elapsed, double delay, double duration, Curve curve) {
    final p = ((elapsed - delay) / duration).clamp(0.0, 1.0);
    return p <= 0 ? 0 : curve.transform(p);
  }

  /// 구간별 선형 보간. `(시각, 값)` 목록은 시각 오름차순이어야 한다.
  double _steps(double p, List<(double, double)> frames) {
    if (p <= frames.first.$1) return frames.first.$2;
    for (var i = 1; i < frames.length; i++) {
      final (t1, v1) = frames[i];
      if (p > t1) continue;
      final (t0, v0) = frames[i - 1];
      return v0 + (v1 - v0) * ((p - t0) / (t1 - t0));
    }
    return frames.last.$2;
  }

  /// ghPop — 0.5초 동안 튀어나온다 (scale 0 → 1.25 → 1).
  void _popped(Canvas c, Offset origin, double delay, VoidCallback draw,
      {double duration = 0.5}) {
    final p = ((entrance - delay) / duration).clamp(0.0, 1.0);
    if (p <= 0) return;

    final e = Curves.easeOut.transform(p);
    final scale = e < 0.6 ? 1.25 * (e / 0.6) : 1.25 - 0.25 * ((e - 0.6) / 0.4);
    if (scale <= 0) return;

    c.save();
    c.translate(origin.dx, origin.dy);
    c.scale(scale);
    c.translate(-origin.dx, -origin.dy);
    draw();
    c.restore();
  }

  /// ghCard — translateY 24 → -4 → 0, rotate -20 → 4 → 0, scale .6 → 1.08 → 1
  (double, double, double) _cardMotion(double t) {
    if (t < 0.6) {
      final p = t / 0.6;
      return (24 + (-4 - 24) * p, -20 + 24 * p, 0.6 + 0.48 * p);
    }
    final p = (t - 0.6) / 0.4;
    return (-4 + 4 * p, 4 - 4 * p, 1.08 - 0.08 * p);
  }

  /// ghSave — 날아가다 막히고 위로 튕겨 나가며 사라진다.
  (double, double, double) _save(double p) {
    if (p < 0.10) return (0, 0, 1);
    if (p < 0.45) {
      final t = _range(p, 0.10, 0.45);
      return (128 * t, -12 * t, 1);
    }
    if (p < 0.75) {
      final t = _range(p, 0.45, 0.75);
      return (128 + (96 - 128) * t, -12 + (-54 + 12) * t, 1);
    }
    final t = _range(p, 0.75, 1.0);
    return (96 + (80 - 96) * t, -54 + (-70 + 54) * t, 1 - t);
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.scene != scene || old.loop != loop || old.entrance != entrance;
}
