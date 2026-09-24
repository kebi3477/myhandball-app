import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/ranking_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../domain/models/attendance.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/game_detail.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/rank_row.dart';
import '../../../domain/models/team.dart';

/// 시안 `나의 직관 기록` 한 줄 (`mh_attended`).
///
/// 경기 상세의 "직관 기록하기"를 누르면 쌓인다.
class AttendanceRecord {
  const AttendanceRecord({
    required this.matchLabel,
    required this.dateLabel,
    required this.venue,
    required this.score,
    required this.result,
  });

  final String matchLabel;
  final String dateLabel;
  final String venue;
  final String score;

  /// `승` / `무` / `패`
  final String result;
}

/// 시안 `나의 승부 예측` 한 줄 (`mh_preds`). 경기 상세의 예측 탭에서 만들어진다.
class PredictionRecord {
  const PredictionRecord({
    required this.matchLabel,
    required this.pickLabel,
    required this.dateLabel,
    required this.hit,
  });

  final String matchLabel;
  final String pickLabel;
  final String dateLabel;
  final bool hit;
}

class MyState {
  const MyState({
    required this.team,
    required this.rank,
    required this.favoritePlayers,
    required this.teamPlayers,
    required this.nextGame,
    required this.recentGames,
    required this.attendance,
    required this.predictions,
  });

  final Team? team;
  final RankRow? rank;
  final List<Player> favoritePlayers;

  /// 시안 "주요 선수" — 마이팀의 **득점 상위** 선수.
  ///
  /// 소속 선수 전부가 아니다. 시안 변수명이 `topScorers`이고 목록이 3줄이다.
  final List<Player> teamPlayers;

  final Game? nextGame;

  /// 마이팀의 최근 종료 경기 5개.
  final List<Game> recentGames;

  final List<AttendanceRecord> attendance;
  final List<PredictionRecord> predictions;

  String get rankLabel =>
      rank == null ? '순위 정보 없음' : '${rank!.rank}위 · 승점 ${rank!.points}';

  int _attendance(String result) =>
      attendance.where((a) => a.result == result).length;

  /// 마이팀이 뛴 직관 경기 수. 관람(`-`)은 빠진다.
  int get cheeredGames =>
      _attendance('승') + _attendance('무') + _attendance('패');

  /// 직관 승률. **분모는 관람을 뺀 응원 경기다** (시안
  /// `aw / (aw + ad + al)`). 관람을 분모에 넣으면 승률이 실제보다 낮게
  /// 나오고, "승리 요정" 배지가 열리지 않는다.
  String get attendanceRate {
    if (cheeredGames == 0) return '-';
    return '${(_attendance('승') * 100 / cheeredGames).round()}%';
  }

  /// 시안 `${aw}-${ad}-${al}`
  String get attendanceWdl =>
      '${_attendance('승')}-${_attendance('무')}-${_attendance('패')}';

  String get predictionRate {
    if (predictions.isEmpty) return '-';
    final hits = predictions.where((p) => p.hit).length;
    return '${(hits * 100 / predictions.length).round()}%';
  }

  int get predictionHits => predictions.where((p) => p.hit).length;

  /// 시안 "시즌 기록" 8칸. `/api/ranking`이 주는 값 그대로다.
  List<(String label, String value, bool highlight)> get seasonStats {
    final r = rank;
    if (r == null) return const [];
    return [
      ('경기', '${r.played}', false),
      ('승', '${r.wins}', false),
      ('무', '${r.draws}', false),
      ('패', '${r.losses}', false),
      ('득점', '${r.goalsFor}', false),
      ('실점', '${r.goalsAgainst}', false),
      ('득실차', r.goalDiff > 0 ? '+${r.goalDiff}' : '${r.goalDiff}', true),
      ('승점', '${r.points}', true),
    ];
  }
}

class MyViewModel extends AsyncNotifier<MyState> {
  /// 시안 "주요 선수" 줄 수.
  static const _topScorerCount = 3;

  @override
  Future<MyState> build() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final team = prefs.myTeam;
    // **마이팀의 부를 따른다.** `preferredGender`는 홈 순위의 남자부/여자부
    // 토글이 바꾼다. 그걸 그대로 쓰면, 여자부 팀을 응원하는 사람이 홈에서
    // 남자부를 한 번 누른 순간 MY의 순위·시즌 기록·직관 기록이 통째로 빈다.
    final gender = team?.gender ?? prefs.preferredGender;

    final ranking = await ref
        .read(rankingRepositoryProvider)
        .getRanking(gender);
    final players = await ref.read(playerRepositoryProvider).getPlayers(gender);

    final favIds = prefs.favoritePlayerIds;
    final favorites = players.where((p) => favIds.contains(p.id)).toList();

    RankRow? rank;
    var teamPlayers = <Player>[];
    var nextGame = <Game>[];
    var recent = <Game>[];

    // 직관·예측 기록은 경기 상세에서 저장한 id를 실제 경기로 되살린다.
    final allGames = await _allGames();
    final attendance = <AttendanceRecord>[];
    final predictions = <PredictionRecord>[];

