import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/models/attendance.dart';
import 'package:myhandball/domain/models/game.dart';
import 'package:myhandball/domain/models/rank_row.dart';
import 'package:myhandball/domain/models/team.dart';
import 'package:myhandball/ui/home/view_models/attendance_view_model.dart';

final _mine = const Team(name: 'SK호크스');
final _rival = const Team(name: '두산');

Game _game({
  required int home,
  required int away,
  bool asHome = true,
  String venue = 'SK호크스 홈구장',
}) =>
    Game(
      id: '$home-$away-$asHome-$venue',
      home: asHome ? _mine : _rival,
      away: asHome ? _rival : _mine,
      status: GameStatus.finished,
      meta: '11.14 (토) 14:00',
      scoreHome: home,
      scoreAway: away,
      venue: venue,
    );

AttendanceState _state(
  List<AttendanceEntry> entries, {
  List<VenueStamp> stamps = const [],
  RankRow? rank,
}) =>
    AttendanceState(
      team: _mine,
      seasonLabel: '25-26 시즌 나의 직관',
      entries: entries,
      stamps: stamps,
      upcoming: const [],
      candidates: const [],
      teamRank: rank,
    );

AttendanceEntry _entry(Game g) =>
    AttendanceEntry(game: g, result: AttendanceEntry.resultFor(g, _mine));

void main() {
  group('직관 결과 판정', () {
    test('원정 경기는 뒤집어 본다', () {
      // 원정에서 26:28이면 마이팀은 28점을 낸 쪽이라 승리다.
      final game = _game(home: 26, away: 28, asHome: false);
      expect(AttendanceEntry.resultFor(game, _mine), AttendanceResult.win);
    });

    test('점수가 없으면 승률에서 뺀다', () {
      final game = Game(
        id: 'x',
        home: _mine,
        away: _rival,
        status: GameStatus.pre,
        meta: '11.14 (토) 14:00',
      );
      expect(AttendanceEntry.resultFor(game, _mine), AttendanceResult.unknown);

      final state = _state([_entry(game), _entry(_game(home: 30, away: 20))]);
      // 확정 1경기 중 1승 → 100%. 미확정 경기가 분모에 들어가면 50%가 된다.
      expect(state.rateLabel, '100%');
      expect(state.wdlLabel, '1·0·0');
    });

    test('마이팀이 안 뛴 경기는 판정하지 않는다', () {
      final other = Game(
        id: 'y',
        home: _rival,
        away: const Team(name: '충남도청'),
        status: GameStatus.finished,
        meta: '',
        scoreHome: 30,
        scoreAway: 20,
      );
      expect(AttendanceEntry.resultFor(other, _mine), AttendanceResult.unknown);
    });
  });

  group('요약', () {
    test('기록이 없으면 승률이 -다', () {
      expect(_state(const []).rateLabel, '-');
      expect(_state(const []).wdlLabel, '0·0·0');
    });

    test('팀 승률보다 높을 때만 배지가 붙는다', () {
      final entries = [
        for (var i = 0; i < 4; i++) _entry(_game(home: 30 + i, away: 20)),
      ];
      // 직관 4전 4승(100%) vs 팀 20경기 10승(50%)
      const high = RankRow(rank: 1, team: Team(name: 'SK호크스'), points: 20,
          played: 20, wins: 10);
      expect(_state(entries, rank: high).badge?.$1, '행운의 직관러');

      // 팀이 전승이면 내가 특별할 게 없다.
      const perfect = RankRow(rank: 1, team: Team(name: 'SK호크스'), points: 40,
          played: 20, wins: 20);
      expect(_state(entries, rank: perfect).badge, isNull);
    });

    test('확정 3경기 미만이면 배지를 달지 않는다', () {
      // 한 경기 이겼다고 "행운의 직관러"를 붙이면 아무 뜻이 없다.
      const rank = RankRow(rank: 1, team: Team(name: 'SK호크스'), points: 20,
          played: 20, wins: 10);
      final one = [_entry(_game(home: 30, away: 20))];
      expect(_state(one, rank: rank).badge, isNull);
    });
  });

  test('도장판은 안 가본 곳도 센다', () {
    const stamps = [
      VenueStamp(venue: 'A', times: 2),
      VenueStamp(venue: 'B', times: 0),
      VenueStamp(venue: 'C', times: 1),
    ];
    expect(_state(const [], stamps: stamps).stampCountLabel, '2/3');
  });
}
