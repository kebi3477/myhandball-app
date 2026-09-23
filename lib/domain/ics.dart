import 'models/game.dart';

/// 경기 일정을 iCalendar(.ics) 문서로 만든다.
///
/// 서버에도 `GET /api/schedule/ics/my-team`이 있지만 **시즌 전체만** 준다.
/// 시안은 경기 하나만 넣는 버튼도 갖고 있고, 앱에는 이미 경기 데이터가
/// 있으므로 여기서 만든다. 경로가 하나라 동작이 어긋날 일도 없다.
///
/// 시안 문구 그대로 **경기 30분 전 알림**을 넣는다.
abstract final class Ics {
  /// 알림을 몇 분 전에 울릴지. 시안: "경기 30분 전 알림 포함 (.ics)"
  static const reminderMinutes = 30;

  /// 기본 경기 시간. 연맹이 종료 시각을 주지 않아 추정한다
  /// (전반 30 + 휴식 10 + 후반 30 + 여유).
  static const _durationMinutes = 120;

  static String forGames(List<Game> games, {required String calendarName}) {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//myhandball//KO//')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('METHOD:PUBLISH')
      ..writeln('X-WR-CALNAME:${_escape(calendarName)}');

    for (final game in games) {
      final start = game.startsAt;
      if (start == null) continue;
      _writeEvent(buffer, game, start);
    }

    buffer.write('END:VCALENDAR');
    return buffer.toString();
  }

  static void _writeEvent(StringBuffer buffer, Game game, DateTime start) {
    final end = start.add(const Duration(minutes: _durationMinutes));
    final title = '${game.home.name} vs ${game.away.name}';

    buffer
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${game.id}@myhandball')
      ..writeln('DTSTAMP:${_utc(DateTime.now().toUtc())}')
      ..writeln('DTSTART:${_local(start)}')
      ..writeln('DTEND:${_local(end)}')
      ..writeln('SUMMARY:${_escape(title)}');

    if (game.venue case final venue? when venue.isNotEmpty) {
      buffer.writeln('LOCATION:${_escape(venue)}');
    }
    if (game.broadcast.isNotEmpty) {
      buffer.writeln('DESCRIPTION:${_escape('중계 ${game.broadcastText}')}');
    }

    buffer
      ..writeln('BEGIN:VALARM')
      ..writeln('ACTION:DISPLAY')
      ..writeln('DESCRIPTION:${_escape(title)}')
      ..writeln('TRIGGER:-PT${reminderMinutes}M')
      ..writeln('END:VALARM')
      ..writeln('END:VEVENT');
  }

  /// 한국 경기라 현지 시각으로 쓴다 (`TZID` 없이 floating time).
  /// 기기 표준시가 달라도 "18:00 경기"는 18:00에 보이는 게 맞다.
  static String _local(DateTime t) =>
      '${_pad4(t.year)}${_pad(t.month)}${_pad(t.day)}'
      'T${_pad(t.hour)}${_pad(t.minute)}00';

  static String _utc(DateTime t) => '${_local(t)}Z';

  static String _pad(int v) => v.toString().padLeft(2, '0');
  static String _pad4(int v) => v.toString().padLeft(4, '0');

  /// RFC 5545 — 쉼표·세미콜론·역슬래시·줄바꿈을 이스케이프한다.
  static String _escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\n', r'\n');
}
