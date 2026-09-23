import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../domain/models/player.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
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

    // 실제 기록 API가 없어 statLine에서 뽑을 수 있는 값만 보여준다.
    final summary = <(String, String)>[
      ('기록', p.statLine.split(' · ').first),
      ('포지션', p.position),
      ('등번호', '${p.number}'),
      ('소속', p.teamName),
    ];

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
                        Text('No.${p.number}',
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
              GestureDetector(
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
          Text('25-26 시즌 요약',
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
          const SizedBox(height: 12),
          Text('경기별 기록은 선수 기록 API가 생기면 채워진다',
              style: MhText.custom(
                  size: 11, weight: FontWeight.w400, color: c.textFaint)),
          const SizedBox(height: 20),
          GestureDetector(
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
