import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../data/repositories/preferences_repository.dart';

/// 규칙 가이드 진행도(완료한 레슨 수).
///
/// 홈 배너와 MY 배지가 **이 값을 지켜본다.** 예전에는 두 화면이 각자
/// `build()` 시점의 `prefs.guideDoneCount`를 복사해 들고 있어서, 가이드를
/// 수료해도 화면을 새로 고치기 전까지 `0/5`로 남아 있었다.
///
/// 저장은 여전히 [PreferencesRepository]가 한다. 이건 그 값을 화면에
/// 흘려보내는 통로일 뿐이다.
class GuideDoneCount extends Notifier<int> {
  @override
  int build() => ref.read(preferencesRepositoryProvider).guideDoneCount;

  bool get allDone => state >= AppConfig.guideLessonCount;

  Future<void> set(int value) async {
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setGuideDoneCount(value);
    // 저장소가 0~5로 잘라내므로 그 결과를 다시 읽는다.
    state = prefs.guideDoneCount;
  }
}

final guideDoneCountProvider =
    NotifierProvider<GuideDoneCount, int>(GuideDoneCount.new);
