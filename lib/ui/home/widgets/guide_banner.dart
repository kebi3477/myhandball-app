import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/app_config.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../guide/widgets/guide_screen.dart';

/// 규칙 가이드 진입 배너.
///
/// 시안은 `box-shadow: 0 4px 0 #0050C8`로 블러 없는 하드 섀도를 깔고,
/// 마스코트에 `ghBounce`(1.6s 왕복 8px)를 건다.
class GuideBanner extends StatelessWidget {
  const GuideBanner({super.key, required this.doneCount});

  final int doneCount;

  @override
  Widget build(BuildContext context) {
    const total = AppConfig.guideLessonCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: MhTap(
        onTap: () => GuideScreen.open(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: MhColors.brand,
            borderRadius: BorderRadius.circular(MhRadius.card),
            boxShadow: const [
              BoxShadow(
                color: MhColors.brandShadow,
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              const _BouncingMascot(size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('핸드볼 처음이세요?',
                        style: MhText.custom(
                            size: 12,
                            weight: FontWeight.w700,
                            color: MhColors.guideYellow)),
                    const SizedBox(height: MhSpacing.xs2),
                    Text('3분 만에 규칙 끝내기',
                        style: MhText.custom(
                            size: 16,
                            weight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: MhSpacing.xs2),
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: doneCount / total,
                              minHeight: 6,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  MhColors.guideYellow),
                            ),
                          ),
                        ),
                        const SizedBox(width: MhSpacing.xs),
                        Text('$doneCount/$total',
                            style: MhText.custom(
                              size: 11,
                              weight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              Text('›',
                  style: MhText.custom(
                      size: 22, weight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 시안 `@keyframes ghBounce` — 1.6s 왕복 8px.
class _BouncingMascot extends StatefulWidget {
  const _BouncingMascot({required this.size});

  final double size;

  @override
  State<_BouncingMascot> createState() => _BouncingMascotState();
}

class _BouncingMascotState extends State<_BouncingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, -8 * Curves.easeInOut.transform(_c.value)),
          child: child,
        ),
        child: SvgPicture.asset('assets/design/guide-mascot.svg'),
      ),
    );
  }
}
