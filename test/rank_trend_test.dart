import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myhandball/data/services/api_client.dart';
import 'package:myhandball/data/services/http_handball_api_service.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/domain/models/team.dart';

/// 라운드별 순위 추이는 **연맹이 주지 않아 앱이 직접 만든다.**
///
/// 전에는 빈 배열이라 팀 상세의 "시즌 추이" 순위 모드가 항상 빈 차트였다.
/// 목업에는 값이 있어서 프리뷰로는 멀쩡해 보였다.
void main() {
  /// 3팀 리그. A는 1차전 승, 2차전 패.
  String schedule() => '''
{"days":[
 {"dateISO":"2025-11-01","dateLabel":"2025.11.01 (토)","games":[
   {"matchSeq":1,"home":{"name":"A"},"away":{"name":"B"},"scoreHome":30,"scoreAway":20,"status":"finished","time":"14:00"},
   {"matchSeq":2,"home":{"name":"C"},"away":{"name":"D"},"scoreHome":25,"scoreAway":24,"status":"finished","time":"16:00"}
 ]},
 {"dateISO":"2025-11-08","dateLabel":"2025.11.08 (토)","games":[
   {"matchSeq":3,"home":{"name":"C"},"away":{"name":"A"},"scoreHome":31,"scoreAway":20,"status":"finished","time":"14:00"}
 ]}
]}''';

  HttpHandballApiService service() => HttpHandballApiService(
        client: ApiClient(
          baseUrl: 'https://example.test',
          deviceId: '11111111-2222-3333-4444-555555555555',
          client: MockClient((req) async {
            if (req.url.path.endsWith('/schedule')) {
              return http.Response(schedule(), 200,
                  headers: {'content-type': 'application/json; charset=utf-8'});
            }
            return http.Response('{}', 200,
                headers: {'content-type': 'application/json; charset=utf-8'});
          }),
        ),
        gender: () => Gender.men,
        season: () => '2025',
      );

  test('내 팀이 뛴 경기마다 한 점씩 남는다', () async {
    final trend =
        await service().rankTrendFor(const Team(name: 'A', gender: Gender.men));

    // A는 두 경기를 치렀다. 다른 팀만 뛴 날은 안 센다.
    expect(trend, hasLength(2));
  });

  test('승점과 득실차로 순위를 매긴다', () async {
    final trend =
        await service().rankTrendFor(const Team(name: 'A', gender: Gender.men));

    // 1라운드 뒤: A 2점(+10), C 2점(+1) → A가 1위
    expect(trend.first, 1);
    // 2라운드 뒤: C 4점(+12), A 2점(-1) → A는 2위
    expect(trend.last, 2);
  });

  test('기록이 없는 팀은 빈 목록이다', () async {
    final trend = await service()
        .rankTrendFor(const Team(name: '없는팀', gender: Gender.men));
    expect(trend, isEmpty);
  });
}
