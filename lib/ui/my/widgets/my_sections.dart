import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/game.dart';
import '../../../domain/models/player.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../../player_detail/widgets/player_detail_sheet.dart';
import '../../shell/view_models/shell_view_model.dart';
import '../../stat/view_models/stat_view_model.dart';

/// 관심 선수 — 분석 > 선수에서 하트를 누른 선수들.
class FavoritePlayersSection extends ConsumerWidget {
  const FavoritePlayersSection({
    super.key,
    required this.players,
    required this.onRemove,
  });

  final List<Player> players;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('관심 선수', style: MhText.sectionTitle(c.text)),
              MhTap(
                onTap: () {
                  ref.read(shellViewModelProvider.notifier).select(ShellTab.stat);
                  ref
                      .read(statViewModelProvider.notifier)
                      .selectTab(StatTab.player);
                },
                child: Text('선수 찾기 >', style: MhText.meta(c.textFaint)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (players.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(MhRadius.card),
              ),
              child: Column(
                children: [
                  Text('아직 관심 선수가 없어요',
                      style: MhText.custom(
                          size: 14, weight: FontWeight.w600, color: c.text)),
                  const SizedBox(height: 4),
                  Text('분석 > 선수에서 ♡를 눌러 추가해 보세요',
                      style: MhText.meta(c.textSub)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(MhRadius.card),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < players.length; i++)
                    _FavoriteRow(
                      player: players[i],
                      isLast: i == players.length - 1,
                      onRemove: () => onRemove(players[i].id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({
    required this.player,
    required this.isLast,
    required this.onRemove,
  });

  final Player player;
  final bool isLast;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: () => showPlayerDetailSheet(context, player),
      child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: isLast ? Colors.transparent : c.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          TeamLogo(size: 36, logoUrl: player.teamLogoUrl, inset: 0.78),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    style: MhText.custom(
                        size: 15, weight: FontWeight.w600, color: c.text)),
                Text('${player.teamName} · ${player.positionFull}',
                    style: MhText.caption(c.textSub)),
              ],
            ),
          ),
          Text(player.statLine,
              style: MhText.custom(
                  size: 13, weight: FontWeight.w700, color: c.text)),
          MhTap(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.favorite_rounded,
                  size: 18, color: Color(0xFFFF4D6A)),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 시즌 기록 — 4열 8칸. `/api/ranking`이 주는 값 그대로다.
class SeasonStatsSection extends StatelessWidget {
  const SeasonStatsSection({super.key, required this.stats});

  final List<(String, String, bool)> stats;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('시즌 기록', style: MhText.sectionTitle(c.text)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: Wrap(
              runSpacing: 16,
              children: [
                for (final (label, value, highlight) in stats)
                  SizedBox(
                    width: (MediaQuery.sizeOf(context).width -
                            MhSpacing.gutter * 2 -
                            16) /
                        4,
                    child: Column(
                      children: [
                        Text(value,
                            style: MhText.custom(
                              size: 20,
                              weight: FontWeight.w700,
                              color: highlight ? MhColors.brand : c.text,
                            )),
                        const SizedBox(height: 2),
                        Text(label,
                            style: MhText.custom(
                                size: 11,
                                weight: FontWeight.w400,
                                color: c.textSub)),
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

/// 최근 5경기 — 승/패 배지 + vs 상대 + 스코어.
class RecentGamesSection extends StatelessWidget {
  const RecentGamesSection({
    super.key,
    required this.games,
    required this.myTeamName,
  });

  final List<Game> games;
  final String myTeamName;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('최근 5경기', style: MhText.sectionTitle(c.text)),
          const SizedBox(height: 12),
          if (games.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(MhRadius.card),
              ),
              child: Text('최근 경기 기록이 없어요',
                  style: MhText.custom(
                      size: 14, weight: FontWeight.w600, color: c.textSub)),
            )
          else
            for (final g in games) ...[
              _RecentRow(game: g, myTeamName: myTeamName),
              const SizedBox(height: MhSpacing.xs),
            ],
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.game, required this.myTeamName});

  final Game game;
  final String myTeamName;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final isHome = game.home.name == myTeamName;
    final opponent = isHome ? game.away.name : game.home.name;
    final mine = isHome ? game.scoreHome : game.scoreAway;
    final theirs = isHome ? game.scoreAway : game.scoreHome;

    final (result, bg) = switch ((mine, theirs)) {
      (final a?, final b?) when a > b => ('승', MhColors.brand),
      (final a?, final b?) when a < b => ('패', const Color(0xFFE5484D)),
      (final a?, final b?) when a == b => ('무', MhColors.closed),
      _ => ('-', MhColors.closed),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Text(result,
                style: MhText.custom(
                    size: 12, weight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('vs $opponent',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MhText.custom(
                    size: 14, weight: FontWeight.w600, color: c.text)),
          ),
          Text('${game.scoreHomeText} : ${game.scoreAwayText}',
              style: MhText.custom(
                  size: 14, weight: FontWeight.w700, color: c.text)),
        ],
      ),
    );
  }
}

/// 주요 선수 — 마이팀 소속 선수 목록.
class TopScorersSection extends StatelessWidget {
  const TopScorersSection({super.key, required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('주요 선수', style: MhText.sectionTitle(c.text)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: players.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text('등록된 선수 정보가 없습니다',
                        style: MhText.custom(
                            size: 13,
                            weight: FontWeight.w400,
                            color: c.textSub)),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < players.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: i == players.length - 1
                                    ? Colors.transparent
                                    : c.borderSubtle,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                child: Text('${i + 1}',
                                    style: MhText.custom(
                                      size: 16,
                                      weight: FontWeight.w700,
                                      color: i < 3 ? MhColors.brand : c.textSub,
                                    )),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(players[i].name,
                                        style: MhText.custom(
                                            size: 15,
                                            weight: FontWeight.w600,
                                            color: c.text)),
                                    Text(players[i].positionFull,
                                        style: MhText.caption(c.textSub)),
                                  ],
                                ),
                              ),
                              Text(players[i].statLine,
                                  style: MhText.custom(
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: c.text)),
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
