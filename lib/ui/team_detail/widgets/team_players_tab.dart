import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/player_card.dart';
import '../../player_detail/widgets/player_detail_sheet.dart';
import '../view_models/team_detail_view_model.dart';

/// 팀 상세 — 선수 탭.
class TeamPlayersTab extends ConsumerWidget {
  const TeamPlayersTab({super.key, required this.state});

  final TeamDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(teamDetailViewModelProvider(state.detail.team).notifier);
    final players = state.detail.players;

    if (players.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(MhSpacing.gutter),
          child: Text('등록된 선수 정보가 없습니다',
              style: MhText.custom(
                  size: 13,
                  weight: FontWeight.w400,
                  color: context.mh.textSub)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 18, MhSpacing.gutter, MhSpacing.xl),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        children: [
          for (final p in players)
            PlayerCard(
              player: p,
              favorite: state.favoritePlayerIds.contains(p.id),
              onToggleFavorite: () => vm.toggleFavoritePlayer(p.id),
              onTap: () => showPlayerDetailSheet(context, p),
            ),
        ],
      ),
    );
  }
}
