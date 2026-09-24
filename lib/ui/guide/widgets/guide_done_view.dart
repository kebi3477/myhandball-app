import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../view_models/guide_view_model.dart';

/// 레슨을 끝내면 나오는 화면. 시안 `guideDone`.
///
/// 퀴즈를 맞히자마자 목록으로 돌려보내면 뭘 했는지 남는 게 없다.
/// 마스코트가 한 번 튀어나오고, 퀴즈 결과와 (마지막이면) 수료 배지를
/// 보여준 뒤 다음 레슨으로 넘긴다.
class GuideDoneView extends ConsumerWidget {
  const GuideDoneView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final state = ref.watch(guideViewModelProvider);
    final vm = ref.read(guideViewModelProvider.notifier);
    final lesson = state.finished;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: MhSpacing.gutter, vertical: MhSpacing.md),
                child: Column(
                  children: [
                    const _PoppingMascot(size: 110),
                    const SizedBox(height: MhSpacing.sm),
                    Text(state.justGraduated ? '핸드볼 입문 수료!' : '잘했어요!',
                        style: MhText.custom(
                            size: 26,
                            weight: FontWeight.w900,
                            color: c.text)),
                    const SizedBox(height: 6),
                    Text(lesson?.title ?? '',
                        textAlign: TextAlign.center,
                        style: MhText.custom(
                            size: 14,
                            weight: FontWeight.w500,
                            color: c.textSub)),
                    const SizedBox(height: MhSpacing.sm),
                    const _QuizBadge(),
                    if (state.justGraduated) ...[
                      const SizedBox(height: MhSpacing.sm),
                      const _BadgeCard(),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  MhSpacing.gutter, 12, MhSpacing.gutter, MhSpacing.md),
              child: Column(
                children: [
                  MhTap(
                    haptic: MhHaptic.impact,
                    onTap: vm.continueFromDone,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: MhColors.brand,
                        borderRadius: BorderRadius.circular(MhRadius.chip),
                        // 시안 `box-shadow: 0 4px 0 <shadow>`
                        boxShadow: const [
                          BoxShadow(
                              color: MhColors.brandShadow,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: Text(state.doneNextLabel,
                          style: MhText.custom(
                            size: 16,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.32,
                          )),
                    ),
                  ),
                  const SizedBox(height: 10),
                  MhTap(
                    behavior: HitTestBehavior.opaque,
                    onTap: vm.exitLesson,
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text('목록으로',
                            style: MhText.custom(
                                size: 14,
                                weight: FontWeight.w800,
                                color: c.textSub)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 시안 `doneQuiz` — 브랜드색 테두리에 "퀴즈 / 정답".
class _QuizBadge extends StatelessWidget {
  const _QuizBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      decoration: BoxDecoration(
        border: Border.all(color: MhColors.brand, width: 2),
        borderRadius: BorderRadius.circular(MhRadius.chip),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: MhColors.brand,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('퀴즈',
                textAlign: TextAlign.center,
                style: MhText.custom(
                    size: 11, weight: FontWeight.w900, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: MhSpacing.xs),
            child: Text('정답',
                style: MhText.custom(
                    size: 22,
                    weight: FontWeight.w900,
                    color: MhColors.brand)),
          ),
        ],
      ),
    );
  }
}

/// 시안 `justGraduated` — 마지막 레슨을 끝낸 그 순간에만 뜬다.
class _BadgeCard extends StatelessWidget {
  const _BadgeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4CC),
        borderRadius: BorderRadius.circular(MhRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MhMedal(size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("'핸드볼 입문 수료' 배지 획득!",
                  style: MhText.custom(
                      size: 14,
                      weight: FontWeight.w900,
                      color: const Color(0xFF8A5A00))),
              const SizedBox(height: 2),
              Text('MY에서 언제든 확인할 수 있어요',
                  style: MhText.custom(
                      size: 11,
                      weight: FontWeight.w500,
                      color: const Color(0xFF8A6A00))),
            ],
          ),
        ],
      ),
    );
  }
}

/// 시안 `ghPop`(0 → 1.25 → 1)으로 한 번 튀어나온 뒤 `ghBounce`로 계속 뛴다.
class _PoppingMascot extends StatefulWidget {
  const _PoppingMascot({required this.size});

  final double size;

  @override
  State<_PoppingMascot> createState() => _PoppingMascotState();
}

class _PoppingMascotState extends State<_PoppingMascot>
    with TickerProviderStateMixin {
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  late final _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pop.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pop, _bounce]),
      builder: (_, child) {
        // ghPop: 0% scale 0 → 60% scale 1.25 → 100% scale 1
        final t = _pop.value;
        final scale = t < 0.6 ? (t / 0.6) * 1.25 : 1.25 - (t - 0.6) / 0.4 * 0.25;
        final dy = -8 * Curves.easeInOut.transform(_bounce.value);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: SvgPicture.asset('assets/design/guide-mascot.svg'),
      ),
    );
  }
}
