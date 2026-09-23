import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/ranking_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/player_stat.dart';
import '../../../domain/models/rank_row.dart';

class HomeState {
  const HomeState({
    required this.games,
    required this.ranking,
    required this.topPlayers,
    required this.gender,
    required this.category,
    required this.guideDoneCount,
  });

  final List<Game> games;
  final List<RankRow> ranking;
  final List<PlayerStat> topPlayers;

  /// 시안 `rankGender` — 순위·기록에 함께 걸린다.
  final Gender gender;
  final StatCategory category;
  final int guideDoneCount;

  /// 시상대에 올라가는 1~3위.
  List<RankRow> get podium => ranking.take(3).toList();

  /// 시상대 아래 리스트.
  List<RankRow> get restOfRanking => ranking.skip(3).toList();

  HomeState copyWith({
    List<Game>? games,
    List<RankRow>? ranking,
    List<PlayerStat>? topPlayers,
    Gender? gender,
    StatCategory? category,
    int? guideDoneCount,
  }) =>
      HomeState(
        games: games ?? this.games,
        ranking: ranking ?? this.ranking,
        topPlayers: topPlayers ?? this.topPlayers,
        gender: gender ?? this.gender,
        category: category ?? this.category,
        guideDoneCount: guideDoneCount ?? this.guideDoneCount,
      );
}

class HomeViewModel extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final gender = prefs.preferredGender;
    const category = StatCategory.goals;

    final (games, ranking, topPlayers) = await _fetch(gender, category);

    return HomeState(
      games: games,
      ranking: ranking,
      topPlayers: topPlayers,
      gender: gender,
      category: category,
      guideDoneCount: prefs.guideDoneCount,
    );
  }

  Future<(List<Game>, List<RankRow>, List<PlayerStat>)> _fetch(
    Gender gender,
    StatCategory category,
  ) async {
    final schedule = ref.read(scheduleRepositoryProvider);
    final ranking = ref.read(rankingRepositoryProvider);

    final results = await Future.wait([
      schedule.getUpcomingGames(),
      ranking.getRanking(gender),
      ranking.getTopPlayers(gender, category),
    ]);

    return (
      results[0] as List<Game>,
      results[1] as List<RankRow>,
      results[2] as List<PlayerStat>,
    );
  }

  /// 시안 `rankSelectM` / `rankSelectW`.
  Future<void> selectGender(Gender gender) async {
    final current = state.valueOrNull;
    if (current == null || current.gender == gender) return;

    state = const AsyncLoading<HomeState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final rankingRepo = ref.read(rankingRepositoryProvider);
      final results = await Future.wait([
        rankingRepo.getRanking(gender),
        rankingRepo.getTopPlayers(gender, current.category),
      ]);
      await ref.read(preferencesRepositoryProvider).setPreferredGender(gender);
      return current.copyWith(
        gender: gender,
        ranking: results[0] as List<RankRow>,
        topPlayers: results[1] as List<PlayerStat>,
      );
    });
  }

  /// 시안 TOP5 탭 전환.
  Future<void> selectCategory(StatCategory category) async {
    final current = state.valueOrNull;
    if (current == null || current.category == category) return;

    state = const AsyncLoading<HomeState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final rows = await ref
          .read(rankingRepositoryProvider)
          .getTopPlayers(current.gender, category);
      return current.copyWith(category: category, topPlayers: rows);
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading<HomeState>().copyWithPrevious(state);
    state = await AsyncValue.guard(build);
  }
}

final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
