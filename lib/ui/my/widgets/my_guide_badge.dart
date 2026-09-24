import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../guide/widgets/guide_screen.dart';

/// 입문 가이드 수료 배지.
///
/// 시안은 완료 시 `#FFF4CC` 카드에 트로피를 컬러로, 미완료 시 일반 카드에
/// 흑백(`grayscale(1)`, opacity .35) 트로피와 진행바를 보여준다.
class MyGuideBadge extends StatelessWidget {
  const MyGuideBadge({
    super.key,
    required this.doneCount,
    required this.allDone,
  });

  final int doneCount;
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: MhTap(
        onTap: () => GuideScreen.open(context),
        child: allDone ? const _Earned() : _InProgress(doneCount: doneCount),
      ),
    );
  }
}

class _Earned extends StatelessWidget {
  const _Earned();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4CC),
        borderRadius: BorderRadius.circular(MhRadius.card),
      ),
      child: Row(
        children: [
          const _Trophy(size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '획득한 배지',
                  style: MhText.custom(
                    size: 11,
                    weight: FontWeight.w700,
                    color: const Color(0xFFB37800),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '핸드볼 입문 수료',
                  style: MhText.custom(
                    size: 16,
                    weight: FontWeight.w800,
                    color: const Color(0xFF6B4500),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '입문 가이드 5개 레슨을 모두 마쳤어요',
                  style: MhText.custom(
                    size: 11,
                    weight: FontWeight.w400,
                    color: const Color(0xFF8A6A00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InProgress extends StatelessWidget {
  const _InProgress({required this.doneCount});

  final int doneCount;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    const total = AppConfig.guideLessonCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(MhRadius.card),
      ),
      child: Row(
        children: [
          // 시안의 grayscale(1) + opacity .35
          Opacity(
            opacity: 0.35,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0, //
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: const _Trophy(size: 40),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '입문 가이드 완료하고 수료 배지 받기',
                  style: MhText.custom(
                    size: 14,
                    weight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: doneCount / total,
                          minHeight: 6,
                          backgroundColor: c.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFC800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: MhSpacing.xs),
                    Text(
                      '$doneCount/$total',
                      style: MhText.custom(
                        size: 11,
                        weight: FontWeight.w700,
                        color: c.textSub,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '›',
            style: MhText.custom(
              size: 18,
              weight: FontWeight.w400,
              color: c.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

/// 시안의 리본 달린 메달. 60x72 viewBox를 그대로 옮겼다.
class _Trophy extends StatelessWidget {
  const _Trophy({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 72 / 60,
      child: CustomPaint(painter: _TrophyPainter()),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 60, size.height / 72);

    // 리본 두 갈래
    canvas.drawPath(
      Path()
        ..moveTo(18, 40)
        ..lineTo(10, 70)
        ..lineTo(22, 64)
        ..lineTo(28, 72)
        ..lineTo(32, 44)
        ..close(),
      Paint()..color = const Color(0xFF0050C8),
    );
    canvas.drawPath(
      Path()
        ..moveTo(42, 40)
        ..lineTo(50, 70)
        ..lineTo(38, 64)
        ..lineTo(32, 72)
        ..lineTo(28, 44)
        ..close(),
      Paint()..color = MhColors.brand,
    );

    // 메달 본체
    canvas.drawCircle(
      const Offset(30, 28),
      26,
      Paint()..color = const Color(0xFFFFC800),
    );
    canvas.drawCircle(
      const Offset(30, 28),
      26,
      Paint()
        ..color = const Color(0xFFD9A400)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      const Offset(30, 28),
      19,
      Paint()..color = MhColors.guideYellow,
    );

    // 공 라인
    final line = Paint()
      ..color = const Color(0xFFE0A800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(13, 25)
        ..cubicTo(22, 31, 38, 31, 47, 25),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(30, 9)
        ..cubicTo(24, 18, 24, 38, 30, 47),
      line,
    );
  }

  @override
  bool shouldRepaint(_TrophyPainter oldDelegate) => false;
}
