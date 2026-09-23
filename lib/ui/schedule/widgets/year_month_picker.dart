import 'package:flutter/material.dart';

import '../../../domain/models/season.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../view_models/schedule_view_model.dart';

/// 시안 YEAR/MONTH PICKER — 일정 탭에서 연·월을 직접 고르는 바텀시트.
///
/// 고른 값을 `(연, 월)`로 돌려준다. 그냥 닫으면 `null`.
/// "이번 달"을 누르면 [YearMonthPick.today]가 온다 — 기본 달로 돌아가라는
/// 뜻이고, 어느 달이 기본인지는 화면 쪽이 정한다 (비시즌이면 오늘 달이
/// 아니라 시즌의 마지막 달이다).
class YearMonthPick {
  const YearMonthPick(this.year, this.month);

  const YearMonthPick.today()
      : year = 0,
        month = 0;

  final int year;
  final int month;

  bool get isToday => year == 0;
}

Future<YearMonthPick?> showYearMonthPicker(
  BuildContext context, {
  required DateTime current,
  required Set<DateTime> monthsWithGames,
  required String loadedSeason,
}) {
  return showModalBottomSheet<YearMonthPick>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    isScrollControlled: true,
    builder: (_) => _YearMonthSheet(
      current: current,
      monthsWithGames: monthsWithGames,
      loadedSeason: loadedSeason,
    ),
  );
}

class _YearMonthSheet extends StatefulWidget {
  const _YearMonthSheet({
    required this.current,
    required this.monthsWithGames,
    required this.loadedSeason,
  });

  final DateTime current;

  /// 지금 받아둔 시즌에서 경기가 있는 달.
  final Set<DateTime> monthsWithGames;

  /// [monthsWithGames]가 어느 시즌 것인지. 다른 시즌의 달은 경기가 있는지
  /// 알 수 없으므로 흐리게 하지 않는다 — 모르는 걸 없다고 표시하면 안 된다.
  final String loadedSeason;

  @override
  State<_YearMonthSheet> createState() => _YearMonthSheetState();
}

class _YearMonthSheetState extends State<_YearMonthSheet> {
  late int _year = widget.current.year;

  /// 받아둔 시즌 밖이면 `true`(모름)로 둬서 흐려지지 않게 한다.
  bool _hasGames(int year, int month) {
    if (Season.at(DateTime(year, month)).year != widget.loadedSeason) {
      return true;
    }
    return widget.monthsWithGames.contains(DateTime(year, month));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mh;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(MhSpacing.gutter, 12,
            MhSpacing.gutter, 28),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('연·월 선택',
                    style: MhText.custom(
                        size: 18, weight: FontWeight.w700, color: c.text)),
                MhTap(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      Navigator.of(context).pop(const YearMonthPick.today()),
                  child: Text('이번 달',
                      style: MhText.custom(
                          size: 13,
                          weight: FontWeight.w600,
                          color: MhColors.brand)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _YearArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => setState(() => _year--),
                ),
                const SizedBox(width: 28),
                SizedBox(
                  width: 80,
                  child: Text('$_year년',
                      textAlign: TextAlign.center,
                      style: MhText.custom(
                          size: 22, weight: FontWeight.w800, color: c.text)),
                ),
                const SizedBox(width: 28),
                _YearArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => setState(() => _year++),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: MhSpacing.xs,
              crossAxisSpacing: MhSpacing.xs,
              // 시안 셀 높이 48
              childAspectRatio:
                  ((MediaQuery.sizeOf(context).width - 48 - 24) / 4) / 48,
              children: [
                for (var m = 1; m <= 12; m++)
                  _MonthCell(
                    month: m,
                    selected: _year == widget.current.year &&
                        m == widget.current.month,
                    // 경기가 없는 걸 확인한 달만 흐리게. 눌러도 빈 화면이라
                    // 미리 알려주는 편이 낫다.
                    hasGames: _hasGames(_year, m),
                    onTap: () =>
                        Navigator.of(context).pop(YearMonthPick(_year, m)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _YearArrow extends StatelessWidget {
  const _YearArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: c.card, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: c.text),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.month,
    required this.selected,
    required this.hasGames,
    required this.onTap,
  });

  final int month;
  final bool selected;
  final bool hasGames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: onTap,
      child: Opacity(
        opacity: selected || hasGames ? 1 : 0.4,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? MhColors.brand : c.card,
            border: Border.all(
              color: selected ? MhColors.brand : c.border,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text('$month월',
              style: MhText.custom(
                size: 15,
                weight: FontWeight.w700,
                color: selected ? Colors.white : c.text,
              )),
        ),
      ),
    );
  }
}

/// 연·월 선택 바텀시트를 띄우고 고른 값을 반영한다.
Future<void> pickYearMonth(
  BuildContext context,
  ScheduleState state,
  ScheduleViewModel vm,
) async {
  final picked = await showYearMonthPicker(
    context,
    current: state.month,
    monthsWithGames: state.monthsWithGames,
    loadedSeason: state.season,
  );
  if (picked == null) return;
  if (picked.isToday) {
    await vm.resetMonth();
  } else {
    await vm.setYearMonth(picked.year, picked.month);
  }
}
