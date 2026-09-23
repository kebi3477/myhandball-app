import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/game_detail.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/game_detail_view_model.dart';

/// MVP 탭 — 경기 종료 전에는 잠겨 있고, 끝나면 투표가 열린다.
class GameMvpTab extends ConsumerWidget {
  const GameMvpTab({super.key, required this.state});

  final GameDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;

    if (!state.detail.mvpOpen) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            MhSpacing.gutter, MhSpacing.sm, MhSpacing.gutter, MhSpacing.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(MhRadius.card),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
                child: Icon(Icons.emoji_events_outlined,
                    size: 26, color: c.textSub),
              ),
              const SizedBox(height: MhSpacing.xs),
              Text('아직 투표 전이에요',
                  style: MhText.custom(
                      size: 15, weight: FontWeight.w700, color: c.text)),
              const SizedBox(height: 4),
              Text('경기가 끝나면 오늘의 MVP 투표가 열려요',
                  textAlign: TextAlign.center,
                  style: MhText.meta(c.textSub)),
            ],
          ),
        ),
      );
    }

    final vm = ref.read(gameDetailViewModelProvider(state.game).notifier);
    final candidates = [...state.detail.mvpCandidates]
      ..sort((a, b) => b.votes.compareTo(a.votes));
    final total = candidates.fold<int>(0, (sum, m) => sum + m.votes) +
        (state.hasVotedMvp ? 1 : 0);

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: MhSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('오늘의 MVP',
                      style: MhText.custom(
                          size: 15, weight: FontWeight.w700, color: c.text)),
                  Flexible(
                    child: Text(
                      state.hasVotedMvp
                          ? '$total표 · 투표 완료'
                          : '$total표 · 한 번만 투표할 수 있어요',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MhText.custom(
                          size: 11,
                          weight: FontWeight.w400,
                          color: c.textFaint),
                    ),
                  ),
                ],
              ),
            ),
            for (final m in candidates) ...[
              _CandidateRow(
                candidate: m,
                total: total,
                myVote: state.mvpVote,
                showResult: state.hasVotedMvp,
                onTap: () => vm.voteMvp(m.id),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.candidate,
    required this.total,
    required this.myVote,
    required this.showResult,
    required this.onTap,
  });

  final MvpCandidate candidate;
  final int total;
  final String? myVote;
  final bool showResult;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final mine = myVote == candidate.id;
    final votes = candidate.votes + (mine ? 1 : 0);
    final pct = total == 0 ? 0.0 : votes / total;

    return GestureDetector(
      onTap: showResult ? null : onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(color: mine ? MhColors.brand : c.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            // 득표율 막대. 투표 전에는 결과를 가린다.
            if (showResult)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    color: MhColors.brand
                        .withValues(alpha: mine ? 0.22 : 0.10),
                  ),
                ),
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  TeamLogo(size: 30, logoUrl: candidate.teamLogoUrl, inset: 0.78),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(candidate.name,
                            style: MhText.custom(
                                size: 14,
                                weight: FontWeight.w700,
                                color: c.text)),
                        Text('${candidate.teamName} · ${candidate.statLine}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MhText.caption(c.textSub)),
                      ],
                    ),
                  ),
                  Text(
                    showResult ? '${(pct * 100).round()}%' : '투표',
                    style: MhText.custom(
                      size: 13,
                      weight: FontWeight.w800,
                      color: mine ? MhColors.brand : c.textSub,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
