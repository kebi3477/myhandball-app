// 디자인 확인용 프리뷰. `flutter test --update-goldens tool/design_preview_test.dart`
// 로 tool/preview/*.png 를 만든다. `flutter test`의 기본 대상(test/)에 없으므로
// CI를 깨지 않는다.
//
// 주의: 테스트 환경은 커스텀 폰트를 로드하지 않아 **본문이 네모로 렌더된다.**
// 레이아웃 확인용이고, 타이포 확인은 시뮬레이터로 한다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/services/mock_handball_api_service.dart' as mock;
import 'package:myhandball/data/services/mock_handball_api_service.dart';
import 'package:myhandball/domain/models/game.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/domain/models/guide_lesson.dart';
import 'package:myhandball/domain/models/player_stat.dart';
import 'package:myhandball/domain/models/season.dart';
import 'package:myhandball/ui/core/themes/theme.dart';
import 'package:myhandball/ui/core/themes/tokens.dart';
import 'package:myhandball/ui/core/ui/mh_error_view.dart';
import 'package:myhandball/ui/core/ui/mh_icons.dart';
import 'package:myhandball/ui/game_detail/view_models/game_detail_view_model.dart';
import 'package:myhandball/ui/game_detail/widgets/game_detail_screen.dart';
import 'package:myhandball/ui/guide/view_models/guide_view_model.dart';
import 'package:myhandball/ui/guide/widgets/guide_scene_view.dart';
import 'package:myhandball/ui/home/view_models/home_tab.dart';
import 'package:myhandball/ui/guide/widgets/guide_screen.dart';
import 'package:myhandball/ui/home/view_models/home_view_model.dart';
import 'package:myhandball/ui/home/widgets/home_screen.dart';
import 'package:myhandball/ui/home/widgets/offseason_card.dart';
import 'package:myhandball/ui/my/widgets/my_screen.dart';
import 'package:myhandball/ui/my/widgets/my_badges_section.dart';
import 'package:myhandball/ui/my/view_models/my_view_model.dart';
import 'package:myhandball/domain/models/rank_row.dart';
import 'package:myhandball/domain/models/team.dart';
import 'package:myhandball/data/services/api_client.dart';
import 'package:myhandball/ui/home/widgets/attendance_tab.dart';
import 'package:myhandball/ui/onboarding/view_models/onboarding_view_model.dart';
import 'package:myhandball/ui/onboarding/widgets/onboarding_screen.dart';
import 'package:myhandball/ui/schedule/view_models/schedule_view_model.dart';
import 'package:myhandball/ui/schedule/widgets/schedule_screen.dart';
import 'package:myhandball/ui/search/widgets/search_screen.dart';
import 'package:myhandball/ui/settings/widgets/settings_screen.dart';
import 'package:myhandball/ui/stat/view_models/stat_view_model.dart';
import 'package:myhandball/ui/stat/widgets/stat_screen.dart';
import 'package:myhandball/ui/team_detail/view_models/team_detail_view_model.dart';
import 'package:myhandball/ui/team_detail/widgets/team_detail_screen.dart';

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget child,
  MhPalette palette, {
  Size size = const Size(390, 1400),
  void Function(ProviderContainer container)? after,
  Future<void> Function(WidgetTester tester)? tap,
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

  if (tap != null) {
    await tap(tester);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('preview/$name.png'),
  );
}

