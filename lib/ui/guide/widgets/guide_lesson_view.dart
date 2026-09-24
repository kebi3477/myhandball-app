import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../view_models/guide_view_model.dart';
import 'guide_mascot.dart';
import 'guide_scene_view.dart';

/// 레슨 진행 화면 — 스텝 삽화 + 설명, 마지막에 퀴즈.
class GuideLessonView extends ConsumerWidget {
  const GuideLessonView({super.key});

  static const _quizAccent = Color(0xFFFF7A45);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final state = ref.watch(guideViewModelProvider);
    final vm = ref.read(guideViewModelProvider.notifier);
    final lesson = state.lesson!;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    MhTap(
                      behavior: HitTestBehavior.opaque,
                      onTap: vm.exitLesson,
                      // 시안은 글자 '✕'를 쓰지만 Pretendard에 그 글리프가
                      // 없어 네모로 깨진다. 같은 모양의 아이콘으로 그린다.
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(Icons.close_rounded,
                            size: 22, color: c.textFaint),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: LinearProgressIndicator(
                          value: state.lessonProgress,
                          minHeight: 14,
                          backgroundColor: c.card,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              MhColors.brand),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    MhSpacing.gutter, 12, MhSpacing.gutter, 24),
                children: state.isQuizPage
                    ? _quiz(context, state, vm)
                    : _step(context, state),
              ),
            ),
            _Footer(state: state, vm: vm, lessonTitle: lesson.title),
          ],
        ),
      ),
    );
  }

  List<Widget> _step(BuildContext context, GuideState state) {
    final c = context.mh;
    final step = state.step!;
    return [
      Text('LESSON ${state.lessonIndex! + 1} · ${state.lesson!.title}',
          style: MhText.custom(
              size: 12,
              weight: FontWeight.w800,
              color: MhColors.brand,
              letterSpacing: 0.04 * 12)),
      const SizedBox(height: 18),
      GuideSceneView(scene: step.scene),
      const SizedBox(height: 18),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GuideMascot(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(MhRadius.chip),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: MhText.custom(
                          size: 18, weight: FontWeight.w900, color: c.text)),
                  const SizedBox(height: 6),
                  Text(step.body,
                      style: MhText.custom(
                          size: 14,
                          weight: FontWeight.w400,
                          color: c.text,
                          height: 1.65)),
                ],
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _quiz(
      BuildContext context, GuideState state, GuideViewModel vm) {
    final c = context.mh;
    final quiz = state.lesson!.quiz;
    const keys = ['A', 'B', 'C', 'D'];

    return [
      Text('퀴즈 타임',
          style: MhText.custom(
              size: 12,
              weight: FontWeight.w800,
              color: _quizAccent,
              letterSpacing: 0.04 * 12)),
      const SizedBox(height: 18),
      Text(quiz.question,
          style: MhText.custom(
              size: 20, weight: FontWeight.w900, color: c.text, height: 1.4)),
      const SizedBox(height: 18),
      for (var i = 0; i < quiz.options.length; i++) ...[
        _Option(
          label: quiz.options[i],
          optionKey: keys[i],
          state: _optionState(state, i, quiz.answerIndex),
          onTap: () => vm.pick(i),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }

  _OptionState _optionState(GuideState state, int index, int answer) {
    if (state.pickedOption == null) return _OptionState.idle;
    if (index == answer) return _OptionState.correct;
    if (index == state.pickedOption) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.optionKey,
    required this.state,
    required this.onTap,
  });

  final String label;
  final String optionKey;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final border = switch (state) {
      _OptionState.correct => MhColors.brand,
      _OptionState.wrong => const Color(0xFFE5484D),
      _ => c.border,
    };

    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.45 : 1,
      child: MhTap(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: border, width: 2),
            borderRadius: BorderRadius.circular(MhRadius.chip),
            // 시안 box-shadow: 0 4px 0 (테두리색)
            boxShadow: [
              BoxShadow(color: border, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: border, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(optionKey,
                    style: MhText.custom(
                        size: 12, weight: FontWeight.w900, color: border)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(label,
                      style: MhText.custom(
                          size: 15, weight: FontWeight.w700, color: c.text)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 하단 CTA. 퀴즈를 풀면 정답/오답 피드백이 위로 올라온다 (시안 ghSlideUp).
class _Footer extends StatelessWidget {
  const _Footer({
    required this.state,
    required this.vm,
    required this.lessonTitle,
  });

  final GuideState state;
  final GuideViewModel vm;
  final String lessonTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final correct = state.isCorrect;

    if (state.isQuizPage && correct != null) {
      final good = correct;
      return TweenAnimationBuilder<double>(
        key: ValueKey(state.pickedOption),
        tween: Tween(begin: 1, end: 0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (_, v, child) =>
            Transform.translate(offset: Offset(0, 120 * v), child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
              MhSpacing.gutter, 18, MhSpacing.gutter, 24),
          color: good
              ? MhColors.brand.withValues(alpha: 0.12)
              : const Color(0xFFE5484D).withValues(alpha: 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(good ? '정답이에요!' : '아쉬워요',
                  style: MhText.custom(
                    size: 16,
                    weight: FontWeight.w900,
                    color: good ? MhColors.brand : const Color(0xFFE5484D),
                  )),
              const SizedBox(height: 6),
              Text(state.lesson!.quiz.explain,
                  style: MhText.custom(
                      size: 13,
                      weight: FontWeight.w400,
                      color: c.text,
                      height: 1.6)),
              const SizedBox(height: 14),
              _Cta(
                label: good ? '레슨 완료' : '다시 풀기',
                onTap: good ? vm.next : vm.retryQuiz,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 12, MhSpacing.gutter, 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderSubtle, width: 2)),
      ),
      child: _Cta(
        label: state.isQuizPage ? '보기를 골라주세요' : '다음',
        onTap: state.isQuizPage ? null : vm.next,
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return MhTap(
        haptic: MhHaptic.impact,
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MhColors.brand,
            borderRadius: BorderRadius.circular(MhRadius.button),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                        color: MhColors.brandShadow, offset: Offset(0, 4)),
                  ]
                : null,
          ),
          child: Text(label,
              style: MhText.custom(
                  size: 16, weight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }
}
