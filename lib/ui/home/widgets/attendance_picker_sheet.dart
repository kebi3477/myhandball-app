import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../domain/models/game.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/external_actions.dart';
import '../../core/ui/mh_tap.dart';
import '../view_models/attendance_view_model.dart';

/// 시안 `attSheetOpen` — 다녀온 경기를 골라 도장을 찍는 시트.
///
/// **체크를 켜고 끄는 시트다.** 이미 기록한 경기도 목록에 남기고 체크만
/// 켜 둔다. 안 그러면 잘못 찍은 기록을 여기서 지울 수 없다.
/// 탭하면 바로 저장되고, 아래 [완료]는 닫기만 한다.
class AttendancePickerSheet extends ConsumerWidget {
  const AttendancePickerSheet._();

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        isScrollControlled: true,
        builder: (_) => const AttendancePickerSheet._(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final state = ref.watch(attendanceViewModelProvider).valueOrNull;
    final pool = state?.pool ?? const <Game>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 12, MhSpacing.gutter, MhSpacing.gutter),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: MhSpacing.sm),
          Text('다녀온 경기를 골라주세요',
              style: MhText.custom(
                  size: 20, weight: FontWeight.w800, color: c.text)),
          const SizedBox(height: MhSpacing.xs2),
          Text(
            '${state?.seasonName ?? ''} ${state?.team?.name ?? '마이팀'} 경기 · '
            '${state?.pickedCount ?? 0}경기 선택됨',
            style: MhText.custom(
                size: 13, weight: FontWeight.w400, color: c.textSub),
          ),
          const SizedBox(height: MhSpacing.sm),
          if (pool.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                state?.team == null ? '마이팀을 먼저 정해 주세요' : '기록할 지난 경기가 없어요',
                textAlign: TextAlign.center,
                style: MhText.meta(c.textSub),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: pool.length,
                separatorBuilder: (_, _) => const SizedBox(height: MhSpacing.xs),
                itemBuilder: (_, i) => _Row(
                  game: pool[i],
                  checked: ref
                      .watch(preferencesRepositoryProvider)
                      .didAttend(pool[i].id),
                  onTap: () async {
                    await ref
                        .read(attendanceViewModelProvider.notifier)
                        .toggle(pool[i].id);
                    if (context.mounted) {
                      showAttendanceOfflineToast(context, ref);
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: MhSpacing.sm),
          MhTap(
            haptic: MhHaptic.impact,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MhColors.brand,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Text('완료',
                  style: MhText.custom(
                      size: 16, weight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.game,
    required this.checked,
    required this.onTap,
  });

  final Game game;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;

    return MhTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: checked ? MhColors.brand.withValues(alpha: 0.1) : c.card,
          border: Border.all(
            color: checked ? MhColors.brand : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(MhRadius.chip),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? MhColors.brand : Colors.transparent,
                border: Border.all(
                  color: checked ? MhColors.brand : c.textFaint,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${game.home.name} vs ${game.away.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MhText.custom(
                          size: 14, weight: FontWeight.w700, color: c.text)),
                  const SizedBox(height: 2),
                  // `meta`는 끝난 경기에서 "종료"로 오기도 한다. 시안은
                  // 날짜와 요일을 적으므로 시작 시각으로 만든다.
                  Text('${game.dateLabel} · ${game.venue ?? '경기장'}',
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
            Text('${game.scoreHomeText} : ${game.scoreAwayText}',
                style: mhDisplay(size: 16, color: c.text)),
          ],
        ),
      ),
    );
  }
}
