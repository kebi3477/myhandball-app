import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/services/mock_handball_api_service.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/ui/core/themes/theme.dart';
import 'package:myhandball/ui/core/themes/tokens.dart';
import 'package:myhandball/ui/home/widgets/profile_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 승부예측 프로필 시트.
///
/// **동의는 여기가 아니라 온보딩에서 받는다** (`test/onboarding_consent_test.dart`).
/// 이 시트는 그 뒤의 편집용이다.
/// 시트 안에 무한 애니메이션(스피너)이 있어 `pumpAndSettle`을 쓸 수 없다.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // 목업의 사용자 콘텐츠는 static이라 앞 테스트가 만든 프로필이 남는다.
    MockHandballApiService.resetUserContent();
  });

  /// 시트가 기본 800x600보다 길다. 좁혀 두면 버튼이 화면 밖이라 눌리지 않는다.
  void sized(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<PreferencesRepository> open(WidgetTester tester) async {
    sized(tester);
    const api = MockHandballApiService(latency: Duration.zero);
    // `load()`는 부르지 않는다 — 위젯 테스트에서 Keychain 채널이 응답하지
    // 않아 멈춘다. 시트가 보는 값은 메모리에만 있어도 된다.
    final prefs = PreferencesRepository();
    final teams = await api.fetchTeams(Gender.men);
    await prefs.setMyTeam(teams.first);

    final container = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(prefs),
      handballApiServiceProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildMhTheme(MhPalette.dark),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showProfileSheet(context),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    // `pumpAndSettle`은 팀 목록을 기다리는 스피너에서 멈추지 않는다.
    await _settle(tester);
    return prefs;
  }

  testWidgets('닉네임과 응원팀만 맞으면 저장된다', (tester) async {
    // 동의는 온보딩에서 이미 받았으므로 시트에서 다시 묻지 않는다.
    final prefs = await open(tester);

    await tester.enterText(find.byType(TextField), '날쌘피벗12');
    await tester.pump();
    expect(find.text('사용할 수 있는 닉네임이에요'), findsOneWidget);
    expect(find.textContaining('공개에 동의해요'), findsNothing);

    await tester.tap(find.text('랭킹 참여하기'));
    await _settle(tester);

    expect(prefs.cachedProfile?.nickname, '날쌘피벗12');
    // 저장하면 MY 화면의 닉네임도 같은 이름이 된다.
    expect(prefs.nickname, '날쌘피벗12');
  });

  testWidgets('중복 닉네임은 서버 문구를 그대로 보여주고 시트를 닫지 않는다', (tester) async {
    final prefs = await open(tester);

    await tester.enterText(find.byType(TextField), '중복닉네임');
    await tester.pump();
    await tester.tap(find.text('랭킹 참여하기'));
    await _settle(tester);

    expect(find.text('이미 사용 중인 닉네임이에요'), findsOneWidget);
    expect(find.text('랭킹 참여하기'), findsOneWidget);
    expect(prefs.cachedProfile, isNull);
  });

  testWidgets('운영자를 사칭하는 이름은 저장 전에 막는다', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), '운영자');
    await tester.pump();

    expect(find.text('사용할 수 없는 단어가 들어 있어요'), findsOneWidget);
  });

  testWidgets('추천을 누르면 규칙을 통과하는 이름이 들어온다', (tester) async {
    await open(tester);

    await tester.tap(find.text('추천'));
    await tester.pump();

    expect(find.text('사용할 수 있는 닉네임이에요'), findsOneWidget);
  });
}
