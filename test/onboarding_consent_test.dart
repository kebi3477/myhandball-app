import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/services/mock_handball_api_service.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/ui/onboarding/view_models/onboarding_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 랭킹 공개 동의는 **온보딩에서** 받는다 (시안 `obConsent`).
///
/// 예전에는 승부예측 탭의 프로필 시트(`pfConsent`)에서 받았는데, 온보딩에서
/// 닉네임을 이미 정해 놓고 또 묻는 꼴이었다. 2026-09-25에 옮겼다.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MockHandballApiService.resetUserContent();
  });

  Future<(ProviderContainer, PreferencesRepository)> make() async {
    const api = MockHandballApiService(latency: Duration.zero);
    final prefs = PreferencesRepository();
    final container = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(prefs),
      handballApiServiceProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    return (container, prefs);
  }

  /// 닉네임 스텝까지 올려 둔다.
  Future<OnboardingViewModel> atNicknameStep(ProviderContainer c) async {
    final vm = c.read(onboardingViewModelProvider.notifier);
    final teams = await const MockHandballApiService(latency: Duration.zero)
        .fetchTeams(Gender.men);
    vm
      ..goTo(OnboardingState.nicknameStep)
      ..selectTeam(teams.first)
      ..setNickname('날쌘피벗12');
    return vm;
  }

  test('동의하지 않으면 다음으로 넘어가지 못한다', () async {
    final (container, _) = await make();
    final vm = await atNicknameStep(container);

    // 닉네임이 맞아도 동의가 없으면 막힌다 — 시안이 `(필수)`로 적어 뒀다.
    expect(container.read(onboardingViewModelProvider).canAdvance, isFalse);

    vm.toggleRankingConsent();
    expect(container.read(onboardingViewModelProvider).canAdvance, isTrue);
  });

  test('온보딩을 마치면 랭킹 프로필이 만들어진다', () async {
    // 시안 `goApp` — 들어가고 나서 다시 묻지 않는다.
    final (container, prefs) = await make();
    final vm = await atNicknameStep(container);
    vm
      ..toggleRankingConsent()
      ..goTo(OnboardingState.stepCount - 1);

    await vm.submit();

    expect(prefs.cachedProfile?.nickname, '날쌘피벗12');
    expect(prefs.nickname, '날쌘피벗12');
  });

  test('프로필 생성에 실패해도 온보딩은 끝난다', () async {
    // 닉네임이 겹치거나 서버가 죽었다고 앱을 못 쓰게 두면 안 된다.
    final (container, prefs) = await make();
    final vm = await atNicknameStep(container);
    vm
      ..setNickname('중복닉네임')
      ..toggleRankingConsent()
      ..goTo(OnboardingState.stepCount - 1);

    await vm.submit();

    expect(prefs.cachedProfile, isNull, reason: '서버가 409로 막았다');
    expect(prefs.onboarded, isTrue, reason: '그래도 앱에는 들어가야 한다');
    expect(prefs.nickname, '중복닉네임', reason: '기기 닉네임은 남는다');
  });
}
