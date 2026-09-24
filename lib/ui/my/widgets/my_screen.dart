import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_error_view.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../../settings/widgets/settings_screen.dart';
import '../view_models/my_view_model.dart';
import 'my_attendance_card.dart';
import 'my_badges_section.dart';
import 'my_next_game_card.dart';
import 'my_profile_card.dart';
import 'my_sections.dart';
import 'my_team_card.dart';

/// MY 탭.
///
/// 시안 순서: 헤더 → 프로필(닉네임) → MY 팀 → 내 배지 → 관심 선수 →
/// 직관 기록 → 승부 예측 → **팀 구분선** → 다음 경기 → 시즌 기록 →
/// 최근 5경기 → 주요 선수.
///
/// 구분선 위는 내 활동, 아래는 마이팀 정보다.
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
            // 여기까지 오는 건 저장소 자체가 깨진 경우다. 평소의 통신 실패는
            // `MyState.error`로 내려와 위쪽 띠로 알린다.
            error: (e, _) =>
                Center(child: MhErrorView(error: e, onRetry: vm.refresh)),
            // **홈·일정·분석과 같은 오류 화면을 쓴다.** 시안은 MY만 위쪽
            // 띠로 알리게 그려 뒀는데, 연결이 끊기면 순위·기록·선수가 전부
            // 비어서 띠만 떠 있고 나머지는 빈 화면이 된다. 무엇이 문제인지도
            // 안 보이고 다시 시도할 자리도 눈에 안 띈다.
            data: (state) => state.hasError
                ? Center(
                    child: MhErrorView(error: state.error!, onRetry: vm.refresh))
                : RefreshIndicator(
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
                  MyBadgesSection(state: state),
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
                  // 여기서부터 아래는 마이팀 정보다 (시안 구분선).
                  MyTeamDivider(state: state),
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
