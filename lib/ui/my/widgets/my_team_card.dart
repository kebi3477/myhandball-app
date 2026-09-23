import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../../core/ui/team_picker_sheet.dart';
import '../../team_detail/widgets/team_detail_screen.dart';
import '../view_models/my_view_model.dart';

/// MY 팀 카드 — 80px 로고 + 팀명 + 순위 + "팀 상세보기".
class MyTeamCard extends ConsumerWidget {
  const MyTeamCard({super.key, required this.state});

  final MyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final team = state.team;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MY 팀', style: MhText.sectionTitle(c.text)),
              MhTap(
                onTap: () async {
                  final prefs = ref.read(preferencesRepositoryProvider);
                  final picked = await showTeamPickerSheet(
                    context,
                    initialGender: prefs.preferredGender,
                    selected: team,
                  );
                  if (picked == null) return;
                  await prefs.setMyTeam(picked);
                  await prefs.setPreferredGender(picked.gender);
                  ref.invalidate(myViewModelProvider);
                },
                child: Text('팀변경 >', style: MhText.meta(c.textFaint)),
              ),
            ],
          ),
        ),
        const SizedBox(height: MhSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    children: [
                      TeamLogo(size: 80, logoUrl: team?.logoUrl),
                      const SizedBox(height: MhSpacing.sm),
                      Text(
                        team?.name ?? '마이팀 없음',
                        style: MhText.custom(
                            size: 24,
                            weight: FontWeight.w700,
                            color: c.text,
                            height: 40 / 24),
                      ),
                      Text(
                        team == null ? '팀을 골라주세요' : state.rankLabel,
                        style: MhText.custom(
                            size: 14,
                            weight: FontWeight.w400,
                            color: c.text,
                            height: 24 / 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MhSpacing.sm),
                MhTap(
                  onTap: team == null
                      ? null
                      : () => TeamDetailScreen.open(context, team),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF898989),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text('팀 상세보기',
                        style: MhText.custom(
                            size: 14,
                            weight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
