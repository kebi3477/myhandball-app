import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/ui/ads/view_models/ads_view_model.dart';
import 'package:myhandball/ui/app/view_models/app_update_view_model.dart';
import 'package:myhandball/ui/core/themes/theme.dart';
import 'package:myhandball/ui/core/themes/tokens.dart';
import 'package:myhandball/ui/settings/widgets/blocked_users_screen.dart';
import 'package:myhandball/ui/settings/widgets/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 설정의 "광고 개인정보 옵션".
///
/// UMP가 요구하는 진입점이라 **동의가 필요한 지역에서는 반드시 있어야 하고**,
/// 한국처럼 필요 없는 곳에서는 보이지 않아야 한다. 처리방침 15항이 이 메뉴를
/// 가리킨다.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<_FakeAds> pumpSettings(WidgetTester tester,
      {required bool privacyOptions}) async {
    final prefs = PreferencesRepository();
    // 실제 비동기 I/O라 가짜 시간(testWidgets) 밖에서 읽는다.
    await tester.runAsync(prefs.load);
    final ads = _FakeAds(AdsState(privacyOptions: privacyOptions));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(prefs),
        appUpdateProvider.overrideWith((ref) async => null),
        blockedAuthorsProvider.overrideWith((ref) async => []),
        adsViewModelProvider.overrideWith(() => ads),
      ],
      child: MaterialApp(
        theme: buildMhTheme(MhPalette.light),
        home: const SettingsScreen(),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return ads;
  }

  testWidgets('동의가 필요한 지역이면 메뉴가 보이고, 누르면 동의 창을 연다',
      (tester) async {
    final ads = await pumpSettings(tester, privacyOptions: true);

    await tester.tap(find.text('광고 개인정보 옵션'));
    await tester.pump();
    expect(ads.opened, 1);
  });

  testWidgets('필요 없는 지역이면 메뉴가 없다', (tester) async {
    await pumpSettings(tester, privacyOptions: false);
    expect(find.text('광고 개인정보 옵션'), findsNothing);
  });
}

class _FakeAds extends AdsViewModel {
  _FakeAds(this._initial);

  final AdsState _initial;
  int opened = 0;

  @override
  AdsState build() => _initial;

  @override
  Future<void> openPrivacyOptions() async => opened++;
}
