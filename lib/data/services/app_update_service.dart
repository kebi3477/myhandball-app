import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';

/// 스토어에 올라와 있는 최신 버전.
class AppUpdate {
  const AppUpdate({required this.version, required this.storeUrl});

  /// `1.2.0` 꼴. 빌드 번호는 없다 — 스토어가 표시 버전만 준다.
  final String version;

  /// 눌렀을 때 열 스토어 주소.
  final String storeUrl;
}

/// 스토어의 최신 버전을 확인한다. 배포본의 `AppUpdateChecker.swift`를 옮긴 것이다.
///
/// **강제 업데이트가 아니다.** 안내만 하고, 사용자가 "나중에"를 고르면 그
/// 버전은 다시 묻지 않는다. 자체 호스팅 서버라 앱을 막아 세울 근거가 약하고,
/// 막아 두면 서버가 잠깐 이상해도 앱을 못 쓰게 된다.
class AppUpdateService {
  AppUpdateService({http.Client? client, this.timeout = const Duration(seconds: 8)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  void close() => _client.close();

  /// 스토어에 물어본 최신 버전. 확인할 수 없으면 `null`.
  ///
  /// 플랫폼을 고르기만 한다. **안드로이드는 Play 스토어에 공개 조회 API가
  /// 없어서 아직 확인할 방법이 없다** — 서버에 버전 엔드포인트가 생기면
  /// 그때 붙인다 (API 프롬프트 참조).
  Future<AppUpdate?> fetchLatest() async =>
      Platform.isIOS ? fetchFromAppStore() : null;

  /// iTunes Lookup API. 배포본이 쓰던 것과 같은 주소다.
  ///
  /// **실패해도 절대 예외를 올리지 않는다.** 업데이트 확인 때문에 앱이
  /// 멈추면 안 된다. 그래서 try/catch가 호출부가 아니라 여기 있다.
  Future<AppUpdate?> fetchFromAppStore() async {
    try {
      return await _lookup();
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[MyHandball] 버전 확인 실패: $e');
      return null;
    }
  }

  Future<AppUpdate?> _lookup() async {
    final uri = Uri.https('itunes.apple.com', '/lookup', {
      'bundleId': AppConfig.iosBundleId,
      'country': 'kr',
      // iTunes가 응답을 오래 캐시한다. 심사 통과 직후에도 옛 버전이 오는 걸
      // 막으려고 매번 다른 값을 붙인다.
      't': '${DateTime.now().millisecondsSinceEpoch}',
    });

    final res = await _client.get(uri).timeout(timeout);
    if (res.statusCode != 200) return null;

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is! Map) return null;
    final results = decoded['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map) return null;

    final version = first['version'];
    final url = first['trackViewUrl'];
    if (version is! String || url is! String) return null;
    return AppUpdate(version: version, storeUrl: url);
  }

  /// [latest]가 [current]보다 높은 버전인지.
  ///
  /// `1.10.0`이 `1.9.0`보다 높아야 하므로 **문자열 비교를 쓰면 안 된다.**
  /// 점으로 끊어 숫자로 본다. 자리 수가 다르면 없는 자리는 0으로 친다
  /// (`1.2`와 `1.2.0`은 같다).
  static bool isNewer({required String current, required String latest}) {
    final a = _parts(current);
    final b = _parts(latest);
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (y > x) return true;
      if (y < x) return false;
    }
    return false;
  }

  /// `1.2.0+4` → `[1, 2, 0]`. 숫자가 아닌 자리는 0으로 본다.
  static List<int> _parts(String version) => [
        for (final piece in version.split('+').first.split('.'))
          int.tryParse(piece.trim()) ?? 0,
      ];
}
