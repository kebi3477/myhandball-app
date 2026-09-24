import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/game_detail.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/game_detail_view_model.dart';

/// MVP 탭 — 경기 종료 전에는 잠겨 있고, 끝나면 투표가 열린다.
class GameMvpTab extends ConsumerWidget {
  const GameMvpTab({super.key, required this.state});

  final GameDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;

    // 못 받아온 것과 아직 안 열린 것은 다르다. 섞으면 경기가 끝났는데도
    // "아직 투표 전"으로 보이고 다시 시도할 방법이 없다.
    if (state.mvpFailed) {
      return _Notice(
        icon: MhIcons.alert,
        title: '투표를 불러오지 못했어요',
        description: '잠시 뒤에 다시 시도해 주세요',
        onRetry: ref
            .read(gameDetailViewModelProvider(state.game).notifier)
            .refresh,
      );
    }

    if (!state.mvpOpen) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter,
          MhSpacing.sm,
          MhSpacing.gutter,
          MhSpacing.xl,
        ),
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
                child: MhIcon(MhIcons.star, size: 26, color: c.textSub),
              ),
              const SizedBox(height: MhSpacing.xs),
              Text(
                '아직 투표 전이에요',
                style: MhText.custom(
                  size: 15,
                  weight: FontWeight.w700,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '경기가 끝나면 오늘의 MVP 투표가 열려요',
                textAlign: TextAlign.center,
                style: MhText.meta(c.textSub),
              ),
            ],
          ),
        ),
      );
    }

    final vm = ref.read(gameDetailViewModelProvider(state.game).notifier);
    // 서버가 득표 내림차순으로 주고, 내 표도 이미 반영돼 있다.
    final candidates = state.mvp.candidates;
    final total = state.mvp.total;

    // 투표는 열렸는데 후보가 없는 경우 — 연맹에 선수 기록이 아직 안 올라온
    // 경기다. 빈 카드만 두면 눌러도 아무 일이 없는 화면이 된다.
    if (candidates.isEmpty) {
      return const _Notice(
        icon: MhIcons.star,
        title: '후보가 아직 없어요',
        description: '경기 기록이 올라오면 투표할 수 있어요',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MhSpacing.gutter,
        MhSpacing.sm,
        MhSpacing.gutter,
        MhSpacing.xl,
      ),
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
                  Text(
                    '오늘의 MVP',
                    style: MhText.custom(
                      size: 15,
                      weight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      state.hasVotedMvp
                          ? '$total표 · 이미 투표했어요'
                          : '$total표 · 한 번만 투표할 수 있어요',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MhText.custom(
                        size: 11,
                        weight: FontWeight.w400,
                        color: c.textFaint,
                      ),
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
    final pct = total == 0 ? 0.0 : candidate.votes / total;

    return MhTap(
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
                    color: MhColors.brand.withValues(alpha: mine ? 0.22 : 0.10),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  TeamLogo(
                    size: 30,
                    logoUrl: candidate.teamLogoUrl,
                    inset: 0.78,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          candidate.name,
                          style: MhText.custom(
                            size: 14,
                            weight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                        Text(
                          '${candidate.teamName} · ${candidate.statLine}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MhText.caption(c.textSub),
                        ),
                      ],
                    ),
                  ),
                  // **내가 뽑은 줄은 한눈에 보여야 한다.** 투표 뒤에는 모든
                  // 줄이 눌리지 않는데, 표시가 흐릿하면 "눌러도 안 된다"로
                  // 읽힌다.
                  if (mine) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: MhColors.brand,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('내 표',
                          style: MhText.custom(
                              size: 10,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                    const SizedBox(width: 6),
                  ],
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

/// MVP 탭이 투표 대신 띄우는 안내 카드.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.description,
    this.onRetry,
  });

  final String icon;
  final String title;
  final String description;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MhSpacing.gutter,
        MhSpacing.sm,
        MhSpacing.gutter,
        MhSpacing.xl,
      ),
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
              child: MhIcon(icon, size: 26, color: c.textSub),
            ),
            const SizedBox(height: MhSpacing.xs),
            Text(
              title,
              style: MhText.custom(
                size: 15,
                weight: FontWeight.w700,
                color: c.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: MhText.meta(c.textSub),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: MhSpacing.sm),
              MhTap(
                haptic: MhHaptic.impact,
                onTap: onRetry,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: MhColors.brand,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      '다시 시도',
                      style: MhText.custom(
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
