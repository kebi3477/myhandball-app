import 'package:flutter/material.dart';

import '../../../domain/models/game.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/game_detail_view_model.dart';

/// 경기 상세 상단 스코어 카드 — 칩 + 양 팀 + 스코어 + 전·후반 표.
class GameDetailHeader extends StatelessWidget {
  const GameDetailHeader({super.key, required this.state});

  final GameDetailState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final game = state.game;
    final detail = state.detail;
    final chipBg = switch (game.status) {
      GameStatus.live => MhColors.live,
      GameStatus.pre => MhColors.brand,
      GameStatus.finished => MhColors.closed,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 4, MhSpacing.gutter, MhSpacing.sm),
      child: Container(
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
                Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      if (game.status == GameStatus.live) ...[
                        const _LivePulse(),
                        const SizedBox(width: 5),
                      ],
                      Text(game.status.chipLabel,
                          style: MhText.custom(
                              size: 11,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
                ),
                Text(game.meta, style: MhText.meta(c.textSub)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _Side(name: game.home.name, logo: game.home.logoUrl)),
                SizedBox(
                  width: 110,
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          game.hasScore
                              ? '${game.scoreHomeText} : ${game.scoreAwayText}'
                              : game.meta,
                          style: MhText.score(c.text, size: 44),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        game.venue ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MhText.custom(
                            size: 12,
                            weight: FontWeight.w700,
                            color: c.textSub),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _Side(name: game.away.name, logo: game.away.logoUrl)),
              ],
            ),
            if (game.hasScore) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Column(
                  children: [
                    _HalfRow(
                      label: '',
                      first: '전반',
                      second: '후반',
                      muted: true,
                    ),
                    const SizedBox(height: 6),
                    _HalfRow(
                      label: game.home.name,
                      first: '${detail.firstHalfHome}',
                      second: '${detail.secondHalfHome}',
                    ),
                    const SizedBox(height: 6),
                    _HalfRow(
                      label: game.away.name,
                      first: '${detail.firstHalfAway}',
                      second: '${detail.secondHalfAway}',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.name, required this.logo});

  final String name;
  final String? logo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamLogo(size: 60, logoUrl: logo, inset: 0.78),
        const SizedBox(height: MhSpacing.xs),
        Text(name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: MhText.custom(
                size: 14, weight: FontWeight.w700, color: context.mh.text)),
      ],
    );
  }
}

class _HalfRow extends StatelessWidget {
  const _HalfRow({
    required this.label,
    required this.first,
    required this.second,
    this.muted = false,
  });

  final String label;
  final String first;
  final String second;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final style = MhText.custom(
      size: 12,
      weight: muted ? FontWeight.w400 : FontWeight.w700,
      color: muted ? c.textSub : c.text,
    );
    return Row(
      children: [
        Expanded(
          child: Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
        SizedBox(
            width: 34,
            child: Text(first, textAlign: TextAlign.center, style: style)),
        const SizedBox(width: 16),
        SizedBox(
            width: 34,
            child: Text(second, textAlign: TextAlign.center, style: style)),
      ],
    );
  }
}

/// LIVE 칩의 깜빡이는 점 (시안 `skPulse`).
class _LivePulse extends StatefulWidget {
  const _LivePulse();

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1).animate(_c),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
