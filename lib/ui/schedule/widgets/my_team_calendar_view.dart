import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/game.dart';
import '../../../domain/models/schedule_day.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/change_my_team.dart';
import '../../core/ui/external_actions.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../../game_detail/widgets/game_detail_screen.dart';
import '../view_models/schedule_view_model.dart';
import 'month_switcher.dart';
import 'year_month_picker.dart';

/// 일정 — MY팀 달력 뷰.
class MyTeamCalendarView extends ConsumerWidget {
  const MyTeamCalendarView({super.key, required this.state});

  final ScheduleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(scheduleViewModelProvider.notifier);
    final myTeam = state.myTeam;

    if (myTeam == null) return const _NoTeam();

    final selectedGame = state.selectedGame;

    return Column(
      children: [
        MonthSwitcher(
          label: state.monthLabel,
          onPrev: () => vm.shiftMonth(-1),
          onNext: () => vm.shiftMonth(1),
          onPickYearMonth: () => pickYearMonth(context, state, vm),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                MhSpacing.gutter, 0, MhSpacing.gutter, MhSpacing.xl),
            children: [
              _TeamHeader(state: state),
              const SizedBox(height: 14),
              _CalendarCard(state: state, onSelect: vm.selectDate),
              const SizedBox(height: 14),
              if (selectedGame != null)
                _SelectedGameCard(
                  date: state.selectedDate!,
                  game: selectedGame,
                )
              else if (state.myTeamDays.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text('이번 달 MY팀 경기가 없어요',
                      textAlign: TextAlign.center,
                      style: MhText.custom(
                          size: 14,
                          weight: FontWeight.w600,
                          color: context.mh.textSub)),
                ),
              const SizedBox(height: 14),
              _IcsExportCard(
                count: state.upcomingMyTeamCount,
                games: state.upcomingMyTeamGames,
                teamName: state.myTeam?.name ?? 'MY팀',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamHeader extends ConsumerWidget {
  const _TeamHeader({required this.state});

  final ScheduleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final team = state.myTeam!;
    final total = state.myTeamDays.expand((d) => d.games).length;

    return Row(
      children: [
        TeamLogo(size: 40, logoUrl: team.logoUrl),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${team.name} 일정',
                  style: MhText.custom(
                      size: 15, weight: FontWeight.w800, color: c.text)),
              Text('${state.month.month}월 $total경기',
                  style: MhText.meta(c.textSub)),
            ],
          ),
        ),
        MhTap(
          behavior: HitTestBehavior.opaque,
          onTap: () => changeMyTeam(context, ref, current: team),
          child: Text('팀변경 >', style: MhText.meta(c.textFaint)),
        ),
      ],
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.state, required this.onSelect});

  final ScheduleState state;
  final ValueChanged<DateTime?> onSelect;

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final cells = state.calendarCells;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(MhRadius.card),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _weekdays[i],
                      textAlign: TextAlign.center,
                      style: MhText.custom(
                        size: 11,
                        weight: FontWeight.w600,
                        // 일요일 빨강 / 토요일 파랑
                        color: switch (i) {
                          0 => const Color(0xFFE5484D),
                          6 => MhColors.brand,
                          _ => c.textSub,
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 2,
              // 시안은 64px이지만 Pretendard가 Impact보다 높아 살짝 넘친다.
              mainAxisExtent: 70,
            ),
            itemBuilder: (_, i) => _DayCell(
              cell: cells[i],
              selected: _isSelected(cells[i]),
              onTap: cells[i].hasGame ? () => onSelect(cells[i].date) : null,
            ),
          ),
          const SizedBox(height: 8),
          const _Legend(),
        ],
      ),
    );
  }

  bool _isSelected(CalendarCell cell) {
    final sel = state.selectedDate;
    return sel != null &&
        sel.year == cell.date.year &&
        sel.month == cell.date.month &&
        sel.day == cell.date.day;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.cell,
    required this.selected,
    required this.onTap,
  });

  final CalendarCell cell;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    if (!cell.inMonth) return const SizedBox.shrink();

    final game = cell.game;
    // 마이팀 기준 상대팀 로고를 띄운다. 홈이면 브랜드 링, 원정이면 흐린 링.
    final ringColor = cell.isHome ? MhColors.brand : c.textFaint;

    String? tag;
    Color tagColor = c.textSub;
    if (game != null) {
      if (game.status == GameStatus.finished) {
        final mine = cell.isHome ? game.scoreHome : game.scoreAway;
        final theirs = cell.isHome ? game.scoreAway : game.scoreHome;
        if (mine != null && theirs != null) {
          final win = mine > theirs;
          tag = mine == theirs ? '무' : (win ? '승' : '패');
          tagColor = mine == theirs
              ? c.textSub
              : (win ? MhColors.brand : const Color(0xFFE5484D));
        }
      } else {
        tag = game.meta;
      }
    }

    return MhTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: selected ? MhColors.brand.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? MhColors.brand : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              '${cell.date.day}',
              style: MhText.custom(
                size: 11,
                weight: cell.hasGame ? FontWeight.w800 : FontWeight.w400,
                color: cell.hasGame ? c.text : c.textFaint,
                height: 14 / 11,
              ),
            ),
            if (game != null) ...[
              const SizedBox(height: 3),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 2),
                ),
                padding: const EdgeInsets.all(1),
                child: TeamLogo(
                  size: 20,
                  logoUrl:
                      cell.isHome ? game.away.logoUrl : game.home.logoUrl,
                ),
              ),
              if (tag != null)
                // 폰트 메트릭 차이로 칸을 넘기지 않도록 높이를 고정한다.
                SizedBox(
                  height: 12,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tag,
                        style: MhText.custom(
                            size: 9,
                            weight: FontWeight.w800,
                            color: tagColor)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final style = MhText.custom(
        size: 10, weight: FontWeight.w400, color: c.textSub);

    Widget dot(Color ring) => Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MhColors.logoBg,
            border: Border.all(color: ring, width: 2),
          ),
        );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          dot(MhColors.brand),
          const SizedBox(width: 5),
          Text('홈', style: style),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          dot(c.textFaint),
          const SizedBox(width: 5),
          Text('원정', style: style),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('승',
              style: MhText.custom(
                  size: 10, weight: FontWeight.w800, color: MhColors.brand)),
          const SizedBox(width: 2),
          Text('패',
              style: MhText.custom(
                  size: 10,
                  weight: FontWeight.w800,
                  color: const Color(0xFFE5484D))),
          const SizedBox(width: 4),
          Text('경기 결과', style: style),
        ]),
        Text('아이콘 = 상대팀', style: style),
      ],
    );
  }
}

