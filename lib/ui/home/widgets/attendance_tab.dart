import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../domain/models/attendance.dart';
import '../../../domain/models/game.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/external_actions.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../../game_detail/widgets/game_detail_screen.dart';
import '../view_models/attendance_view_model.dart';
import 'attendance_picker_sheet.dart';
import 'section_header.dart';

/// 홈 · 직관 탭.
///
/// 시안 순서: 시즌 요약(브랜드 카드) → 경기장 도장깨기 → 다음 직관 어때요?
/// → 직관 일지.
class AttendanceTab extends ConsumerWidget {
  const AttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final async = ref.watch(attendanceViewModelProvider);
    final vm = ref.read(attendanceViewModelProvider.notifier);

    return async.when(
      skipLoadingOnReload: true,
      loading: () =>
          const Center(child: CircularProgressIndicator(color: MhColors.brand)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(MhSpacing.gutter),
          child: Text(mhErrorMessage(e),
              textAlign: TextAlign.center, style: MhText.meta(c.textSub)),
        ),
      ),
      data: (state) => RefreshIndicator(
        color: MhColors.brand,
        backgroundColor: c.card,
        onRefresh: vm.refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: MhSpacing.xl),
          children: [
            _SummaryCard(state: state),
            const SizedBox(height: MhSpacing.md),
            _StampSection(state: state),
            const SizedBox(height: MhSpacing.md),
            _NextGamesSection(state: state),
            const SizedBox(height: MhSpacing.md),
            _JournalSection(state: state),
          ],
        ),
      ),
    );
  }
}

/// 시안 브랜드 카드 — 큰 숫자 + 3칸 지표.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final AttendanceState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          color: MhColors.brand,
          borderRadius: BorderRadius.circular(MhRadius.card),
          // 시안 `box-shadow: 0 4px 0 #0050C8`
          boxShadow: const [
            BoxShadow(color: MhColors.brandShadow, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.seasonLabel, style: _onBrand(12, w: 700)),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('${state.count}',
                              style: mhDisplay(
                                  size: 48, color: Colors.white, height: 1.05)),
                          const SizedBox(width: 4),
                          Text('경기',
                              style: MhText.custom(
                                  size: 16,
                                  weight: FontWeight.w800,
                                  color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(state.cheerLine, style: _onBrand(12, w: 600)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                TeamLogo(size: 56, logoUrl: state.team?.logoUrl, inset: 0.76),
              ],
            ),
            const SizedBox(height: MhSpacing.sm),
            Row(
              children: [
                _Metric(value: state.wdlLabel, label: '응원 승·무·패'),
                const SizedBox(width: MhSpacing.xs),
                _Metric(
                    value: state.rateLabel,
                    label: '직관 승률',
                    color: MhColors.guideYellow),
                const SizedBox(width: MhSpacing.xs),
                _Metric(value: state.teamRateLabel, label: '팀 시즌 승률'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _onBrand(double size, {required int w}) => MhText.custom(
        size: size,
        weight: FontWeight.values[w ~/ 100 - 1],
        color: Colors.white.withValues(alpha: 0.85),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: MhText.custom(
                    size: 17,
                    weight: FontWeight.w800,
                    color: color ?? Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: MhText.custom(
                    size: 11,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }
}

/// 시안 "경기장 도장깨기" — 4열 그리드.
class _StampSection extends StatelessWidget {
  const _StampSection({required this.state});

  final AttendanceState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    if (state.stamps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '경기장 도장깨기',
          trailing: Text(state.stampCountLabel,
              style: MhText.custom(
                  size: 12, weight: FontWeight.w700, color: MhColors.brand)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: MhSpacing.sm),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: state.stamps.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 6,
                // 52px 배지 + 6 gap + 두 줄짜리 이름.
                mainAxisExtent: 86,
              ),
              itemBuilder: (_, i) => _Stamp(stamp: state.stamps[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.stamp});

  final VenueStamp stamp;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Column(
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 안 가본 곳은 흐리고 회색이다. 목표라는 게 보여야 한다.
              Opacity(
                opacity: stamp.visited ? 1 : 0.4,
                child: ColorFiltered(
                  colorFilter: stamp.visited
                      ? const ColorFilter.mode(
                          Colors.transparent, BlendMode.dst)
                      : const ColorFilter.matrix(_grayscale),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stamp.visited ? MhColors.brand : c.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: TeamLogo(
                          size: 44, logoUrl: stamp.logoUrl, inset: 0.7),
                    ),
                  ),
                ),
              ),
              if (stamp.visited)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: MhColors.brand,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.card, width: 2),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text('${stamp.times}',
                          style: MhText.custom(
                              size: 10,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stamp.venue,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: MhText.custom(
            size: 10,
            weight: FontWeight.w600,
            color: stamp.visited ? c.text : c.textFaint,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  /// 회색조 변환 행렬. `filter: grayscale(1)`.
  static const _grayscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

/// 시안 "다음 직관 어때요?"
class _NextGamesSection extends StatelessWidget {
  const _NextGamesSection({required this.state});

  final AttendanceState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '다음 직관 어때요?',
          trailing: Text('${state.team?.name ?? '마이팀'} 경기',
              style: MhText.custom(
                  size: 11, weight: FontWeight.w500, color: c.textNeutral)),
        ),
        const SizedBox(height: 12),
        if (state.upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(MhRadius.card),
              ),
              child: Text('개막 일정이 나오면 여기에서 알려드릴게요',
                  textAlign: TextAlign.center, style: MhText.meta(c.textSub)),
            ),
          )
        else
          for (final game in state.upcoming) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
              child: _NextGameRow(game: game, myTeamName: state.team?.name),
            ),
            const SizedBox(height: MhSpacing.xs),
          ],
      ],
    );
  }
}

