import 'package:flutter/material.dart';

import '../../../domain/models/player.dart';
import '../themes/theme.dart';
import '../themes/tokens.dart';
import 'mh_icons.dart';
import 'mh_tap.dart';

/// 97x123 선수 카드. 분석 > 선수 탭과 팀 상세 > 선수 탭이 함께 쓴다.
///
/// 팀명 / 등번호(44px 브랜드 블루) / 포지션 + 우상단 하트, 아래 이름·기록.
class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.player,
    required this.favorite,
    required this.onToggleFavorite,
    this.onTap,
    this.width = width375,
  });

  /// 시안 기준 폭. 375 화면에서 `97×3 + 18×2 = 327`로 거터에 딱 맞는다.
  /// 더 넓은 화면에서는 [width]를 늘려 3열이 폭을 채우게 한다.
  static const width375 = 97.0;
  static const cardHeight = 123.0;

  /// 시안 카드 사이 간격.
  static const gap = 18.0;

  /// 주어진 폭에서 3열로 놓을 때의 카드 폭.
  static double widthFor(double available) => (available - gap * 2) / 3;

  final double width;

  final Player player;
  final bool favorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          MhTap(
            onTap: onTap,
            child: Container(
              width: width,
              height: cardHeight,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(MhRadius.card),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: Text(
                          player.teamName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MhText.custom(
                              size: 10,
                              weight: FontWeight.w600,
                              color: c.textSub),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                player.numberText,
                                // 시안 Impact 44px / line-height 0.9
                                style: mhDisplay(
                                  size: 44,
                                  color: MhColors.brand,
                                  height: 0.9,
                                ),
                              ),
                            ),
                          ),
                          Text(player.positionText,
                              style: MhText.custom(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: c.textSub)),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: MhTap(
                      behavior: HitTestBehavior.opaque,
                      onTap: onToggleFavorite,
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: MhIcon(
                          favorite ? MhIcons.heartFilled : MhIcons.heart,
                          size: 18,
                          color: favorite
                              ? const Color(0xFFFF4D6A)
                              : c.textFaint,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MhSpacing.xs),
          Text(player.name,
              style: MhText.custom(
                  size: 16, weight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text(player.statLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MhText.custom(
                  size: 11, weight: FontWeight.w400, color: c.textMuted)),
        ],
      ),
    );
  }
}
