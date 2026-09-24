import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/ui/my/view_models/nickname_provider.dart';

/// 닉네임은 MY에서 고치고 승부예측 탭이 읽는다.
///
/// [PreferencesRepository]는 `Provider`라 내부 값이 바뀌어도 아무도 다시
/// 그리지 않는다. 저장소에 직접 쓰면 MY만 바뀌고 승부예측 탭은 옛 이름으로
/// 남는데, 화면을 안 보면 알아챌 수 없는 종류라 여기서 잡는다.
void main() {
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(PreferencesRepository()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('저장하면 지켜보던 쪽에 바로 전달된다', () async {
    final c = container();
    final seen = <String>[];
    c.listen(nicknameProvider, (_, next) => seen.add(next));

    expect(c.read(nicknameProvider), '');
    await c.read(nicknameProvider.notifier).set('날쌘피벗');

    expect(c.read(nicknameProvider), '날쌘피벗');
    expect(seen, ['날쌘피벗']);
  });

  test('앞뒤 공백은 저장소가 떼고, 그 결과가 내려온다', () async {
    final c = container();
    await c.read(nicknameProvider.notifier).set('  호크스  ');

    expect(c.read(nicknameProvider), '호크스');
    expect(c.read(preferencesRepositoryProvider).nickname, '호크스');
  });

  test('처음 정한 달을 가입 시점으로 잡고, 바꿔도 밀리지 않는다', () async {
    final c = container();
    final prefs = c.read(preferencesRepositoryProvider);

    expect(prefs.joinedLabel, isNull);
    await c.read(nicknameProvider.notifier).set('호크스');
    final joined = prefs.joinedLabel;
    expect(joined, isNotNull);

    await c.read(nicknameProvider.notifier).set('두산팬');
    expect(prefs.joinedLabel, joined);
  });
}
