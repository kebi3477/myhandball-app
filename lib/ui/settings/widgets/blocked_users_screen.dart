import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models/team_detail.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/external_actions.dart';
import '../../core/ui/mh_error_view.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/sub_page_scaffold.dart';

/// 차단한 작성자 목록.
///
/// **심사에서 요구한다.** 차단 수단만 있고 해제할 곳이 없으면 안 된다.
/// 서버는 `authorId`와 차단 시각만 주므로 이름은 차단할 때 기기에 적어 둔
/// 값을 쓴다 ([PreferencesRepository.blockedName]).
final blockedAuthorsProvider = FutureProvider<List<BlockedAuthor>>((ref) async {
  final items = await ref.watch(handballApiServiceProvider).fetchBlocks();
  final prefs = ref.watch(preferencesRepositoryProvider);
  return [
    for (final b in items)
      BlockedAuthor(
        authorId: b.authorId,
        blockedAt: b.blockedAt,
        nickname: prefs.blockedName(b.authorId),
      ),
  ]..sort((a, b) =>
      (b.blockedAt ?? DateTime(0)).compareTo(a.blockedAt ?? DateTime(0)));
});

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const BlockedUsersScreen(),
      ));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final async = ref.watch(blockedAuthorsProvider);

    return SubPageScaffold(
      title: '차단한 사용자',
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: MhColors.brand)),
        error: (e, _) => Center(
          child: MhErrorView(
            error: e,
            onRetry: () => ref.invalidate(blockedAuthorsProvider),
          ),
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(
              MhSpacing.gutter, MhSpacing.sm, MhSpacing.gutter, MhSpacing.xl),
          children: [
            Text('차단한 사용자의 응원글은 모든 팀에서 보이지 않아요. 해제하면 다시 보여요.',
                style: MhText.custom(
                    size: 12,
                    weight: FontWeight.w400,
                    color: c.textSub,
                    height: 1.5)),
            const SizedBox(height: MhSpacing.sm),
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(MhRadius.card),
                ),
                child: Column(
                  children: [
                    Text('차단한 사용자가 없어요',
                        style: MhText.custom(
                            size: 14,
                            weight: FontWeight.w700,
                            color: c.text)),
                    const SizedBox(height: 6),
                    Text('응원글의 ⋯ 메뉴에서 차단할 수 있어요',
                        style: MhText.meta(c.textSub)),
                  ],
                ),
              )
            else
              for (final item in items) ...[
                _Row(author: item),
                const SizedBox(height: MhSpacing.xs),
              ],
          ],
        ),
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.author});

  final BlockedAuthor author;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(MhRadius.chip),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.bg,
              shape: BoxShape.circle,
            ),
            child: Text(
              author.displayName.characters.first,
              style: MhText.custom(
                  size: 13, weight: FontWeight.w700, color: c.textSub),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(author.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MhText.custom(
                        size: 14, weight: FontWeight.w700, color: c.text)),
                const SizedBox(height: 2),
                Text(author.blockedLabel,
                    style: MhText.custom(
                        size: 11,
                        weight: FontWeight.w400,
                        color: c.textSub)),
              ],
            ),
          ),
          MhTap(
            haptic: MhHaptic.impact,
            onTap: () => _unblock(context, ref),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                widthFactor: 1,
                child: Text('해제',
                    style: MhText.custom(
                        size: 13, weight: FontWeight.w700, color: c.text)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 해제는 확인 없이 바로 한다 (시안). 되돌리기 쉬운 동작이다.
  Future<void> _unblock(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final name = author.displayName;
    try {
      await ref.read(handballApiServiceProvider).unblockAuthor(author.authorId);
      await prefs.forgetBlockedName(author.authorId);
      ref.invalidate(blockedAuthorsProvider);
      if (context.mounted) showMhToast(context, '$name님 차단을 해제했어요');
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showMhToast(
        context,
        e.isOffline
            ? '오프라인 상태라 차단을 해제하지 못했어요. 연결을 확인해 주세요.'
            : '일시적인 오류로 차단을 해제하지 못했어요. 잠시 후 다시 시도해 주세요.',
      );
    }
  }
}
