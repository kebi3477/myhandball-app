import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/app_config.dart';
import '../../../domain/models/guide_lesson.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../view_models/guide_view_model.dart';
import 'guide_lesson_view.dart';

/// 핸드볼 입문 가이드. 시안 HANDBALL GUIDE.
///
/// 홈 배너와 MY 배지에서 열린다.
class GuideScreen extends ConsumerWidget {
  const GuideScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GuideScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final state = ref.watch(guideViewModelProvider);
    final vm = ref.read(guideViewModelProvider.notifier);

    if (state.inLesson) return const GuideLessonView();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  MhTap(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: SizedBox(
                      width: 48,
                      height: 36,
                      child: MhIcon(MhIcons.chevLeft,
                          size: 18, color: c.text),
                    ),
                  ),
                  Expanded(
                    child: Text('핸드볼 입문 가이드',
                        textAlign: TextAlign.center,
                        style: MhText.custom(
                            size: 16,
                            weight: FontWeight.w800,
                            color: c.text)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    MhSpacing.gutter, MhSpacing.xs, MhSpacing.gutter, 48),
                children: [
                  _ProgressBanner(state: state),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 2),
                    child: Text('레슨 목록',
                        style: MhText.custom(
                            size: 15,
                            weight: FontWeight.w700,
                            color: c.text)),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < HandballGuide.lessons.length; i++) ...[
                    _LessonRow(
                      index: i,
                      lesson: HandballGuide.lessons[i],
                      state: state,
                      onTap: () => vm.openLesson(i),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (state.allDone) const _GraduationCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({required this.state});

  final GuideState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MhColors.brand,
        borderRadius: BorderRadius.circular(MhRadius.card),
        boxShadow: const [
          BoxShadow(
              color: MhColors.brandShadow,
              offset: Offset(0, 4),
              blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/design/guide-mascot.svg',
              width: 60, height: 60),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.headline,
                    style: MhText.custom(
                        size: 16,
                        weight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: MhSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: state.overallProgress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        MhColors.guideYellow),
                  ),
                ),
                const SizedBox(height: MhSpacing.xs),
                Text(
                  '${state.doneCount} / ${AppConfig.guideLessonCount} 레슨 완료',
                  style: MhText.custom(
                    size: 12,
                    weight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
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

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.index,
    required this.lesson,
    required this.state,
    required this.onTap,
  });

  final int index;
  final GuideLesson lesson;
  final GuideState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final done = state.isDone(index);
    final unlocked = state.isUnlocked(index);
    final current = unlocked && !done;

    return Opacity(
      opacity: unlocked ? 1 : 0.45,
      child: MhTap(
        onTap: unlocked ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(
                color: current ? MhColors.brand : Colors.transparent),
            borderRadius: BorderRadius.circular(MhRadius.chip),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done
                      ? MhColors.brand
                      : (current ? MhColors.brand.withValues(alpha: 0.14) : c.bg),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: done
                    ? const MhIcon(MhIcons.checkThick,
                        size: 20, color: Colors.white)
                    : Text('${index + 1}',
                        style: MhText.custom(
                          size: 20,
                          weight: FontWeight.w800,
                          color: current ? MhColors.brand : c.textFaint,
                        )),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title,
                        style: MhText.custom(
                            size: 15,
                            weight: FontWeight.w700,
                            color: c.text)),
                    Text(lesson.subtitle, style: MhText.caption(c.textSub)),
                  ],
                ),
              ),
              if (current)
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MhColors.brand,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text('시작',
                      style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                )
              else if (done)
                Text('다시 보기 ›',
                    style: MhText.custom(
                        size: 12, weight: FontWeight.w600, color: c.textSub))
              else
                MhIcon(MhIcons.lock, size: 18, color: c.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _GraduationCard extends StatelessWidget {
  const _GraduationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: MhSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4CC),
        borderRadius: BorderRadius.circular(MhRadius.card),
      ),
      child: Column(
        children: [
          const MhMedal(size: 44),
          const SizedBox(height: MhSpacing.xs),
          // 문구·색은 시안 그대로.
          Text('핸드볼 입문 수료',
              style: MhText.custom(
                  size: 15,
                  weight: FontWeight.w900,
                  color: const Color(0xFF8A5A00))),
          const SizedBox(height: MhSpacing.xs),
          Text('이제 경기 보러 갈 준비 끝이에요',
              textAlign: TextAlign.center,
              style: MhText.custom(
                  size: 12,
                  weight: FontWeight.w400,
                  color: const Color(0xFF8A6A00))),
        ],
      ),
    );
  }
}
