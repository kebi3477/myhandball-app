import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';

/// 홈 로딩 상태.
///
/// 시안 `loadingHome` 블록을 그대로 옮겼다 — 카드 자리를 `c.card` 색
/// 블록으로 채우고 `@keyframes skPulse`(1.4s, opacity 0.5↔1)를 건다.
class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key});

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            MhSpacing.gutter, 0, MhSpacing.gutter, MhSpacing.xl),
        children: const [
          _Block(width: 96, height: 16, radius: 6),
          SizedBox(height: 12),
          _Block(height: 180),
          SizedBox(height: MhSpacing.md),
          _Block(width: 80, height: 16, radius: 6),
          SizedBox(height: 12),
          _Block(height: 257),
          SizedBox(height: MhSpacing.md),
          _Block(width: 140, height: 16, radius: 6),
          SizedBox(height: 12),
          _Block(height: 100, radius: MhRadius.chip),
          SizedBox(height: MhSpacing.xs),
          _Block(height: 100, radius: MhRadius.chip),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    this.width,
    required this.height,
    this.radius = MhRadius.card,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: context.mh.card,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
