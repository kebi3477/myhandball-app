import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/user_records_repository.dart';
import '../../../data/repositories/ranking_repository.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/rank_row.dart';

/// 시안 `statTab` — 분석 탭의 4개 서브탭.
enum StatTab {
  rank('순위'),
  record('기록'),
  team('팀'),
  player('선수');

  const StatTab(this.label);

  final String label;
}

class StatState {
  const StatState({
    required this.tab,
    required this.gender,
    required this.ranking,
    required this.players,
    required this.favoritePlayerIds,
  });

  final StatTab tab;
  final Gender gender;
  final List<RankRow> ranking;
  final List<Player> players;
  final Set<String> favoritePlayerIds;

  /// 기록 탭은 득실차 내림차순으로 보여준다.
  List<RankRow> get byGoalDiff {
    final rows = [...ranking];
    rows.sort((a, b) => b.goalDiff.compareTo(a.goalDiff));
    return rows;
  }

  /// 즐겨찾기한 선수를 앞으로 올린다.
  List<Player> get sortedPlayers {
    final favs = players.where((p) => favoritePlayerIds.contains(p.id));
    final rest = players.where((p) => !favoritePlayerIds.contains(p.id));
    return [...favs, ...rest];
  }

  /// 남/여 토글이 붙는 탭. 기록·선수 탭은 시안에 토글이 없다.
  bool get showsGenderToggle =>
      tab == StatTab.rank || tab == StatTab.team;

  StatState copyWith({
    StatTab? tab,
    Gender? gender,
    List<RankRow>? ranking,
    List<Player>? players,
    Set<String>? favoritePlayerIds,
  }) =>
      StatState(
        tab: tab ?? this.tab,
        gender: gender ?? this.gender,
        ranking: ranking ?? this.ranking,
        players: players ?? this.players,
        favoritePlayerIds: favoritePlayerIds ?? this.favoritePlayerIds,
      );
}

class StatViewModel extends AsyncNotifier<StatState> {
  @override
  Future<StatState> build() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final gender = prefs.preferredGender;
    final (ranking, players) = await _fetch(gender);

    return StatState(
      tab: StatTab.rank,
      gender: gender,
      ranking: ranking,
      players: players,
      favoritePlayerIds: prefs.favoritePlayerIds,
    );
  }

  Future<(List<RankRow>, List<Player>)> _fetch(Gender gender) async {
    final results = await Future.wait([
      ref.read(rankingRepositoryProvider).getRanking(gender),
      ref.read(playerRepositoryProvider).getPlayers(gender),
    ]);
    return (results[0] as List<RankRow>, results[1] as List<Player>);
  }

  void selectTab(StatTab tab) {
    final current = state.valueOrNull;
    if (current == null || current.tab == tab) return;
    state = AsyncData(current.copyWith(tab: tab));
  }

  Future<void> selectGender(Gender gender) async {
    final current = state.valueOrNull;
    if (current == null || current.gender == gender) return;

    state = const AsyncLoading<StatState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final (ranking, players) = await _fetch(gender);
      await ref.read(preferencesRepositoryProvider).setPreferredGender(gender);
      return current.copyWith(
        gender: gender,
        ranking: ranking,
        players: players,
      );
    });
  }

  /// 시안 `toggleFav` — 선수 카드의 하트.
  Future<void> toggleFavorite(String playerId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final prefs = ref.read(preferencesRepositoryProvider);
    await ref
        .read(userRecordsRepositoryProvider)
        .setFavoritePlayer(playerId, on: !prefs.isFavoritePlayer(playerId));
    state = AsyncData(
      current.copyWith(favoritePlayerIds: prefs.favoritePlayerIds),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<StatState>().copyWithPrevious(state);
    state = await AsyncValue.guard(build);
  }
}

final statViewModelProvider =
    AsyncNotifierProvider<StatViewModel, StatState>(StatViewModel.new);
