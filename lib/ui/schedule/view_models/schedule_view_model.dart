import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/season.dart';
import '../../../domain/models/schedule_day.dart';
import '../../../domain/models/team.dart';

/// 시안 `schedView` — 목록 / MY팀 달력
enum ScheduleView { list, calendar }

class ScheduleState {
  const ScheduleState({
    required this.view,
    required this.gender,
    required this.month,
    required this.days,
    required this.season,
    required this.monthsWithGames,
    this.myTeam,
    this.selectedDayLabel,
    this.selectedDate,
  });

  final ScheduleView view;
  final Gender gender;

  /// 보고 있는 달의 1일.
  final DateTime month;

  final List<ScheduleDay> days;

  /// 지금 조회 중인 시즌(시작 연도). 연·월 선택이 이걸 같이 바꾼다.
  final String season;

  /// [season]에서 경기가 있는 달. 연·월 선택기가 흐리게 표시하는 데 쓴다.
  final Set<DateTime> monthsWithGames;

  final Team? myTeam;

  /// 목록 뷰의 날짜 칩 선택. null이면 그 달 전체.
  final String? selectedDayLabel;

  /// 달력 뷰에서 탭한 날.
  final DateTime? selectedDate;

  String get monthLabel => '${month.year}년 ${month.month}월';

  /// 날짜 칩으로 거른 결과.
  List<ScheduleDay> get visibleDays {
    if (selectedDayLabel == null) return days;
    return days.where((d) => d.label == selectedDayLabel).toList();
  }

  List<Game> get visibleGames =>
      visibleDays.expand((d) => d.games).toList(growable: false);

  bool get isEmpty => days.isEmpty;

  /// 마이팀 경기만 추린 것 (달력 뷰).
  List<ScheduleDay> get myTeamDays {
    final team = myTeam;
    if (team == null) return const [];
    return days
        .map((d) => ScheduleDay(
              label: d.label,
              date: d.date,
              games: d.games
                  .where((g) =>
                      g.home.name == team.name || g.away.name == team.name)
                  .toList(),
            ))
        .where((d) => d.games.isNotEmpty)
        .toList();
  }

  /// 달력 격자. 그 달 1일이 속한 주의 일요일부터 6주치.
  List<CalendarCell> get calendarCells {
    final team = myTeam;
    final byDay = <int, (Game, bool)>{};
    for (final d in myTeamDays) {
      final date = d.date;
      if (date == null) continue;
      final g = d.games.first;
      byDay[date.day] = (g, team != null && g.home.name == team.name);
    }

    final first = DateTime(month.year, month.month, 1);
    // DateTime.weekday는 월=1 … 일=7. 일요일 시작 격자로 바꾼다.
    final leading = first.weekday % 7;
    final start = first.subtract(Duration(days: leading));

    return List.generate(42, (i) {
      final date = DateTime(start.year, start.month, start.day + i);
      final inMonth = date.month == month.month && date.year == month.year;
      final hit = inMonth ? byDay[date.day] : null;
      return CalendarCell(
        date: date,
        inMonth: inMonth,
        game: hit?.$1,
        isHome: hit?.$2 ?? false,
      );
    });
  }

  /// 달력에서 선택한 날의 경기.
  Game? get selectedGame {
    final sel = selectedDate;
    if (sel == null) return null;
    for (final c in calendarCells) {
      if (c.date.year == sel.year &&
          c.date.month == sel.month &&
          c.date.day == sel.day) {
        return c.game;
      }
    }
    return null;
  }

  /// 아직 안 치른 마이팀 경기. 캘린더 내보내기가 이 목록을 쓴다.
  List<Game> get upcomingMyTeamGames => myTeamDays
      .expand((d) => d.games)
      .where((g) => g.status == GameStatus.pre)
      .toList();

  int get upcomingMyTeamCount => upcomingMyTeamGames.length;

  ScheduleState copyWith({
    ScheduleView? view,
    Gender? gender,
    DateTime? month,
    List<ScheduleDay>? days,
    String? season,
    Set<DateTime>? monthsWithGames,
    Team? myTeam,
    String? selectedDayLabel,
    bool clearSelectedDay = false,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
  }) =>
      ScheduleState(
        view: view ?? this.view,
        gender: gender ?? this.gender,
        month: month ?? this.month,
        days: days ?? this.days,
        season: season ?? this.season,
        monthsWithGames: monthsWithGames ?? this.monthsWithGames,
        myTeam: myTeam ?? this.myTeam,
        selectedDayLabel:
            clearSelectedDay ? null : (selectedDayLabel ?? this.selectedDayLabel),
        selectedDate:
            clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      );
}

class ScheduleViewModel extends AsyncNotifier<ScheduleState> {
  @override
  Future<ScheduleState> build() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final gender = prefs.preferredGender;
    final season = prefs.season.year;
    final repo = ref.read(scheduleRepositoryProvider);

