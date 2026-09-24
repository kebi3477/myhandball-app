import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';

/// 닉네임을 화면들에 흘려보내는 통로.
///
/// [guideDoneCountProvider]와 같은 이유로 있다. MY의 프로필 카드와 홈 ·
/// 승부예측 탭의 프로필이 **각자 `build()` 시점의 `prefs.nickname`을 복사해**
/// 들고 있으면, MY에서 닉네임을 바꿔도 승부예측 탭은 화면을 새로 고치기
/// 전까지 옛 이름으로 남는다. `PreferencesRepository`는 `Provider`라
/// 내부 값이 바뀌어도 아무도 다시 그리지 않는다.
///
/// 저장은 여전히 저장소가 한다. 이건 그 값이 바뀐 걸 알리는 역할만 한다.
class NicknameNotifier extends Notifier<String> {
  @override
  String build() => ref.read(preferencesRepositoryProvider).nickname;

  Future<void> set(String value) async {
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setNickname(value);
    // 저장소가 앞뒤 공백을 떼므로 그 결과를 다시 읽는다.
    state = prefs.nickname;
  }
}

final nicknameProvider =
    NotifierProvider<NicknameNotifier, String>(NicknameNotifier.new);
