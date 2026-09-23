import 'package:flutter/material.dart';

import '../../../domain/models/game.dart';
import '../../../domain/models/team.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/team_logo.dart';

/// 홈 상단 "가까운 경기" 카드 한 장.
class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.game, this.onTap});

  /// 카드 실측 높이: 패딩 32 + 칩 22 + 20 + (로고 64 + 8 + 이름 2줄 40)
  /// + 20 + 구분선 12 + 버튼 32
  static const height = 256.0;

  final Game game;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final chipBg = switch (game.status) {
      GameStatus.live => MhColors.live,
      GameStatus.pre => MhColors.brand,
      GameStatus.finished => MhColors.closed,
    };
    final scoreColor = game.hasScore ? c.text : c.textFaint;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(MhSpacing.sm),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(game.status.chipLabel,
                      style: MhText.chip(Colors.white)),
                ),
                Text(game.meta, style: MhText.meta(c.textSub)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _CardTeam(team: game.home)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    height: 64,
                    child: Center(
                      child: Text(
                        '${game.scoreHomeText} : ${game.scoreAwayText}',
                        style: MhText.score(scoreColor),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _CardTeam(team: game.away)),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('중계 ${game.broadcastText}',
                        style: MhText.caption(c.textSub),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: MhSpacing.xs),
                  _OutlineButton(label: game.watchLabel),
                  if (game.canBook) ...[
                    const SizedBox(width: MhSpacing.xs),
                    const _FilledButton(label: '예매하기'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTeam extends StatelessWidget {
  const _CardTeam({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Column(
      children: [
        TeamLogo(size: 64, logoUrl: team.logoUrl),
        const SizedBox(height: MhSpacing.xs),
        // 팀 이름 길이에 따라 카드 높이가 흔들리지 않도록 2줄 높이로 고정한다.
        SizedBox(
          height: 40,
          child: Text(
            team.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: MhText.teamName(c.text),
          ),
        ),
      ],
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(MhRadius.chip),
      ),
      child: Text(label,
          style:
              MhText.custom(size: 12, weight: FontWeight.w700, color: c.text)),
    );
  }
}

class _FilledButton extends StatelessWidget {
  const _FilledButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: MhColors.brand,
        borderRadius: BorderRadius.circular(MhRadius.chip),
      ),
      child: Text(label,
          style: MhText.custom(
              size: 12, weight: FontWeight.w700, color: Colors.white)),
    );
  }
}
