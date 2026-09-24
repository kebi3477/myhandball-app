import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../schedule/view_models/schedule_view_model.dart';
import '../../shell/view_models/shell_view_model.dart';
import '../view_models/my_view_model.dart';

/// 다음 경기 카드 — D-day 칩 + 팀 VS 상대 + 장소·시간.
class MyNextGameCard extends ConsumerWidget {
  const MyNextGameCard({super.key, required this.state});

  final MyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final game = state.nextGame;
    final myName = state.team?.name ?? '';
    final opponent = game == null
        ? ''
        : (game.home.name == myName ? game.away.name : game.home.name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('다음 경기', style: MhText.sectionTitle(c.text)),
              MhTap(
                onTap: () {
                  ref
                      .read(shellViewModelProvider.notifier)
                      .select(ShellTab.schedule);
                  ref
                      .read(scheduleViewModelProvider.notifier)
                      .setView(ScheduleView.calendar);
                },
                child: Text('MY팀 달력 >', style: MhText.meta(c.textFaint)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: game == null
                ? Text(
                    '예정된 경기가 없어요',
                    textAlign: TextAlign.center,
                    style: MhText.custom(
                      size: 14,
                      weight: FontWeight.w600,
                      color: c.textSub,
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: MhColors.brand,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _dday(game.meta),
                              style: MhText.custom(
                                size: 12,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(game.meta, style: MhText.meta(c.textSub)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              myName,
                              textAlign: TextAlign.center,
                              style: MhText.custom(
                                size: 17,
                                weight: FontWeight.w700,
                                color: c.text,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: MhSpacing.xs,
                            ),
                            child: Text(
                              'VS',
                              style: MhText.custom(
                                size: 14,
                                weight: FontWeight.w600,
                                color: c.textFaint,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              opponent,
                              textAlign: TextAlign.center,
                              style: MhText.custom(
                                size: 17,
                                weight: FontWeight.w700,
                                color: c.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: c.border)),
                        ),
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          '${game.venue ?? '경기장 미정'} · ${game.meta}',
                          textAlign: TextAlign.center,
                          style: MhText.meta(c.textSub),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// 목업 일정은 시각 문자열만 주므로 날짜 계산 없이 "다음 경기"로 둔다.
  /// 실제 API 연동 후 `dateISO`로 D-day를 계산한다.
  String _dday(String meta) => '다음 경기';
}
