import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/services/mock_handball_api_service.dart';
import 'package:myhandball/ui/app/view_models/app_view_model.dart';
import 'package:myhandball/ui/app/widgets/my_handball_app.dart';
import 'package:myhandball/ui/shell/widgets/app_shell.dart';

/// 테스트용 설정 저장소. `onboarded`만 바꿔가며 쓴다.
PreferencesRepository _prefs({bool onboarded = false}) {
  final repo = PreferencesRepository();
  if (onboarded) repo.setOnboarded(value: true);
  return repo;
}

ProviderContainer _container({bool onboarded = false}) {
  final container = ProviderContainer(
    overrides: [
      preferencesRepositoryProvider
          .overrideWithValue(_prefs(onboarded: onboarded)),
      // 지연 없는 목업 — 테스트가 타이머를 기다리지 않게 한다.
      handballApiServiceProvider.overrideWithValue(
        const MockHandballApiService(latency: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _pumpApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MyHandballApp(),
    ),
  );
  // 가이드 배너 마스코트가 무한 반복 애니메이션이라 pumpAndSettle은 끝나지
  // 않는다. 목업이 지연 0이므로 두 프레임이면 데이터가 들어온다.
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('온보딩을 마치지 않으면 온보딩 첫 화면이 뜬다', (tester) async {
    await _pumpApp(tester, _container());

    expect(find.text('마이팀 경기,\n이제 놓치지 않기'), findsOneWidget);
    // 하단 탭바는 아직 없다.
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('온보딩을 마치면 4탭 셸로 들어간다', (tester) async {
    await _pumpApp(tester, _container(onboarded: true));

    expect(find.byType(AppShell), findsOneWidget);
    for (final label in ['일정', '분석', 'MY']) {
      expect(find.text(label), findsOneWidget);
    }
    // '홈'은 하단 탭바와 홈 화면 안의 탭 줄에 하나씩 있다.
    expect(find.text('홈'), findsNWidgets(2));
  });

  testWidgets('홈에 승부예측·직관 탭이 함께 뜬다', (tester) async {
    await _pumpApp(tester, _container(onboarded: true));

    expect(find.text('승부예측'), findsOneWidget);
    expect(find.text('직관'), findsOneWidget);
  });

  testWidgets('테마를 라이트로 바꾸면 팔레트 배경이 흰색이 된다', (tester) async {
    final container = _container(onboarded: true);
    await _pumpApp(tester, container);

    expect(container.read(paletteProvider).bg, const Color(0xFF111111));

    await container.read(appViewModelProvider.notifier).toggleTheme();
    await tester.pump();

    expect(container.read(paletteProvider).bg, const Color(0xFFFFFFFF));
    expect(container.read(appViewModelProvider).themeMode, ThemeMode.light);
  });

  testWidgets('온보딩을 끝내면 앱 본체로 전환된다', (tester) async {
    final container = _container();
    await _pumpApp(tester, container);

    expect(find.byType(AppShell), findsNothing);

    await container.read(appViewModelProvider.notifier).completeOnboarding();
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppShell), findsOneWidget);
  });
}
