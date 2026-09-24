import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 가이드 마스코트 — 공이 위아래로 튀고 **그림자는 제자리에 있다.**
///
/// 시안은 그림자 타원을 애니메이션 `<g>` **밖에** 둔다. 공만 뛰고 바닥
/// 그림자는 가만히 있어야 뜬 것처럼 보인다. 그림자까지 같이 움직이면
/// 공이 뛰는 게 아니라 그림 전체가 흔들리는 걸로 보인다.
///
/// 그래서 `guide-mascot.svg`에는 그림자가 없다. 여기서 따로 깔아 준다.
class GuideMascot extends StatefulWidget {
  const GuideMascot({super.key, required this.size, this.pop = false});

  final double size;

  /// 시안 `ghPop` — 한 번 튀어나온 뒤 그 자리에 멈춘다. 완료 화면에서 쓴다.
  final bool pop;

  @override
  State<GuideMascot> createState() => _GuideMascotState();
}

class _GuideMascotState extends State<GuideMascot>
    with TickerProviderStateMixin {
  /// 시안 `ghBounce 1.6s ease-in-out infinite`
  late final _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  /// 시안 `ghPop .6s ease-out both`
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: widget.pop ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.pop) _pop.forward();
  }

  @override
  void dispose() {
    _bounce.dispose();
    _pop.dispose();
    super.dispose();
  }

  /// 시안 좌표계는 `viewBox="0 0 64 64"`다. 크기에 맞춰 비율로 환산한다.
  static const _viewBox = 64.0;

  @override
  Widget build(BuildContext context) {
    final unit = widget.size / _viewBox;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 그림자: cx 32, cy 60, rx 16, ry 3 — 애니메이션 밖이다.
          Positioned(
            top: (60 - 3) * unit,
            child: Container(
              width: 32 * unit,
              height: 6 * unit,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.all(
                  Radius.elliptical(16 * unit, 3 * unit),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_bounce, _pop]),
            builder: (_, child) {
              // ghPop: 0% scale 0 → 60% scale 1.25 → 100% scale 1
              final t = _pop.value;
              final scale =
                  t < 0.6 ? (t / 0.6) * 1.25 : 1.25 - (t - 0.6) / 0.4 * 0.25;
              // ghBounce: 50%에서 -8 (시안 좌표 기준)
              final dy = -8 * unit * Curves.easeInOut.transform(_bounce.value);
              return Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: SvgPicture.asset(
              'assets/design/guide-mascot.svg',
              width: widget.size,
              height: widget.size,
            ),
          ),
        ],
      ),
    );
  }
}
