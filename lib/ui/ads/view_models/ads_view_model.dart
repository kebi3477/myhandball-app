import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/ads_service.dart';

/// 광고를 보여줄지 (디자인 핸드오프의 `showAds`).
///
/// SDK가 뜨고 동의가 끝나기 전까지는 `false`라 모든 슬롯이 접혀 있다.
/// 광고 제거 구독이 생기면 여기서 같이 내린다.
class AdsViewModel extends Notifier<bool> {
  @override
  bool build() => false;

  /// 셸에 들어온 뒤 한 번 부른다. 온보딩은 광고 금지 구역이라
  /// 동의 창도 그 뒤에 뜨게 한다.
  Future<void> start() async {
    final ads = ref.read(adsServiceProvider);
    if (ads == null) return;
    state = await ads.start();
  }
}

final showAdsProvider =
    NotifierProvider<AdsViewModel, bool>(AdsViewModel.new);
