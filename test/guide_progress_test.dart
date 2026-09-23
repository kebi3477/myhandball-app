import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/config/app_config.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/ui/guide/view_models/guide_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 규칙 가이드 진행도는 **홈 배너와 MY 배지가 지켜보는 값**이다.
///
/// 예전에는 두 화면이 `build()` 때 `prefs.guideDoneCount`를 복사해 들고
/// 있어서, 레슨을 끝내도 화면을 새로 고치기 전까지 `0/5`로 남았다.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> makeContainer() async {
    final prefs = PreferencesRepository();
    await prefs.load();
    final container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('진행도를 올리면 구독자에게 바로 전달된다', () async {
    final container = await makeContainer();

    final seen = <int>[];
    container.listen(guideDoneCountProvider, (_, next) => seen.add(next));

    expect(container.read(guideDoneCountProvider), 0);

    await container.read(guideDoneCountProvider.notifier).set(1);
    await container.read(guideDoneCountProvider.notifier).set(2);

    expect(seen, [1, 2], reason: '값이 바뀌면 화면이 알아야 한다');
    expect(container.read(guideDoneCountProvider), 2);
  });

  test('레슨 수를 넘겨도 최대치에서 멈춘다', () async {
    final container = await makeContainer();

    await container
        .read(guideDoneCountProvider.notifier)
        .set(AppConfig.guideLessonCount + 3);

    expect(container.read(guideDoneCountProvider), AppConfig.guideLessonCount);
    expect(container.read(guideDoneCountProvider.notifier).allDone, isTrue);
  });

  test('진행도가 기기에 남는다', () async {
    final first = await makeContainer();
    await first.read(guideDoneCountProvider.notifier).set(3);

    // 앱을 껐다 켠 것과 같다.
    final prefs = PreferencesRepository();
    await prefs.load();
    final second = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(prefs)],
    );
    addTearDown(second.dispose);

    expect(second.read(guideDoneCountProvider), 3);
  });
}
