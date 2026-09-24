import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/game_detail.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/team.dart';
import '../../my/view_models/nickname_provider.dart';

/// 예측을 저장할 때마다 1 올라간다.
///
/// 홈 탭 줄의 빨간 점이 이걸 본다. 점은 `mh_preds`(저장소의 가변 값)를
/// 읽는데 `PreferencesRepository`는 `Provider`라 값이 바뀌어도 아무도 다시
/// 그리지 않는다. **예측을 다 해도 점이 안 없어지는 걸 막으려고 둔다.**
class PredictionRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final predictionRevisionProvider =
    NotifierProvider<PredictionRevision, int>(PredictionRevision.new);

/// 승부예측 탭의 부 필터. 시안 `pv.divTabs`.
enum PredictionDivision {
  all('전체', null),
  men('남자부', Gender.men),
  women('여자부', Gender.women);

  const PredictionDivision(this.label, this.gender);

  final String label;
  final Gender? gender;
}

/// 예측 한 줄 — 경기 + 서버 집계 + 내 선택.
class PredictionRow {
  const PredictionRow({required this.game, required this.tally});

  final Game game;

  /// 서버 집계. 못 받아오면 `null`이고 분포를 그리지 않는다.
  final PredictionTally? tally;

  PredictionPick? get myPick => tally?.myPick;

  bool get open => tally?.open ?? (game.status == GameStatus.pre);

  /// 시안 `g.stateLabel` — 칩 문구.
  String get stateLabel {
    if (!open) return '마감';
    return myPick == null ? '예측 가능' : '예측 완료';
  }

  /// 분포 막대는 참여자가 있을 때만 그린다. 0명일 때 0%짜리 막대를
  /// 세 개 그려 두면 "아무도 안 찍었다"가 아니라 "고장났다"로 보인다.
  bool get showDistribution => (tally?.total ?? 0) > 0;
}

/// 시안 `myPred` — 내가 참여한 예측의 결과.
class PredictionHistoryRow {
  const PredictionHistoryRow({
    required this.game,
    required this.pick,
    required this.settled,
    required this.hit,
  });

  final Game game;
  final PredictionPick pick;

  /// 경기가 끝나 적중 여부가 정해졌는지.
  final bool settled;
  final bool hit;

  String get matchLabel => '${game.home.name} vs ${game.away.name}';

  String get pickLabel => switch (pick) {
        PredictionPick.home => '${game.home.name} 승',
        PredictionPick.away => '${game.away.name} 승',
        PredictionPick.draw => '무승부',
      };

  /// 시안 `r.chip` — `적중` / `실패` / `대기`
  String get chipLabel => settled ? (hit ? '적중' : '실패') : '대기';
}

class PredictionState {
  const PredictionState({
    required this.nickname,
    required this.team,
    required this.joinedLabel,
    required this.seasonLabel,
    required this.division,
    required this.rows,
    required this.history,
    required this.isOffseason,
  });

  /// 온보딩에서 정한 닉네임. 비어 있으면 아직 프로필이 없다.
  final String nickname;
  final Team? team;
  final String? joinedLabel;

  /// `25-26 정규리그`
  final String seasonLabel;

  final PredictionDivision division;
  final List<PredictionRow> rows;
  final List<PredictionHistoryRow> history;
  final bool isOffseason;

  /// 시안 `pv.hasProfile` — 닉네임과 응원팀이 다 있어야 랭킹에 올라간다.
  bool get hasProfile => nickname.isNotEmpty && team != null;

  List<PredictionHistoryRow> get _settled =>
      history.where((h) => h.settled).toList();

  int get count => history.length;
  int get hits => _settled.where((h) => h.hit).length;

  /// 시안 `pv.rate` — 확정된 경기만 분모에 넣는다.
  String get rateLabel {
    if (_settled.isEmpty) return '-';
    return '${(hits * 100 / _settled.length).round()}%';
  }

  /// 시안 `pv.rec` — `12 / 18`
  String get recordLabel => '$hits / ${_settled.length}';

  /// 시안 `pv.openLabel` — 이번 주 예측이 열려 있는지.
  String get openLabel {
    final open = rows.where((r) => r.open).length;
    if (isOffseason) return '비시즌';
    return open == 0 ? '마감' : '$open경기 열림';
  }
}

class PredictionViewModel extends AsyncNotifier<PredictionState> {
  /// 시안 "이번 주 예측"이 훑는 범위.
  static const _window = Duration(days: 7);

  /// 한 번에 집계를 받아올 경기 수의 상한.
  ///
  /// 서버에 주간 집계 엔드포인트가 없어서 **경기마다 한 번씩 부른다.**
  /// 목록을 통째로 주는 API가 생기면 이 상한은 없어져야 한다.
  static const _tallyLimit = 6;

  PredictionDivision _division = PredictionDivision.all;

