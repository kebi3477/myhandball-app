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
    this.openingGender = Gender.men,
    this.notificationsOn = true,
    this.nextSeasonOpensAt,
    this.rankingUpdatedAt,
  });

  final List<Game> games;
  final List<RankRow> ranking;
  final List<PlayerStat> topPlayers;

  /// 시안 `rankGender` — 순위·기록에 함께 걸린다.
  final Gender gender;
  final StatCategory category;

  /// 비시즌 카드가 기준으로 삼는 부. **마이팀의 부**이고, 마이팀이 없으면
  /// 남자부다. 개막 달이 부마다 다르기 때문이다 (남자부 11월, 여자부 1월).
  ///
  /// 순위·기록에 걸린 [gender]와 다르다 — 그쪽은 화면에서 토글로 바뀐다.
  final Gender openingGender;

  /// 알림 설정. 꺼져 있으면 "알려드릴게요"라고 약속하지 않는다.
  final bool notificationsOn;

  /// 다음 시즌 개막 시각. 연맹이 일정을 올리기 전에는 `null`이다.
  final DateTime? nextSeasonOpensAt;

  /// 순위가 마지막으로 바뀐 시점 = **마지막으로 치른 경기 날짜**.
  ///
  /// API가 갱신 시각을 주지 않아 일정에서 계산한다. 시안은 날짜를 박아
  /// 두었지만 그대로 두면 영영 틀린 날짜가 남는다.
  final DateTime? rankingUpdatedAt;

  /// `2026.05.26 업데이트`
  String? get rankingUpdatedLabel {
    final at = rankingUpdatedAt;
    if (at == null) return null;
    final m = at.month.toString().padLeft(2, '0');
    final d = at.day.toString().padLeft(2, '0');
    return '${at.year}.$m.$d 업데이트';
  }

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

  /// H리그 개막 달. **남자부 11월, 여자부 1월.**
  int get openingMonth => openingGender == Gender.women ? 1 : 11;

  /// 개막 달에 들어섰는데 아직 일정이 없는 상태.
  ///
  /// 일 년에 한 달만 나타나는 분기라 테스트에서 [now]를 넣을 수 있게 열어
  /// 둔다.
  bool isOpeningMonthAt(DateTime now) => now.month == openingMonth;

  bool get isOpeningMonth => isOpeningMonthAt(DateTime.now());

  /// 비시즌 카드 아래 한 줄.
  ///
  /// 개막일을 알면 그 날짜를, 모르면 일정이 나오면 알리겠다고 한다.
  /// **알림이 꺼져 있으면 알리겠다는 말을 하지 않는다** — 지킬 수 없는
  /// 약속이다.
  String get offseasonNote {
    final opens = nextSeasonOpensAt;
    if (opens != null) {
      const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      return '지금은 비시즌이에요 · ${opens.month}월 ${opens.day}일'
          '(${weekdays[opens.weekday - 1]}) 개막 예정이에요';
    }
    return notificationsOn
        ? '지금은 비시즌이에요 · 일정이 나오면 알려드릴게요'
        : '지금은 비시즌이에요 · 개막 일정 발표 전이에요';
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
    Gender? openingGender,
    bool? notificationsOn,
    DateTime? nextSeasonOpensAt,
    DateTime? rankingUpdatedAt,
  }) =>
      HomeState(
        games: games ?? this.games,
        ranking: ranking ?? this.ranking,
        topPlayers: topPlayers ?? this.topPlayers,
        gender: gender ?? this.gender,
        category: category ?? this.category,
        openingGender: openingGender ?? this.openingGender,
        notificationsOn: notificationsOn ?? this.notificationsOn,
        nextSeasonOpensAt: nextSeasonOpensAt ?? this.nextSeasonOpensAt,
        rankingUpdatedAt: rankingUpdatedAt ?? this.rankingUpdatedAt,
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
      // 개막 달은 마이팀의 부를 따른다. 마이팀이 없으면 남자부다.
      openingGender: prefs.myTeam?.gender ?? Gender.men,
      notificationsOn: prefs.notificationsOn,
      nextSeasonOpensAt: offseason ? await _nextSeasonOpening(gender) : null,
      rankingUpdatedAt: await _lastPlayedAt(gender),
    );
  }

  /// 마지막으로 치른 경기 시각. 순위 갱신 시점으로 쓴다.
  Future<DateTime?> _lastPlayedAt(Gender gender) async {
    try {
      final days = await ref
          .read(scheduleRepositoryProvider)
          .getSeasonSchedule(gender, Season.current.year);
      final played = [
        for (final d in days)
          for (final g in d.games)
            if (g.status == GameStatus.finished) ?g.startsAt,
      ]..sort();
      return played.isEmpty ? null : played.last;
    } on Exception {
      return null;
    }
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
