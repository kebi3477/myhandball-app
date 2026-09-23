import 'package:flutter/material.dart';

import '../../../domain/models/player.dart';
import '../themes/theme.dart';
import '../themes/tokens.dart';
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
  });

  static const width = 97.0;
  static const cardHeight = 123.0;

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
                                style: MhText.custom(
                                  size: 44,
                                  weight: FontWeight.w800,
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
                        child: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
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
