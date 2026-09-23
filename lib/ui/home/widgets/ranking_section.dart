import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/gender.dart';
import '../../../domain/models/rank_row.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/home_view_model.dart';

/// 팀순위 — 남/여 토글 + 시상대(1~3위) + 나머지 리스트.
class RankingSection extends ConsumerWidget {
  const RankingSection({super.key, required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final vm = ref.read(homeViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('팀순위', style: MhText.sectionTitle(c.text)),
              Text('2026.05.26 업데이트',
                  style: MhText.custom(
                      size: 10,
                      weight: FontWeight.w400,
                      color: c.textNeutral)),
            ],
          ),
          const SizedBox(height: MhSpacing.xs),
          Row(
            children: [
              for (final g in Gender.values) ...[
                if (g != Gender.values.first) const SizedBox(width: 10),
                _GenderPill(
                  label: g.divisionLabel,
                  selected: state.gender == g,
                  onTap: () => vm.selectGender(g),
                ),
              ],
            ],
          ),
          const SizedBox(height: MhSpacing.xs),
          _Podium(rows: state.podium),
          const SizedBox(height: MhSpacing.md),
          for (final r in state.restOfRanking) ...[
            _RankRowTile(row: r),
            const SizedBox(height: MhSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _GenderPill extends StatelessWidget {
  const _GenderPill({
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? MhColors.brand : c.card,
          borderRadius: BorderRadius.circular(MhRadius.pill),
        ),
        child: Text(
          label,
          style: MhText.custom(
            size: 14,
            weight: FontWeight.w500,
            color: selected ? Colors.white : c.textSub,
          ),
        ),
      ),
    );
  }
}

/// 시안은 `height:257px` 안에 105px 카드 3장을 절대배치한다.
/// 1위가 가장 높고 2·3위가 내려앉는 구조.
///
/// 시안의 `left`/`top` 실제 값은 스크립트가 잘린 쪽에 있어 확인하지 못했다.
/// 화면 폭에 맞춰 2위 · 1위 · 3위 순으로 배치하고 1·2·3위를 40px 낮춘다.
class _Podium extends StatelessWidget {
  const _Podium({required this.rows});

  final List<RankRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.length < 3) return const SizedBox.shrink();
    final order = [rows[1], rows[0], rows[2]];
    const drops = [40.0, 0.0, 40.0];

    return SizedBox(
      height: 257,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: drops[i]),
                child: _PodiumCard(row: order[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.row});

  final RankRow row;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Column(
      children: [
        Text('${row.rank}위',
            style: MhText.custom(
              size: 24,
              weight: FontWeight.w700,
              color: MhColors.brand,
              height: 40 / 24,
            )),
        const SizedBox(height: MhSpacing.xs),
        Container(
          height: 149,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(MhRadius.button),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(2, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TeamLogo(size: 60, logoUrl: row.team.logoUrl),
              const SizedBox(height: 17),
              Text(
                row.team.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MhText.custom(
                    size: 14,
                    weight: FontWeight.w700,
                    color: c.text,
                    height: 24 / 14),
              ),
              Text('${row.points}점',
                  style: MhText.custom(
                      size: 10,
                      weight: FontWeight.w400,
                      color: c.text,
                      height: 16 / 10)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankRowTile extends StatelessWidget {
  const _RankRowTile({required this.row});

  final RankRow row;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(MhRadius.chip),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('${row.rank}위',
                style: MhText.custom(
                    size: 14, weight: FontWeight.w600, color: c.text)),
          ),
          const SizedBox(width: 12),
          TeamLogo(size: 40, logoUrl: row.team.logoUrl, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Text(row.team.name,
                style: MhText.custom(
                    size: 14, weight: FontWeight.w700, color: c.text)),
          ),
          Text('${row.points}점',
              style: MhText.custom(
                  size: 12, weight: FontWeight.w500, color: c.textMuted)),
        ],
      ),
    );
  }
}
