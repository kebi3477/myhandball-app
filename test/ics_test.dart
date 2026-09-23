import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/ics.dart';
import 'package:myhandball/domain/models/game.dart';
import 'package:myhandball/domain/models/team.dart';

/// 캘린더에 들어가는 문서라 **한 글자 틀리면 통째로 안 열린다.**
/// 손으로 확인하기 어려워서 테스트로 잡는다.
void main() {
  Game game({
    String id = 'g5490',
    DateTime? startsAt,
    String? venue = '청주 SK호크스아레나',
    List<String> broadcast = const ['MAXPORTS', 'NAVER'],
  }) =>
      Game(
        id: id,
        home: const Team(name: 'SK호크스'),
        away: const Team(name: '충남도청'),
        status: GameStatus.pre,
        meta: '',
        startsAt: startsAt ?? DateTime(2026, 2, 6, 17),
        venue: venue,
        broadcast: broadcast,
      );

  test('VCALENDAR 골격과 이벤트가 만들어진다', () {
    final ics = Ics.forGames([game()], calendarName: 'SK호크스 일정');

    expect(ics, startsWith('BEGIN:VCALENDAR'));
    expect(ics, endsWith('END:VCALENDAR'));
    expect(ics, contains('VERSION:2.0'));
    expect(ics, contains('X-WR-CALNAME:SK호크스 일정'));
    expect(ics, contains('BEGIN:VEVENT'));
    expect(ics, contains('SUMMARY:SK호크스 vs 충남도청'));
    expect(ics, contains('LOCATION:청주 SK호크스아레나'));
    expect(ics, contains('UID:g5490@myhandball'));
  });

  test('시작·종료 시각이 현지 시각으로 들어간다', () {
    final ics = Ics.forGames([game(startsAt: DateTime(2026, 2, 6, 17))],
        calendarName: 'x');

    expect(ics, contains('DTSTART:20260206T170000'));
    // 기본 2시간
    expect(ics, contains('DTEND:20260206T190000'));
  });

  test('경기 30분 전 알림이 붙는다', () {
    final ics = Ics.forGames([game()], calendarName: 'x');

    expect(ics, contains('BEGIN:VALARM'));
    expect(ics, contains('TRIGGER:-PT30M'));
    expect(ics, contains('END:VALARM'));
  });

  test('쉼표·세미콜론을 이스케이프한다', () {
    // 중계 목록이 "MAXPORTS, NAVER"라 쉼표가 들어간다.
    // 이스케이프하지 않으면 캘린더가 필드가 끊긴 것으로 읽는다.
    final ics = Ics.forGames([game()], calendarName: 'x');

    expect(ics, contains(r'DESCRIPTION:중계 MAXPORTS\, NAVER'));
    expect(ics, isNot(contains('DESCRIPTION:중계 MAXPORTS, NAVER')));
  });

  test('시작 시각이 없는 경기는 건너뛴다', () {
    final ics = Ics.forGames(
      [game(), Game(
        id: 'no-time',
        home: const Team(name: 'A'),
        away: const Team(name: 'B'),
        status: GameStatus.pre,
        meta: '',
      )],
      calendarName: 'x',
    );

    expect('BEGIN:VEVENT'.allMatches(ics), hasLength(1));
  });

  test('장소·중계가 없으면 그 줄을 넣지 않는다', () {
    final ics = Ics.forGames(
      [game(venue: null, broadcast: const [])],
      calendarName: 'x',
    );

    expect(ics, isNot(contains('LOCATION:')));
    expect(ics, isNot(contains('DESCRIPTION:중계')));
    expect(ics, contains('SUMMARY:'));
  });

  test('여러 경기를 한 문서에 담는다', () {
    final ics = Ics.forGames(
      [game(id: 'a'), game(id: 'b'), game(id: 'c')],
      calendarName: 'x',
    );

    expect('BEGIN:VEVENT'.allMatches(ics), hasLength(3));
    expect('END:VEVENT'.allMatches(ics), hasLength(3));
  });
}
