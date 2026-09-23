import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/team_logo.dart';
import '../../team_detail/widgets/team_detail_screen.dart';
import '../view_models/stat_view_model.dart';

/// 분석 — 팀 탭. 2열 카드 그리드. 카드를 누르면 팀 상세가 열린다.
class StatTeamTab extends StatelessWidget {
  const StatTeamTab({super.key, required this.state});

  final StatState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 0, MhSpacing.gutter, MhSpacing.xl),
      itemCount: state.ranking.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: MhSpacing.xs,
        crossAxisSpacing: 10,
        mainAxisExtent: 180,
      ),
      itemBuilder: (_, i) {
        final team = state.ranking[i].team;
        return GestureDetector(
          onTap: () => TeamDetailScreen.open(context, team),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TeamLogo(size: 70, logoUrl: team.logoUrl),
                const SizedBox(height: MhSpacing.xs),
                Text(
                  team.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MhText.custom(
                      size: 16,
                      weight: FontWeight.w600,
                      color: c.text,
                      height: 24 / 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
