import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../domain/badge_service.dart';
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

/// MY "내 배지" — 3칸 그리드. **MY 탭에서만 보여준다.**
///
/// 예전의 "입문 수료" 카드 한 장을 대신한다. 딴 것만 보여주는 게 아니라
/// 못 딴 것도 흑백으로 깔고 진행바를 보여준다 — 목표가 보여야 채우러 간다.
///
/// 판정은 [BadgeService] 한 곳에 있다. 조건과 획득일이 나중에 서버 기준으로
/// 바뀌기 때문이다.
class MyBadgesSection extends ConsumerWidget {
  const MyBadgesSection({super.key, required this.state});

  final MyState state;

  /// 승·패만 센다. 무승부와 "관람"(마이팀이 안 뛰었거나 점수가 없는 경기)은
  /// 승리 요정 계산에서 빠진다.
  int _count(String result) =>
      state.attendance.where((a) => a.result == result).length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final rank = state.rank;

    final badges = const BadgeService().evaluate(
      guideDone: ref.watch(guideDoneCountProvider),
      guideCompletedAt:
          ref.watch(preferencesRepositoryProvider).guideCompletedAt,
      attendanceWins: _count('승'),
      attendanceLosses: _count('패'),
      teamWins: rank?.wins ?? 0,
      teamLosses: rank?.losses ?? 0,
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
              Text('내 배지',
                  style: MhText.custom(
                      size: 16, weight: FontWeight.w700, color: c.text)),
              Text(MhBadge.countLabel(badges),
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
              // 패딩 16+14 + 메달 53 + 이름 + 진행바 + 문구.
              mainAxisExtent: 150,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final style = badge.style;
    final earned = badge.earned;

    return MhTap(
      onTap: () => _open(ref, context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, MhSpacing.sm, 8, 14),
        decoration: BoxDecoration(
          color: earned ? style.cardBg : c.card,
          borderRadius: BorderRadius.circular(MhRadius.card),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 못 딴 배지는 흑백에 흐리다.
            Opacity(
              opacity: earned ? 1 : 0.35,
              child: ColorFiltered(
                colorFilter: earned
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix(_grayscale),
                child: MhMedal(
                  size: 44,
                  glyph: style.glyph,
                  arcs: false,
                  colors: MhMedalColors(
                    ribbonLeft: style.ribbonLeft,
                    ribbonRight: style.ribbonRight,
                    rim: style.rim,
                    outer: style.coin,
                    inner: style.inner,
                    glyphStrokeWidth: style.glyphStrokeWidth,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MhText.custom(
                size: 13,
                weight: FontWeight.w800,
                color: earned ? style.nameColor : c.text,
              ),
            ),
            const SizedBox(height: 6),
            if (!earned) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: badge.ratio,
                  minHeight: 5,
                  backgroundColor: c.border,
                  valueColor: AlwaysStoppedAnimation<Color>(style.accent),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              badge.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MhText.custom(
                size: 11,
                weight: FontWeight.w600,
                color: earned ? style.nameColor : c.textSub,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(WidgetRef ref, BuildContext context) {
    switch (badge.kind.target) {
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
