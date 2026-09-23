import 'package:flutter/material.dart';

import '../../../domain/models/rank_row.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/stat_view_model.dart';
import 'stat_table.dart';

/// 분석 — 순위 탭. 팀명/순위 + 승점·승·무·패.
class StatRankTab extends StatelessWidget {
  const StatRankTab({super.key, required this.state});

  final StatState state;

  static const _columns = [
    StatColumn('승점', 32),
    StatColumn('승', 32),
    StatColumn('무', 32),
    StatColumn('패', 32),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 0, MhSpacing.gutter, MhSpacing.xl),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('팀순위', style: MhText.sectionTitle(c.text)),
            Text('${DateTime.now().year}',
                style: MhText.custom(
                    size: 10, weight: FontWeight.w400, color: c.textNeutral)),
          ],
        ),
        const SizedBox(height: MhSpacing.xs),
        const StatTableHeader(first: '팀명/순위', columns: _columns),
        const SizedBox(height: MhSpacing.xs),
        for (final row in state.ranking) ...[
          StatTableRow(
            columns: _columns,
            values: [
              '${row.points}',
              '${row.wins}',
              '${row.draws}',
              '${row.losses}',
            ],
            leading: _RankLeading(row: row),
          ),
          const SizedBox(height: MhSpacing.xs),
        ],
      ],
    );
  }
}

class _RankLeading extends StatelessWidget {
  const _RankLeading({required this.row});

  final RankRow row;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Row(
      children: [
        TeamLogo(size: 40, logoUrl: row.team.logoUrl, borderRadius: 10),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${row.rank}위',
                  style: MhText.custom(
                      size: 11, weight: FontWeight.w400, color: c.textMuted)),
              const SizedBox(height: 2),
              Text(
                row.team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MhText.custom(
                    size: 14, weight: FontWeight.w800, color: c.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
