import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/ads_service.dart';

@immutable
class AdsState {
  const AdsState({this.show = false, this.privacyOptions = false});

  /// 광고를 보여줄지 (디자인 핸드오프의 `showAds`).
  final bool show;

  /// 설정에 "광고 개인정보 옵션"을 보일지. 동의가 필요한 지역에서만 `true`.
  final bool privacyOptions;
}

/// 광고 SDK와 동의 상태.
///
/// SDK가 뜨고 동의가 끝나기 전까지는 [AdsState.show]가 `false`라 모든 슬롯이
/// 접혀 있다. 광고 제거 구독이 생기면 여기서 같이 내린다.
class AdsViewModel extends Notifier<AdsState> {
  @override
  AdsState build() => const AdsState();

  /// 셸에 들어온 뒤 한 번 부른다. 온보딩은 광고 금지 구역이라
  /// 동의 창도 그 뒤에 뜨게 한다.
  Future<void> start() async {
    final ads = ref.read(adsServiceProvider);
    if (ads == null) return;
    final show = await ads.start();
    state = AdsState(show: show, privacyOptions: ads.privacyOptionsRequired);
  }

  /// 동의 선택을 다시 고른다. 거부로 바꾸면 슬롯이 전부 접힌다.
  Future<void> openPrivacyOptions() async {
    final ads = ref.read(adsServiceProvider);
    if (ads == null) return;
    final show = await ads.showPrivacyOptions();
    state = AdsState(show: show, privacyOptions: ads.privacyOptionsRequired);
  }
}

final adsViewModelProvider =
    NotifierProvider<AdsViewModel, AdsState>(AdsViewModel.new);

/// 광고 슬롯이 보는 값.
final showAdsProvider =
    Provider<bool>((ref) => ref.watch(adsViewModelProvider).show);
