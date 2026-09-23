import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/team_detail.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../view_models/team_detail_view_model.dart';

/// 팀 상세 — 응원 탭. 작성 폼 + 응원글 목록.
///
/// 응원글은 서버에 저장된다 (`/api/team/:teamNum/cheer`). 좋아요·내 글
/// 여부는 익명 기기 ID로 서버가 판정한다.
///
/// **아직 없는 것은 신고·차단이다.** 지금은 DB에서 `cheers.hidden`을 손으로
/// 켜는 수밖에 없고, iOS 심사에서 UGC 신고 수단을 요구할 수 있다
/// (`../myhandball-api/docs/api-tasks/07-후속-작업.md` B-1).
class TeamCheerTab extends ConsumerStatefulWidget {
  const TeamCheerTab({super.key, required this.state});

  final TeamDetailState state;

  @override
  ConsumerState<TeamCheerTab> createState() => _TeamCheerTabState();
}

class _TeamCheerTabState extends ConsumerState<TeamCheerTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final state = widget.state;
    final team = state.detail.team;
    final vm = ref.read(teamDetailViewModelProvider(team).notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 20, MhSpacing.gutter, MhSpacing.xl),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(MhRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${team.name}에게 응원 한마디',
                  style: MhText.custom(
                      size: 15, weight: FontWeight.w700, color: c.text)),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                onChanged: vm.setCheerDraft,
                maxLength: 200,
                maxLines: null,
                minLines: 3,
                style: MhText.custom(
                    size: 14,
                    weight: FontWeight.w400,
                    color: c.text,
                    height: 1.5),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '매너 있는 응원 부탁드려요 (최대 200자)',
                  hintStyle: MhText.custom(
                      size: 14, weight: FontWeight.w400, color: c.textFaint),
                  filled: true,
                  fillColor: c.bg,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: MhColors.brand),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${state.cheerDraft.length}/200',
                      style: MhText.custom(
                          size: 11,
                          weight: FontWeight.w400,
                          color: c.textFaint)),
                  MhTap(
                    onTap: state.canSubmitCheer
                        ? () async {
                            await vm.submitCheer();
                            _controller.clear();
                          }
                        : null,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: state.canSubmitCheer
                            ? MhColors.brand
                            : c.textFaint,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text('등록',
                          style: MhText.custom(
                              size: 13,
                              weight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('응원글 ${state.cheers.length}',
                  style: MhText.custom(
                      size: 13, weight: FontWeight.w700, color: c.text)),
              // 시안 원문. 로그인이 없어서 서버가 익명 기기 ID로 "내 글"을
              // 가린다 — 지우는 건 쓴 기기에서만 된다. 글 자체는 모두에게
              // 보이므로 "보여요"라고 쓰면 거짓말이 된다.
              Text('내 글은 이 기기에서만 삭제할 수 있어요',
                  style: MhText.custom(
                      size: 11,
                      weight: FontWeight.w400,
                      color: c.textFaint)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (state.cheers.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: Text('첫 응원글을 남겨보세요',
                style: MhText.custom(
                    size: 14, weight: FontWeight.w600, color: c.textSub)),
          )
        else
          for (final post in state.cheers) ...[
            _CheerCard(
              post: post,
              liked: post.liked,
              onLike: () => vm.toggleCheerLike(post.id),
              onDelete: () => vm.deleteCheer(post.id),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _CheerCard extends StatelessWidget {
  const _CheerCard({
    required this.post,
    required this.liked,
    required this.onLike,
    required this.onDelete,
  });

  final CheerPost post;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(
            color: post.isMine ? MhColors.brand : Colors.transparent),
        borderRadius: BorderRadius.circular(MhRadius.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: MhColors.brand,
                  shape: BoxShape.circle,
                ),
                child: Text(post.initial,
                    style: MhText.custom(
                        size: 12,
                        weight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: MhSpacing.xs),
              Expanded(
                child: Row(
                  children: [
                    Text(post.author,
                        style: MhText.custom(
                            size: 13,
                            weight: FontWeight.w700,
                            color: c.text)),
                    if (post.isMine) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          border: Border.all(color: MhColors.brand),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('내 글',
                            style: MhText.custom(
                                size: 10,
                                weight: FontWeight.w700,
                                color: MhColors.brand)),
                      ),
                    ],
                  ],
                ),
              ),
              Text(post.dateLabel,
                  style: MhText.custom(
                      size: 11,
                      weight: FontWeight.w400,
                      color: c.textFaint)),
            ],
          ),
          const SizedBox(height: MhSpacing.xs),
          Text(post.text,
              style: MhText.custom(
                  size: 14,
                  weight: FontWeight.w400,
                  color: c.text,
                  height: 1.55)),
          const SizedBox(height: MhSpacing.xs),
          Row(
            children: [
              MhTap(
                onTap: onLike,
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      MhIcon(
                        liked ? MhIcons.heartFilled : MhIcons.heart,
                        size: 14,
                        color: liked ? const Color(0xFFFF4D6A) : c.textSub,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.likes + (liked ? 1 : 0)}',
                          style: MhText.custom(
                              size: 12,
                              weight: FontWeight.w600,
                              color: c.textSub)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (post.isMine)
                MhTap(
                  onTap: () => _confirmDelete(context),
                  child: Text('삭제',
                      style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w600,
                          color: c.textSub)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final c = context.mh;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('이 응원글을 삭제할까요?',
            style: MhText.custom(
                size: 15, weight: FontWeight.w700, color: c.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('취소', style: MhText.meta(c.textSub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            child: Text('삭제',
                style: MhText.custom(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFFE5484D))),
          ),
        ],
      ),
    );
  }
}