void main() {
  // 테스트 환경은 기본적으로 커스텀 폰트를 로드하지 않아 글자가 네모로
  // 렌더된다. 번들에서 Pretendard를 직접 올려 실제 타이포로 확인한다.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard');
    for (final weight in const [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      loader.addFont(rootBundle.load('assets/fonts/Pretendard-$weight.otf'));
    }
    await loader.load();

    // 시안 Impact 자리를 대신하는 디스플레이 폰트.
    final anton = FontLoader('Anton')
      ..addFont(rootBundle.load('assets/fonts/Anton-Regular.ttf'));
    await anton.load();

    // Material 아이콘도 마찬가지로 안 올라와서 전부 네모(□)로 찍힌다.
    // 자물쇠·체크가 깨진 건지 폰트가 없는 건지 구분이 안 되므로 같이 올린다.
    // SDK 안의 폰트를 직접 읽는다 — 앱 번들에는 없다.
    // FLUTTER_ROOT는 `flutter test`가 넣어준다.
    final root = Platform.environment['FLUTTER_ROOT'] ?? '';
    final icons = File('$root/bin/cache/artifacts/material_fonts'
        '/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      final iconLoader = FontLoader('MaterialIcons')
        ..addFont(Future.value(icons.readAsBytesSync().buffer.asByteData()));
      await iconLoader.load();
    } else {
      // ignore: avoid_print
      print('MaterialIcons 폰트를 못 찾았다 — 아이콘은 네모로 찍힌다: ${icons.path}');
    }
  });

  testWidgets('home dark', (t) async {
    await _shoot(t, 'home-dark', const HomeScreen(), MhPalette.dark);
  });

  testWidgets('home prediction tab', (t) async {
    await _shoot(
      t,
      'home-prediction',
      const HomeScreen(),
      MhPalette.dark,
      after: (container) =>
          container.read(homeTabProvider.notifier).select(HomeTab.prediction),
    );
  });

  testWidgets('home attendance tab', (t) async {
    await _shoot(
      t,
      'home-attendance',
      const HomeScreen(),
      MhPalette.dark,
      after: (container) =>
          container.read(homeTabProvider.notifier).select(HomeTab.attendance),
    );
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

  const finishedGame = Game(
    id: 'preview-1',
    home: mock.MockHandballApiService.skHawks,
    away: mock.MockHandballApiService.incheon,
    status: GameStatus.finished,
    meta: '11.09 (일) 14:00',
    broadcast: ['MAXPORTS'],
    scoreHome: 28,
    scoreAway: 26,
    venue: '청주 SK호크스 아레나',
  );

  for (final tab in GameDetailTab.values) {
    testWidgets('game detail ${tab.name}', (t) async {
      await _shoot(
        t,
        'game-${tab.name}',
        const GameDetailScreen(game: finishedGame),
        MhPalette.dark,
        after: (container) => container
            .read(gameDetailViewModelProvider(finishedGame).notifier)
            .selectTab(tab),
      );
    });
  }

  for (final tab in TeamDetailTab.values) {
    testWidgets('team detail ${tab.name}', (t) async {
      await _shoot(
        t,
        'team-${tab.name}',
        const TeamDetailScreen(team: mock.MockHandballApiService.skHawks),
        MhPalette.dark,
        after: (container) => container
            .read(teamDetailViewModelProvider(
                    mock.MockHandballApiService.skHawks)
                .notifier)
            .selectTab(tab),
      );
    });
  }

  // 규칙 가이드 삽화 11개를 한 장에. 시안 SVG와 나란히 놓고 비교하려고 둔다.
  //
  // 등장 애니메이션이 끝나고(최대 2.8초) **반복 애니메이션이 중간쯤 온**
  // 시점에 찍는다. 딱 주기의 0초에 찍으면 아직 안 나타난 요소가 많아
  // 씬이 비어 보인다.
  for (final (name, scenes) in [
    ('guide-scenes-1', GuideScene.values.take(6).toList()),
    ('guide-scenes-2', GuideScene.values.skip(6).toList()),
  ]) {
    testWidgets(name, (t) async {
    t.view.physicalSize = const Size(390, 1500);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildMhTheme(MhPalette.dark),
      home: Scaffold(
        backgroundColor: MhPalette.dark.bg,
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final scene in scenes) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(scene.name,
                    style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 11,
                        color: Colors.white70)),
              ),
              GuideSceneView(scene: scene),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ));

    for (var i = 0; i < 44; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/$name.png'),
    );
    });
  }

  // 연·월 선택 바텀시트. 월 칩을 실제로 눌러서 띄운다.
  testWidgets('schedule year-month picker', (t) async {
    await _shoot(
      t,
      'schedule-ym-picker',
      const ScheduleScreen(),
      MhPalette.dark,
      size: const Size(390, 780),
      after: (_) {},
      tap: (tester) async {
        // 월 라벨 칩을 눌러 연·월 피커를 연다.
        await tester.tap(find.textContaining(RegExp(r'년 \d+월')).first);
      },
    );
  });

  // 시안 데모 상태: 오프라인 / 서버 오류 / 비시즌

  // 배지 세 종류를 딴 상태와 못 딴 상태로 나란히 본다. 실제 화면에서는
  // 기록이 쌓여야 보여서, 색·문양을 눈으로 대조할 자리가 여기뿐이다.
  testWidgets('my badges', (t) async {
    t.view.physicalSize = const Size(390, 420);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    const team = Team(name: 'SK호크스');
    const rank = RankRow(
        rank: 1, team: team, points: 20, played: 20, wins: 10, losses: 10);

    MyState build({required bool earned}) => MyState(
          team: team,
          rank: rank,
          favoritePlayers: const [],
          teamPlayers: const [],
          nextGame: null,
          recentGames: const [],
          attendance: [
            for (var i = 0; i < (earned ? 3 : 1); i++)
              const AttendanceRecord(
                matchLabel: 'SK호크스 vs 두산',
                dateLabel: '11.09',
                venue: 'SK호크스 홈구장',
                score: '28 : 26',
                result: '승',
              ),
          ],
          predictions: [
            for (var i = 0; i < (earned ? 12 : 4); i++)
              const PredictionRecord(
                matchLabel: 'SK호크스 vs 두산',
                pickLabel: 'SK호크스 승',
                dateLabel: '11.09',
                settled: true,
                hit: true,
              ),
          ],
        );

    final prefs = PreferencesRepository();
    await prefs.setGuideDoneCount(5);

    final container = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(prefs),
      handballApiServiceProvider.overrideWithValue(
        const MockHandballApiService(latency: Duration.zero),
      ),
    ]);
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildMhTheme(MhPalette.dark),
        home: Scaffold(
          backgroundColor: MhPalette.dark.bg,
          body: ListView(children: [
            const SizedBox(height: 12),
            MyBadgesSection(state: build(earned: true)),
            const SizedBox(height: 20),
            MyBadgesSection(state: build(earned: false)),
          ]),
        ),
      ),
    ));
    await t.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/my-badges.png'),
    );
  });

  // 기록 추가 시트 — 체크를 켜고 끄는 시트라 이미 기록한 경기도 남는다.
  testWidgets('attendance sheet', (t) async {
    await _shoot(
      t,
      'attendance-sheet',
      const AttendanceTab(),
      MhPalette.dark,
      size: const Size(390, 900),
      tap: (tester) async {
        await tester.tap(find.text('기록 추가'));
      },
    );
  });

  testWidgets('states', (t) async {
    t.view.physicalSize = const Size(390, 1340);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    // 개막일을 모를 때 — 큰 자리에 개막 달이 들어간다.
    const offseason = HomeState(
      games: [],
      ranking: [],
      topPlayers: [],
      gender: Gender.men,
      category: StatCategory.goals,
    );
    // 알림을 꺼 둔 경우 — 아래 한 줄이 "알려드릴게요" 대신 담백해진다.
    // (큰 자리가 "이번 달"로 바뀌는 분기는 개막 달에만 나와서 여기선 못
    //  찍는다. `test/offseason_card_test.dart`가 대신 잡는다.)
    final thisMonth = HomeState(
      games: const [],
      ranking: const [],
      topPlayers: const [],
      gender: Gender.men,
      category: StatCategory.goals,
      notificationsOn: false,
    );
    final opening = HomeState(
      games: const [],
      ranking: const [],
      topPlayers: const [],
      gender: Gender.men,
      category: StatCategory.goals,
      nextSeasonOpensAt: DateTime.now().add(const Duration(days: 53)),
    );

    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildMhTheme(MhPalette.dark),
      home: Scaffold(
        backgroundColor: MhPalette.dark.bg,
        body: ListView(
          children: [
            const MhErrorView(
              error: ApiException('서버에 연결하지 못했어요'),
            ),
            const Divider(height: 1),
            MhErrorView(
              error: const ApiException('요청에 실패했어요 (500)',
                  statusCode: 500),
              onRetry: () {},
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),
            OffseasonCard(state: opening, onSeeSchedule: () {}),
            const SizedBox(height: 16),
            OffseasonCard(state: offseason, onSeeSchedule: () {}),
            OffseasonCard(state: thisMonth, onSeeSchedule: () {}),
          ],
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/states.png'),
    );
  });

  // 아이콘이 부모 제약에 따라 얼마나 커지는지 — Material 과 나란히 비교
  testWidgets('icon sizes', (t) async {
    t.view.physicalSize = const Size(390, 420);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    Widget row(String label, Widget a, Widget b, Widget c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            SizedBox(width: 92, child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 11))),
            Container(color: Colors.red.withValues(alpha: 0.25), child: a),
            const SizedBox(width: 16),
            Container(color: Colors.red.withValues(alpha: 0.25), child: b),
            const SizedBox(width: 16),
            Container(color: Colors.red.withValues(alpha: 0.25), child: c),
          ]),
        );

    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('느슨 / SizedBox 48x36 / SizedBox 32x32',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
            row('MhIcon 18',
                const MhIcon(MhIcons.chevLeft, size: 18, color: Colors.white),
                const SizedBox(width: 48, height: 36,
                    child: MhIcon(MhIcons.chevLeft, size: 18, color: Colors.white)),
                const SizedBox(width: 32, height: 32,
                    child: MhIcon(MhIcons.chevLeft, size: 18, color: Colors.white))),
            row('Material 18',
                const Icon(Icons.chevron_left, size: 18, color: Colors.white),
                const SizedBox(width: 48, height: 36,
                    child: Icon(Icons.chevron_left, size: 18, color: Colors.white)),
                const SizedBox(width: 32, height: 32,
                    child: Icon(Icons.chevron_left, size: 18, color: Colors.white))),
            row('MhIcon 30',
                const MhIcon(MhIcons.heart, size: 30, color: Colors.white),
                const SizedBox(width: 72, height: 72,
                    child: MhIcon(MhIcons.heart, size: 30, color: Colors.white)),
                const SizedBox(width: 32, height: 32,
                    child: MhIcon(MhIcons.heart, size: 30, color: Colors.white))),
          ]),
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 200));
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('preview/icon-sizes.png'));
  });

  testWidgets('season picker', (t) async {
    t.view.physicalSize = const Size(390, 640);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildMhTheme(MhPalette.dark),
      home: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: MhPalette.dark.bg,
          body: Center(
            child: TextButton(
              onPressed: () => showSeasonPicker(context, Season.current),
              child: const Text('열기'),
            ),
          ),
        );
      }),
    ));
    await t.tap(find.text('열기'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 80));
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/season-picker.png'),
    );
  });

  testWidgets('search idle', (t) async {
    await _shoot(t, 'search-idle', const SearchScreen(), MhPalette.dark,
        size: const Size(390, 700));
  });

  testWidgets('guide path', (t) async {
    await _shoot(t, 'guide-path', const GuideScreen(), MhPalette.dark,
        size: const Size(390, 900));
  });

  testWidgets('guide lesson', (t) async {
    await _shoot(
      t,
      'guide-lesson',
      const GuideScreen(),
      MhPalette.dark,
      size: const Size(390, 900),
      after: (container) =>
          container.read(guideViewModelProvider.notifier).openLesson(0),
    );
  });

  testWidgets('guide quiz', (t) async {
    await _shoot(
      t,
      'guide-quiz',
      const GuideScreen(),
      MhPalette.dark,
      size: const Size(390, 900),
      after: (container) {
        final vm = container.read(guideViewModelProvider.notifier);
        vm.openLesson(0);
        vm.next();
        vm.next();
        vm.next();
        vm.pick(1);
      },
    );
  });

  testWidgets('onboarding', (t) async {
    await _shoot(t, 'onboarding', const OnboardingScreen(), MhPalette.dark,
        size: const Size(390, 844));
  });

  // figassets 아이콘 4개가 실제로 들어왔는지 확인하는 컷.
  testWidgets('onboarding nickname', (t) async {
    await _shoot(
      t,
      'onboarding-nickname',
      const OnboardingScreen(),
      MhPalette.dark,
      after: (container) => container
          .read(onboardingViewModelProvider.notifier)
          .goTo(OnboardingState.nicknameStep),
    );
  });

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
