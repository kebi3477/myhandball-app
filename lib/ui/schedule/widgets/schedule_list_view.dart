import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/game.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/team.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../../game_detail/widgets/game_detail_screen.dart';
import '../view_models/schedule_view_model.dart';
import 'month_switcher.dart';

/// 일정 — 목록 뷰.
class ScheduleListView extends ConsumerWidget {
  const ScheduleListView({super.key, required this.state});

  final ScheduleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(scheduleViewModelProvider.notifier);
    final games = state.visibleGames;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
          child: Row(
            children: [
              for (final g in Gender.values) ...[
                if (g != Gender.values.first) const SizedBox(width: MhSpacing.sm),
                Expanded(
                  child: _GenderPill(
                    label: g.divisionLabel,
                    selected: state.gender == g,
                    onTap: () => vm.selectGender(g),
                  ),
                ),
              ],
            ],
          ),
        ),
        MonthSwitcher(
          label: state.monthLabel,
          onPrev: () => vm.shiftMonth(-1),
          onNext: () => vm.shiftMonth(1),
        ),
        if (state.days.isNotEmpty) _DayChips(state: state, onTap: vm.toggleDay),
        Expanded(
          child: games.isEmpty
              ? const _Empty()
              : RefreshIndicator(
                  color: MhColors.brand,
                  backgroundColor: context.mh.card,
                  onRefresh: vm.refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        MhSpacing.gutter, 0, MhSpacing.gutter, MhSpacing.xl),
                    itemCount: games.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MhSpacing.xs),
                    itemBuilder: (context, i) => MhTap(
                      onTap: () => GameDetailScreen.open(context, games[i]),
                      child: _ScheduleGameCard(game: games[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _GenderPill extends StatelessWidget {
  const _GenderPill({
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
    return MhTap(
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

/// 날짜 칩 가로 스크롤. 누르면 그 날짜만 보고, 다시 누르면 전체로 돌아간다.
class _DayChips extends StatelessWidget {
  const _DayChips({required this.state, required this.onTap});

  final ScheduleState state;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
            MhSpacing.gutter, 0, MhSpacing.gutter, MhSpacing.sm),
        itemCount: state.days.length,
        separatorBuilder: (_, _) => const SizedBox(width: MhSpacing.xs),
        itemBuilder: (_, i) {
          final day = state.days[i];
          final selected = state.selectedDayLabel == day.label;
          return MhTap(
            onTap: () => onTap(day.label),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? MhColors.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                    color: selected ? MhColors.brand : c.border),
              ),
              child: Text(
                day.shortLabel,
                style: MhText.custom(
                  size: 13,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : c.textSub,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 134px 경기 카드 — 로고 70px · 칩 + 스코어 · 로고 70px
class _ScheduleGameCard extends StatelessWidget {
  const _ScheduleGameCard({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final chipBg = switch (game.status) {
      GameStatus.live => MhColors.live,
      GameStatus.pre => MhColors.brand,
      GameStatus.finished => MhColors.closed,
    };
    final chipLabel =
        game.status == GameStatus.pre ? game.meta : game.status.chipLabel;

    return Container(
      height: 134,
      padding: const EdgeInsets.all(MhSpacing.sm),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(MhRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _Side(team: game.home)),
          SizedBox(
            width: 91,
            child: Column(
              children: [
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(chipLabel,
                      style: MhText.custom(
                          size: 10,
                          weight: FontWeight.w400,
                          color: Colors.white,
                          height: 16 / 10)),
                ),
                const SizedBox(height: MhSpacing.sm),
                // 시안은 Impact(좁은 폭)로 91px 안에 36px 숫자를 넣는다.
                // Pretendard는 더 넓어 그대로면 줄바꿈되므로 축소해 맞춘다.
                SizedBox(
                  height: 30,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${game.scoreHomeText} : ${game.scoreAwayText}',
                      style: MhText.score(c.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _Side(team: game.away)),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final name = team.name;
    // 시안은 이름 길이에 따라 글자 크기를 줄인다 (`g.nameSize`).
    final size = name.length >= 8 ? 12.0 : 14.0;

    return Column(
      children: [
        TeamLogo(size: 70, logoUrl: team.logoUrl),
        const SizedBox(height: MhSpacing.xs),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MhText.custom(
            size: size,
            weight: FontWeight.w600,
            color: c.text,
            height: 24 / size,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('이번 달 예정된 경기가 없습니다',
          style: MhText.custom(
              size: 14, weight: FontWeight.w600, color: context.mh.textSub)),
    );
  }
}
