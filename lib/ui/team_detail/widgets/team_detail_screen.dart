import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/team.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/sub_page_scaffold.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/team_detail_view_model.dart';
import 'team_cheer_tab.dart';
import 'team_info_tab.dart';
import 'team_players_tab.dart';
import 'team_record_tab.dart';

/// 팀 상세. 시안 teamDetail 섹션.
class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, required this.team});

  final Team team;

  static Future<void> open(BuildContext context, Team team) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TeamDetailScreen(team: team)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamDetailViewModelProvider(team));
    final vm = ref.read(teamDetailViewModelProvider(team).notifier);

    // 서버가 쓰기를 거절했을 때(마감·중복 투표·요청 제한) 이유를 알려준다.
    ref.listen(teamDetailViewModelProvider(team), (_, next) {
      final notice = next.valueOrNull?.notice;
      if (notice == null || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(notice)));
      vm.clearNotice();
    });

    return SubPageScaffold(
      title: team.name,
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: MhColors.brand)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(MhSpacing.gutter),
            child: Text(mhErrorMessage(e),
                textAlign: TextAlign.center,
                style: MhText.meta(context.mh.textSub)),
          ),
        ),
        data: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryCard(state: state),
            _TabBar(current: state.tab, onSelect: vm.selectTab),
            Expanded(
              child: switch (state.tab) {
                TeamDetailTab.info => TeamInfoTab(state: state),
                TeamDetailTab.record => TeamRecordTab(state: state),
                TeamDetailTab.players => TeamPlayersTab(state: state),
                TeamDetailTab.cheer => TeamCheerTab(state: state),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final TeamDetailState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final d = state.detail;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 0, MhSpacing.gutter, MhSpacing.sm),
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
                TeamLogo(size: 68, logoUrl: d.team.logoUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(d.divisionLabel,
                              style: MhText.custom(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: c.textSub)),
                          if (state.isMyTeam) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: MhColors.brand,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('MY팀',
                                  style: MhText.custom(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(d.team.name,
                          style: MhText.custom(
                              size: 22,
                              weight: FontWeight.w800,
                              color: c.text)),
                      Text(d.slogan, style: MhText.meta(c.textSub)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: MhSpacing.sm),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  for (final (label, value) in d.summaryChips)
                    Expanded(
                      child: Column(
                        children: [
                          Text(value,
                              style: MhText.custom(
                                  size: 18,
                                  weight: FontWeight.w800,
                                  color: label == '순위'
                                      ? MhColors.brand
                                      : c.text)),
                          const SizedBox(height: 2),
                          Text(label, style: MhText.caption(c.textSub)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onSelect});

  final TeamDetailTab current;
  final ValueChanged<TeamDetailTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: Row(
        children: [
          for (final tab in TeamDetailTab.values)
            Expanded(
              child: MhTap(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(tab),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: tab == current
                            ? MhColors.brand
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    tab.label,
                    style: MhText.custom(
                      size: 14,
                      weight: FontWeight.w600,
                      color: tab == current ? c.text : c.textSub,
                      height: 24 / 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
