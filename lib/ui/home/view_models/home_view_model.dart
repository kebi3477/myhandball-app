import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/ranking_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/player_stat.dart';
import '../../../domain/models/rank_row.dart';
import '../../../domain/models/season.dart';

class HomeState {
  const HomeState({
    required this.games,
    required this.ranking,
    required this.topPlayers,
    required this.gender,
    required this.category,
    this.nextSeasonOpensAt,
  });

  final List<Game> games;
  final List<RankRow> ranking;
  final List<PlayerStat> topPlayers;

  /// 시안 `rankGender` — 순위·기록에 함께 걸린다.
  final Gender gender;
  final StatCategory category;

  /// 다음 시즌 개막 시각. 연맹이 일정을 올리기 전에는 `null`이다.
  final DateTime? nextSeasonOpensAt;

  /// 시안 `isOffseason` — 앞으로 치를 경기가 하나도 없는 상태.
  ///
  /// 비시즌에 "가까운 경기"가 지난 경기로만 채워지면 사용자는 앱이 고장난
  /// 줄 안다. 그래서 개막까지 남은 날을 대신 보여준다.
  bool get isOffseason => !games.any((g) => g.status != GameStatus.finished);

  /// 개막까지 남은 날. 일정이 안 올라왔으면 `null`.
  int? get daysToOpening {
    final opens = nextSeasonOpensAt;
    if (opens == null) return null;
    final today = DateTime.now();
    final days = DateTime(opens.year, opens.month, opens.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    return days < 0 ? null : days;
  }

  /// `26-27 시즌 개막까지`
  String get nextSeasonLabel {
    final opens = nextSeasonOpensAt;
    final season = opens == null
        ? Season.ofYear(Season.current.startYear + 1)
        : Season.at(opens);
    return '${season.label} 시즌 개막까지';
  }

  /// `11월 14일(토) 개막 예정`
  String? get openingLabel {
    final opens = nextSeasonOpensAt;
    if (opens == null) return null;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${opens.month}월 ${opens.day}일'
        '(${weekdays[opens.weekday - 1]}) 개막 예정';
  }

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
    DateTime? nextSeasonOpensAt,
  }) =>
      HomeState(
        games: games ?? this.games,
        ranking: ranking ?? this.ranking,
        topPlayers: topPlayers ?? this.topPlayers,
        gender: gender ?? this.gender,
        category: category ?? this.category,
        nextSeasonOpensAt: nextSeasonOpensAt ?? this.nextSeasonOpensAt,
      );
}

class HomeViewModel extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final gender = prefs.preferredGender;
    const category = StatCategory.goals;

    final (games, ranking, topPlayers) = await _fetch(gender, category);

    final offseason = !games.any((g) => g.status != GameStatus.finished);

    return HomeState(
      games: games,
      ranking: ranking,
      topPlayers: topPlayers,
      gender: gender,
      category: category,
      nextSeasonOpensAt: offseason ? await _nextSeasonOpening(gender) : null,
    );
  }

  /// 다음 시즌 첫 경기 시각.
  ///
  /// 연맹이 일정을 올리기 전에는 빈 응답이 오고, 그때는 `null`이다.
  /// **개막일을 지어내지 않는다** — 틀린 D-day가 없는 것보다 나쁘다.
  Future<DateTime?> _nextSeasonOpening(Gender gender) async {
    final next = Season.ofYear(Season.current.startYear + 1);
    try {
      final days = await ref
          .read(scheduleRepositoryProvider)
          .getSeasonSchedule(gender, next.year);
      final starts = [
        for (final d in days)
          for (final g in d.games) ?g.startsAt,
      ]..sort();
      return starts.isEmpty ? null : starts.first;
    } on Exception {
      return null;
    }
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
