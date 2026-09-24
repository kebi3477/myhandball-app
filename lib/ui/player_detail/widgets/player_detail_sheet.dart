import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/ranking_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/player.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../../player_compare/widgets/player_compare_screen.dart';
import '../../team_detail/widgets/team_detail_screen.dart';

/// 선수 요약 시트. 시안 PLAYER SUMMARY.
Future<void> showPlayerDetailSheet(BuildContext context, Player player) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    isScrollControlled: true,
    builder: (_) => _PlayerDetailSheet(player: player),
  );
}

class _PlayerDetailSheet extends ConsumerStatefulWidget {
  const _PlayerDetailSheet({required this.player});

  final Player player;

  @override
  ConsumerState<_PlayerDetailSheet> createState() => _PlayerDetailSheetState();
}

class _PlayerDetailSheetState extends ConsumerState<_PlayerDetailSheet> {
  late bool _favorite = ref
      .read(preferencesRepositoryProvider)
      .isFavoritePlayer(widget.player.id);

  /// 목록에는 경기 수와 프로필이 없어서 상세를 따로 받는다.
  /// 실패해도 시트는 목록에서 받은 기록으로 열린다.
  PlayerDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await ref
          .read(handballApiServiceProvider)
          .fetchPlayerDetail(widget.player);
      if (mounted) setState(() => _detail = detail);
    } on ApiException {
      // 프로필 없이 그대로 둔다.
    }
  }

  /// 시안 `cardPlayer.openTeam` — 소속 팀 상세로.
  ///
  /// 목록이 팀 번호를 주지 않는 경우가 있어 팀 목록에서 이름으로 찾는다.
  /// 못 찾으면 아무 일도 안 하는 대신 시트를 그대로 둔다.
  Future<void> _openTeam(BuildContext context) async {
    // `Player`에 부가 없다. 지금 보고 있는 부를 먼저 뒤지고, 없으면 반대편도
    // 본다 — 검색으로 들어오면 다른 부 선수가 열릴 수 있다.
    final repo = ref.read(teamRepositoryProvider);
    final preferred = ref.read(preferencesRepositoryProvider).preferredGender;
    for (final gender in {preferred, ...Gender.values}) {
      final teams = await repo.getTeams(gender);
      for (final team in teams) {
        if (team.name != widget.player.teamName) continue;
        if (!context.mounted) return;
        Navigator.of(context).pop();
        await TeamDetailScreen.open(context, team);
        return;
      }
    }
  }

  /// 시안 `cardPlayer.compare` — 같은 부 선수 목록을 들고 비교 화면으로.
  Future<void> _openCompare(BuildContext context) async {
    final players = await ref
        .read(playerRepositoryProvider)
        .getPlayers(ref.read(preferencesRepositoryProvider).preferredGender);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await PlayerCompareScreen.open(context, [
      widget.player,
      ...players.where((p) => p.id != widget.player.id),
    ]);
  }

  Future<void> _toggleFavorite() async {
    await ref
        .read(preferencesRepositoryProvider)
        .toggleFavoritePlayer(widget.player.id);
    setState(() => _favorite = !_favorite);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final p = widget.player;

    // 상세가 오면 경기 수까지 채워진다. 오기 전에는 목록 기록으로 그린다.
    final season = ref.read(preferencesRepositoryProvider).season;
    final stats =
        _detail?.statsForSeason(season.year) ??
        p.stats ??
        const PlayerSeasonSummary();
    final summary = stats.summaryCells;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        MhSpacing.gutter,
        12,
        MhSpacing.gutter,
        28,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              TeamLogo(size: 56, logoUrl: p.teamLogoUrl, inset: 0.78),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.teamName} · ${p.positionFull}',
                      style: MhText.custom(
                        size: 12,
                        weight: FontWeight.w500,
                        color: c.textSub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'No.${p.numberText}',
                          style: mhDisplay(size: 28, color: MhColors.brand),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MhText.custom(
                              size: 24,
                              weight: FontWeight.w800,
                              color: c.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              MhTap(
                onTap: _toggleFavorite,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.card,
                    shape: BoxShape.circle,
                  ),
                  child: MhIcon(
                    _favorite ? MhIcons.heartFilled : MhIcons.heart,
                    size: 22,
                    color: _favorite ? const Color(0xFFFF4D6A) : c.textSub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${season.label} 시즌 요약',
            style: MhText.custom(
              size: 13,
              weight: FontWeight.w700,
              color: c.text,
            ),
          ),
          const SizedBox(height: MhSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.chip),
            ),
            child: Row(
              children: [
                for (final (label, value) in summary)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MhText.custom(
                            size: 20,
                            weight: FontWeight.w800,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(label, style: MhText.caption(c.textSub)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_detail case final detail?) ...[
            if (detail.profileFacts.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '프로필',
                style: MhText.custom(
                  size: 13,
                  weight: FontWeight.w700,
                  color: c.text,
                ),
              ),
              const SizedBox(height: MhSpacing.xs),
              for (final (label, value) in detail.profileFacts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(label, style: MhText.caption(c.textSub)),
                      ),
                      Expanded(
                        child: Text(
                          value,
                          style: MhText.custom(
                            size: 13,
                            weight: FontWeight.w600,
                            color: c.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Text(
              '정규리그 통산',
              style: MhText.custom(
                size: 13,
                weight: FontWeight.w700,
                color: c.text,
              ),
            ),
            const SizedBox(height: MhSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(MhRadius.chip),
              ),
              child: Row(
                children: [
                  for (final (label, value) in detail.career.summaryCells)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MhText.custom(
                              size: 18,
                              weight: FontWeight.w800,
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(label, style: MhText.caption(c.textSub)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // 시안은 팀 보기 · 비교 · 관심 세 버튼을 1 : 1 : 1.4로 깐다.
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: '팀 보기',
                  onTap: () => _openTeam(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SheetButton(
                  label: '비교',
                  onTap: () => _openCompare(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _SheetButton(
                  label: _favorite ? '관심 선수 해제' : '관심 선수 추가',
                  filled: true,
                  onTap: _toggleFavorite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 시트 아래쪽 버튼. 시안은 height 48 / radius 12.
class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      haptic: filled ? MhHaptic.impact : MhHaptic.selection,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? MhColors.brand : c.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MhText.custom(
            size: 15,
            weight: FontWeight.w700,
            color: filled ? Colors.white : c.text,
          ),
        ),
      ),
    );
  }
}
