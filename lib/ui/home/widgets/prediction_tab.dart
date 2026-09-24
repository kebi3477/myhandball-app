import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/game_detail.dart';
import '../../../domain/models/prediction.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../../game_detail/widgets/game_detail_screen.dart';
import '../view_models/prediction_view_model.dart';
import 'profile_sheet.dart';
import 'section_header.dart';

/// 홈 · 승부예측 탭.
///
/// 시안 순서: 프로필 → 이번 주 예측 → 적중률 랭킹 → 팬덤 적중률 →
/// 내 예측 기록.
///
/// 랭킹·팬덤은 서버 집계다 (`/api/prediction/{leaderboard,fandom}`).
/// **못 받았을 때 빈 랭킹을 그리지 않는다** — "아직 아무도 없다"와
/// "연결이 안 됐다"가 같은 화면이 되면 안 된다.
class PredictionTab extends ConsumerWidget {
  const PredictionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final async = ref.watch(predictionViewModelProvider);
    final vm = ref.read(predictionViewModelProvider.notifier);

    return async.when(
      skipLoadingOnReload: true,
      loading: () =>
          const Center(child: CircularProgressIndicator(color: MhColors.brand)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(MhSpacing.gutter),
          child: Text(
            mhErrorMessage(e),
            textAlign: TextAlign.center,
            style: MhText.meta(c.textSub),
          ),
        ),
      ),
      data: (state) => RefreshIndicator(
        color: MhColors.brand,
        backgroundColor: c.card,
        onRefresh: vm.refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: MhSpacing.xl),
          children: [
            _ProfileCard(state: state),
            const SizedBox(height: MhSpacing.md),
            _WeekSection(state: state),
            const SizedBox(height: MhSpacing.md),
            _RankingSection(state: state),
            const SizedBox(height: MhSpacing.md),
            _FandomSection(state: state),
            const SizedBox(height: MhSpacing.md),
            _HistorySection(state: state),
          ],
        ),
      ),
    );
  }
}

