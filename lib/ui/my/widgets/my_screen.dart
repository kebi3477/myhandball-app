import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../../guide/view_models/guide_progress.dart';
import '../../settings/widgets/settings_screen.dart';
import '../view_models/my_view_model.dart';
import 'my_attendance_card.dart';
import 'my_guide_badge.dart';
import 'my_next_game_card.dart';
import 'my_profile_card.dart';
import 'my_sections.dart';
import 'my_team_card.dart';

/// MY 탭.
///
/// 시안 순서: 헤더 → 프로필(닉네임) → MY 팀 → 수료 배지 → 관심 선수 →
/// 직관 기록 → 승부 예측 → 다음 경기 → 시즌 기록 → 최근 5경기 → 주요 선수.
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myViewModelProvider);
    final vm = ref.read(myViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        Expanded(
          child: async.when(
            skipLoadingOnReload: true,
            loading: () => const Center(
              child: CircularProgressIndicator(color: MhColors.brand),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(MhSpacing.gutter),
                child: Text(
                  mhErrorMessage(e),
                  textAlign: TextAlign.center,
                  style: MhText.meta(context.mh.textSub),
                ),
              ),
            ),
            data: (state) => RefreshIndicator(
              color: MhColors.brand,
              backgroundColor: context.mh.card,
              onRefresh: vm.refresh,
              child: ListView(
                padding: const EdgeInsets.only(bottom: MhSpacing.xl),
                children: [
                  MyProfileCard(state: state),
                  const SizedBox(height: MhSpacing.md),
                  MyTeamCard(state: state),
                  const SizedBox(height: MhSpacing.md),
                  MyGuideBadge(
                    doneCount: ref.watch(guideDoneCountProvider),
                    allDone: ref.watch(guideDoneCountProvider.notifier).allDone,
                  ),
                  const SizedBox(height: MhSpacing.md),
                  FavoritePlayersSection(
                    players: state.favoritePlayers,
                    onRemove: vm.removeFavorite,
                  ),
                  const SizedBox(height: MhSpacing.md),
                  MyAttendanceCard(state: state),
                  const SizedBox(height: MhSpacing.md),
                  MyPredictionCard(state: state),
                  const SizedBox(height: MhSpacing.md),
                  MyNextGameCard(state: state),
                  const SizedBox(height: MhSpacing.md),
                  SeasonStatsSection(stats: state.seasonStats),
                  const SizedBox(height: MhSpacing.md),
                  RecentGamesSection(
                    games: state.recentGames,
                    myTeamName: state.team?.name ?? '',
                  ),
                  const SizedBox(height: MhSpacing.md),
                  TopScorersSection(players: state.teamPlayers),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return SizedBox(
      height: MhSizes.header,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MY',
              style: MhText.custom(
                size: 20,
                weight: FontWeight.w700,
                color: c.text,
              ),
            ),
            MhTap(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              child: SizedBox(
                width: 32,
                height: 32,
                child: MhIcon(MhIcons.gear, size: 22, color: c.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
