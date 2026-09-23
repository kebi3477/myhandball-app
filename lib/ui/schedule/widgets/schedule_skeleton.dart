import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';

/// 일정 로딩 상태. 시안 `loadingSchedule` 블록 — 칩 3개 + 134px 카드 3장.
class ScheduleSkeleton extends StatefulWidget {
  const ScheduleSkeleton({super.key});

  @override
  State<ScheduleSkeleton> createState() => _ScheduleSkeletonState();
}

class _ScheduleSkeletonState extends State<ScheduleSkeleton>
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
    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            MhSpacing.gutter, 0, MhSpacing.gutter, MhSpacing.xl),
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: MhSpacing.xs),
                Container(
                  width: 60,
                  height: 36,
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: MhSpacing.sm),
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: MhSpacing.xs),
            Container(
              height: 134,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(MhRadius.card),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
