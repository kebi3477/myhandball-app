import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/game_detail.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/game_detail_view_model.dart';

/// 예측 탭 — 3지선다 + 결과.
class GamePredictTab extends ConsumerWidget {
  const GamePredictTab({super.key, required this.state});

  final GameDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final vm = ref.read(gameDetailViewModelProvider(state.game).notifier);
    final open = state.predictionOpen;
    final tally = state.tally;
    final hit = state.predictionHit;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, MhSpacing.sm, MhSpacing.gutter, MhSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('누가 이길까요?',
                        style: MhText.custom(
                            size: 15, weight: FontWeight.w700, color: c.text)),
                    Text(
                      open ? '투표 진행 중' : '투표 마감',
                      style: MhText.custom(
                        size: 11,
                        weight: FontWeight.w700,
                        color: open ? MhColors.brand : c.textFaint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final pick in PredictionPick.values) ...[
                      if (pick != PredictionPick.values.first)
                        const SizedBox(width: MhSpacing.xs),
                      Expanded(
                        child: _Option(
                          pick: pick,
                          state: state,
                          enabled: open,
                          onTap: () => vm.pick(pick),
                        ),
                      ),
                    ],
                  ],
                ),
                // 서버 집계가 생기기 전에는 그릴 수 없던 시안의 분포 막대.
                if (tally.total > 0) ...[
                  const SizedBox(height: 14),
                  _Distribution(tally: tally),
                ],
              ],
            ),
          ),
          if (hit != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(MhRadius.chip),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hit ? MhColors.brand : MhColors.closed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(hit ? '적중' : '아쉽',
                        style: MhText.custom(
                            size: 13,
                            weight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hit ? '예측이 맞았어요!' : '이번엔 빗나갔어요',
                      style: MhText.custom(
                          size: 13, weight: FontWeight.w400, color: c.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text('예측은 경기 시작 전까지 바꿀 수 있어요 · 결과는 MY에 쌓여요',
              textAlign: TextAlign.center,
              style: MhText.custom(
                  size: 11, weight: FontWeight.w400, color: c.textFaint)),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.pick,
    required this.state,
    required this.enabled,
    required this.onTap,
  });

  final PredictionPick pick;
  final GameDetailState state;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final game = state.game;
    final selected = state.prediction == pick;

    final (label, logo) = switch (pick) {
      PredictionPick.home => (game.home.name, game.home.logoUrl),
      PredictionPick.away => (game.away.name, game.away.logoUrl),
      PredictionPick.draw => ('무승부', null),
    };

    return Opacity(
      opacity: enabled || selected ? 1 : 0.5,
      child: MhTap(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 92,
          decoration: BoxDecoration(
            color: selected
                ? MhColors.brand.withValues(alpha: 0.12)
                : Colors.transparent,
            border: Border.all(
              color: selected ? MhColors.brand : c.border,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (pick == PredictionPick.draw)
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(color: c.bg, shape: BoxShape.circle),
                  child: Text('=',
                      style: MhText.custom(
                          size: 14,
                          weight: FontWeight.w800,
                          color: c.textSub)),
                )
              else
                TeamLogo(size: 32, logoUrl: logo, inset: 0.78),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MhText.custom(
                      size: 12, weight: FontWeight.w700, color: c.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 예측 분포. `GET /api/game/:matchSeq/prediction`의 집계를 그린다.
class _Distribution extends StatelessWidget {
  const _Distribution({required this.tally});

  final PredictionTally tally;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (final pick in PredictionPick.values)
                  if (tally.votesFor(pick) > 0)
                    Expanded(
                      flex: tally.votesFor(pick),
                      child: ColoredBox(
                        color: switch (pick) {
                          PredictionPick.home => MhColors.brand,
                          PredictionPick.draw => c.textFaint,
                          PredictionPick.away =>
                            MhColors.brand.withValues(alpha: 0.45),
                        },
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final pick in PredictionPick.values)
              Text(
                '${pick.label} ${tally.percentFor(pick)}%',
                style: MhText.custom(
                  size: 11,
                  weight:
                      tally.myPick == pick ? FontWeight.w800 : FontWeight.w400,
                  color: tally.myPick == pick ? MhColors.brand : c.textFaint,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text('${tally.total}명이 예측했어요',
            textAlign: TextAlign.center,
            style: MhText.custom(
                size: 11, weight: FontWeight.w400, color: c.textFaint)),
      ],
    );
  }
}
