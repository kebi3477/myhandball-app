import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/badge.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../../guide/view_models/guide_progress.dart';
import '../../guide/widgets/guide_screen.dart';
import '../../home/view_models/home_tab.dart';
import '../../shell/view_models/shell_view_model.dart';
import '../view_models/my_view_model.dart';

/// MY "내 배지" — 3열 그리드. 시안 `myBadges`.
///
/// 예전의 "수료 배지" 카드 한 장을 대신한다. 딴 것만 보여주는 게 아니라
/// **아직 못 딴 것도 흐리게 깔고 진행바를 보여준다** — 목표가 보여야
/// 채우러 간다.
class MyBadgesSection extends ConsumerWidget {
  const MyBadgesSection({super.key, required this.state});

  final MyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;

    final badges = MhBadges.evaluate(
      guideDone: ref.watch(guideDoneCountProvider),
      attended: state.attendance.length,
      // 같은 경기장을 여러 번 가도 한 곳으로 센다.
      venues: state.attendance.map((a) => a.venue).toSet().length,
      predictionHits: state.predictionHits,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('내 배지', style: MhText.sectionTitle(c.text)),
              Text(MhBadges.countLabel(badges),
                  style: MhText.custom(
                      size: 12, weight: FontWeight.w700, color: c.textSub)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: MhSpacing.xs,
              crossAxisSpacing: MhSpacing.xs,
              // 메달 53 + 이름 + 진행바/문구.
              mainAxisExtent: 148,
            ),
            itemBuilder: (_, i) => _BadgeTile(badge: badges[i]),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends ConsumerWidget {
  const _BadgeTile({required this.badge});

  final MhBadge badge;

  /// 획득한 배지의 카드 배경·글자색. 시안 그대로다.
  static const _earnedBg = Color(0xFFFFF4CC);
  static const _earnedName = Color(0xFF6B4500);
  static const _earnedSub = Color(0xFF8A6A00);
  static const _barColor = Color(0xFFFFC800);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final earned = badge.earned;

    return MhTap(
      onTap: () => _open(ref, context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, MhSpacing.sm, 8, 14),
        decoration: BoxDecoration(
          color: earned ? _earnedBg : c.card,
          borderRadius: BorderRadius.circular(MhRadius.card),
        ),
        child: Column(
          children: [
            // 못 딴 배지는 흐리고 회색이다 (시안 `b.op` / `b.filter`).
            Opacity(
              opacity: earned ? 1 : 0.35,
              child: ColorFiltered(
                colorFilter: earned
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix(_grayscale),
                child: MhMedal(
                  size: 44,
                  glyph: badge.spec.glyph,
                  colors: badge.spec.colors,
                  // 시안의 배지 메달에는 곡선 장식이 없다. 가이드 화면
                  // 메달에만 있다.
                  arcs: false,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.spec.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MhText.custom(
                size: 13,
                weight: FontWeight.w800,
                color: earned ? _earnedName : c.text,
              ),
            ),
            const SizedBox(height: 6),
            if (earned)
              Text(badge.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MhText.custom(
                      size: 11, weight: FontWeight.w600, color: _earnedSub))
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: badge.ratio,
                        minHeight: 5,
                        backgroundColor: c.border,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_barColor),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(badge.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MhText.custom(
                            size: 11,
                            weight: FontWeight.w500,
                            color: c.textSub)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _open(WidgetRef ref, BuildContext context) {
    switch (badge.spec.target) {
      case MhBadgeTarget.guide:
        GuideScreen.open(context);
      case MhBadgeTarget.attendance:
        ref.read(homeTabProvider.notifier).select(HomeTab.attendance);
        ref.read(shellViewModelProvider.notifier).select(ShellTab.home);
      case MhBadgeTarget.prediction:
        ref.read(homeTabProvider.notifier).select(HomeTab.prediction);
        ref.read(shellViewModelProvider.notifier).select(ShellTab.home);
    }
  }

  /// `filter: grayscale(1)`.
  static const _grayscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}
