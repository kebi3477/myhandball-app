import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/gender.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/nav_icons.dart';
import '../../search/widgets/search_screen.dart';
import '../view_models/stat_view_model.dart';
import 'stat_player_tab.dart';
import 'stat_rank_tab.dart';
import 'stat_record_tab.dart';
import 'stat_skeleton.dart';
import 'stat_team_tab.dart';

/// 분석 탭.
///
/// 시안: 헤더 → 서브탭 4개(순위 / 기록 / 팀 / 선수) → 남·여 토글(순위·팀 탭만)
/// → 탭별 본문.
class StatScreen extends ConsumerWidget {
  const StatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(statViewModelProvider);
    final vm = ref.read(statViewModelProvider.notifier);
    final tab = async.valueOrNull?.tab ?? StatTab.rank;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        _TabBar(current: tab, onSelect: vm.selectTab),
        Expanded(
          child: async.when(
            skipLoadingOnReload: true,
            loading: () => const StatSkeleton(),
            error: (e, _) => _ErrorView(message: '$e', onRetry: vm.refresh),
            data: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.showsGenderToggle)
                  _GenderToggle(
                    gender: state.gender,
                    // 시안은 순위 탭에서 64px 알약, 팀 탭에서 절반 너비를 쓴다.
                    expanded: state.tab == StatTab.team,
                    onSelect: vm.selectGender,
                  ),
                Expanded(
                  child: switch (state.tab) {
                    StatTab.rank => StatRankTab(state: state),
                    StatTab.record => StatRecordTab(state: state),
                    StatTab.team => StatTeamTab(state: state),
                    StatTab.player => StatPlayerTab(state: state),
                  },
                ),
              ],
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
            Text('분석',
                style: MhText.custom(
                    size: 20, weight: FontWeight.w700, color: c.text)),
            GestureDetector(
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

/// 4등분 탭 + 선택된 탭 아래 2px 브랜드 언더라인.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onSelect});

  final StatTab current;
  final ValueChanged<StatTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: Row(
        children: [
          for (final tab in StatTab.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                    textAlign: TextAlign.center,
                    style: MhText.custom(
                      size: 14,
                      weight: FontWeight.w700,
                      color: tab == current ? c.text : c.textSub,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GenderToggle extends StatelessWidget {
  const _GenderToggle({
    required this.gender,
    required this.expanded,
    required this.onSelect,
  });

  final Gender gender;
  final bool expanded;
  final ValueChanged<Gender> onSelect;

  @override
  Widget build(BuildContext context) {
    final pills = [
      for (final g in Gender.values)
        _Pill(
          label: g.divisionLabel,
          selected: gender == g,
          onTap: () => onSelect(g),
        ),
    ];

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MhSpacing.sm),
        child: Row(
          children: expanded
              ? [
                  Expanded(child: pills[0]),
                  const SizedBox(width: MhSpacing.sm),
                  Expanded(child: pills[1]),
                ]
              : [
                  SizedBox(width: 64, child: pills[0]),
                  const SizedBox(width: 10),
                  SizedBox(width: 64, child: pills[1]),
                ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? MhColors.brand : c.card,
          borderRadius: BorderRadius.circular(MhRadius.pill),
        ),
        child: Text(
          label,
          style: MhText.custom(
            size: 14,
            weight: FontWeight.w500,
            color: selected ? Colors.white : c.textSub,
            height: 24 / 14,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            MhSpacing.gutter, MhSpacing.xl, MhSpacing.gutter, 60),
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
            Text('기록을 불러오지 못했어요',
                style: MhText.custom(
                    size: 17, weight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: MhText.custom(
                    size: 13,
                    weight: FontWeight.w400,
                    color: c.textSub,
                    height: 1.6)),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                height: 44,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MhColors.brand,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text('다시 시도',
                    style: MhText.custom(
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
