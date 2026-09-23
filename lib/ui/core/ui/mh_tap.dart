import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 탭에 걸 진동의 세기.
enum MhHaptic {
  /// 목록·탭·칩처럼 고르는 동작. 기본값이고 가장 가볍다.
  selection,

  /// 주요 버튼(다음·완료·투표)처럼 확정되는 동작.
  impact,

  /// 진동 없음. 스크롤 대용으로 쓰는 탭이나 반복 입력에 쓴다.
  none,
}

/// `GestureDetector`를 대신하는 탭 위젯. **탭에 진동을 붙인다.**
///
/// 앱의 모든 탭이 이걸 거치게 해서 한 곳에서 정책을 바꿀 수 있다.
/// `GestureDetector`를 직접 쓰면 진동이 빠지므로, 새 화면에서도 이걸 쓴다.
///
/// iOS는 설정 > 소리 및 햅틱의 "시스템 햅틱"이 꺼져 있으면 OS가 알아서
/// 무시한다. 앱에서 따로 막지 않는다.
class MhTap extends StatelessWidget {
  const MhTap({
    super.key,
    required this.child,
    this.onTap,
    this.behavior,
    this.haptic = MhHaptic.selection,
  });

  final Widget child;

  /// `null`이면 탭도 진동도 없다 (비활성 상태).
  final VoidCallback? onTap;

  final HitTestBehavior? behavior;

  final MhHaptic haptic;

  @override
  Widget build(BuildContext context) {
    final handler = onTap;
    return GestureDetector(
      behavior: behavior,
      onTap: handler == null
          ? null
          : () {
              switch (haptic) {
                case MhHaptic.selection:
                  HapticFeedback.selectionClick();
                case MhHaptic.impact:
                  HapticFeedback.lightImpact();
                case MhHaptic.none:
                  break;
              }
              handler();
            },
      child: child,
    );
  }
}
