import 'package:flutter/material.dart';

import '../../../domain/models/game_detail.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/game_detail_view_model.dart';

/// 기록 탭 — 팀 비교 바 + 맞대결 기록.
class GameStatsTab extends StatelessWidget {
  const GameStatsTab({super.key, required this.state});

  final GameDetailState state;

  /// 시안은 원정팀 쪽 강조에 주황을 쓴다.
  static const _awayColor = Color(0xFFFF7A45);

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final game = state.game;
    final h2h = state.detail.headToHead;

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
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TeamLogo(size: 22, logoUrl: game.home.logoUrl, inset: 0.78),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(game.home.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MhText.custom(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: c.text)),
                          ),
                        ],
                      ),
                    ),
                    Text('팀 기록',
                        style: MhText.custom(
                            size: 12,
                            weight: FontWeight.w700,
                            color: c.textSub)),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(game.away.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MhText.custom(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: c.text)),
                          ),
                          const SizedBox(width: 6),
                          TeamLogo(size: 22, logoUrl: game.away.logoUrl, inset: 0.78),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final s in state.detail.stats) ...[
                  _StatBar(line: s),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('기록은 집계 방식에 따라 공식 기록과 다를 수 있어요',
              textAlign: TextAlign.center,
              style: MhText.custom(
                  size: 11, weight: FontWeight.w400, color: c.textFaint)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('맞대결 기록',
                        style: MhText.custom(
                            size: 15, weight: FontWeight.w700, color: c.text)),
                    Text('최근 3시즌 · ${h2h.total}경기',
                        style: MhText.custom(
                            size: 11,
                            weight: FontWeight.w400,
                            color: c.textFaint)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _H2hTile(
                      value: '${h2h.homeWins}',
                      label: '${game.home.name} 승',
                      color: MhColors.brand,
                    ),
                    _H2hTile(
                      value: '${h2h.draws}',
                      label: '무',
                      color: c.textSub,
                    ),
                    _H2hTile(
                      value: '${h2h.awayWins}',
                      label: '${game.away.name} 승',
                      color: _awayColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (h2h.ratio(h2h.homeWins) * 1000).round() + 1,
                          child: Container(color: MhColors.brand),
                        ),
                        Expanded(
                          flex: (h2h.ratio(h2h.draws) * 1000).round() + 1,
                          child: Container(color: MhColors.closed),
                        ),
                        Expanded(
                          flex: (h2h.ratio(h2h.awayWins) * 1000).round() + 1,
                          child: Container(color: _awayColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(h2h.avgHome.toStringAsFixed(1),
                        style: MhText.custom(
                            size: 12, weight: FontWeight.w800, color: c.text)),
                    Text('맞대결 평균 득점', style: MhText.meta(c.textSub)),
                    Text(h2h.avgAway.toStringAsFixed(1),
                        style: MhText.custom(
                            size: 12, weight: FontWeight.w800, color: c.text)),
                  ],
                ),
                const SizedBox(height: 4),
                for (final g in h2h.games)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.border)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 78,
                          child: Text('${g.season} · ${g.date}',
                              style: MhText.caption(c.textSub)),
                        ),
                        Expanded(
                          child: Text(g.score,
                              textAlign: TextAlign.center,
                              style: MhText.custom(
                                  size: 15,
                                  weight: FontWeight.w800,
                                  color: c.text)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: g.homeWon ? MhColors.brand : _awayColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(g.resultLabel,
                              style: MhText.custom(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 가운데 라벨을 두고 양쪽으로 뻗는 바.
class _StatBar extends StatelessWidget {
  const _StatBar({required this.line});

  final TeamStatLine line;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final homeLeads = line.home >= line.away;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(line.homeText,
                style: MhText.custom(
                  size: 13,
                  weight: FontWeight.w800,
                  color: homeLeads ? MhColors.brand : c.textSub,
                )),
            Text(line.label, style: MhText.meta(c.textSub)),
            Text(line.awayText,
                style: MhText.custom(
                  size: 13,
                  weight: FontWeight.w800,
                  color: homeLeads ? c.textSub : GameStatsTab._awayColor,
                )),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 6,
          child: Row(
            children: [
              Expanded(
                child: _HalfBar(
                  ratio: line.homeRatio,
                  color: MhColors.brand,
                  alignEnd: true,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _HalfBar(
                  ratio: line.awayRatio,
                  color: GameStatsTab._awayColor,
                  alignEnd: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HalfBar extends StatelessWidget {
  const _HalfBar({
    required this.ratio,
    required this.color,
    required this.alignEnd,
  });

  final double ratio;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        color: context.mh.border,
        child: FractionallySizedBox(
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          widthFactor: ratio.clamp(0.0, 1.0),
          child: Container(color: color),
        ),
      ),
    );
  }
}

class _H2hTile extends StatelessWidget {
  const _H2hTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: MhText.custom(
                  size: 26, weight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MhText.caption(context.mh.textSub)),
        ],
      ),
    );
  }
}
