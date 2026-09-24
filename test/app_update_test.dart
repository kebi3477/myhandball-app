import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myhandball/data/services/app_update_service.dart';

/// 버전 비교가 틀리면 둘 중 하나가 난다 — 최신인데 안내가 안 뜨거나,
/// 최신인데도 계속 업데이트하라고 조른다.
void main() {
  group('버전 비교', () {
    bool newer(String current, String latest) =>
        AppUpdateService.isNewer(current: current, latest: latest);

    test('같은 버전은 업데이트가 아니다', () {
      expect(newer('1.1.0', '1.1.0'), isFalse);
    });

    test('스토어가 더 높으면 업데이트다', () {
      expect(newer('1.1.0', '1.1.1'), isTrue);
      expect(newer('1.1.0', '1.2.0'), isTrue);
      expect(newer('1.1.0', '2.0.0'), isTrue);
    });

    test('내 쪽이 더 높으면(심사 대기 중 빌드) 조르지 않는다', () {
      expect(newer('1.2.0', '1.1.0'), isFalse);
    });

    test('문자열 비교로는 틀리는 자리를 숫자로 본다', () {
      // '1.10.0' < '1.9.0' (문자열) 이지만 실제로는 10이 더 높다.
      expect(newer('1.9.0', '1.10.0'), isTrue);
      expect(newer('1.10.0', '1.9.0'), isFalse);
    });

    test('자리 수가 달라도 없는 자리는 0으로 본다', () {
      expect(newer('1.2', '1.2.0'), isFalse);
      expect(newer('1.2', '1.2.1'), isTrue);
    });

    test('빌드 번호는 무시한다', () {
      expect(newer('1.1.0+4', '1.1.0'), isFalse);
    });
  });

  // `fetchLatest()`는 플랫폼으로 갈라지고, 테스트는 macOS에서 돈다.
  // 실제 조회·파싱은 `fetchFromAppStore()`에 있어 그쪽을 부른다.
  group('스토어 조회', () {
    test('응답이 깨져 있어도 예외를 올리지 않는다', () async {
      final service = AppUpdateService(
        client: MockClient((_) async => http.Response('{"results":[]}', 200)),
      );
      expect(await service.fetchFromAppStore(), isNull);
    });

    test('서버가 죽어도 예외를 올리지 않는다', () async {
      // 업데이트 확인 때문에 앱이 안 뜨면 안 된다.
      final service = AppUpdateService(
        client: MockClient((_) async => throw const SocketishError()),
      );
      expect(await service.fetchFromAppStore(), isNull);
    });

    test('정상 응답에서 버전과 스토어 주소를 읽는다', () async {
      final service = AppUpdateService(
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'resultCount': 1,
                'results': [
                  {
                    'version': '1.2.0',
                    'trackViewUrl': 'https://apps.apple.com/kr/app/id123',
                  },
                ],
              }),
              200,
            )),
      );
      final latest = await service.fetchFromAppStore();
      expect(latest?.version, '1.2.0');
      expect(latest?.storeUrl, 'https://apps.apple.com/kr/app/id123');
    });
  });
}

class SocketishError implements Exception {
  const SocketishError();
}
