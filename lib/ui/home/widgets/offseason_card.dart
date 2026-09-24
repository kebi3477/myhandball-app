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
/// 구조는 시안 그대로다: **작은 브랜드 라벨 → 큰 숫자 → 설명 → 버튼.**
/// 큰 자리에 무엇이 들어가는지는 개막일을 아는지에 따라 셋으로 갈린다
/// ([_Headline]).
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
            Text(state.nextSeasonLabel,
                style: MhText.custom(
                    size: 12, weight: FontWeight.w700, color: MhColors.brand)),
            const SizedBox(height: _gap),
            _Headline(state: state),
            const SizedBox(height: _gap),
            Text(
              state.offseasonNote,
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

/// 카드 가운데의 큰 글자.
///
/// 연맹이 다음 시즌 일정을 올리기 전에는 **개막일을 알 방법이 없다.**
/// 그래도 개막 달은 정해져 있어서(남자부 11월, 여자부 1월) 달까지는 말할
/// 수 있다. 날짜를 지어내지 않으면서 큰 자리에 숫자를 유지한다.
class _Headline extends StatelessWidget {
  const _Headline({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final days = state.daysToOpening;

    // 1. 개막일을 안다 — 시안 그대로 D-day.
    if (days != null) {
      return Text('D-$days',
          style: mhDisplay(size: 44, color: c.text, height: 1.1));
    }

    // 2. 개막 달에 들어섰는데 아직 일정이 없다.
    if (state.isOpeningMonth) {
      return Text('이번 달',
          style: MhText.custom(
              size: 32, weight: FontWeight.w800, color: c.text, height: 1.1));
    }

    // 3. 개막 달만 안다. **숫자와 "월"을 따로 그린다** — 디스플레이 폰트에
    // 한글이 없어서 한 덩어리로 쓰면 "월"만 다른 글꼴로 대체되고 크기가
    // 어긋난다.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('${state.openingMonth}',
            style: mhDisplay(size: 44, color: c.text, height: 1.1)),
        const SizedBox(width: 2),
        Text('월',
            style: MhText.custom(
                size: 20, weight: FontWeight.w800, color: c.text)),
      ],
    );
  }
}
