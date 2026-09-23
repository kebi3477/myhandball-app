import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../view_models/schedule_view_model.dart';
import 'my_team_calendar_view.dart';
import 'schedule_list_view.dart';
import 'schedule_skeleton.dart';

/// 일정 탭.
///
/// 시안: 헤더(목록/MY팀 달력 세그먼트) → 남/여 토글(목록 뷰만) → 월 이동 →
/// 뷰별 본문.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(scheduleViewModelProvider);
    final vm = ref.read(scheduleViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          view: async.valueOrNull?.view ?? ScheduleView.list,
          onSelect: vm.setView,
        ),
        Expanded(
          child: async.when(
            skipLoadingOnReload: true,
            loading: () => const ScheduleSkeleton(),
            error: (e, _) => _ErrorView(
              message: '$e',
              onRetry: vm.refresh,
            ),
            data: (state) => switch (state.view) {
              ScheduleView.list => ScheduleListView(state: state),
              ScheduleView.calendar => MyTeamCalendarView(state: state),
            },
          ),
        ),
      ],
    );
  }
}

/// 66px 헤더 — 제목 + 목록/달력 세그먼트
class _Header extends StatelessWidget {
  const _Header({required this.view, required this.onSelect});

  final ScheduleView view;
  final ValueChanged<ScheduleView> onSelect;

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
            Text('일정',
                style: MhText.custom(
                    size: 20, weight: FontWeight.w700, color: c.text)),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _SegmentTab(
                    label: '목록',
                    icon: Icons.format_list_bulleted_rounded,
                    selected: view == ScheduleView.list,
                    onTap: () => onSelect(ScheduleView.list),
                  ),
                  const SizedBox(width: 2),
                  _SegmentTab(
                    label: 'MY팀 달력',
                    icon: Icons.calendar_today_rounded,
                    selected: view == ScheduleView.calendar,
                    onTap: () => onSelect(ScheduleView.calendar),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final fg = selected ? Colors.white : c.textSub;
    return MhTap(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? MhColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(label,
                style: MhText.custom(
                    size: 13, weight: FontWeight.w700, color: fg)),
          ],
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
            Text('일정을 불러오지 못했어요',
                style: MhText.custom(
                    size: 17, weight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: MhText.custom(
                  size: 13,
                  weight: FontWeight.w400,
                  color: c.textSub,
                  height: 1.6),
            ),
            const SizedBox(height: 6),
            MhTap(
              onTap: onRetry,
              child: Container(
                height: 44,
                margin: const EdgeInsets.only(top: 6),
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
