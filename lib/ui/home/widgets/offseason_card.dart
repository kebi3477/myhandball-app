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
/// 시안 구조를 그대로 따른다: **작은 브랜드 라벨 → 큰 숫자 → 설명 → 버튼.**
/// 개막일은 연맹이 다음 시즌 일정을 올려야 알 수 있는데, 아직이면 큰 자리에
/// 시즌 이름을 넣는다 — 날짜를 지어내지 않으면서 리듬은 유지한다.
class OffseasonCard extends StatelessWidget {
  const OffseasonCard({
    super.key,
    required this.state,
    required this.onSeeSchedule,
  });

  final HomeState state;
  final VoidCallback onSeeSchedule;

  /// 시안 `gap:6`
  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final days = state.daysToOpening;
    final known = days != null;

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
            Text(known ? state.nextSeasonLabel : '다음 시즌',
                style: MhText.custom(
                    size: 12, weight: FontWeight.w700, color: MhColors.brand)),
            const SizedBox(height: _gap),
            Text(
              known ? 'D-$days' : state.nextSeasonName,
              style: mhDisplay(size: 44, color: c.text, height: 1.1),
            ),
            const SizedBox(height: _gap),
            Text(
              known
                  ? '지금은 비시즌이에요 · ${state.openingLabel}'
                  : '지금은 비시즌이에요 · 개막 일정이 아직 안 나왔어요',
              textAlign: TextAlign.center,
              style: MhText.custom(
                  size: 13, weight: FontWeight.w400, color: c.textSub),
            ),
            // 시안 버튼은 gap(6) 위에 margin-top(8)이 더 붙는다.
            const SizedBox(height: _gap + 8),
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
