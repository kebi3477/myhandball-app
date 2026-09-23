import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../view_models/home_view_model.dart';

/// 시안 `isOffseason` — 치를 경기가 없을 때 "가까운 경기" 자리에 들어간다.
///
/// 비시즌에 지난 경기만 늘어놓으면 앱이 멈춘 것처럼 보인다. 개막까지 남은
/// 날을 대신 보여준다.
///
/// **개막일은 연맹이 다음 시즌 일정을 올려야 알 수 있다.** 아직이면 D-day를
/// 빼고 안내만 남긴다 — 지어낸 날짜를 띄우는 것보다 낫다.
class OffseasonCard extends StatelessWidget {
  const OffseasonCard({
    super.key,
    required this.state,
    required this.onSeeSchedule,
  });

  final HomeState state;
  final VoidCallback onSeeSchedule;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final days = state.daysToOpening;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(MhRadius.card),
        ),
        child: Column(
          children: [
            if (days != null) ...[
              Text(state.nextSeasonLabel,
                  style: MhText.custom(
                      size: 12,
                      weight: FontWeight.w700,
                      color: MhColors.brand)),
              const SizedBox(height: 6),
              Text('D-$days',
                  style: mhDisplay(size: 44, color: c.text, height: 1.1)),
              const SizedBox(height: 6),
            ] else ...[
              Text('다음 시즌을 기다리는 중',
                  style: MhText.custom(
                      size: 15, weight: FontWeight.w800, color: c.text)),
              const SizedBox(height: 6),
            ],
            Text(
              days != null
                  ? '지금은 비시즌이에요 · ${state.openingLabel}'
                  : '지금은 비시즌이에요 · 개막 일정이 아직 안 나왔어요',
              textAlign: TextAlign.center,
              style: MhText.custom(
                  size: 13, weight: FontWeight.w400, color: c.textSub),
            ),
            const SizedBox(height: MhSpacing.xs),
            MhTap(
              onTap: onSeeSchedule,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text('지난 시즌 일정 보기',
                      style: MhText.custom(
                          size: 13, weight: FontWeight.w700, color: c.text)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
