import 'package:flutter/material.dart';

import '../../../domain/models/game.dart';
import '../../../domain/models/game_detail.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/game_detail_view_model.dart';

/// 중계 탭 — 이벤트 타임라인.
class GameLiveTab extends StatelessWidget {
  const GameLiveTab({super.key, required this.state});

  final GameDetailState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final game = state.game;

    if (game.status == GameStatus.pre) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            MhSpacing.gutter, MhSpacing.sm, MhSpacing.gutter, MhSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(MhRadius.card),
          ),
          child: Column(
            children: [
              Text('경기 시작 후 문자중계가 시작돼요',
                  style: MhText.custom(
                      size: 15, weight: FontWeight.w700, color: c.text)),
              const SizedBox(height: 6),
              Text('${game.meta} 킥오프', style: MhText.meta(c.textSub)),
            ],
          ),
        ),
      );
    }

    final events = state.detail.events;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, MhSpacing.sm, MhSpacing.gutter, MhSpacing.xl),
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++)
            _EventRow(
              event: events[i],
              game: game,
              isFirst: i == 0,
              isLast: i == events.length - 1,
            ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.game,
    required this.isFirst,
    required this.isLast,
  });

  final GameEvent event;
  final Game game;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final isGoal = event.type == GameEventType.goal;
    final isMarker = !event.hasTeam;

    final dotColor = switch (event.type) {
      GameEventType.goal => MhColors.brand,
      GameEventType.twoMinutes => const Color(0xFFE5484D),
      GameEventType.save => const Color(0xFF00A86B),
      _ => c.textFaint,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                event.minuteLabel,
                textAlign: TextAlign.right,
                style: MhText.custom(
                  size: 12,
                  weight: FontWeight.w700,
                  color: isGoal ? c.text : c.textSub,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 세로선 + 점
          SizedBox(
            width: 14,
            child: Column(
              children: [
                Container(
                    width: 1,
                    height: 14,
                    color: isFirst ? Colors.transparent : c.border),
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Container(
                      width: 1, color: isLast ? Colors.transparent : c.border),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isMarker ? Colors.transparent : c.card,
                  border: isMarker ? Border.all(color: c.borderSubtle) : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    if (event.hasTeam) ...[
                      TeamLogo(
                        size: 24,
                        logoUrl: event.isHome!
                            ? game.home.logoUrl
                            : game.away.logoUrl,
                        inset: 0.78,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title,
                              style: MhText.custom(
                                size: 13,
                                weight:
                                    isGoal ? FontWeight.w800 : FontWeight.w600,
                                color: c.text,
                              )),
                          if (event.playerName != null)
                            Text(event.playerName!,
                                style: MhText.caption(c.textSub)),
                        ],
                      ),
                    ),
                    if (isGoal && event.scoreHome != null)
                      Text('${event.scoreHome} : ${event.scoreAway}',
                          style: MhText.score(c.text, size: 16)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
