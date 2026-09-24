import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/game_detail.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/prediction.dart';
import '../../../domain/models/team.dart';

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

/// 시안 `myPred.recent` — 내가 참여한 예측 한 줄.
///
/// 출처가 둘이다. **서버의 `GET /api/prediction/my`가 정본이고**, 그걸
/// 못 받았을 때만 기기에 남은 `mh_preds`로 되살린다. 두 경로가 같은
/// 위젯을 그리도록 문자열까지 만들어서 담는다.
class PredictionHistoryRow {
  const PredictionHistoryRow({
    required this.matchLabel,
    required this.pickLabel,
    required this.settled,
    required this.hit,
    required this.dateLabel,
    this.startsAt,
  });

  /// 서버가 준 한 줄.
  factory PredictionHistoryRow.of(MyPredictionItem item) =>
      PredictionHistoryRow(
        matchLabel: item.matchLabel,
        pickLabel: item.pickLabel,
        settled: item.settled,
        hit: item.hit,
        dateLabel: item.dateLabel,
        startsAt: item.startsAt,
      );

  /// 기기에 남은 내 선택 + 일정으로 되살린 한 줄.
  factory PredictionHistoryRow.local(Game game, PredictionPick pick) {
    final outcome = PredictionOutcome.of(game, pick);
    final at = game.startsAt?.toLocal();
    return PredictionHistoryRow(
      matchLabel: '${game.home.name} vs ${game.away.name}',
      pickLabel: switch (pick) {
        PredictionPick.home => '${game.home.name} 승',
        PredictionPick.away => '${game.away.name} 승',
        PredictionPick.draw => '무승부',
      },
      settled: outcome.settled,
      hit: outcome.hit,
      dateLabel: at == null
          ? ''
          : '${at.month.toString().padLeft(2, '0')}.'
              '${at.day.toString().padLeft(2, '0')}',
      startsAt: game.startsAt,
    );
  }

  final String matchLabel;
  final String pickLabel;

  /// 경기가 끝나 적중 여부가 정해졌는지.
  final bool settled;
  final bool hit;

  /// `11.30`
  final String dateLabel;

  final DateTime? startsAt;

  /// 시안 `r.chip` — `적중` / `실패` / `대기`
  String get chipLabel => settled ? (hit ? '적중' : '실패') : '대기';
}

class PredictionState {
  const PredictionState({
    required this.profile,
    required this.team,
    required this.seasonLabel,
    required this.division,
    required this.rows,
    required this.history,
    required this.isOffseason,
    required this.scope,
    required this.leaderboard,
    required this.fandom,
    required this.fandomGender,
    required this.mine,
  });

  /// 서버에 올라간 랭킹 프로필. 없으면 아직 랭킹에 참여하지 않았다.
  final PredictionProfile? profile;

  /// 랭킹 범위를 '내 팀 팬'으로 좁힐 때 쓰는 팀. 프로필 팀 → 마이팀 순.
  final Team? team;

  /// 시안 `pv.seasonLabel` — 비시즌이면 최종 기록이라고 알린다.
  final String seasonLabel;

  final PredictionDivision division;
  final List<PredictionRow> rows;
  final List<PredictionHistoryRow> history;
  final bool isOffseason;

  final LeaderboardScope scope;

  /// `null`이면 못 받았다. 빈 랭킹(`rows: []`)과 구분해야 한다 —
  /// 하나는 "아직 아무도 없다", 하나는 "연결이 안 됐다"다.
  final Leaderboard? leaderboard;
  final List<FandomRow>? fandom;

  /// 팬덤 적중률이 보여주는 부. 시안 `pv.divLabel`.
  final Gender fandomGender;

  /// 서버 집계. 못 받았으면 `null`이고 [history]로 대신 센다.
  final MyPredictions? mine;

  PredictionState copyWith({
    PredictionProfile? profile,
    List<PredictionRow>? rows,
  }) =>
      PredictionState(
        profile: profile ?? this.profile,
        team: team,
        seasonLabel: seasonLabel,
        division: division,
        rows: rows ?? this.rows,
        history: history,
        isOffseason: isOffseason,
        scope: scope,
        leaderboard: leaderboard,
        fandom: fandom,
        fandomGender: fandomGender,
        mine: mine,
      );

