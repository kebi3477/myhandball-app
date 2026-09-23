import 'game.dart';

/// 하루치 경기. API `/api/schedule`의 `DayBlock`에 대응한다.
///
/// API는 `dateISO`가 null일 수 있고 `dateLabel`(원문 문자열)만 오는 경우가
/// 있다. 그 경우 [date]는 null이고 [label]만 쓴다.
class ScheduleDay {
  const ScheduleDay({
    required this.label,
    required this.games,
    this.date,
  });

  /// 원문 라벨. 예: `2026.11.14 (토)`
  final String label;

  final DateTime? date;
  final List<Game> games;

  /// 날짜 칩에 쓰는 짧은 라벨. 예: `11.14 (토)`
  String get shortLabel {
    final d = date;
    if (d == null) return label;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final w = weekdays[d.weekday - 1];
    return '${d.month}.${d.day} ($w)';
  }
}

/// 마이팀 달력의 한 칸.
class CalendarCell {
  const CalendarCell({
    required this.date,
    required this.inMonth,
    this.game,
    this.isHome = false,
  });

  final DateTime date;

  /// 앞뒤 달에서 넘어온 빈 칸인지.
  final bool inMonth;

  /// 그날 마이팀 경기. 없으면 null.
  final Game? game;

  /// 마이팀이 홈인지 (달력 링 색이 달라진다).
  final bool isHome;

  bool get hasGame => game != null;
}