    for (final g in allGames) {
      if (prefs.didAttend(g.id)) {
        attendance.add(_toAttendance(g, team));
      }
      final pick = prefs.predictionFor(g.id);
      if (pick != null) predictions.add(_toPrediction(g, pick));
    }

    if (team != null) {
      for (final r in ranking) {
        if (r.team.name == team.name) rank = r;
      }
      // 시안 `topScorers` — 명단 전체가 아니라 득점 상위 3명이다.
      // 그냥 소속 선수를 다 넣으면 16줄이 깔린다.
      teamPlayers = players.where((p) => p.teamName == team.name).toList()
        ..sort((a, b) => (b.goals ?? 0).compareTo(a.goals ?? 0));
      if (teamPlayers.length > _topScorerCount) {
        teamPlayers = teamPlayers.sublist(0, _topScorerCount);
      }

      final games = allGames
          .where((g) => g.home.name == team.name || g.away.name == team.name)
          .toList();
      nextGame = games.where((g) => g.status == GameStatus.pre).toList();
      recent = games.reversed
          .where((g) => g.status == GameStatus.finished)
          .take(5)
          .toList();
    }

    return MyState(
      team: team,
      rank: rank,
      favoritePlayers: favorites,
      teamPlayers: teamPlayers,
      nextGame: nextGame.isEmpty ? null : nextGame.first,
      recentGames: recent,
      attendance: attendance,
      predictions: predictions,
    );
  }

  /// **판정은 [AttendanceEntry.resultFor] 하나만 쓴다.**
  ///
  /// 예전에는 여기서 따로 계산했는데, **마이팀이 아예 안 뛴 경기(관람)를
  /// 거르지 않아** 원정 팀을 내 팀인 양 보고 승·패를 매겼다. 그 값이
  /// 직관 승률과 "승리 요정" 배지에 그대로 들어갔다. 직관 탭은 제대로
  /// 거르고 있어서 두 화면의 숫자가 달랐다.
  AttendanceRecord _toAttendance(Game g, Team? myTeam) {
    final result = switch (AttendanceEntry.resultFor(g, myTeam)) {
      AttendanceResult.win => '승',
      AttendanceResult.draw => '무',
      AttendanceResult.loss => '패',
      AttendanceResult.unknown => '-',
    };

    return AttendanceRecord(
      matchLabel: '${g.home.name} vs ${g.away.name}',
      dateLabel: g.meta,
      venue: g.venue ?? '경기장',
      score: '${g.scoreHomeText} : ${g.scoreAwayText}',
      result: result,
    );
  }

  PredictionRecord _toPrediction(Game g, PredictionPick pick) {
    final h = g.scoreHome ?? 0;
    final a = g.scoreAway ?? 0;
    final actual = h > a
        ? PredictionPick.home
        : (h < a ? PredictionPick.away : PredictionPick.draw);

    return PredictionRecord(
      matchLabel: '${g.home.name} vs ${g.away.name}',
      pickLabel: switch (pick) {
        PredictionPick.home => '${g.home.name} 승',
        PredictionPick.away => '${g.away.name} 승',
        PredictionPick.draw => '무승부',
      },
      dateLabel: g.meta,
      hit: g.status == GameStatus.finished && pick == actual,
    );
  }

  /// 시즌 경기를 남·여 모두 모은다.
  ///
  /// 직관은 마이팀 경기뿐이지만 **예측은 부를 가리지 않는다** — 승부예측
  /// 탭이 두 부를 다 보여준다. 한쪽만 받으면 반대편 부에 한 예측이 적중
  /// 수에서 빠지고, "예측 고수" 배지가 영영 안 열린다.
  ///
  /// 이번 달·지난 달만 보면 비시즌에 마이팀 경기가 하나도 안 잡히므로
  /// 시즌 전체를 받는다 (저장소가 캐시한다).
  Future<List<Game>> _allGames() async {
    final repo = ref.read(scheduleRepositoryProvider);
    final year = ref.read(preferencesRepositoryProvider).season.year;

    final results = await Future.wait([
      for (final g in Gender.values) repo.getSeasonSchedule(g, year),
    ]);
    return [
      for (final days in results)
        for (final d in days) ...d.games,
    ];
  }

  Future<void> refresh() async {
    state = const AsyncLoading<MyState>().copyWithPrevious(state);
    state = await AsyncValue.guard(build);
  }

  /// 관심 선수 목록에서 하트를 눌러 빼는 경우.
  Future<void> removeFavorite(String playerId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await ref
        .read(preferencesRepositoryProvider)
        .toggleFavoritePlayer(playerId);
    state = AsyncData(
      MyState(
        team: current.team,
        rank: current.rank,
        favoritePlayers: current.favoritePlayers
            .where((p) => p.id != playerId)
            .toList(),
        teamPlayers: current.teamPlayers,
        nextGame: current.nextGame,
        recentGames: current.recentGames,
        attendance: current.attendance,
        predictions: current.predictions,
      ),
    );
  }
}

final myViewModelProvider = AsyncNotifierProvider<MyViewModel, MyState>(
  MyViewModel.new,
);