/// 시안 `pv.hasProfile` / `pv.noProfile`.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.state});

  final PredictionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;

    if (!state.hasProfile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(MhRadius.card),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '닉네임 하나로 랭킹에 참여해요',
                      style: MhText.custom(
                        size: 15,
                        weight: FontWeight.w800,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: MhSpacing.xs2),
                    Text(
                      '닉네임과 응원팀만 정하면 적중률 랭킹에 이름이 올라가요',
                      style: MhText.custom(
                        size: 12,
                        weight: FontWeight.w500,
                        color: c.textSub,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              MhTap(
                haptic: MhHaptic.impact,
                onTap: () => showProfileSheet(context),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: MhColors.brand,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      '시작하기',
                      style: MhText.custom(
                        size: 13,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: MhTap(
        // 시안 — 카드를 누르면 프로필 편집 시트가 열린다.
        onTap: () => showProfileSheet(context),
        child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(MhRadius.card),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: MhColors.brand, width: 2),
                  ),
                  child: Center(
                    child: TeamLogo(
                      size: 46,
                      logoUrl: state.teamLogoUrl,
                      inset: 0.74,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MhText.custom(
                          size: 17,
                          weight: FontWeight.w800,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          '${state.teamName} 팬',
                          if (state.joinedLabel case final j?) '$j 가입',
                        ].join(' · '),
                        style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w500,
                          color: c.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  _Stat(
                    value: state.rateLabel,
                    label: '적중률',
                    color: MhColors.brand,
                  ),
                  _Stat(value: state.recordLabel, label: '적중 / 확정'),
                  _Stat(value: state.myRankLabel, label: state.myRankSub),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: MhText.custom(
              size: 20,
              weight: FontWeight.w800,
              color: color ?? c.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: MhText.custom(
              size: 11,
              weight: FontWeight.w500,
              color: c.textSub,
            ),
          ),
        ],
      ),
    );
  }
}

/// 시안 "이번 주 예측".
class _WeekSection extends ConsumerWidget {
  const _WeekSection({required this.state});

  final PredictionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final vm = ref.read(predictionViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '이번 주 예측',
          trailing: Text(
            state.openLabel,
            style: MhText.custom(
              size: 12,
              weight: FontWeight.w600,
              color: state.isOffseason ? c.textSub : MhColors.brand,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
          child: Row(
            children: [
              for (final d in PredictionDivision.values) ...[
                if (d != PredictionDivision.values.first)
                  const SizedBox(width: MhSpacing.xs),
                _Chip(
                  label: d.label,
                  selected: state.division == d,
                  onTap: () => vm.selectDivision(d),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (state.rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(MhRadius.card),
              ),
              child: Column(
                children: [
                  Text(
                    state.isOffseason
                        ? '비시즌에는 예측이 열리지 않아요'
                        : '이번 주에 예측할 경기가 없어요',
                    style: MhText.custom(
                      size: 14,
                      weight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: MhSpacing.xs2),
                  Text('개막 라운드부터 새 랭킹이 시작돼요', style: MhText.meta(c.textSub)),
                ],
              ),
            ),
          )
        else
          for (final row in state.rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
              child: _PredictionCard(
                row: row,
                myTeamName: state.team?.name,
                hasProfile: state.hasProfile,
              ),
            ),
            const SizedBox(height: 12),
          ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
          child: Text(
            '경기 시작 전까지 바꿀 수 있어요 · 경기 종료 후 적중 여부가 반영돼요',
            textAlign: TextAlign.center,
            style: MhText.custom(
              size: 11,
              weight: FontWeight.w500,
              color: c.textFaint,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? MhColors.brand : c.card,
          borderRadius: BorderRadius.circular(MhRadius.chip),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: MhText.custom(
              size: 13,
              weight: FontWeight.w600,
              color: selected ? Colors.white : c.textSub,
            ),
          ),
        ),
      ),
    );
  }
}

/// 경기 하나짜리 예측 카드 — 홈/무/원정 3칸 + 분포 막대.
class _PredictionCard extends ConsumerWidget {
  const _PredictionCard({
    required this.row,
    required this.myTeamName,
    required this.hasProfile,
  });

  final PredictionRow row;
  final String? myTeamName;

  /// 랭킹 프로필이 있는지. 없으면 고르기 전에 시트를 먼저 연다.
  final bool hasProfile;

  /// 시안 `pickPredFor` — 프로필이 없으면 고른 값을 들고 시트를 열고,
  /// 만들고 나면 **그 선택을 그대로 이어서** 저장한다. 시트를 닫아도
  /// 예측은 남기므로 "눌렀는데 아무 일도 없다"가 되지 않는다.
  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    PredictionPick choice,
  ) async {
    if (!hasProfile) await showProfileSheet(context);
    if (!context.mounted) return;
    await ref.read(predictionViewModelProvider.notifier).pick(row.game, choice);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final game = row.game;
    final isMine = game.home.name == myTeamName || game.away.name == myTeamName;

    return Container(
      padding: const EdgeInsets.all(MhSpacing.sm),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(MhRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Tag(
                label: game.home.gender.divisionLabel,
                color: c.textSub,
                borderColor: c.border,
              ),
              if (isMine) ...[
                const SizedBox(width: 6),
                const _Tag(
                  label: 'MY팀',
                  color: MhColors.brand,
                  borderColor: MhColors.brand,
                ),
              ],
              const SizedBox(width: 6),
              Expanded(
                child: MhTap(
                  onTap: () => GameDetailScreen.open(context, game),
                  child: Text(
                    '${game.meta} ›',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MhText.custom(
                      size: 12,
                      weight: FontWeight.w600,
                      color: c.textSub,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: MhSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: row.open
                      ? MhColors.brand.withValues(alpha: 0.14)
                      : c.borderSubtle,
                  borderRadius: BorderRadius.circular(MhRadius.pill / 2),
                ),
                child: Text(
                  row.stateLabel,
                  style: MhText.custom(
                    size: 10,
                    weight: FontWeight.w700,
                    color: row.open ? MhColors.brand : c.textSub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // **`IntrinsicHeight`가 있어야 한다.** 세 칸의 높이를 맞추려고
          // `CrossAxisAlignment.stretch`를 쓰는데, Row의 높이가 정해지지
          // 않은 자리(스크롤 안의 Column)에서 stretch는 무한 높이를 요구해
          // 레이아웃이 터진다.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Option(
                    label: game.home.name,
                    logoUrl: game.home.logoUrl,
                    selected: row.myPick == PredictionPick.home,
                    enabled: row.open,
                    onTap: () => _pick(context, ref, PredictionPick.home),
                  ),
                ),
                const SizedBox(width: MhSpacing.xs),
                SizedBox(
                  width: 64,
                  child: _Option(
                    label: '무승부',
                    selected: row.myPick == PredictionPick.draw,
                    enabled: row.open,
                    onTap: () => _pick(context, ref, PredictionPick.draw),
                  ),
                ),
                const SizedBox(width: MhSpacing.xs),
                Expanded(
                  child: _Option(
                    label: game.away.name,
                    logoUrl: game.away.logoUrl,
                    selected: row.myPick == PredictionPick.away,
                    enabled: row.open,
                    onTap: () => _pick(context, ref, PredictionPick.away),
                  ),
                ),
              ],
            ),
          ),
          if (row.showDistribution) ...[
            const SizedBox(height: 14),
            _Distribution(tally: row.tally!),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.borderColor,
  });

  final String label;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: MhText.custom(size: 10, weight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.logoUrl,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      haptic: enabled ? MhHaptic.impact : MhHaptic.none,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled || selected ? 1 : 0.5,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: MhSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? MhColors.brand.withValues(alpha: 0.12) : c.bg,
            border: Border.all(
              color: selected ? MhColors.brand : c.border,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (logoUrl != null) ...[
                TeamLogo(size: 32, logoUrl: logoUrl),
                const SizedBox(height: 6),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: MhText.custom(
                  size: 12,
                  weight: FontWeight.w700,
                  color: selected ? MhColors.brand : c.text,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Distribution extends StatelessWidget {
  const _Distribution({required this.tally});

  final PredictionTally tally;

  static const _away = Color(0xFFFF7A45);

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final home = tally.percentFor(PredictionPick.home);
    final draw = tally.percentFor(PredictionPick.draw);
    final away = tally.percentFor(PredictionPick.away);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 6,
          child: Row(
            children: [
              Expanded(flex: home, child: _bar(MhColors.brand)),
              if (home > 0 && draw + away > 0) const SizedBox(width: 2),
              Expanded(flex: draw, child: _bar(c.textFaint)),
              if (draw > 0 && away > 0) const SizedBox(width: 2),
              Expanded(flex: away, child: _bar(_away)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$home%',
              style: MhText.custom(
                size: 11,
                weight: FontWeight.w700,
                color: MhColors.brand,
              ),
            ),
            Text(
              '무 $draw%',
              style: MhText.custom(
                size: 11,
                weight: FontWeight.w500,
                color: c.textSub,
              ),
            ),
            Text(
              '$away%',
              style: MhText.custom(
                size: 11,
                weight: FontWeight.w700,
                color: _away,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${tally.total}명 참여',
          textAlign: TextAlign.center,
          style: MhText.custom(
            size: 10,
            weight: FontWeight.w500,
            color: c.textFaint,
          ),
        ),
      ],
    );
  }

  Widget _bar(Color color) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

/// 시안 "내 예측 기록".
class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.state});

  final PredictionState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final rows = state.history.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '내 예측 기록',
          trailing: Text(
            '참여 ${state.count} · 적중 ${state.hits}',
            style: MhText.custom(
              size: 12,
              weight: FontWeight.w500,
              color: c.textNeutral,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      '아직 예측한 경기가 없어요',
                      textAlign: TextAlign.center,
                      style: MhText.meta(c.textSub),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < rows.length; i++)
                        _HistoryRow(row: rows[i], last: i == rows.length - 1),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.row, required this.last});

  final PredictionHistoryRow row;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final chip = row.settled
        ? (row.hit ? MhColors.brand : const Color(0xFFFF4D6A))
        : c.textFaint;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: last ? Colors.transparent : c.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: chip,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              row.chipLabel,
              textAlign: TextAlign.center,
              style: MhText.custom(
                size: 11,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.matchLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MhText.custom(
                    size: 13,
                    weight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                Text(
                  '내 예측: ${row.pickLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MhText.custom(
                    size: 11,
                    weight: FontWeight.w500,
                    color: c.textSub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MhSpacing.xs),
          Text(
            row.dateLabel,
            style: MhText.custom(
              size: 11,
              weight: FontWeight.w500,
              color: c.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

/// 시안 "적중률 랭킹".
class _RankingSection extends ConsumerWidget {
  const _RankingSection({required this.state});

  final PredictionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final vm = ref.read(predictionViewModelProvider.notifier);
    final board = state.leaderboard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '적중률 랭킹',
          trailing: Text(
            state.seasonLabel,
            style: MhText.custom(
              size: 11,
              weight: FontWeight.w500,
              color: c.textNeutral,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
          child: Row(
            children: [
              for (final scope in LeaderboardScope.values) ...[
                if (scope != LeaderboardScope.values.first)
                  const SizedBox(width: MhSpacing.xs),
                _Chip(
                  // '내 팀 팬'은 팀 이름을 넣어 부른다 (시안 `SK호크스 팬`).
                  label: scope == LeaderboardScope.team &&
                          state.teamName.isNotEmpty
                      ? '${state.teamName} 팬'
                      : scope.label,
                  selected: state.scope == scope,
                  onTap: () => vm.selectScope(scope),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: board == null
                ? _SectionError(onRetry: vm.refresh)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (board.rows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          child: Text(
                            state.scope == LeaderboardScope.team
                                ? '아직 이 팀 팬 중에 랭킹에 오른 사람이 없어요'
                                : '아직 랭킹에 오른 사람이 없어요',
                            textAlign: TextAlign.center,
                            style: MhText.meta(c.textSub),
                          ),
                        ),
                      for (final row in board.rows) _RankRow(row: row),
                      if (board.pinsMe) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '···',
                            textAlign: TextAlign.center,
                            style: MhText.custom(
                              size: 12,
                              weight: FontWeight.w400,
                              color: c.textFaint,
                            ).copyWith(letterSpacing: 3),
                          ),
                        ),
                        _RankRow(row: board.me!),
                      ],
                      if (board.meHint case final hint?) ...[
                        const SizedBox(height: 4),
                        MhTap(
                          onTap: state.hasProfile
                              ? null
                              : () => showProfileSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: c.border),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              hint,
                              textAlign: TextAlign.center,
                              style: MhText.custom(
                                size: 12,
                                weight: FontWeight.w500,
                                color: c.textSub,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        if (board != null) ...[
          const SizedBox(height: MhSpacing.xs2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
            child: Text(
              '확정 ${board.minSettled}경기 이상 참여자 대상 · 동률이면 참여 수가 많은 순 · '
              '참여 ${board.totalLabel}명',
              style: MhText.custom(
                size: 11,
                weight: FontWeight.w500,
                color: c.textFaint,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.row});

  final LeaderboardRow row;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: row.isMe ? MhColors.brand.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${row.rank}',
              textAlign: TextAlign.center,
              style: MhText.custom(
                size: 14,
                weight: FontWeight.w800,
                // 시안 — 1~3위와 내 줄만 브랜드색이다.
                color: row.isMe || row.rank <= 3 ? MhColors.brand : c.text,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TeamLogo(size: 32, logoUrl: row.teamLogoUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        row.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MhText.custom(
                          size: 14,
                          weight: FontWeight.w700,
                          color: row.isMe ? MhColors.brand : c.text,
                        ),
                      ),
                    ),
                    if (row.isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: MhColors.brand,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '나',
                          style: MhText.custom(
                            size: 9,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  row.teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MhText.custom(
                    size: 11,
                    weight: FontWeight.w400,
                    color: c.textSub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MhSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                row.rateLabel,
                style: MhText.custom(
                  size: 15,
                  weight: FontWeight.w800,
                  color: c.text,
                ),
              ),
              Text(
                row.recordLabel,
                style: MhText.custom(
                  size: 10,
                  weight: FontWeight.w400,
                  color: c.textSub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 시안 "팬덤 적중률" — 사용자 평균이 아니라 경기 수 가중 평균이다.
class _FandomSection extends ConsumerWidget {
  const _FandomSection({required this.state});

  final PredictionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final vm = ref.read(predictionViewModelProvider.notifier);
    final rows = state.fandom;
    // 막대 너비는 1위 대비 비율이다.
    final top = rows == null || rows.isEmpty
        ? 0.0
        : rows.map((r) => r.rate).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '팬덤 적중률',
          trailing: Text(
            '${state.fandomGender.divisionLabel} · 팬 평균',
            style: MhText.custom(
              size: 11,
              weight: FontWeight.w500,
              color: c.textNeutral,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: rows == null
                ? _SectionError(onRetry: vm.refresh)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (rows.every((r) => r.fans == 0))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            '아직 팬덤 적중률을 낼 만큼 기록이 모이지 않았어요',
                            textAlign: TextAlign.center,
                            style: MhText.meta(c.textSub),
                          ),
                        )
                      else
                        for (final row in rows)
                          _FandomRowView(
                            row: row,
                            ratio: top == 0 ? 0 : row.rate / top,
                            mine: row.teamNum == state.team?.teamNum,
                          ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _FandomRowView extends StatelessWidget {
  const _FandomRowView({
    required this.row,
    required this.ratio,
    required this.mine,
  });

  final FandomRow row;
  final double ratio;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final color = mine ? MhColors.brand : c.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '${row.rank}',
              textAlign: TextAlign.center,
              style: MhText.custom(
                  size: 13, weight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(width: 10),
          TeamLogo(size: 28, logoUrl: row.teamLogoUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MhText.custom(
                      size: 13, weight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: c.border,
                    valueColor: AlwaysStoppedAnimation(
                        mine ? MhColors.brand : c.textNeutral),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              row.rateLabel,
              textAlign: TextAlign.right,
              style: MhText.custom(
                  size: 13, weight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// 섹션 하나만 실패했을 때. 탭 전체를 오류로 덮지 않는다.
class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Text('집계를 불러오지 못했어요',
              style: MhText.custom(
                  size: 13, weight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 8),
          MhTap(
            haptic: MhHaptic.impact,
            onTap: onRetry,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Center(
                widthFactor: 1,
                child: Text('다시 시도',
                    style: MhText.custom(
                        size: 13, weight: FontWeight.w700, color: c.text)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