    // 오늘 달을 그냥 열면 비시즌에 빈 화면이 된다. 시즌 안에서 오늘에
    // 가장 가까운, 경기가 있는 달을 고른다.
    final month = await repo.getFocusMonth(gender, season);
    final days = await repo.getMonthlySchedule(gender, season, month);
    final months = await repo.getSeasonMonths(gender, season);

    return ScheduleState(
      view: ScheduleView.list,
      gender: gender,
      month: month,
      days: days,
      season: season,
      monthsWithGames: months.toSet(),
      myTeam: prefs.myTeam,
    );
  }

  Future<void> _reload(ScheduleState next) async {
    state = const AsyncLoading<ScheduleState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final repo = ref.read(scheduleRepositoryProvider);
      final season = ref.read(preferencesRepositoryProvider).season.year;
      final days = await repo.getMonthlySchedule(next.gender, season, next.month);
      final months = await repo.getSeasonMonths(next.gender, season);
      return next.copyWith(
        days: days,
        season: season,
        monthsWithGames: months.toSet(),
      );
    });
  }

  void setView(ScheduleView view) {
    final current = state.valueOrNull;
    if (current == null || current.view == view) return;
    state = AsyncData(current.copyWith(view: view, clearSelectedDate: true));
  }

  Future<void> selectGender(Gender gender) async {
    final current = state.valueOrNull;
    if (current == null || current.gender == gender) return;
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setPreferredGender(gender);

    // 남자부는 11월, 여자부는 1월 개막이라 보고 있던 달이 상대 부에는
    // 없을 수 있다. 시작 달을 다시 고른다.
    final month = await ref
        .read(scheduleRepositoryProvider)
        .getFocusMonth(gender, prefs.season.year);

    await _reload(current.copyWith(
      gender: gender,
      month: month,
      clearSelectedDay: true,
      clearSelectedDate: true,
    ));
  }

  Future<void> shiftMonth(int delta) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final month =
        DateTime(current.month.year, current.month.month + delta);
    await _reload(current.copyWith(
      month: month,
      clearSelectedDay: true,
      clearSelectedDate: true,
    ));
  }

  /// 시안 `setYm` — 연·월을 직접 고른다.
  ///
  /// **시즌도 같이 바뀐다.** API의 `month`는 "시즌 안의 월"이라 연도만
  /// 바꾸면 엉뚱한 시즌을 조회하게 된다. 2024년 12월은 24-25 시즌이고
  /// 2026년 4월은 25-26 시즌이다 (`Season.at`).
  Future<void> setYearMonth(int year, int month) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final season = Season.at(DateTime(year, month));
    await ref.read(preferencesRepositoryProvider).setSeason(season);
    await _reload(current.copyWith(
      month: DateTime(year, month),
      clearSelectedDay: true,
      clearSelectedDate: true,
    ));
  }

  /// 시안 `ymToday` — 기본 달로 돌아간다.
  ///
  /// 비시즌에는 오늘 달이 비어 있으므로 시즌 안에서 오늘에 가장 가까운,
  /// 경기가 있는 달로 간다 ([ScheduleRepository.getFocusMonth]).
  Future<void> resetMonth() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setSeason(Season.current);
    final month = await ref
        .read(scheduleRepositoryProvider)
        .getFocusMonth(current.gender, Season.current.year);

    await _reload(current.copyWith(
      month: month,
      clearSelectedDay: true,
      clearSelectedDate: true,
    ));
  }

  /// 날짜 칩 토글. 이미 선택된 칩을 다시 누르면 전체로 돌아간다.
  void toggleDay(String label) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.selectedDayLabel == label
          ? current.copyWith(clearSelectedDay: true)
          : current.copyWith(selectedDayLabel: label),
    );
  }

  void selectDate(DateTime? date) {
    final current = state.valueOrNull;
    if (current == null) return;
    final same = current.selectedDate != null &&
        date != null &&
        current.selectedDate!.day == date.day &&
        current.selectedDate!.month == date.month;
    state = AsyncData(
      same || date == null
          ? current.copyWith(clearSelectedDate: true)
          : current.copyWith(selectedDate: date),
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading<ScheduleState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      // **값이 없으면 처음부터 다시 만든다.** 오류 화면에서는 이전 값이
      // 없는데, 예전에는 여기서 그냥 돌아가서 "다시 시도"를 눌러도 아무
      // 일도 일어나지 않았다.
      if (current == null) return build();

      final days = await ref.read(scheduleRepositoryProvider).getMonthlySchedule(
            current.gender,
            ref.read(preferencesRepositoryProvider).season.year,
            current.month,
            forceRefresh: true,
          );
      return current.copyWith(days: days);
    });
  }
}

final scheduleViewModelProvider =
    AsyncNotifierProvider<ScheduleViewModel, ScheduleState>(
  ScheduleViewModel.new,
);
