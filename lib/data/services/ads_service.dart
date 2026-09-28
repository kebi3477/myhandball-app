import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/app_config.dart';

/// 네이티브 광고 자리. 디자인 핸드오프의 슬롯 3개와 1:1이다.
///
/// [factoryId]는 네이티브 쪽에 등록한 레이아웃 이름이다 —
/// Android `MhNativeAdFactories.kt`, iOS `MhNativeAdFactories.swift`.
enum AdSlot {
  /// 홈 — 규칙 가이드 카드 아래 미디어형.
  homeFeed(
    'mh_feed_media',
    AppConfig.adUnitHome,
    android: 'ca-app-pub-6280185901199691/4222848781',
    ios: 'ca-app-pub-6280185901199691/7044453241',
  ),

  /// 일정 목록 — 경기 카드 사이 소형.
  scheduleList(
    'mh_list_small',
    AppConfig.adUnitSchedule,
    android: 'ca-app-pub-6280185901199691/3970733197',
    ios: 'ca-app-pub-6280185901199691/8281513298',
  ),

  /// 응원 게시판 — 응원글 사이 게시글형.
  cheerBoard(
    'mh_cheer_post',
    AppConfig.adUnitCheer,
    android: 'ca-app-pub-6280185901199691/5359661477',
    ios: 'ca-app-pub-6280185901199691/6968431626',
  );

  const AdSlot(
    this.factoryId,
    this._configuredUnitId, {
    required this.android,
    required this.ios,
  });

  final String factoryId;
  final String _configuredUnitId;

  /// AdMob 콘솔에서 만든 실제 광고 단위 (2026-09-28).
  final String android;
  final String ios;

  /// 구글이 공개한 네이티브 고급형 테스트 ID.
  static const _testAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const _testIos = 'ca-app-pub-3940256099942544/3986624511';

  /// 요청할 광고 단위 ID.
  ///
  /// 릴리스는 실제 광고, 디버그·프로파일은 **테스트 광고**다 — 개발 중에
  /// 실제 광고를 보고 누르면 무효 트래픽으로 계정이 정지될 수 있다.
  /// dart-define(`MH_AD_*`)을 주면 그 값이 이긴다.
  ///
  /// 예전에는 릴리스에 dart-define이 없으면 슬롯을 껐는데, 빌드 명령에서
  /// 빠뜨려 광고 없는 빌드가 나왔다. 잊기 쉬운 쪽이 망가지지 않게 뒤집었다.
  String get unitId {
    if (_configuredUnitId.isNotEmpty) return _configuredUnitId;
    if (kReleaseMode) return Platform.isIOS ? ios : android;
    return Platform.isIOS ? _testIos : _testAndroid;
  }
}

/// AdMob SDK 시작 — 동의(UMP)를 받고 SDK를 초기화한다.
///
/// **광고 때문에 앱이 멈추면 안 된다.** 어디서 실패하든 `false`를 돌려
/// 광고 슬롯이 전부 접힌 채로 앱은 그대로 쓴다.
///
/// iOS의 ATT(추적 허용) 창은 앱이 직접 띄우지 않는다. AdMob 콘솔의
/// "개인정보 보호 및 메시지"에서 IDFA 안내 메시지를 켜 두면 UMP가 동의
/// 창 다음에 띄운다 (Info.plist `NSUserTrackingUsageDescription` 필요).
class AdsService {
  bool? _started;

  /// 광고를 요청해도 되면 `true`.
  Future<bool> start() async {
    if (_started != null) return _started!;
    try {
      await _requestConsent();
      final canRequest = await ConsentInformation.instance.canRequestAds();
      if (canRequest) await MobileAds.instance.initialize();
      return _started = canRequest;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[MyHandball] 광고 꺼짐 — $e');
      return _started = false;
    }
  }

  /// 동의가 필요한 지역(EEA 등)이면 동의 창을 띄운다. 한국은 보통 바로 넘어간다.
  Future<void> _requestConsent() async {
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      updated.complete,
      (error) => updated.completeError(Exception(error.message)),
    );
    await updated.future;
    await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
  }
}

/// 광고 SDK. 모바일이 아니거나(테스트·데스크톱) 광고를 끈 빌드면 없다.
final adsServiceProvider = Provider<AdsService?>((ref) {
  if (!AppConfig.adsEnabled || kIsWeb) return null;
  if (!Platform.isAndroid && !Platform.isIOS) return null;
  return AdsService();
});
