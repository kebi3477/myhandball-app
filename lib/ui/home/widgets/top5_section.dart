import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../domain/models/player_stat.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/home_view_model.dart';

/// 시즌 TOP5 — 카테고리 칩 + 선수 기록 리스트.
class Top5Section extends ConsumerWidget {
  const Top5Section({super.key, required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final vm = ref.read(homeViewModelProvider.notifier);
    final rows = state.topPlayers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('시즌 TOP5', style: MhText.sectionTitle(c.text)),
              Text('${state.gender.divisionLabel} · 25-26 정규리그',
                  style: MhText.caption(c.textNeutral)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final category in StatCategory.values) ...[
                if (category != StatCategory.values.first)
                  const SizedBox(width: MhSpacing.xs),
                _CategoryChip(
                  label: category.label,
                  selected: state.category == category,
                  onTap: () => vm.selectCategory(category),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  _PlayerRow(
                    player: rows[i],
                    unit: state.category.unit,
                    isLast: i == rows.length - 1,
                  ),
                // 시안 `top5Short` — 집계가 덜 된 경우.
                if (rows.length < AppConfig.topPlayerCount)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('나머지 순위는 기록 집계 중이에요',
                        textAlign: TextAlign.center,
                        style: MhText.meta(c.textSub)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: onTap,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? MhColors.brand : c.card,
          borderRadius: BorderRadius.circular(MhRadius.chip),
        ),
        child: Text(
          label,
          style: MhText.custom(
            size: 13,
            weight: FontWeight.w600,
            color: selected ? Colors.white : c.textSub,
          ),
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.unit,
    required this.isLast,
  });

  final PlayerStat player;
  final String unit;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: isLast ? Colors.transparent : c.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text('${player.rank}',
                style: MhText.custom(
                  size: 15,
                  weight: FontWeight.w800,
                  color: player.rank <= 3 ? MhColors.brand : c.textSub,
                )),
          ),
          const SizedBox(width: 12),
          TeamLogo(size: 36, logoUrl: player.logoUrl, inset: 0.78),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(player.name,
                          style: MhText.custom(
                              size: 14,
                              weight: FontWeight.w700,
                              color: c.text)),
                    ),
                    if (player.isEstimated) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('추정',
                            style: MhText.custom(
                                size: 9,
                                weight: FontWeight.w700,
                                color: c.textSub)),
                      ),
                    ],
                  ],
                ),
                Text('${player.teamName} · ${player.position}',
                    style: MhText.caption(c.textSub)),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              text: player.value,
              style: MhText.custom(
                  size: 16, weight: FontWeight.w800, color: c.text),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: MhText.custom(
                      size: 11, weight: FontWeight.w500, color: c.textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