  /// 시안 `pv.hasProfile`.
  bool get hasProfile => profile != null;

  String get nickname => profile?.nickname ?? '';

  String? get joinedLabel => profile?.joinedLabel;

  /// 프로필의 팀 로고. 없으면 마이팀 로고로 떨어진다.
  String? get teamLogoUrl => profile?.teamLogoUrl ?? team?.logoUrl;

  String get teamName => profile?.teamName ?? team?.name ?? '';

  List<PredictionHistoryRow> get _settled =>
      history.where((h) => h.settled).toList();

  /// 결과를 기다리는 것까지 포함한 전체 참여 수.
  int get count => mine?.count ?? history.length;

  int get hits => mine?.hits ?? _settled.where((h) => h.hit).length;

  /// 시안 `pv.rate` — 확정된 경기만 분모에 넣는다.
  String get rateLabel {
    if (mine case final m?) return m.rateLabel;
    if (_settled.isEmpty) return '-';
    return '${(hits * 100 / _settled.length).round()}%';
  }

  /// 시안 `pv.rec` — `12 / 18`
  String get recordLabel => mine?.recordLabel ?? '$hits / ${_settled.length}';

  /// 적중 여부가 정해진 참여 수. 랭킹 자격의 기준이다.
  int get settledCount => mine?.settled ?? _settled.length;

  /// 시안 `pv.rankAll`.
  String get myRankLabel => leaderboard?.myRankLabel ?? '-';

  /// 시안 `pv.rankSub` — 랭킹에 있으면 상위 %, 없으면 남은 경기 수.
  String get myRankSub {
    final board = leaderboard;
    if (board?.me != null && board?.meTopPercent != null) return board!.myRankSub;
    final left = (board?.minSettled ?? 10) - settledCount;
    return left > 0 ? '$left경기 더 참여' : '랭킹 밖';
  }

  /// 시안 `pv.openLabel` — 아직 **고르지 않은** 열린 경기 수.
  ///
  /// 이미 예측한 경기는 빠진다. "3경기 예측 가능"인데 셋 다 찍어 둔
  /// 상태면 할 일이 없는데 있는 것처럼 보인다.
  String get openLabel {
    if (isOffseason) return '';
    final open = rows.where((r) => r.open && r.myPick == null).length;
    return open == 0 ? '모두 참여했어요' : '$open경기 예측 가능';
  }

  /// 열린 경기가 남았는지. 남았을 때만 문구를 브랜드색으로 쓴다.
  bool get hasOpenGames => rows.any((r) => r.open && r.myPick == null);
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
  LeaderboardScope _scope = LeaderboardScope.all;

  @override
  Future<PredictionState> build() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final season = prefs.season;

    // 시트에서 프로필을 만들면 이 탭이 따라와야 한다.
    final profile = ref.watch(profileProvider).valueOrNull;

    // 랭킹 범위와 팬덤이 보는 팀. 프로필 팀이 있으면 그게 기준이다.
    final team = _scopeTeam(profile, prefs.myTeam);
    final gender = profile?.gender ?? prefs.myTeam?.gender ?? prefs.preferredGender;

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
    // 랭킹·팬덤·내 기록도 같이 던진다 — 서로 기다릴 이유가 없다.
    final shown = filtered.take(_tallyLimit).toList();
    final (tallies, board, fandom, mine) = await (
      Future.wait(shown.map(_tally)),
      _leaderboard(team),
      _fandom(gender),
      _mine(),
    ).wait;

    final rows = [
      for (var i = 0; i < shown.length; i++)
        PredictionRow(game: shown[i], tally: tallies[i]),
    ];

