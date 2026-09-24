import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/domain/models/prediction.dart';
import 'package:myhandball/domain/models/team.dart';
import 'package:myhandball/ui/core/themes/theme.dart';
import 'package:myhandball/ui/core/themes/tokens.dart';
import 'package:myhandball/ui/home/view_models/prediction_view_model.dart';
import 'package:myhandball/ui/home/widgets/prediction_tab.dart';

const _team = Team(name: 'SK호크스', teamNum: 101);

const _profile = PredictionProfile(
  nickname: '날쌘피벗12',
  teamNum: 101,
  teamName: 'SK호크스',
  gender: Gender.men,
);

PredictionState _state({
  Leaderboard? leaderboard,
  List<FandomRow>? fandom,
  PredictionProfile? profile = _profile,
}) =>
    PredictionState(
      profile: profile,
      team: _team,
      seasonLabel: '25-26 시즌 최종',
      division: PredictionDivision.all,
      rows: const [],
      history: const [],
      isOffseason: true,
      scope: LeaderboardScope.all,
      leaderboard: leaderboard,
      fandom: fandom,
      fandomGender: Gender.men,
      mine: const MyPredictions(
          count: 12, settled: 11, hits: 6, rate: 54.5, items: []),
    );

class _FakeVm extends PredictionViewModel {
  _FakeVm(this._state);

  final PredictionState _state;
  int refreshes = 0;

  @override
  Future<PredictionState> build() async => _state;

  @override
  Future<void> refresh() async => refreshes++;
}

Future<_FakeVm> _pump(WidgetTester tester, PredictionState state) async {
  final fake = _FakeVm(state);
  final container = ProviderContainer(
    overrides: [predictionViewModelProvider.overrideWith(() => fake)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildMhTheme(MhPalette.dark),
        home: const Scaffold(body: PredictionTab()),
      ),
    ),
  );
  await tester.pump();
  return fake;
}

void main() {
  testWidgets('서버 랭킹을 그대로 그린다', (tester) async {
    await _pump(
      tester,
      _state(
        leaderboard: const Leaderboard(
          scope: LeaderboardScope.all,
          minSettled: 10,
          total: 1240,
          rows: [
            LeaderboardRow(
              rank: 1,
              nickname: '피벗왕',
              teamName: '두산',
              settled: 15,
              hits: 12,
              rate: 80,
              isMe: false,
            ),
            LeaderboardRow(
              rank: 2,
              nickname: '날쌘피벗12',
              teamName: 'SK호크스',
              settled: 11,
              hits: 6,
              rate: 54.5,
              isMe: true,
            ),
          ],
          // 서버는 내가 rows 안에 있어도 me를 채워 준다.
          me: LeaderboardRow(
            rank: 2,
            nickname: '날쌘피벗12',
            teamName: 'SK호크스',
            settled: 11,
            hits: 6,
            rate: 54.5,
            isMe: true,
          ),
          meTopPercent: 1,
        ),
        fandom: const [],
      ),
    );

    expect(find.text('피벗왕'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('12 / 15'), findsOneWidget);
    // 내 줄에는 '나' 배지가 붙는다.
    expect(find.text('나'), findsOneWidget);
    expect(find.textContaining('참여 1,240명'), findsOneWidget);
    // 프로필 카드의 등수도 서버 값이다.
    expect(find.text('2위'), findsOneWidget);
    expect(find.text('전체 상위 1%'), findsOneWidget);
  });

  testWidgets('랭킹을 못 받으면 빈 랭킹 대신 다시 시도를 띄운다', (tester) async {
    // "아직 아무도 없다"와 "연결이 안 됐다"가 같은 화면이 되면 안 된다.
    final fake = await _pump(tester, _state(fandom: const []));

    expect(find.text('집계를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('아직 랭킹에 오른 사람이 없어요'), findsNothing);

    await tester.tap(find.text('다시 시도').first);
    await tester.pump();
    expect(fake.refreshes, 1);
  });

  testWidgets('아무도 없는 랭킹은 비어 있다고 말한다', (tester) async {
    await _pump(
      tester,
      _state(
        leaderboard: const Leaderboard.empty(),
        fandom: const [],
      ),
    );

    expect(find.text('아직 랭킹에 오른 사람이 없어요'), findsOneWidget);
    expect(find.text('집계를 불러오지 못했어요'), findsNothing);
  });

  testWidgets('프로필이 없으면 서버 안내를 그대로 띄운다', (tester) async {
    await _pump(
      tester,
      _state(
        profile: null,
        leaderboard: const Leaderboard(
          scope: LeaderboardScope.all,
          minSettled: 10,
          total: 0,
          rows: [],
          meHint: '프로필을 만들면 내 순위가 여기에 표시돼요 ›',
        ),
        fandom: const [],
      ),
    );

    expect(find.text('프로필을 만들면 내 순위가 여기에 표시돼요 ›'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('팬덤 적중률은 참여자가 없으면 0%를 그리지 않는다', (tester) async {
    await _pump(
      tester,
      _state(
        leaderboard: const Leaderboard.empty(),
        fandom: const [
          FandomRow(rank: 1, teamNum: 101, teamName: 'SK호크스', fans: 0, rate: 0),
          FandomRow(rank: 2, teamNum: 102, teamName: '두산', fans: 0, rate: 0),
        ],
      ),
    );

    expect(find.text('아직 팬덤 적중률을 낼 만큼 기록이 모이지 않았어요'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });
}
