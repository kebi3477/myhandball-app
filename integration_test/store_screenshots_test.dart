// 스토어 스크린샷 촬영용 화면 이동. 직접 돌리지 않고 tool/store_screenshots.sh가
// 부른다 — 이 테스트가 `MH_SHOT <이름>`을 찍고 멈춰 있는 동안 스크립트가
// 시뮬레이터 화면(상태바 포함)을 캡처한다.
//
// 푸시 권한 창·광고 동의 창·테스트 광고가 찍히지 않게 둘 다 뺀다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/services/ads_service.dart';
import 'package:myhandball/ui/app/widgets/my_handball_app.dart';

/// 일정 탭을 이 달로 옮겨 찍는다 — 비시즌에는 이번 달이 비어 있다.
/// 예전 스크린샷(2026-09-25)과 같은 2025-26 시즌 막바지다.
const _scheduleMonth = (2026, 4);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('스토어 스크린샷', (tester) async {
    final preferences = PreferencesRepository();
    await preferences.load();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(preferences),
        pushServiceProvider.overrideWithValue(null),
        adsServiceProvider.overrideWithValue(null),
      ],
      child: const MyHandballApp(),
    ));

    await _idle(tester, seconds: 6);
    await _shot(tester, '01-home');

    await _tapNav(tester, '일정');
    await _idle(tester, seconds: 3);
    final now = DateTime.now();
    final back = (now.year - _scheduleMonth.$1) * 12 + now.month - _scheduleMonth.$2;
    for (var i = 0; i < back; i++) {
      await tester.tap(find.text('<').first);
      await _idle(tester, seconds: 1);
    }
    await _idle(tester, seconds: 3);
    await _shot(tester, '02-schedule');

    await _tapNav(tester, '분석');
    await _idle(tester, seconds: 4);
    await _shot(tester, '03-stat');

    await _tapNav(tester, 'MY');
    await _idle(tester, seconds: 4);
    await _shot(tester, '04-my');

    await _tapNav(tester, '홈');
    await tester.tap(find.text('승부예측').first);
    await _idle(tester, seconds: 4);
    await _shot(tester, '05-prediction');

    await tester.tap(find.text('직관').first);
    await _idle(tester, seconds: 4);
    await _shot(tester, '06-attendance');
  });
}

/// 하단 탭바의 라벨. 화면 제목과 글자가 겹칠 수 있어 맨 아래 것을 누른다.
Future<void> _tapNav(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await _idle(tester, seconds: 1);
}

/// 실제 시간을 흘려 네트워크 응답과 애니메이션이 끝나게 한다.
/// 스켈레톤처럼 계속 도는 애니메이션이 있어 pumpAndSettle은 쓰지 않는다.
Future<void> _idle(WidgetTester tester, {required int seconds}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
    await tester.pump();
  }
}

/// 스크립트가 이 줄을 보고 캡처한다. 캡처하는 동안 화면을 그대로 둔다.
Future<void> _shot(WidgetTester tester, String name) async {
  debugPrint('MH_SHOT $name');
  await _idle(tester, seconds: 4);
}
