import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/game.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/sub_page_scaffold.dart';
import '../view_models/game_detail_view_model.dart';
import 'game_detail_header.dart';
import 'game_live_tab.dart';
import 'game_mvp_tab.dart';
import 'game_predict_tab.dart';
import 'game_stats_tab.dart';

/// 경기 상세. 시안 GAME DETAIL.
///
/// 홈 카드 · 일정 카드 · MY 탭 세 곳에서 열린다.
class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({super.key, required this.game});

  final Game game;

  static Future<void> open(BuildContext context, Game game) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gameDetailViewModelProvider(game));
    final vm = ref.read(gameDetailViewModelProvider(game).notifier);

    return SubPageScaffold(
      title: '경기 상세',
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: MhColors.brand)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(MhSpacing.gutter),
            child: Text('$e',
                textAlign: TextAlign.center,
                style: MhText.meta(context.mh.textSub)),
          ),
        ),
        data: (state) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  GameDetailHeader(state: state),
                  if (state.canAttend) _AttendButton(state: state, onTap: vm.toggleAttended),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                current: state.tab,
                onSelect: vm.selectTab,
                palette: context.mh,
              ),
            ),
            SliverToBoxAdapter(
              child: switch (state.tab) {
                GameDetailTab.live => GameLiveTab(state: state),
                GameDetailTab.stats => GameStatsTab(state: state),
                GameDetailTab.predict => GamePredictTab(state: state),
                GameDetailTab.mvp => GameMvpTab(state: state),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 직관 기록 토글. 시안은 1.5px 브랜드 테두리에 눌리면 채워진다.
class _AttendButton extends StatelessWidget {
  const _AttendButton({required this.state, required this.onTap});

  final GameDetailState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = state.attended;
    final fg = on ? Colors.white : MhColors.brand;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 0, MhSpacing.gutter, MhSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? MhColors.brand : Colors.transparent,
            border: Border.all(color: MhColors.brand, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(on ? Icons.place : Icons.place_outlined, size: 16, color: fg),
              const SizedBox(width: MhSpacing.xs),
              Text(on ? '직관 기록됨' : '직관 기록하기',
                  style: MhText.custom(
                      size: 14, weight: FontWeight.w700, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 스크롤해도 붙어 있는 탭바 (시안 `position: sticky`).
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate({
    required this.current,
    required this.onSelect,
    required this.palette,
  });

  final GameDetailTab current;
  final ValueChanged<GameDetailTab> onSelect;
  final MhPalette palette;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(bottom: BorderSide(color: palette.borderSubtle)),
      ),
      child: Row(
        children: [
          for (final tab in GameDetailTab.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(tab),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: tab == current
                            ? MhColors.brand
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    tab.label,
                    style: MhText.custom(
                      size: 14,
                      weight: FontWeight.w600,
                      color: tab == current ? palette.text : palette.textSub,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.current != current || old.palette != palette;
}
