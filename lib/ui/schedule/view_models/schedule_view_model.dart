import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/gender.dart';
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
    this.myTeam,
    this.selectedDayLabel,
    this.selectedDate,
  });

  final ScheduleView view;
  final Gender gender;

  /// 보고 있는 달의 1일.
  final DateTime month;

  final List<ScheduleDay> days;
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

  int get upcomingMyTeamCount => myTeamDays
      .expand((d) => d.games)
      .where((g) => g.status == GameStatus.pre)
      .length;

  ScheduleState copyWith({
    ScheduleView? view,
    Gender? gender,
    DateTime? month,
    List<ScheduleDay>? days,
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
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);

    final days = await ref
        .read(scheduleRepositoryProvider)
        .getMonthlySchedule(gender, month);

    return ScheduleState(
      view: ScheduleView.list,
      gender: gender,
      month: month,
      days: days,
      myTeam: prefs.myTeam,
    );
  }

  Future<void> _reload(ScheduleState next) async {
    state = const AsyncLoading<ScheduleState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final days = await ref
          .read(scheduleRepositoryProvider)
          .getMonthlySchedule(next.gender, next.month);
      return next.copyWith(days: days);
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
    await ref.read(preferencesRepositoryProvider).setPreferredGender(gender);
    await _reload(current.copyWith(
      gender: gender,
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
    if (current == null) return;
    state = const AsyncLoading<ScheduleState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final days = await ref.read(scheduleRepositoryProvider).getMonthlySchedule(
            current.gender,
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
