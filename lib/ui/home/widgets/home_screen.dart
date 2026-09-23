import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/nav_icons.dart';
import '../../search/widgets/search_screen.dart';
import '../view_models/home_view_model.dart';
import 'guide_banner.dart';
import 'home_skeleton.dart';
import 'nearby_games_section.dart';
import 'ranking_section.dart';
import 'top5_section.dart';

/// 홈 탭.
///
/// 시안 순서: 헤더 → 가까운 경기(가로 스와이프) → 규칙 가이드 배너 →
/// 팀순위(시상대 + 리스트) → 시즌 TOP5.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final home = ref.watch(homeViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        Expanded(
          child: home.when(
            // 이전 값이 있으면 그걸 계속 보여준다 (성별 전환 시 화면이 안 비게).
            skipLoadingOnReload: true,
            loading: () => const HomeSkeleton(),
            error: (e, _) => _ErrorView(message: mhErrorMessage(e)),
            data: (state) => RefreshIndicator(
              color: MhColors.brand,
              backgroundColor: c.card,
              onRefresh: () =>
                  ref.read(homeViewModelProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: MhSpacing.xl),
                children: [
                  NearbyGamesSection(games: state.games),
                  const SizedBox(height: MhSpacing.md),
                  GuideBanner(doneCount: state.guideDoneCount),
                  const SizedBox(height: MhSpacing.md),
                  RankingSection(state: state),
                  const SizedBox(height: MhSpacing.md),
                  Top5Section(state: state),
                ],
              ),
            ),
          ),
        ),
      ],
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

/// 시안의 에러 상태 — 72px 원형 + 제목 + 설명.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            MhSpacing.md, MhSpacing.xl, MhSpacing.md, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: c.card, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(Icons.cloud_off_rounded, size: 32, color: c.textSub),
            ),
            const SizedBox(height: 14),
            Text('경기 정보를 불러오지 못했어요',
                style: MhText.sectionTitle(c.text)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: MhText.custom(
                size: 13,
                weight: FontWeight.w400,
                color: c.textSub,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
