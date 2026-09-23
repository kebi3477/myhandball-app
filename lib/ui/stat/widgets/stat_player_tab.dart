import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/player.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../view_models/stat_view_model.dart';

/// 분석 — 선수 탭. 선수 비교 진입 카드 + 선수 카드 그리드.
class StatPlayerTab extends ConsumerWidget {
  const StatPlayerTab({super.key, required this.state});

  final StatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(statViewModelProvider.notifier);
    final players = state.sortedPlayers;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, MhSpacing.xs, MhSpacing.gutter, MhSpacing.xl),
      children: [
        const _CompareEntry(),
        const SizedBox(height: MhSpacing.sm),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (final p in players)
              _PlayerCard(
                player: p,
                favorite: state.favoritePlayerIds.contains(p.id),
                onToggleFavorite: () => vm.toggleFavorite(p.id),
              ),
          ],
        ),
      ],
    );
  }
}

/// 시안의 "선수 비교" 진입 카드.
class _CompareEntry extends StatelessWidget {
  const _CompareEntry();

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return GestureDetector(
      onTap: () {}, // TODO: 선수 비교 화면 (시안 PLAYER COMPARE 섹션)
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(MhRadius.chip),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MhColors.brand.withValues(alpha: 0.14),
              ),
              child: const Icon(Icons.compare_arrows_rounded,
                  size: 18, color: MhColors.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('선수 비교',
                      style: MhText.custom(
                          size: 14, weight: FontWeight.w700, color: c.text)),
                  const SizedBox(height: 2),
                  Text('두 선수의 시즌 기록을 한눈에 비교해요',
                      style: MhText.meta(c.textSub)),
                ],
              ),
            ),
            Text('›',
                style: MhText.custom(
                    size: 18, weight: FontWeight.w400, color: c.textFaint)),
          ],
        ),
      ),
    );
  }
}

/// 97x123 선수 카드 — 팀명 / 등번호 / 포지션 + 하트, 아래 이름·기록.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.favorite,
    required this.onToggleFavorite,
  });

  final Player player;
  final bool favorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return SizedBox(
      width: 97,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {}, // TODO: 선수 상세 (시안 PLAYER SUMMARY 섹션)
            child: Container(
              width: 97,
              height: 123,
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
                                '${player.number}',
                                style: MhText.custom(
                                  size: 44,
                                  weight: FontWeight.w800,
                                  color: MhColors.brand,
                                  height: 0.9,
                                ),
                              ),
                            ),
                          ),
                          Text(player.position,
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
                    child: GestureDetector(
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
                          color: favorite ? MhColors.live : c.textFaint,
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
