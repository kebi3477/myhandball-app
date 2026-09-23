import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';

/// `< 2026년 11월 ∨ >` 월 이동 줄. 시안 높이 56, gap 24.
///
/// 가운데 라벨은 **눌러서 연·월을 직접 고르는 칩**이다
/// (시안 `openYmPicker`).
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onPickYearMonth,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickYearMonth;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final style = MhText.custom(
      size: 16,
      weight: FontWeight.w700,
      color: c.textNeutral,
      height: 24 / 16,
    );

    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Arrow(glyph: '<', style: style, onTap: onPrev),
          const SizedBox(width: MhSpacing.md),
          MhTap(
            onTap: onPickYearMonth,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: MhText.custom(
                        size: 16,
                        weight: FontWeight.w700,
                        color: c.text,
                        height: 24 / 16,
                      )),
                  const SizedBox(width: 6),
                  MhIcon(MhIcons.chevDown, size: 12, color: c.textNeutral),
                ],
              ),
            ),
          ),
          const SizedBox(width: MhSpacing.md),
          _Arrow(glyph: '>', style: style, onTap: onNext),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.glyph,
    required this.style,
    required this.onTap,
  });

  final String glyph;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MhTap(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(glyph, style: style),
      ),
    );
  }
}
