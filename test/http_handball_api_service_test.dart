import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myhandball/data/services/api_client.dart';
import 'package:myhandball/data/services/http_handball_api_service.dart';
import 'package:myhandball/domain/models/game.dart';
import 'package:myhandball/domain/models/game_detail.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/domain/models/player_stat.dart';
import 'package:myhandball/domain/models/team.dart';
import 'package:myhandball/domain/models/team_detail.dart';

/// `test/fixtures/`는 **실제 서버 응답을 잘라 둔 것**이다
/// (2026-09-23, `localhost:3000`, 25-26 시즌 남자부).
///
/// 연맹 사이트가 개편되면 서버 쪽 파서가 먼저 깨지지만, 서버가 필드 이름이나
/// 타입을 바꿨을 때 앱이 조용히 빈 화면을 그리는 걸 여기서 잡는다.
String _fixture(String name) =>
    File('test/fixtures/$name.json').readAsStringSync();

void main() {
  /// 요청 경로별로 픽스처를 돌려주는 가짜 서버.
  ///
  /// [seen]에 실제로 나간 요청이 쌓이므로 쿼리 파라미터도 검증할 수 있다.
  HttpHandballApiService build(
    Map<String, String> routes, {
    List<http.Request>? seen,
    int status = 200,
  }) {
    final client = MockClient((request) async {
      seen?.add(request);
      final body = routes[request.url.path];
      if (body == null) {
        return http.Response(
          jsonEncode({'statusCode': 404, 'message': '없는 경로: ${request.url.path}'}),
          404,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response.bytes(
        utf8.encode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    return HttpHandballApiService(
      client: ApiClient(
        baseUrl: 'https://example.test',
        deviceId: '11111111-2222-4333-8444-555555555555',
        client: client,
      ),
      gender: () => Gender.men,
      season: () => '2025',
    );
  }

  group('일정', () {
    test('경기 카드에 matchSeq·상태·점수가 실린다', () async {
      final seen = <http.Request>[];
      final api = build({
        '/api/schedule': _fixture('schedule'),
        '/api/team': _fixture('team'),
      }, seen: seen);

      final days = await api.fetchMonthlySchedule(Gender.men, DateTime(2025, 11));

      expect(days, hasLength(1));
      expect(days.first.label, '2025.11.15 (토)');
      expect(days.first.date, DateTime(2025, 11, 15));

      final game = days.first.games.single;
      expect(game.matchSeq, 5490);
      expect(game.id, 'g5490');
      expect(game.hasDetail, isTrue);
      expect(game.status, GameStatus.finished);
      expect(game.scoreHome, 20);
      expect(game.scoreAway, 23);
      expect(game.home.name, '두산');
      expect(game.away.name, 'SK호크스');
      expect(game.venue, '티켓링크 라이브 아레나(핸드볼경기장)');
      expect(game.broadcast, contains('KBS1'));
      expect(game.startsAt, isNotNull);

      // 끝난 경기는 날짜 + 시각. 연도는 떼고 보여준다.
      expect(game.meta, '11.15 (토) 15:20');
    });

    test('요청에 gender·season·type·month가 실린다', () async {
      final seen = <http.Request>[];
      final api = build({
        '/api/schedule': _fixture('schedule'),
        '/api/team': _fixture('team'),
      }, seen: seen);

      await api.fetchMonthlySchedule(Gender.women, DateTime(2025, 11));

      final q = seen.firstWhere((r) => r.url.path == '/api/schedule').url
          .queryParameters;
      expect(q['gender'], 'W');
      expect(q['season'], '2025');
      expect(q['type'], '1');
      expect(q['month'], '11');
    });

    test('월을 빼면 month 파라미터가 나가지 않는다 (시즌 전체)', () async {
      final seen = <http.Request>[];
      final api = build({
        '/api/schedule': _fixture('schedule'),
        '/api/team': _fixture('team'),
      }, seen: seen);

      await api.fetchUpcomingGames();

      final q = seen.firstWhere((r) => r.url.path == '/api/schedule').url
          .queryParameters;
      expect(q.containsKey('month'), isFalse);
    });
  });

  group('순위 · 팀', () {
    test('순위에 팀 번호를 팀 목록에서 붙인다', () async {
      // 순위 응답에는 teamNum이 없다. 없으면 팀 상세로 넘어갈 수 없다.
      final api = build({
        '/api/ranking': _fixture('ranking'),
        '/api/team': _fixture('team'),
      });

      final rows = await api.fetchRanking(Gender.men);

      expect(rows.first.rank, 1);
      expect(rows.first.team.name, '인천도시공사');
      expect(rows.first.points, 42);
      expect(rows.first.wins, 21);
      expect(rows.first.goalDiff, 102);
      expect(rows.first.last5, isNotEmpty);
    });

    test('팀 목록을 못 받아도 순위는 나온다', () async {
      final api = build({'/api/ranking': _fixture('ranking')});

      final rows = await api.fetchRanking(Gender.men);

      expect(rows, isNotEmpty);
      expect(rows.first.team.teamNum, isNull);
    });
  });

  group('선수', () {
    test('배번·포지션이 없는 선수도 통과시킨다', () async {
      // 이적·은퇴 선수는 로스터에 없어 둘 다 null로 온다 (07 C절).
      final api = build({'/api/player': _fixture('players')});

      final players = await api.fetchPlayers(Gender.men);

      expect(players.first.name, '이요셉');
      expect(players.first.id, 'p69');
      expect(players.first.teamName, '인천도시공사');
      expect(players.first.statLine, '166골 · 82AS');
    });

    test('기록 랭킹은 원본 단위를 붙여 보여준다', () async {
      final api = build({'/api/player/ranking': _fixture('player_ranking')});

      final top = await api.fetchTopPlayers(Gender.men, StatCategory.goals);

      expect(top.first.rank, 1);
      expect(top.first.value, endsWith('골'));
    });
  });

  group('경기 상세', () {
    Future<GameDetail> detail() => build({
          '/api/game/5490': _fixture('game'),
          '/api/game/5490/live': _fixture('live'),
          '/api/schedule': _fixture('schedule'),
          '/api/team': _fixture('team'),
        }).fetchGameDetail(const Game(
          id: 'g5490',
          matchSeq: 5490,
          home: Team(name: '두산'),
          away: Team(name: 'SK호크스'),
          status: GameStatus.finished,
          meta: '',
        ));

    test('전·후반과 팀 기록이 붙는다', () async {
      final d = await detail();

      expect(d.game.scoreHome, 20);
      expect(d.game.scoreAway, 23);
      expect(d.firstHalfHome, 10);
      expect(d.firstHalfAway, 10);
      expect(d.secondHalfHome, 10);
      expect(d.secondHalfAway, 13);

      final shots = d.stats.firstWhere((s) => s.label == '슛 성공률');
      expect(shots.isPercent, isTrue);
      expect(shots.homeText, '54.1%');
    });

    test('중계 이벤트에서 득점자를 읽고, 그리지 않는 종류는 버린다', () async {
      final d = await detail();

      final goals = d.events.where((e) => e.type == GameEventType.goal);
      expect(goals, isNotEmpty);
      expect(goals.first.playerName, isNotNull);
      expect(goals.first.isHome, isNotNull);

      // 시안 타임라인에 없는 종류(shot, period 중 일부 등)는 남기지 않는다.
      expect(d.events.every((e) => GameEventType.values.contains(e.type)),
          isTrue);
      expect(d.events.any((e) => e.type == GameEventType.end), isTrue);
    });

    test('matchSeq가 없는 경기는 상세를 열지 않는다', () async {
      final api = build({});

      expect(
        () => api.fetchGameDetail(const Game(
          id: 'x',
          home: Team(name: 'A'),
          away: Team(name: 'B'),
          status: GameStatus.pre,
          meta: '',
        )),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('팀 상세', () {
    test('소개·연혁·명단·전적을 읽는다', () async {
      final api = build({'/api/team/132': _fixture('team_detail')});

      final d = await api.fetchTeamDetail(
          const Team(name: 'SK호크스', teamNum: 132));

      expect(d.team.name, 'SK호크스');
      expect(d.intro, isNotEmpty);
      expect(d.slogan, isNotEmpty);
      expect(d.results, isNotEmpty);
      expect(d.results.every((r) => MatchResult.values.contains(r)), isTrue);
      // 홈구장은 원본에 없다 — facts에 들어가면 안 된다 (07 C절).
      expect(d.facts.map((f) => f.$1), isNot(contains('홈구장')));
    });

    test('팀 번호가 없으면 상세를 열지 않는다', () async {
      final api = build({});

      expect(
        () => api.fetchTeamDetail(const Team(name: 'A')),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('사용자 콘텐츠', () {
    const game = Game(
      id: 'g5490',
      matchSeq: 5490,
      home: Team(name: '두산'),
      away: Team(name: 'SK호크스'),
      status: GameStatus.finished,
      meta: '',
    );

    test('예측 분포와 내 선택을 읽는다', () async {
      final api = build({'/api/game/5490/prediction': _fixture('prediction')});

      final t = await api.fetchPrediction(game);

      expect(t.total, 3);
      expect(t.myPick, PredictionPick.home);
      expect(t.open, isTrue);
      expect(t.percentFor(PredictionPick.home), 67);
      expect(t.percentFor(PredictionPick.away), 33);
    });

    test('쓰기 요청에 X-Device-Id가 실린다', () async {
      final seen = <http.Request>[];
      final api = build(
        {'/api/game/5490/prediction': _fixture('prediction')},
        seen: seen,
      );

      await api.submitPrediction(game, PredictionPick.away);

      final post = seen.firstWhere((r) => r.method == 'POST');
      expect(post.headers['X-Device-Id'], isNotEmpty);
      expect(jsonDecode(post.body), {'pick': 'away'});
    });

    test('playerSeq가 없는 후보는 이름으로 식별한다', () async {
      final api = build({'/api/game/5490/mvp': _fixture('mvp')});

      final board = await api.fetchMvp(game);

      expect(board.open, isTrue);
      expect(board.candidates, isNotEmpty);
      expect(board.candidates.first.id, startsWith('p'));
      expect(board.candidates.first.playerSeq, isNotNull);
    });

    test('응원글의 좋아요·내 글 여부는 서버 판정을 그대로 쓴다', () async {
      final api = build({'/api/team/132/cheer': _fixture('cheer')});

      final posts =
          await api.fetchCheers(const Team(name: 'SK호크스', teamNum: 132));

      expect(posts, hasLength(2));
      expect(posts.first.isMine, isTrue);
      expect(posts.first.liked, isTrue);
      expect(posts.first.author, '나');
      expect(posts.last.author, '익명');
      expect(posts.first.likes, 3);
    });
  });

  group('실패 처리', () {
    test('429는 요청 제한으로 구분된다', () async {
      final api = build({'/api/team/132/cheer': '{"message":"너무 잦아요"}'},
          status: 429);

      await expectLater(
        api.submitCheer(const Team(name: 'A', teamNum: 132), '화이팅'),
        throwsA(isA<ApiException>()
            .having((e) => e.isRateLimited, 'isRateLimited', isTrue)),
      );
    });

    test('서버에 닿지 못하면 오프라인으로 구분된다', () async {
      final api = HttpHandballApiService(
        client: ApiClient(
          baseUrl: 'https://example.test',
          deviceId: 'device-0001',
          client: MockClient((_) => throw const SocketException('down')),
        ),
        gender: () => Gender.men,
        season: () => '2025',
      );

      await expectLater(
        api.fetchTeams(Gender.men),
        throwsA(isA<ApiException>()
            .having((e) => e.isOffline, 'isOffline', isTrue)),
      );
    });
  });
}
