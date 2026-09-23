import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// 마이팀 경기 푸시.
///
/// **"내 팀만"은 서버가 처리한다.** 등록할 때 넘긴 `teamNum`이 뛰는 경기에만
/// 알림이 나간다 (`myhandball-api`의 `PushService.recipients`가
/// `teamNum: In([홈, 원정])`으로 대상을 고른다). 그래서 앱이 할 일은
/// **마이팀 번호를 정확히 등록하고, 바뀌면 다시 등록하는 것**뿐이다.
///
/// 받는 알림은 세 가지다 — 경기 시작 10분 전, 득점(120초로 묶임), 경기 종료.
///
/// ### Firebase 설정이 없으면 조용히 꺼진다
///
/// `GoogleService-Info.plist` / `google-services.json`이 없으면
/// [Firebase.initializeApp]이 실패한다. 그때는 [available]이 `false`가 되고
/// 모든 호출이 아무 일도 하지 않는다 — **푸시 때문에 앱이 안 뜨면 안 된다.**
class PushService {
  PushService(this._client);

  final ApiClient _client;

  bool _available = false;
  bool _initialized = false;

  /// Firebase가 붙었고 토큰을 받을 수 있는 상태인지.
  bool get available => _available;

  /// 알림을 눌렀을 때 열 경기. 서버 payload의 `data.matchSeq`.
  ///
  /// 앱이 완전히 꺼진 상태에서 눌러 실행된 경우도 여기로 들어온다.
  final ValueNotifier<int?> tappedMatchSeq = ValueNotifier(null);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      _available = true;
    } on Exception catch (e) {
      // 설정 파일이 없거나 프로젝트가 아직 없을 때. 앱은 그대로 뜬다.
      if (kDebugMode) {
        debugPrint('[MyHandball] 푸시 꺼짐 — Firebase 설정이 없습니다: $e');
      }
      return;
    }

    final messaging = FirebaseMessaging.instance;

    // iOS는 앱이 떠 있을 때 기본으로 배너를 안 띄운다.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 알림을 눌러 앱이 열린 경우 — 꺼져 있었을 때와 떠 있었을 때 둘 다.
    final initial = await messaging.getInitialMessage();
    if (initial != null) _remember(initial);
    FirebaseMessaging.onMessageOpenedApp.listen(_remember);

    // 토큰은 갱신될 수 있다. 바뀌면 서버에 다시 알린다.
    messaging.onTokenRefresh.listen((token) => _register(token, _last));
  }

  void _remember(RemoteMessage message) {
    final seq = int.tryParse('${message.data['matchSeq']}');
    if (seq != null) tappedMatchSeq.value = seq;
  }

  /// 마지막으로 등록한 구독 내용. 토큰 갱신 때 다시 쓴다.
  ({int teamNum, String gender})? _last;

  /// 구독 상태를 서버와 맞춘다.
  ///
  /// 마이팀이 없거나 알림을 껐으면 **구독을 해제**한다. 알림을 끈 채로
  /// 토큰이 서버에 남아 있으면 계속 알림이 간다.
  Future<void> sync({
    required bool notificationsOn,
    required int? teamNum,
    required String gender,
  }) async {
    if (!_available) return;

    if (!notificationsOn || teamNum == null) {
      _last = null;
      await _unregister();
      return;
    }

    final granted = await _requestPermission();
    if (!granted) {
      // 시스템 설정에서 거부한 상태. 토큰을 받아도 알림이 안 뜨므로
      // 서버에도 남기지 않는다.
      _last = null;
      await _unregister();
      return;
    }

    final String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[MyHandball] FCM 토큰 실패: $e');
      return;
    }
    if (token == null || token.isEmpty) return;

    _last = (teamNum: teamNum, gender: gender);
    await _register(token, _last);
  }

  Future<bool> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _register(String token, ({int teamNum, String gender})? sub) async {
    if (sub == null) return;
    try {
      await _client.post('/push/register', body: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'teamNum': sub.teamNum,
        'gender': sub.gender,
      });
    } on ApiException catch (e) {
      // 알림이 안 오는 것뿐이라 화면을 막지 않는다.
      if (kDebugMode) debugPrint('[MyHandball] 푸시 등록 실패: ${e.message}');
    }
  }

  Future<void> _unregister() async {
    try {
      await _client.delete('/push/register');
    } on ApiException {
      // 등록된 적이 없어도 서버가 성공으로 본다. 실패해도 할 일이 없다.
    }
  }
}