  @override
  Future<PredictionState> build() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final team = prefs.myTeam;
    final season = prefs.season;

    final games = await _seasonGames(prefs);

    final now = DateTime.now();
    final upcoming = [
      for (final g in games)
        if (g.status != GameStatus.finished &&
            g.startsAt != null &&
            g.startsAt!.isAfter(now) &&
            g.startsAt!.isBefore(now.add(_window)))
          g,
    ]..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));

    final filtered = [
      for (final g in upcoming)
        if (_division.gender == null || g.home.gender == _division.gender) g,
    ];

    // 경기마다 한 번씩 부르므로 **동시에** 던진다. 순서대로 기다리면
    // 여섯 경기에 요청 여섯 번이 줄줄이 붙어 탭이 그만큼 늦게 뜬다.
    final shown = filtered.take(_tallyLimit).toList();
    final tallies = await Future.wait(shown.map(_tally));
    final rows = [
      for (var i = 0; i < shown.length; i++)
        PredictionRow(game: shown[i], tally: tallies[i]),
    ];

    return PredictionState(
      // 저장소를 직접 읽으면 MY에서 닉네임을 바꿔도 여기가 안 따라온다.
      nickname: ref.watch(nicknameProvider),
      team: team,
      joinedLabel: prefs.joinedLabel,
      seasonLabel: '${season.label} 정규리그',
      division: _division,
      rows: rows,
      history: _history(games, prefs),
      isOffseason: upcoming.isEmpty,
    );
  }

  /// 예측은 성별을 가리지 않고 보여준다. 전체 탭이 있으므로 두 부를 다 받는다.
  Future<List<Game>> _seasonGames(PreferencesRepository prefs) async {
    final repo = ref.read(scheduleRepositoryProvider);
    final year = prefs.season.year;
    final results = await Future.wait([
      repo.getSeasonSchedule(Gender.men, year),
      repo.getSeasonSchedule(Gender.women, year),
    ]);
    return [
      for (final days in results)
        for (final d in days) ...d.games,
    ];
  }

  Future<PredictionTally?> _tally(Game game) async {
    if (!game.hasDetail) return null;
    try {
      return await ref.read(handballApiServiceProvider).fetchPrediction(game);
    } on Exception {
      // 집계 하나 못 받았다고 목록 전체를 못 보여줄 이유는 없다.
      return null;
    }
  }

  /// `mh_preds`에 남아 있는 내 선택을 실제 경기와 맞춰 본다.
  ///
  /// **서버에 "내 예측 목록" 엔드포인트가 없어서** 이렇게 되살린다.
  /// 기기를 바꾸면 기록도 사라진다.
  List<PredictionHistoryRow> _history(
    List<Game> games,
    PreferencesRepository prefs,
  ) {
    final rows = <PredictionHistoryRow>[];
    for (final g in games) {
      final pick = prefs.predictionFor(g.id);
      if (pick == null) continue;

      final outcome = PredictionOutcome.of(g, pick);
      rows.add(PredictionHistoryRow(
        game: g,
        pick: pick,
        settled: outcome.settled,
        hit: outcome.hit,
      ));
    }
    rows.sort((a, b) {
      final x = a.game.startsAt, y = b.game.startsAt;
      if (x == null || y == null) return 0;
      return y.compareTo(x);
    });
    return rows;
  }

  Future<void> selectDivision(PredictionDivision division) async {
    if (_division == division) return;
    _division = division;
    state = const AsyncLoading<PredictionState>().copyWithPrevious(state);
    state = await AsyncValue.guard(build);
  }

  /// 시안 `o.pick` — 카드에서 바로 예측한다.
  ///
  /// 서버가 받아들인 뒤에만 기기에 적는다. 실패하면 화면도 그대로 둔다.
  Future<void> pick(Game game, PredictionPick choice) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final PredictionTally tally;
    try {
      tally = await ref
          .read(handballApiServiceProvider)
          .submitPrediction(game, choice);
    } on Exception {
      return;
    }
    await ref.read(preferencesRepositoryProvider).setPrediction(game.id, choice);
    ref.read(predictionRevisionProvider.notifier).bump();

    state = AsyncData(PredictionState(
      nickname: current.nickname,
      team: current.team,
      joinedLabel: current.joinedLabel,
      seasonLabel: current.seasonLabel,
      division: current.division,
      rows: [
        for (final r in current.rows)
          if (r.game.id == game.id)
            PredictionRow(game: r.game, tally: tally)
          else
            r,
      ],
      history: current.history,
      isOffseason: current.isOffseason,
    ));
  }

  Future<void> refresh() async {
    state = const AsyncLoading<PredictionState>().copyWithPrevious(state);
    state = await AsyncValue.guard(build);
  }
}

final predictionViewModelProvider =
    AsyncNotifierProvider<PredictionViewModel, PredictionState>(
  PredictionViewModel.new,
);
