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
  });

  /// 완료한 레슨 수.
  final int doneCount;

  /// 열려 있는 레슨. null이면 레슨 목록 화면.
  final int? lessonIndex;

  /// 레슨 안에서 보고 있는 페이지 (스텝들 다음에 퀴즈).
  final int page;

  /// 퀴즈에서 고른 보기. null이면 아직 안 골랐다.
  final int? pickedOption;

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

  String get headline => allDone
      ? '핸드볼 입문 수료!'
      : (doneCount == 0 ? '3분이면 규칙 끝!' : '조금만 더 하면 수료예요');

  /// 시안은 앞 레슨을 끝내야 다음이 열린다.
  bool isUnlocked(int index) => index <= doneCount;

  bool isDone(int index) => index < doneCount;

  GuideState copyWith({
    int? doneCount,
    int? lessonIndex,
    bool clearLesson = false,
    int? page,
    int? pickedOption,
    bool clearPick = false,
  }) =>
      GuideState(
        doneCount: doneCount ?? this.doneCount,
        lessonIndex: clearLesson ? null : (lessonIndex ?? this.lessonIndex),
        page: page ?? this.page,
        pickedOption: clearPick ? null : (pickedOption ?? this.pickedOption),
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

  void exitLesson() =>
      state = state.copyWith(clearLesson: true, page: 0, clearPick: true);

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
    if (index == state.doneCount) {
      final done = state.doneCount + 1;
      // 홈 배너·MY 배지가 바로 따라오도록 공용 진행도를 통해 저장한다.
      await ref.read(guideDoneCountProvider.notifier).set(done);
      state = state.copyWith(doneCount: ref.read(guideDoneCountProvider));
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
