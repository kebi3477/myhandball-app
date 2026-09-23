import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/stat_view_model.dart';
import 'stat_table.dart';

/// 분석 — 기록 탭. 팀별 득점·실점·득실차.
class StatRecordTab extends StatelessWidget {
  const StatRecordTab({super.key, required this.state});

  final StatState state;

  static const _columns = [
    StatColumn('득점', 44),
    StatColumn('실점', 44),
    StatColumn('득실차', 44),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 20, MhSpacing.gutter, MhSpacing.xl),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('팀 기록', style: MhText.sectionTitle(c.text)),
            Text('${DateTime.now().year}',
                style: MhText.custom(
                    size: 10, weight: FontWeight.w400, color: c.textNeutral)),
          ],
        ),
        const SizedBox(height: MhSpacing.xs),
        const StatTableHeader(first: '팀명', columns: _columns),
        const SizedBox(height: MhSpacing.xs),
        for (final row in state.byGoalDiff) ...[
          StatTableRow(
            columns: _columns,
            values: [
              '${row.goalsFor}',
              '${row.goalsAgainst}',
              // 양수면 부호를 붙여 준다.
              row.goalDiff > 0 ? '+${row.goalDiff}' : '${row.goalDiff}',
            ],
            valueColors: const [null, null, MhColors.brand],
            leading: Row(
              children: [
                TeamLogo(size: 40, logoUrl: row.team.logoUrl, borderRadius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MhText.custom(
                        size: 14, weight: FontWeight.w800, color: c.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MhSpacing.xs),
        ],
      ],
    );
  }
}