    return PredictionState(
      profile: profile,
      team: team,
      seasonLabel: upcoming.isEmpty
          ? '${season.label} 시즌 최종'
          : '${season.label} 시즌 · 매주 월 갱신',
      division: _division,
      rows: rows,
      // 서버 목록이 오면 그걸 쓰고, 못 받았으면 기기에 남은 선택으로 되살린다.
      history: mine == null
          ? _localHistory(games, prefs)
          : [for (final item in mine.items) PredictionHistoryRow.of(item)],
      isOffseason: upcoming.isEmpty,
      scope: _scope,
      leaderboard: board,
      fandom: fandom,
      fandomGender: gender,
      mine: mine,
    );
  }

  /// 랭킹을 '내 팀 팬'으로 좁힐 때의 기준 팀.
  ///
  /// 프로필의 팀이 먼저다. 프로필에는 `teamNum`이 있으니 그걸로 만든다 —
  /// 기기에 적힌 마이팀에는 번호가 없을 수 있다.
  Team? _scopeTeam(PredictionProfile? profile, Team? myTeam) {
    if (profile == null) return myTeam;
    return Team(
      name: profile.teamName,
      gender: profile.gender,
      teamNum: profile.teamNum,
      logoUrl: profile.teamLogoUrl,
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

  /// 랭킹. 못 받으면 `null`이고 그 섹션만 다시 시도를 띄운다.
  ///
  /// '내 팀 팬' 범위인데 팀 번호를 모르면 전체로 떨어진다 — 빈 랭킹을
  /// 보여주는 것보다 낫다.
  Future<Leaderboard?> _leaderboard(Team? team) async {
    final teamNum = team?.teamNum;
    final scope = _scope == LeaderboardScope.team && teamNum == null
        ? LeaderboardScope.all
        : _scope;
    try {
      return await ref.read(handballApiServiceProvider).fetchLeaderboard(
            scope: scope,
            teamNum: scope == LeaderboardScope.team ? teamNum : null,
          );
    } on Exception {
      return null;
    }
  }

  Future<List<FandomRow>?> _fandom(Gender gender) async {
    try {
      return await ref.read(handballApiServiceProvider).fetchFandom(gender);
    } on Exception {
      return null;
    }
  }

  Future<MyPredictions?> _mine() async {
    try {
      return await ref.read(handballApiServiceProvider).fetchMyPredictions();
    } on Exception {
      return null;
    }
  }

  /// `mh_preds`에 남아 있는 내 선택을 실제 경기와 맞춰 본다.
  ///
  /// **서버 목록을 못 받았을 때만 쓴다.** 오프라인에서 기록이 통째로
  /// 비어 보이지 않게 하려고 남겨 둔 길이다.
  List<PredictionHistoryRow> _localHistory(
    List<Game> games,
    PreferencesRepository prefs,
  ) {
    final rows = <PredictionHistoryRow>[];
    for (final g in games) {
      final pick = prefs.predictionFor(g.id);
      if (pick == null) continue;
      rows.add(PredictionHistoryRow.local(g, pick));
    }
    rows.sort((a, b) {
      final x = a.startsAt, y = b.startsAt;
      if (x == null || y == null) return 0;
      return y.compareTo(x);
    });
    return rows;
  }

  Future<void> selectDivision(PredictionDivision division) async {
    if (_division == division) return;
    _division = division;
    await _rebuild();
  }

  /// 시안 `pv.scopeTabs` — 랭킹 범위를 전체/내 팀 팬으로 바꾼다.
  Future<void> selectScope(LeaderboardScope scope) async {
    if (_scope == scope) return;
    _scope = scope;
    await _rebuild();
  }

  /// 시안 `o.pick` — 카드에서 바로 예측한다.
  ///
  /// 서버가 받아들인 뒤에만 기기에 적는다. 실패하면 화면도 그대로 둔다.
  Future<void> pick(Game game, PredictionPick choice) async {
    // 프로필을 막 만들고 바로 고른 경우 이 탭이 아직 다시 그려지는 중이다.
    // 그때 그냥 돌아가면 **누른 예측이 사라진다.**
    final current = state.valueOrNull ?? await future;

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

    // 다시 그려지는 사이에 상태가 바뀌었을 수 있으니 최신 것에 얹는다.
    final latest = state.valueOrNull ?? current;
    state = AsyncData(latest.copyWith(
      rows: [
        for (final r in latest.rows)
          if (r.game.id == game.id)
            PredictionRow(game: r.game, tally: tally)
          else
            r,
      ],
    ));
  }

  Future<void> refresh() => _rebuild();

  Future<void> _rebuild() async {
    state = const AsyncLoading<PredictionState>().copyWithPrevious(state);
    state = await AsyncValue.guard(build);
  }
}

final predictionViewModelProvider =
    AsyncNotifierProvider<PredictionViewModel, PredictionState>(
  PredictionViewModel.new,
);
