import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../data/services/ads_service.dart';
import '../../core/themes/theme.dart';
import '../view_models/ads_view_model.dart';

/// 네이티브 광고 한 자리 (디자인 핸드오프 "네이티브 광고").
///
/// 카드 모양은 **네이티브 쪽이 그린다** — AdMob 정책상 광고 에셋은
/// SDK의 `NativeAdView` 안에 있어야 해서 Flutter 위젯으로 그릴 수 없다.
/// 여기서는 그 뷰가 들어갈 높이만 정한다. 높이 계산은 네이티브 레이아웃의
/// 고정값과 맞물려 있으니 한쪽을 고치면 같이 고친다.
///
/// - 광고를 끈 상태이거나 불러오지 못하면 [padding]까지 통째로 접는다
///   (빈 카드 금지).
/// - 화면에 들어올 때 불러오고, 60초 넘게 보인 뒤 새 광고로 바꾼다.
///   보이지 않는 탭(IndexedStack)에 있으면 돌아왔을 때 바꾼다.
class NativeAdSlot extends ConsumerStatefulWidget {
  const NativeAdSlot(this.slot, {super.key, this.padding = EdgeInsets.zero});

  final AdSlot slot;

  /// 광고가 있을 때만 두는 바깥 여백.
  final EdgeInsets padding;

  @override
  ConsumerState<NativeAdSlot> createState() => _NativeAdSlotState();
}

class _NativeAdSlotState extends ConsumerState<NativeAdSlot> {
  static const _refreshAfter = Duration(seconds: 60);

  NativeAd? _shown;
  NativeAd? _loading;
  Timer? _refresh;
  bool _failed = false;
  bool _stale = false;
  bool _visible = true;
  bool? _dark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 카드 색은 광고를 만들 때 넘기므로 테마가 바뀌면 새로 받는다.
    final dark = context.mh.isDark;
    if (_dark != null && _dark != dark) _clear();
    _dark = dark;

    _visible = TickerMode.valuesOf(context).enabled;
    if (_stale && _visible) {
      _stale = false;
      _load();
    }
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  void _clear() {
    _refresh?.cancel();
    _shown?.dispose();
    _loading?.dispose();
    _refresh = null;
    _shown = null;
    _loading = null;
    _failed = false;
  }

  void _load() {
    final unitId = widget.slot.unitId;
    if (unitId == null || _loading != null) return;

    late final NativeAd ad;
    ad = NativeAd(
      adUnitId: unitId,
      factoryId: widget.slot.factoryId,
      customOptions: {'dark': _dark ?? false},
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
      ),
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted || _loading != ad) {
            ad.dispose();
            return;
          }
          final previous = _shown;
          setState(() {
            _shown = ad;
            _loading = null;
          });
          previous?.dispose();
          _refresh?.cancel();
          _refresh = Timer(_refreshAfter, _onRefreshDue);
        },
        onAdFailedToLoad: (_, _) {
          ad.dispose();
          if (!mounted || _loading != ad) return;
          // 이미 보이던 광고가 있으면 그대로 두고, 없으면 자리를 접는다.
          setState(() {
            _loading = null;
            _failed = _shown == null;
          });
        },
      ),
    );
    _loading = ad;
    ad.load();
  }

  void _onRefreshDue() {
    if (!mounted) return;
    if (_visible) {
      _load();
    } else {
      _stale = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final show = ref.watch(showAdsProvider);
    ref.listen(showAdsProvider, (_, next) {
      if (!next) setState(_clear);
    });

    if (show && _shown == null && _loading == null && !_failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shown == null && _loading == null) _load();
      });
    }

    final ad = _shown;
    if (!show || ad == null) return const SizedBox.shrink();

    return Padding(
      padding: widget.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.slot.radius),
            child: SizedBox(
              width: width,
              height: widget.slot.heightFor(width),
              child: AdWidget(ad: ad),
            ),
          );
        },
      ),
    );
  }
}

/// 슬롯별 카드 치수. 네이티브 레이아웃(`MhNativeAdFactories`)과 같은 값이다.
extension on AdSlot {
  double get radius => this == AdSlot.cheerBoard ? 16 : 20;

  /// 카드 폭 [width]에서의 높이. 좌우 패딩 16씩 빼고 미디어 비율을 적용한다.
  double heightFor(double width) {
    final inner = width - 32;
    return switch (this) {
      // 14 + 아이콘 40 + 12 + 미디어 16:9 + 12 + CTA 36 + 16
      AdSlot.homeFeed => 130 + inner * 9 / 16,
      // 14 + 아이콘 44 + 14
      AdSlot.scheduleList => 72,
      // 14 + 28 + 10 + 본문 2줄 44 + 10 + 미디어 2:1 + 10 + CTA 40 + 14
      AdSlot.cheerBoard => 170 + inner / 2,
    };
  }
}
