import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// API 호출이 실패했을 때 던진다.
///
/// 화면은 대부분 [message]만 보여주면 되지만, 쓰기 엔드포인트는 상태 코드에
/// 따라 문구가 달라서 [statusCode]를 따로 노출한다
/// (`../myhandball-api/docs/api-tasks/07-후속-작업.md` C절).
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.path});

  final String message;
  final int? statusCode;
  final String? path;

  /// 이미 투표했거나 마감된 경기 — `409`.
  bool get isConflict => statusCode == 409;

  /// 분당 30회 제한 또는 응원글 하루 5개 제한 — `429`.
  bool get isRateLimited => statusCode == 429;

  /// `X-Device-Id`가 없거나 형식이 틀렸을 때, 본문이 200자를 넘을 때 — `400`.
  bool get isBadRequest => statusCode == 400;

  bool get isNotFound => statusCode == 404;

  /// 서버에 닿지 못한 경우 (DNS 실패, 인증서 만료, 타임아웃).
  ///
  /// 자체 호스팅이라 실제로 일어난다. `CLAUDE.md`의 서버 상태 참조.
  bool get isOffline => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode $path): $message';
}

/// `myhandball-api`를 치는 얇은 래퍼. 상태를 갖지 않는다.
///
/// 서버는 전역 prefix `/api`를 쓰고 **인증이 없다.** 쓰기 요청만 익명 기기
/// UUID를 `X-Device-Id` 헤더로 보낸다.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.deviceId,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  /// 예: `https://myhandball.lab241.com`. 뒤 슬래시는 있어도 된다.
  final String baseUrl;

  /// 앱이 처음 켜질 때 만든 난수 UUID v4.
  ///
  /// 서버는 영문·숫자·하이픈 8~64자만 받는다.
  final String deviceId;

  final Duration timeout;
  final http.Client _client;

  /// 마지막 요청이 서버에 닿지 못했는지. 시안 `isOffline`.
  ///
  /// 셸 상단의 회색 띠가 이걸 본다. 연결 상태를 따로 감시하는 패키지를
  /// 들이는 대신 **실제로 실패한 요청**을 신호로 쓴다 — 와이파이에는
  /// 붙어 있는데 서버만 죽은 경우도 사용자에겐 똑같이 "안 된다"이다.
  final ValueNotifier<bool> offline = ValueNotifier(false);

  /// **[offline]은 일부러 dispose 하지 않는다.** 셸 상단의 오프라인 띠가
  /// 이걸 계속 듣고 있어서, 클라이언트가 먼저 정리되면 폐기된 notifier를
  /// 듣는 위젯이 남는다. 앱에 하나뿐인 작은 객체라 그냥 둔다.
  void close() => _client.close();

  Uri _uri(String path, [Map<String, String?>? query]) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final params = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.isNotEmpty) params[k] = v;
    });
    return Uri.parse('$root/api$path')
        .replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<dynamic> get(String path, [Map<String, String?>? query]) =>
      _send('GET', path, query);

  Future<dynamic> post(String path,
          {Map<String, String?>? query, Object? body}) =>
      _send('POST', path, query, body);

  Future<dynamic> put(String path,
          {Map<String, String?>? query, Object? body}) =>
      _send('PUT', path, query, body);

  Future<dynamic> delete(String path, [Map<String, String?>? query]) =>
      _send('DELETE', path, query);

  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, String?>? query,
    Object? body,
  ]) async {
    final uri = _uri(path, query);
    final headers = <String, String>{
      'Accept': 'application/json',
      // 조회에도 함께 보낸다. 서버가 "내 예측 / 내가 쓴 글"을 표시하려면
      // GET에도 기기를 알아야 한다.
      'X-Device-Id': deviceId,
      if (body != null) 'Content-Type': 'application/json',
    };

    final http.Response res;
    try {
      final request = switch (method) {
        'POST' => _client.post(uri,
            headers: headers, body: body == null ? null : jsonEncode(body)),
        'PUT' => _client.put(uri,
            headers: headers, body: body == null ? null : jsonEncode(body)),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => _client.get(uri, headers: headers),
      };
      res = await request.timeout(timeout);
    } on TimeoutException {
      offline.value = true;
      throw ApiException('서버가 응답하지 않아요', path: path);
    } on Exception catch (e) {
      offline.value = true;
      throw ApiException(_offlineMessage(e), path: path);
    }

    // 상태 코드가 무엇이든 응답이 왔으면 연결은 살아 있다.
    offline.value = false;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.bodyBytes.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(res.bodyBytes));
      } on FormatException {
        throw ApiException('응답을 읽지 못했어요',
            statusCode: res.statusCode, path: path);
      }
    }

    throw ApiException(
      _serverMessage(res) ?? '요청에 실패했어요 (${res.statusCode})',
      statusCode: res.statusCode,
      path: path,
    );
  }

  /// NestJS 기본 예외 응답은 `{ statusCode, message, error }` 모양이다.
  /// `message`는 문자열이거나 문자열 배열이다.
  String? _serverMessage(http.Response res) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map) return null;
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) return message.first.toString();
    } on Exception {
      return null;
    }
    return null;
  }

  /// 인증서 만료는 앱을 통째로 먹통으로 만든다. 원인을 구분해 둔다.
  String _offlineMessage(Exception e) {
    final text = e.toString();
    if (text.contains('CERTIFICATE') || text.contains('HandshakeException')) {
      return '서버 인증서에 문제가 있어요';
    }
    return '서버에 연결하지 못했어요';
  }
}
