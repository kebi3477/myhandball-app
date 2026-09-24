import 'package:flutter/material.dart';

import '../../../data/services/api_client.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';

/// MY 위쪽의 오류 띠. 시안 `hasError`.
///
/// **MY만 전체 오류 화면을 쓰지 않는다.** 마이팀·닉네임·직관 기록·배지는
/// 기기에 있어서 연결이 끊겨도 보여줄 수 있다. 화면을 통째로 지우면
/// 그것까지 못 보게 되고, 다시 시도할 방법도 없어진다.
class MyErrorBanner extends StatelessWidget {
  const MyErrorBanner({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  bool get _offline =>
      error is ApiException && (error as ApiException).isOffline;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(MhRadius.chip),
        ),
        child: Row(
          children: [
            MhIcon(
              _offline ? MhIcons.wifiOff : MhIcons.alert,
              size: 22,
              color: const Color(0xFFF5A524),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _offline ? '인터넷에 연결되어 있지 않아요' : '정보를 불러오지 못했어요',
                    style: MhText.custom(
                        size: 13, weight: FontWeight.w700, color: c.text),
                  ),
                  const SizedBox(height: 2),
                  Text('기기에 저장된 정보를 보여드리고 있어요',
                      style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w500,
                          color: c.textSub)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            MhTap(
              haptic: MhHaptic.impact,
              onTap: onRetry,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: MhColors.brand,
                  borderRadius: BorderRadius.circular(MhRadius.chip),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text('다시 시도',
                      style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
