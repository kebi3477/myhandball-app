import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../domain/models/guide_lesson.dart';
import 'guide_progress.dart';

class GuideState {
  const GuideState({
    required this.doneCount,
    this.lessonIndex,
    this.page = 0,
    this.pickedOption,
    this.finishedLesson,
    this.justGraduated = false,
  });

  /// 완료한 레슨 수.
  final int doneCount;

  /// 열려 있는 레슨. null이면 레슨 목록 화면.
  final int? lessonIndex;

  /// 레슨 안에서 보고 있는 페이지 (스텝들 다음에 퀴즈).
  final int page;

  /// 퀴즈에서 고른 보기. null이면 아직 안 골랐다.
  final int? pickedOption;

  /// 방금 끝낸 레슨. null이 아니면 완료 화면을 띄운다 (시안 `guideDone`).
  ///
  /// 끝내자마자 목록으로 돌아가면 뭘 했는지 남는 게 없다. 시안이 마스코트와
  /// 퀴즈 결과를 한 번 보여주고 다음 레슨으로 넘긴다.
  final int? finishedLesson;

  /// 시안 `justGraduated` — 이번 완료로 5개를 다 채웠는지.
  final bool justGraduated;

  bool get showingDone => finishedLesson != null;

  GuideLesson? get finished => finishedLesson == null
      ? null
      : HandballGuide.lessons[finishedLesson!];

  /// 시안 `doneNextLabel`.
  String get doneNextLabel =>
      finishedLesson == null || finishedLesson! >= HandballGuide.lessons.length - 1
          ? '가이드 완료'
          : '다음 레슨';

  /// 시안 `doneHeadline`.
  String get doneHeadline => justGraduated ? '입문 가이드 수료!' : '레슨 완료!';

  /// 시안 `doneTitle`.
  String get doneTitle =>
      finished == null ? '' : '${finished!.title} 레슨을 끝냈어요';

  bool get inLesson => lessonIndex != null;

  GuideLesson? get lesson =>
      lessonIndex == null ? null : HandballGuide.lessons[lessonIndex!];

  bool get isQuizPage => lesson != null && page >= lesson!.steps.length;

  GuideStep? get step =>
      isQuizPage || lesson == null ? null : lesson!.steps[page];

  bool? get isCorrect =>
      pickedOption == null ? null : pickedOption == lesson?.quiz.answerIndex;

  double get lessonProgress =>
      lesson == null ? 0 : (page + 1) / lesson!.pageCount;

  bool get allDone => doneCount >= AppConfig.guideLessonCount;

  double get overallProgress => doneCount / AppConfig.guideLessonCount;

  /// 시안 `guideHeadline`.
  String get headline => allDone
      ? '핸드볼 마스터 달성!'
      : (doneCount == 0 ? '핸드볼, 같이 배워볼까요?' : '좋아요, 계속 가볼까요?');

  /// 시안은 앞 레슨을 끝내야 다음이 열린다.
  bool isUnlocked(int index) => index <= doneCount;

  bool isDone(int index) => index < doneCount;

  GuideState copyWith({
    int? doneCount,
    int? lessonIndex,
    bool clearLesson = false,
    int? finishedLesson,
    bool clearFinished = false,
    bool? justGraduated,
    int? page,
    int? pickedOption,
    bool clearPick = false,
  }) =>
      GuideState(
        doneCount: doneCount ?? this.doneCount,
        lessonIndex: clearLesson ? null : (lessonIndex ?? this.lessonIndex),
        page: page ?? this.page,
        pickedOption: clearPick ? null : (pickedOption ?? this.pickedOption),
        finishedLesson:
            clearFinished ? null : (finishedLesson ?? this.finishedLesson),
        justGraduated: justGraduated ?? this.justGraduated,
      );
}

class GuideViewModel extends AutoDisposeNotifier<GuideState> {
  @override
  GuideState build() => GuideState(
        doneCount: ref.read(guideDoneCountProvider),
      );

  void openLesson(int index) {
    if (!state.isUnlocked(index)) return;
    state = state.copyWith(lessonIndex: index, page: 0, clearPick: true);
  }

  void exitLesson() => state = state.copyWith(
        clearLesson: true,
        clearFinished: true,
        justGraduated: false,
        page: 0,
        clearPick: true,
      );

  /// 다음 스텝으로. 퀴즈를 맞히면 레슨이 완료된다.
  Future<void> next() async {
    final lesson = state.lesson;
    if (lesson == null) return;

    if (!state.isQuizPage) {
      state = state.copyWith(page: state.page + 1);
      return;
    }

    if (state.isCorrect != true) return;

    final index = state.lessonIndex!;
    final wasAllDone = state.allDone;
    if (index == state.doneCount) {
      final done = state.doneCount + 1;
      // 홈 배너·MY 배지가 바로 따라오도록 공용 진행도를 통해 저장한다.
      await ref.read(guideDoneCountProvider.notifier).set(done);
      state = state.copyWith(doneCount: ref.read(guideDoneCountProvider));
    }
    // 목록으로 바로 돌아가지 않고 완료 화면을 띄운다 (시안 `guideDone`).
    state = state.copyWith(
      clearLesson: true,
      finishedLesson: index,
      justGraduated: !wasAllDone && state.allDone,
      page: 0,
      clearPick: true,
    );
  }

  /// 완료 화면의 기본 버튼 — 다음 레슨이 있으면 열고, 없으면 목록으로.
  void continueFromDone() {
    final index = state.finishedLesson;
    if (index == null) return;
    final next = index + 1;
    if (next < HandballGuide.lessons.length && state.isUnlocked(next)) {
      state = state.copyWith(
        clearFinished: true,
        justGraduated: false,
        lessonIndex: next,
        page: 0,
        clearPick: true,
      );
      return;
    }
    exitLesson();
  }

  void pick(int option) {
    if (!state.isQuizPage || state.pickedOption != null) return;
    state = state.copyWith(pickedOption: option);
  }

  /// 틀렸을 때 다시 고르기.
  void retryQuiz() => state = state.copyWith(clearPick: true);
}

final guideViewModelProvider =
    NotifierProvider.autoDispose<GuideViewModel, GuideState>(
  GuideViewModel.new,
);
