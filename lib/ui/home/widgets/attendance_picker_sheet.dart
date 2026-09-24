import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/game.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../view_models/attendance_view_model.dart';

/// 시안 "기록 추가" — 다녀온 경기를 골라 도장을 찍는 시트.
///
/// 시안의 이 시트 마크업은 디자인 파일이 256KiB 상한에서 잘려 원문을 보지
/// 못했다. 다른 시트(마이팀 선택·연월 선택)와 같은 껍데기를 쓴다.
///
/// **후보는 이미 끝난 마이팀 경기뿐이다.** 앞으로 할 경기를 "다녀왔다"고
/// 기록할 수는 없고, 이미 기록한 경기는 목록에서 빠진다.
class AttendancePickerSheet extends ConsumerWidget {
  const AttendancePickerSheet._();

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        isScrollControlled: true,
        builder: (_) => const AttendancePickerSheet._(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final state = ref.watch(attendanceViewModelProvider).valueOrNull;
    final games = state?.candidates ?? const <Game>[];

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
                Text('다녀온 경기 고르기',
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
                      borderRadius: BorderRadius.circular(MhRadius.button),
                    ),
                    // Pretendard에 U+2715 글리프가 없어 두부로 찍힌다.
                    child: Icon(Icons.close_rounded, size: 16, color: c.textSub),
                  ),
                ),
              ],
            ),
          ),
          if (games.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                state?.team == null
                    ? '마이팀을 먼저 정해 주세요'
                    : '기록할 수 있는 지난 경기가 없어요',
                style: MhText.meta(c.textSub),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: games.length,
                separatorBuilder: (_, _) => const SizedBox(height: MhSpacing.xs),
                itemBuilder: (_, i) => _Row(
                  game: games[i],
                  onTap: () {
                    ref
                        .read(attendanceViewModelProvider.notifier)
                        .toggle(games[i].id);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.game, required this.onTap});

  final Game game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      haptic: MhHaptic.impact,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.bg,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(MhRadius.chip),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${game.home.name} vs ${game.away.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MhText.custom(
                          size: 14, weight: FontWeight.w700, color: c.text)),
                  const SizedBox(height: 3),
                  Text('${game.meta} · ${game.venue ?? '경기장'}',
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
            Text('${game.scoreHomeText}:${game.scoreAwayText}',
                style: mhDisplay(size: 16, color: c.text)),
          ],
        ),
      ),
    );
  }
}
