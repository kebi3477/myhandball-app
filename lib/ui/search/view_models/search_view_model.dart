import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/ranking_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/team.dart';

class SearchState {
  const SearchState({
    required this.query,
    required this.allTeams,
    required this.allPlayers,
    required this.recent,
  });

  final String query;
  final List<Team> allTeams;
  final List<Player> allPlayers;
  final List<String> recent;

  bool get isIdle => query.trim().isEmpty;

  List<Team> get teamResults {
    if (isIdle) return const [];
    final q = query.trim();
    return allTeams.where((t) => t.name.contains(q)).toList();
  }

  List<Player> get playerResults {
    if (isIdle) return const [];
    final q = query.trim();
    return allPlayers
        .where((p) => p.name.contains(q) || p.teamName.contains(q))
        .take(30)
        .toList();
  }

  bool get hasResults => teamResults.isNotEmpty || playerResults.isNotEmpty;

  /// 시안 "추천 검색어" — 남녀 상위 팀 이름을 그대로 쓴다.
  List<String> get suggestions =>
      allTeams.take(6).map((t) => t.name).toList();
}

class SearchViewModel extends AutoDisposeAsyncNotifier<SearchState> {
  @override
  Future<SearchState> build() async {
    final teamRepo = ref.read(teamRepositoryProvider);
    final playerRepo = ref.read(playerRepositoryProvider);

    // 검색은 부와 무관하게 전체를 대상으로 한다.
    final teams = <Team>[];
    final players = <Player>[];
    for (final gender in Gender.values) {
      teams.addAll(await teamRepo.getTeams(gender));
      players.addAll(await playerRepo.getPlayers(gender));
    }

    return SearchState(
      query: '',
      allTeams: teams,
      allPlayers: players,
      recent: ref.read(preferencesRepositoryProvider).recentSearches,
    );
  }

  void setQuery(String value) {
    final c = state.valueOrNull;
    if (c == null) return;
    state = AsyncData(SearchState(
      query: value,
      allTeams: c.allTeams,
      allPlayers: c.allPlayers,
      recent: c.recent,
    ));
  }

  /// 결과를 열었을 때만 최근 검색에 남긴다.
  Future<void> remember(String query) async {
    final c = state.valueOrNull;
    if (c == null || query.trim().isEmpty) return;
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.addRecentSearch(query.trim());
    state = AsyncData(SearchState(
      query: c.query,
      allTeams: c.allTeams,
      allPlayers: c.allPlayers,
      recent: prefs.recentSearches,
    ));
  }

  Future<void> removeRecent(String query) async {
    final c = state.valueOrNull;
    if (c == null) return;
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.removeRecentSearch(query);
    state = AsyncData(SearchState(
      query: c.query,
      allTeams: c.allTeams,
      allPlayers: c.allPlayers,
      recent: prefs.recentSearches,
    ));
  }

  Future<void> clearRecent() async {
    final c = state.valueOrNull;
    if (c == null) return;
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.clearRecentSearches();
    state = AsyncData(SearchState(
      query: c.query,
      allTeams: c.allTeams,
      allPlayers: c.allPlayers,
      recent: const [],
    ));
  }
}

final searchViewModelProvider =
    AsyncNotifierProvider.autoDispose<SearchViewModel, SearchState>(
  SearchViewModel.new,
);