class _NextGameRow extends StatelessWidget {
  const _NextGameRow({required this.game, required this.myTeamName});

  final Game game;
  final String? myTeamName;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final isHome = game.home.name == myTeamName;
    final opponent = isHome ? game.away : game.home;
    final at = game.startsAt;

    return MhTap(
      onTap: () => GameDetailScreen.open(context, game),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(MhRadius.card),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Column(
                children: [
                  Text(game.ddayLabel ?? '',
                      style: MhText.custom(
                          size: 11,
                          weight: FontWeight.w700,
                          color: MhColors.brand)),
                  const SizedBox(height: 2),
                  Text(at == null ? '-' : '${at.day}',
                      style: mhDisplay(size: 22, color: c.text, height: 1)),
                  const SizedBox(height: 2),
                  Text(at == null ? '' : '${at.month}월',
                      style: MhText.custom(
                          size: 10,
                          weight: FontWeight.w500,
                          color: c.textSub)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 44, color: c.border),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isHome ? MhColors.brand : c.textSub),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(isHome ? '홈' : '원정',
                            style: MhText.custom(
                                size: 10,
                                weight: FontWeight.w800,
                                color: isHome ? MhColors.brand : c.textSub)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('vs ${opponent.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MhText.custom(
                                size: 14,
                                weight: FontWeight.w700,
                                color: c.text)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${game.meta} · ${game.venue ?? '경기장 미정'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MhText.custom(
                          size: 11,
                          weight: FontWeight.w500,
                          color: c.textSub)),
                ],
              ),
            ),
            const SizedBox(width: MhSpacing.xs),
            MhTap(
              haptic: MhHaptic.impact,
              onTap: () => openExternalUrl(context, AppConfig.ticketUrl),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: MhColors.brand,
                  borderRadius: BorderRadius.circular(MhRadius.chip),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text('예매',
                      style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}

/// 시안 "직관 일지" — 왼쪽 날짜, 가운데 타임라인, 오른쪽 카드.
class _JournalSection extends ConsumerWidget {
  const _JournalSection({required this.state});

  final AttendanceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '직관 일지',
          trailing: MhTap(
            onTap: () => AttendancePickerSheet.open(context),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('+',
                      style: MhText.custom(
                          size: 15, weight: FontWeight.w700, color: c.text)),
                  const SizedBox(width: 4),
                  Text('기록 추가',
                      style: MhText.custom(
                          size: 12, weight: FontWeight.w700, color: c.text)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (state.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(MhRadius.card),
              ),
              child: Column(
                children: [
                  Text('아직 직관 기록이 없어요',
                      style: MhText.custom(
                          size: 14, weight: FontWeight.w700, color: c.text)),
                  const SizedBox(height: 6),
                  Text('다녀온 경기를 골라 첫 도장을 찍어 보세요',
                      style: MhText.meta(c.textSub)),
                  const SizedBox(height: MhSpacing.xs),
                  MhTap(
                    haptic: MhHaptic.impact,
                    onTap: () => AttendancePickerSheet.open(context),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: MhColors.brand,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text('경기 고르기',
                            style: MhText.custom(
                                size: 13,
                                weight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
            child: Column(
              children: [
                for (var i = 0; i < state.entries.length; i++)
                  _JournalRow(
                    entry: state.entries[i],
                    isFirst: i == 0,
                    isLast: i == state.entries.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  final AttendanceEntry entry;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final at = entry.at;
    final chip = _chipColor(entry.result, c.textFaint);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(at == null ? '-' : '${at.month}.${at.day}',
                      style: MhText.custom(
                          size: 13, weight: FontWeight.w800, color: c.text)),
                  Text(at == null ? '' : _weekday(at),
                      style: MhText.custom(
                          size: 10,
                          weight: FontWeight.w500,
                          color: c.textSub)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 14,
            child: Column(
              children: [
                Container(
                    width: 2,
                    height: 18,
                    color: isFirst ? Colors.transparent : c.border),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: chip),
                ),
                Expanded(
                  child: Container(
                      width: 2, color: isLast ? Colors.transparent : c.border),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: MhTap(
                onTap: () => GameDetailScreen.open(context, entry.game),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(MhRadius.chip),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: chip,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(entry.result.label,
                                      style: MhText.custom(
                                          size: 11,
                                          weight: FontWeight.w800,
                                          color: Colors.white)),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(entry.matchLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: MhText.custom(
                                          size: 13,
                                          weight: FontWeight.w700,
                                          color: c.text)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(entry.venue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MhText.custom(
                                    size: 11,
                                    weight: FontWeight.w500,
                                    color: c.textSub)),
                          ],
                        ),
                      ),
                      const SizedBox(width: MhSpacing.xs),
                      Text(entry.scoreLabel,
                          style: mhDisplay(size: 18, color: c.text)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _chipColor(AttendanceResult result, Color fallback) =>
      switch (result) {
        AttendanceResult.win => MhColors.brand,
        AttendanceResult.loss => const Color(0xFFFF4D6A),
        AttendanceResult.draw => const Color(0xFF8A8A8A),
        AttendanceResult.unknown => fallback,
      };

  static String _weekday(DateTime at) =>
      const ['월', '화', '수', '목', '금', '토', '일'][at.weekday - 1];
}
