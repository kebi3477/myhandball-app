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
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/services/mock_handball_api_service.dart';
import 'package:myhandball/ui/core/themes/theme.dart';
import 'package:myhandball/ui/core/themes/tokens.dart';
import 'package:myhandball/ui/home/widgets/home_screen.dart';
import 'package:myhandball/ui/my/widgets/my_screen.dart';
import 'package:myhandball/ui/onboarding/view_models/onboarding_view_model.dart';
import 'package:myhandball/ui/onboarding/widgets/onboarding_screen.dart';
import 'package:myhandball/ui/schedule/view_models/schedule_view_model.dart';
import 'package:myhandball/ui/schedule/widgets/schedule_screen.dart';
import 'package:myhandball/ui/stat/view_models/stat_view_model.dart';
import 'package:myhandball/ui/stat/widgets/stat_screen.dart';

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget child,
  MhPalette palette, {
  Size size = const Size(390, 1400),
  void Function(ProviderContainer container)? after,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // 달력 뷰를 보려면 마이팀이 있어야 한다.
  final prefs = PreferencesRepository();
  prefs.setMyTeam(MockHandballApiService.skHawks);

  final container = ProviderContainer(
    overrides: [
      preferencesRepositoryProvider.overrideWithValue(prefs),
      // 지연 0. MY 탭은 목업 호출이 4번 이어져 기본 지연(500ms)으로는
      // 프리뷰가 로딩 상태에서 끝난다.
      handballApiServiceProvider.overrideWithValue(
        const MockHandballApiService(latency: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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

  if (after != null) {
    after(container);
    // PageView 전환(500ms) 같은 애니메이션이 끝날 때까지 여러 프레임 돌린다.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

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

  testWidgets('schedule list', (t) async {
    await _shoot(t, 'schedule-list', const ScheduleScreen(), MhPalette.dark);
  });

  testWidgets('schedule calendar', (t) async {
    await _shoot(
      t,
      'schedule-calendar',
      const ScheduleScreen(),
      MhPalette.dark,
      after: (container) => container
          .read(scheduleViewModelProvider.notifier)
          .setView(ScheduleView.calendar),
    );
  });

  for (final tab in StatTab.values) {
    testWidgets('stat ${tab.name}', (t) async {
      await _shoot(
        t,
        'stat-${tab.name}',
        const StatScreen(),
        MhPalette.dark,
        after: (container) =>
            container.read(statViewModelProvider.notifier).selectTab(tab),
      );
    });
  }

  testWidgets('my', (t) async {
    await _shoot(t, 'my', const MyScreen(), MhPalette.dark,
        size: const Size(390, 2100));
  });

  testWidgets('onboarding', (t) async {
    await _shoot(t, 'onboarding', const OnboardingScreen(), MhPalette.dark,
        size: const Size(390, 844));
  });

  // figassets 아이콘 4개가 실제로 들어왔는지 확인하는 컷.
  testWidgets('onboarding interest', (t) async {
    await _shoot(
      t,
      'onboarding-interest',
      const OnboardingScreen(),
      MhPalette.dark,
      size: const Size(390, 844),
      after: (container) =>
          container.read(onboardingViewModelProvider.notifier).goTo(1),
    );
  });
}
