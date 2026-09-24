import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/models/game.dart';
import 'package:myhandball/domain/models/game_detail.dart';
import 'package:myhandball/domain/models/team.dart';
import 'package:myhandball/ui/core/themes/theme.dart';
import 'package:myhandball/ui/core/themes/tokens.dart';
import 'package:myhandball/ui/game_detail/view_models/game_detail_view_model.dart';
import 'package:myhandball/ui/game_detail/widgets/game_mvp_tab.dart';

const _game = Game(
  id: 'g1',
  matchSeq: 5490,
  home: Team(name: 'SK호크스'),
  away: Team(name: '두산'),
  status: GameStatus.finished,
  meta: '11.09 (일) 14:00',
  scoreHome: 28,
  scoreAway: 26,
);

const _candidates = [
  MvpCandidate(
    id: 'p1',
    name: '강예린',
    teamName: 'SK호크스',
    statLine: '55골 · 15AS',
    votes: 3,
  ),
  MvpCandidate(
    id: 'p2',
    name: '윤서연',
    teamName: '두산',
    statLine: '41골 · 69AS',
    votes: 1,
  ),
];

/// 투표 호출을 받아 적는 가짜 뷰모델.
class _FakeVm extends GameDetailViewModel {
  final voted = <String>[];

  static const fixture = GameDetailState(
    detail: GameDetail(
      game: _game,
      firstHalfHome: 14,
      firstHalfAway: 13,
      events: [],
      stats: [],
      headToHead: HeadToHead(
        homeWins: 0,
        draws: 0,
        awayWins: 0,
        avgHome: 0,
        avgAway: 0,
        games: [],
      ),
    ),
    tab: GameDetailTab.mvp,
    attended: false,
    tally: PredictionTally.empty(),
    mvp: MvpBoard(candidates: _candidates, total: 4, open: true),
  );

  @override
  Future<GameDetailState> build(Game game) async => fixture;

  @override
  Future<void> voteMvp(String candidateId) async => voted.add(candidateId);
}

void main() {
  testWidgets('후보 줄의 빈 곳을 눌러도 투표가 나간다', (tester) async {
    final fake = _FakeVm();
    final container = ProviderContainer(
      overrides: [gameDetailViewModelProvider.overrideWith(() => fake)],
    );
    addTearDown(container.dispose);

    // autoDispose 프로바이더를 미리 read 하면 타이머가 남는다. 상태는
    // 직접 만들고, 프로바이더는 위젯이 알아서 잡게 둔다.
    const state = _FakeVm.fixture;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildMhTheme(MhPalette.dark),
          home: Scaffold(
            backgroundColor: MhPalette.dark.bg,
            body: GameMvpTab(state: state),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('강예린'), findsOneWidget);

    // '투표' 글자 위가 아니라, 줄 가운데의 **빈 곳**을 누른다.
    final row = tester.getRect(find.text('강예린'));
    await tester.tapAt(Offset(row.right + 40, row.center.dy));
    await tester.pump();

    expect(fake.voted, ['p1']);
  });

  testWidgets('이미 투표했으면 누를 수 없고 결과가 보인다', (tester) async {
    // 기기당 한 번만 투표할 수 있다(서버 unique 제약). 투표 뒤에는 모든
    // 줄이 눌리지 않으므로, 머리글이 그 사실을 말해 줘야 한다.
    final fake = _FakeVm();
    final container = ProviderContainer(
      overrides: [gameDetailViewModelProvider.overrideWith(() => fake)],
    );
    addTearDown(container.dispose);

    final state = GameDetailState(
      detail: _FakeVm.fixture.detail,
      tab: GameDetailTab.mvp,
      attended: false,
      tally: const PredictionTally.empty(),
      mvp: const MvpBoard(
          candidates: _candidates, total: 4, open: true, myVoteId: 'p1'),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildMhTheme(MhPalette.dark),
          home: Scaffold(
            backgroundColor: MhPalette.dark.bg,
            body: GameMvpTab(state: state),
          ),
        ),
      ),
    );
    await tester.pump();

    // 시안 `mvp.total`표 · `mvp.hint`
    expect(find.text('4표 · 투표 완료'), findsOneWidget);
    // 투표 전에는 모든 줄이 '투표', 후에는 득표율이 보인다.
    expect(find.text('투표'), findsNothing);

    await tester.tap(find.text('강예린'));
    await tester.pump();
    expect(fake.voted, isEmpty);
  });
}
