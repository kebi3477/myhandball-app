// 디자인 확인용 프리뷰. `flutter test --update-goldens tool/design_preview_test.dart`
// 로 tool/preview/*.png 를 만든다. `flutter test`의 기본 대상(test/)에 없으므로
// CI를 깨지 않는다.
//
// 주의: 테스트 환경은 커스텀 폰트를 로드하지 않아 **본문이 네모로 렌더된다.**
// 레이아웃 확인용이고, 타이포 확인은 시뮬레이터로 한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/ui/core/themes/theme.dart';
import 'package:myhandball/ui/core/themes/tokens.dart';
import 'package:myhandball/ui/home/widgets/home_screen.dart';
import 'package:myhandball/ui/onboarding/widgets/onboarding_screen.dart';

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget child,
  MhPalette palette, {
  Size size = const Size(390, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(PreferencesRepository()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildMhTheme(palette),
        home: Scaffold(backgroundColor: palette.bg, body: child),
      ),
    ),
  );
  // 목업 서비스의 지연(500ms)과 스켈레톤이 끝날 때까지 기다린다.
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 300));

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('preview/$name.png'),
  );
}

void main() {
  testWidgets('home dark', (t) async {
    await _shoot(t, 'home-dark', const HomeScreen(), MhPalette.dark);
  });

  testWidgets('home light', (t) async {
    await _shoot(t, 'home-light', const HomeScreen(), MhPalette.light);
  });

  testWidgets('onboarding', (t) async {
    await _shoot(t, 'onboarding', const OnboardingScreen(), MhPalette.dark,
        size: const Size(390, 844));
  });
}
