import 'package:flutter/material.dart';

import '../themes/theme.dart';
import '../themes/tokens.dart';

/// 아직 시안 이식이 안 된 탭에 쓰는 자리표시 화면.
///
/// 시안의 빈 상태(에러/오프라인) 레이아웃을 따른다 — 72px 원형 카드 +
/// 제목 + 설명.
class ComingSoon extends StatelessWidget {
  const ComingSoon({
    super.key,
    required this.palette,
    required this.title,
    required this.description,
  });

  final MhPalette palette;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            MhSpacing.md, MhSpacing.xl, MhSpacing.md, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.card,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                title.characters.first,
                style: MhText.custom(
                  size: 26,
                  weight: FontWeight.w800,
                  color: palette.textSub,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: MhText.sectionTitle(palette.text)),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: MhText.custom(
                size: 13,
                weight: FontWeight.w400,
                color: palette.textSub,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
