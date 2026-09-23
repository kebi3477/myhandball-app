import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';

/// 분석 로딩 상태. 시안 `loadingStat` — 40px 한 줄 + 56px 세 줄.
class StatSkeleton extends StatefulWidget {
  const StatSkeleton({super.key});

  @override
  State<StatSkeleton> createState() => _StatSkeletonState();
}

class _StatSkeletonState extends State<StatSkeleton>
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
    final card = context.mh.card;
    Widget block(double height) => Container(
          height: height,
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
          ),
        );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(MhSpacing.gutter, MhSpacing.sm,
            MhSpacing.gutter, MhSpacing.xl),
        children: [
          block(40),
          const SizedBox(height: MhSpacing.xs),
          block(56),
          const SizedBox(height: MhSpacing.xs),
          block(56),
          const SizedBox(height: MhSpacing.xs),
          block(56),
        ],
      ),
    );
  }
}
