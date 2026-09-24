import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../domain/models/game.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_error_view.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/nav_icons.dart';
import '../../guide/view_models/guide_progress.dart';
import '../../search/widgets/search_screen.dart';
import '../view_models/home_tab.dart';
import '../view_models/home_view_model.dart';
import 'attendance_tab.dart';
import 'guide_banner.dart';
import 'home_skeleton.dart';
import 'nearby_games_section.dart';
import 'prediction_tab.dart';
import 'ranking_section.dart';
import 'top5_section.dart';

/// 홈 탭.
///
/// 헤더 아래에 **홈 / 승부예측 / 직관** 세 탭이 있다 (시안 `homeTabs`).
/// 탭 줄은 로딩·오류와 무관하게 늘 떠 있어야 한다 — 홈 데이터를 못 받았다고
/// 직관 기록까지 못 보게 할 이유가 없다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const _TabBar(),
        Expanded(
          child: switch (tab) {
            HomeTab.home => const _HomeContent(),
            HomeTab.prediction => const PredictionTab(),
            HomeTab.attendance => const AttendanceTab(),
          },
        ),
      ],
    );
  }
}

/// 시안 `homeTabs` 줄 — height 40, gap 22, 선택 탭에 2px 밑줄.
class _TabBar extends ConsumerWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final selected = ref.watch(homeTabProvider);
    final dot = ref.watch(_predictionDotProvider);

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final tab in HomeTab.values) ...[
            if (tab != HomeTab.values.first) const SizedBox(width: 22),
            MhTap(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.read(homeTabProvider.notifier).select(tab),
              child: Container(
                height: 40,
                // 밑줄이 컨테이너 테두리를 덮게 1px 내린다 (시안 margin-bottom:-1px).
                transform: Matrix4.translationValues(0, 1, 0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: tab == selected
                          ? MhColors.brand
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      tab.label,
                      style: MhText.custom(
                        size: 16,
                        weight: FontWeight.w700,
                        color: tab == selected ? c.text : c.textSub,
                      ),
                    ),
                    if (tab == HomeTab.prediction && dot) ...[
                      const SizedBox(width: 5),
                      // 시안 `margin-top:-10px` — 글자 오른쪽 위에 붙는다.
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF4D6A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 아직 예측하지 않은 경기가 있으면 승부예측 탭에 빨간 점을 찍는다.
///
/// **이미 받아둔 홈 데이터와 기기에 있는 값만 본다.** 점 하나 찍자고
/// 예측 탭의 시즌 일정을 미리 받아오면 홈이 그만큼 늦게 뜬다.
final _predictionDotProvider = Provider<bool>((ref) {
  final home = ref.watch(homeViewModelProvider).valueOrNull;
  if (home == null) return false;
  final prefs = ref.watch(preferencesRepositoryProvider);
  return home.games.any(
      (g) => g.status == GameStatus.pre && prefs.predictionFor(g.id) == null);
});

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final home = ref.watch(homeViewModelProvider);

    return home.when(
      // 이전 값이 있으면 그걸 계속 보여준다 (성별 전환 시 화면이 안 비게).
      skipLoadingOnReload: true,
      loading: () => const HomeSkeleton(),
      error: (e, _) => Center(
        child: MhErrorView(
          error: e,
          onRetry: ref.read(homeViewModelProvider.notifier).refresh,
        ),
      ),
      data: (state) => RefreshIndicator(
        color: MhColors.brand,
        backgroundColor: c.card,
        onRefresh: () => ref.read(homeViewModelProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: MhSpacing.xl),
          children: [
            NearbyGamesSection(state: state),
            const SizedBox(height: MhSpacing.md),
            GuideBanner(doneCount: ref.watch(guideDoneCountProvider)),
            const SizedBox(height: MhSpacing.md),
            RankingSection(state: state),
            const SizedBox(height: MhSpacing.md),
            Top5Section(state: state),
          ],
        ),
      ),
    );
  }
}

/// 헤더 (66px) — 워드마크 + 검색
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
            SvgPicture.asset('assets/design/logo-wordmark.svg',
                width: 119, height: 26),
            MhTap(
              behavior: HitTestBehavior.opaque,
              onTap: () => SearchScreen.open(context),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CustomPaint(painter: MhSearchIconPainter(c.text)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
