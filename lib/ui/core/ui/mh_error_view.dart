import 'package:flutter/material.dart';

import '../../../data/services/api_client.dart';
import '../themes/theme.dart';
import '../themes/tokens.dart';
import 'mh_icons.dart';
import 'mh_tap.dart';

/// 시안의 오류 화면. 홈·일정·분석이 같은 모양을 쓴다.
///
/// 시안은 데모 상태를 **오프라인 / 서버 오류** 둘로 나눠 두었다. 원인에 따라
/// 사용자가 할 수 있는 일이 다르기 때문이다 — 하나는 연결을 확인하면 되고,
/// 다른 하나는 기다리는 수밖에 없다.
class MhErrorView extends StatelessWidget {
  const MhErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.offlineDescription,
  });

  final Object error;
  final VoidCallback? onRetry;

  /// 오프라인일 때 설명을 갈아끼운다.
  ///
  /// 경기 상세처럼 **무엇을 못 보는지가 분명한 화면**은 시안이 그걸 적어
  /// 준다 — "문자중계·기록·예측·MVP 투표는 연결이 복구되면 다시 볼 수 있어요."
  final String? offlineDescription;

  bool get _offline => error is ApiException && (error as ApiException).isOffline;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;

    final (icon, title, description) = _offline
        ? (
            MhIcons.wifiOff,
            '연결할 수 없어요',
            offlineDescription ?? '인터넷 연결을 확인하고\n다시 시도해 주세요',
          )
        : (
            MhIcons.alert,
            '잠시 문제가 생겼어요',
            '${_message(error)}\n잠시 뒤에 다시 시도해 주세요',
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(MhSpacing.gutter, 40, MhSpacing.gutter, 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.card, shape: BoxShape.circle),
            child: MhIcon(icon, size: 32, color: c.textSub),
          ),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: MhText.custom(
                  size: 17, weight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 14),
          Text(
            description,
            textAlign: TextAlign.center,
            style: MhText.custom(
                size: 13, weight: FontWeight.w400, color: c.textSub, height: 1.6),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            MhTap(
              haptic: MhHaptic.impact,
              onTap: onRetry,
              // alignment를 주면 Container가 제약만큼 넓어져 버튼이 한 줄을
              // 다 차지한다. 시안은 글자 폭에 맞는 알약이다.
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  color: MhColors.brand,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text('다시 시도',
                      style: MhText.custom(
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 서버가 준 이유가 있으면 보여준다. 예외 원문은 내보내지 않는다.
  static String _message(Object error) =>
      error is ApiException ? error.message : '알 수 없는 오류예요';
}