class _SelectedGameCard extends StatelessWidget {
  const _SelectedGameCard({required this.date, required this.game});

  final DateTime date;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final finished = game.status == GameStatus.finished;

    return Container(
      padding: const EdgeInsets.all(MhSpacing.sm),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(MhRadius.card),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${date.month}월 ${date.day}일',
                  style: MhText.custom(
                      size: 13, weight: FontWeight.w700, color: c.text)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: finished ? MhColors.closed : MhColors.brand,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(game.status.chipLabel,
                    style: MhText.custom(
                        size: 11,
                        weight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MiniTeam(name: game.home.name, logo: game.home.logoUrl)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  finished
                      ? '${game.scoreHomeText} : ${game.scoreAwayText}'
                      : game.meta,
                  style: MhText.score(c.text, size: 30),
                ),
              ),
              Expanded(child: _MiniTeam(name: game.away.name, logo: game.away.logoUrl)),
            ],
          ),
          const SizedBox(height: 14),
          Text(game.venue ?? '경기장 미정',
              textAlign: TextAlign.center, style: MhText.meta(c.textSub)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MhTap(
                  onTap: () => GameDetailScreen.open(context, game),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('경기 상세',
                        style: MhText.custom(
                            size: 14, weight: FontWeight.w700, color: c.text)),
                  ),
                ),
              ),
              if (!finished) ...[
                const SizedBox(width: MhSpacing.xs),
                Expanded(
                  child: MhTap(
                    haptic: MhHaptic.impact,
                    onTap: () => exportGamesToCalendar(
                      context,
                      [game],
                      calendarName:
                          '${game.home.name} vs ${game.away.name}',
                      fileName: 'myhandball-game.ics',
                    ),
                    child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: MhColors.brand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('캘린더에 추가',
                            style: MhText.custom(
                                size: 14,
                                weight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTeam extends StatelessWidget {
  const _MiniTeam({required this.name, required this.logo});

  final String name;
  final String? logo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamLogo(size: 48, logoUrl: logo),
        const SizedBox(height: 6),
        Text(name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: MhText.custom(
                size: 13, weight: FontWeight.w700, color: context.mh.text)),
      ],
    );
  }
}

/// 시안 하단의 ICS 내보내기 카드.
///
/// 서버에도 `/api/schedule/ics/my-team`이 있지만 시즌 전체만 준다.
/// 경기 하나만 넣는 버튼과 경로를 하나로 두려고 앱에서 만든다 ([Ics]).
class _IcsExportCard extends StatelessWidget {
  const _IcsExportCard({required this.count, required this.games, required this.teamName});

  final int count;

  /// 남은 경기. 이미 끝난 경기를 캘린더에 넣을 이유가 없다.
  final List<Game> games;

  final String teamName;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      padding: const EdgeInsets.all(MhSpacing.sm),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(MhRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MhColors.brand.withValues(alpha: 0.14),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                size: 20, color: MhColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MY팀 일정 캘린더에 추가',
                    style: MhText.custom(
                        size: 14, weight: FontWeight.w700, color: c.text)),
                Text('남은 $count경기 · 경기 30분 전 알림 포함 (.ics)',
                    style: MhText.custom(
                        size: 12,
                        weight: FontWeight.w400,
                        color: c.textSub,
                        height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: MhSpacing.xs),
          MhTap(
            haptic: MhHaptic.impact,
            onTap: () => exportGamesToCalendar(
              context,
              games,
              calendarName: '$teamName 일정',
              fileName: 'myhandball-$teamName.ics',
            ),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MhColors.brand,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Text('내보내기',
                  style: MhText.custom(
                      size: 13, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoTeam extends StatelessWidget {
  const _NoTeam();

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MhSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: c.card, shape: BoxShape.circle),
              child: Icon(Icons.favorite_border_rounded,
                  size: 30, color: c.textSub),
            ),
            const SizedBox(height: 14),
            Text('마이팀을 먼저 골라주세요',
                style: MhText.sectionTitle(c.text)),
            const SizedBox(height: 6),
            Text('MY 탭에서 팀을 고르면 그 팀 일정만 달력으로 볼 수 있어요.',
                textAlign: TextAlign.center,
                style: MhText.custom(
                    size: 13,
                    weight: FontWeight.w400,
                    color: c.textSub,
                    height: 1.6)),
          ],
        ),
      ),
    );
  }
}
