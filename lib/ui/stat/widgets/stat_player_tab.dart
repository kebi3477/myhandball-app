import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/player.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/player_card.dart';
import '../../player_compare/widgets/player_compare_screen.dart';
import '../../player_detail/widgets/player_detail_sheet.dart';
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
        _CompareEntry(candidates: players),
        const SizedBox(height: MhSpacing.sm),
        // 시안은 375에서 3열이 거터에 딱 맞게 짜여 있다. 카드 폭을 고정하면
        // 더 넓은 화면에서 오른쪽에 여백이 남아 위 "선수 비교" 카드와
        // 오른쪽 끝이 어긋난다. 폭을 나눠 always 3열이 꽉 차게 한다.
        LayoutBuilder(builder: (context, constraints) {
          final cardWidth = PlayerCard.widthFor(constraints.maxWidth);
          return Wrap(
            spacing: PlayerCard.gap,
            runSpacing: PlayerCard.gap,
            children: [
              for (final p in players)
                PlayerCard(
                  player: p,
                  width: cardWidth,
                  favorite: state.favoritePlayerIds.contains(p.id),
                  onToggleFavorite: () => vm.toggleFavorite(p.id),
                  onTap: () => showPlayerDetailSheet(context, p),
                ),
            ],
          );
        }),
      ],
    );
  }
}

/// 시안의 "선수 비교" 진입 카드.
class _CompareEntry extends StatelessWidget {
  const _CompareEntry({required this.candidates});

  final List<Player> candidates;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: () => PlayerCompareScreen.open(context, candidates),
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
              child: const MhIcon(MhIcons.shield,
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
