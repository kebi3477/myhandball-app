import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models/player.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';

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
    final stats = _detail?.statsForSeason(season.year) ??
        p.stats ??
        const PlayerSeasonSummary();
    final summary = stats.summaryCells;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 12, MhSpacing.gutter, 28),
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
                    Text('${p.teamName} · ${p.positionFull}',
                        style: MhText.custom(
                            size: 12,
                            weight: FontWeight.w500,
                            color: c.textSub)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('No.${p.numberText}',
                            style: MhText.custom(
                                size: 28,
                                weight: FontWeight.w800,
                                color: MhColors.brand)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MhText.custom(
                                  size: 24,
                                  weight: FontWeight.w800,
                                  color: c.text)),
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
                  decoration:
                      BoxDecoration(color: c.card, shape: BoxShape.circle),
                  child: Icon(
                    _favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 22,
                    color: _favorite ? const Color(0xFFFF4D6A) : c.textSub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('${season.label} 시즌 요약',
              style: MhText.custom(
                  size: 13, weight: FontWeight.w700, color: c.text)),
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
                        Text(value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MhText.custom(
                                size: 20,
                                weight: FontWeight.w800,
                                color: c.text)),
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
              Text('프로필',
                  style: MhText.custom(
                      size: 13, weight: FontWeight.w700, color: c.text)),
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
                        child: Text(value,
                            style: MhText.custom(
                                size: 13,
                                weight: FontWeight.w600,
                                color: c.text)),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Text('정규리그 통산',
                style: MhText.custom(
                    size: 13, weight: FontWeight.w700, color: c.text)),
            const SizedBox(height: MhSpacing.xs),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
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
                          Text(value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MhText.custom(
                                  size: 18,
                                  weight: FontWeight.w800,
                                  color: c.text)),
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
          MhTap(
            onTap: _toggleFavorite,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MhColors.brand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_favorite ? '관심 선수 해제' : '관심 선수 추가',
                  style: MhText.custom(
                      size: 15, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
