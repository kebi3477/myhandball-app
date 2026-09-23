import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/team_repository.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/team.dart';
import '../themes/theme.dart';
import '../themes/tokens.dart';
import 'mh_tap.dart';
import 'team_logo.dart';

/// 마이팀 선택 시트.
///
/// 시안은 하단에서 올라오는 시트(`bottom:84px`, 상단만 둥근 모서리)에
/// 남자팀/여자팀 알약과 2열 팀 그리드를 담는다.
Future<Team?> showTeamPickerSheet(
  BuildContext context, {
  required Gender initialGender,
  Team? selected,
}) {
  return showModalBottomSheet<Team>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    isScrollControlled: true,
    builder: (_) => _TeamPickerSheet(
      initialGender: initialGender,
      selected: selected,
    ),
  );
}

class _TeamPickerSheet extends ConsumerStatefulWidget {
  const _TeamPickerSheet({required this.initialGender, this.selected});

  final Gender initialGender;
  final Team? selected;

  @override
  ConsumerState<_TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends ConsumerState<_TeamPickerSheet> {
  late Gender _gender = widget.initialGender;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final teamsAsync = ref.watch(_pickerTeamsProvider(_gender));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      padding: const EdgeInsets.all(MhSpacing.sm),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('마이팀 선택',
                    style: MhText.custom(
                        size: 16, weight: FontWeight.w800, color: c.text)),
                MhTap(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.bg,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('✕',
                        style: MhText.custom(
                            size: 14,
                            weight: FontWeight.w600,
                            color: c.textSub)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
            child: Row(
              children: [
                for (final g in Gender.values) ...[
                  if (g != Gender.values.first) const SizedBox(width: MhSpacing.xs),
                  _GenderPill(
                    label: g.teamLabel,
                    selected: _gender == g,
                    onTap: () => setState(() => _gender = g),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: teamsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(MhSpacing.lg),
                child: CircularProgressIndicator(color: MhColors.brand),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(MhSpacing.sm),
                child: Text('팀 목록을 불러오지 못했어요',
                    style: MhText.meta(c.textSub)),
              ),
              data: (teams) => GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: teams.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: MhSpacing.xs,
                  crossAxisSpacing: MhSpacing.xs,
                  mainAxisExtent: 56,
                ),
                itemBuilder: (_, i) => _TeamTile(
                  team: teams[i],
                  selected: widget.selected?.name == teams[i].name,
                  onTap: () => Navigator.of(context).pop(teams[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _pickerTeamsProvider =
    FutureProvider.family<List<Team>, Gender>((ref, gender) {
  return ref.read(teamRepositoryProvider).getTeams(gender);
});

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
    return MhTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? MhColors.brand : c.bg,
          border: Border.all(color: selected ? MhColors.brand : c.border),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: MhText.custom(
            size: 14,
            weight: FontWeight.w600,
            color: selected ? Colors.white : c.textSub,
          ),
        ),
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.team,
    required this.selected,
    required this.onTap,
  });

  final Team team;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: c.bg,
          border: Border.all(color: selected ? MhColors.brand : c.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            TeamLogo(size: 36, logoUrl: team.logoUrl, borderRadius: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                team.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: MhText.custom(
                  size: 13,
                  weight: FontWeight.w700,
                  color: c.text,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
