import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/team.dart';
import '../../../domain/models/team_detail.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../view_models/team_detail_view_model.dart';

/// 응원글의 `⋯` 메뉴. 시안 (a).
///
/// **모든 글에 붙는다.** 내 글이면 삭제, 남의 글이면 신고·차단이다.
/// 예전에는 내 글 카드 오른쪽 아래에 "삭제" 글자가 있었는데 시안에서
/// 없어지고 이 메뉴로 들어왔다.
Future<void> showCheerActions(
  BuildContext context,
  WidgetRef ref, {
  required Team team,
  required CheerPost post,
  required VoidCallback onDelete,
}) {
  final c = context.mh;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (sheet) => _Sheet(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, MhSpacing.gutter),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Text('${post.author}님의 응원글',
              style: MhText.custom(
                  size: 12, weight: FontWeight.w500, color: c.textSub)),
        ),
        if (post.isMine)
          _ActionRow(
            icon: MhIcons.trash,
            label: '삭제',
            color: _danger,
            onTap: () {
              Navigator.of(sheet).pop();
              onDelete();
            },
          )
        else ...[
          _ActionRow(
            icon: MhIcons.flag,
            label: '신고하기',
            color: c.text,
            onTap: () {
              Navigator.of(sheet).pop();
              showCheerReportSheet(context, ref, team: team, post: post);
            },
          ),
          _ActionRow(
            icon: MhIcons.ban,
            label: '이 사용자의 글 보지 않기',
            color: _danger,
            onTap: () {
              Navigator.of(sheet).pop();
              showBlockConfirm(context, ref, team: team, post: post);
            },
          ),
        ],
        const SizedBox(height: MhSpacing.xs),
        MhTap(
          onTap: () => Navigator.of(sheet).pop(),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text('취소',
                style: MhText.custom(
                    size: 15, weight: FontWeight.w600, color: c.text)),
          ),
        ),
      ],
    ),
  );
}

/// 시안 (c) — 차단 확인 다이얼로그.
Future<void> showBlockConfirm(
  BuildContext context,
  WidgetRef ref, {
  required Team team,
  required CheerPost post,
}) {
  final c = context.mh;

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (dialog) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(MhRadius.card),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${post.author}님의 글을 보지 않을까요?',
                  style: MhText.custom(
                      size: 17, weight: FontWeight.w800, color: c.text)),
              const SizedBox(height: MhSpacing.xs),
              Text(
                '이 사용자의 응원글이 모든 팀에서 보이지 않아요. '
                '설정 > 차단한 사용자에서 언제든 해제할 수 있어요.',
                style: MhText.custom(
                    size: 13,
                    weight: FontWeight.w400,
                    color: c.textSub,
                    height: 1.5),
              ),
              const SizedBox(height: MhSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: '취소',
                      background: c.card,
                      border: c.border,
                      foreground: c.text,
                      onTap: () => Navigator.of(dialog).pop(),
                    ),
                  ),
                  const SizedBox(width: MhSpacing.xs),
                  Expanded(
                    child: _DialogButton(
                      label: '보지 않기',
                      background: _danger,
                      foreground: Colors.white,
                      onTap: () {
                        Navigator.of(dialog).pop();
                        ref
                            .read(teamDetailViewModelProvider(team).notifier)
                            .blockAuthor(post);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 시안 (b) — 신고 시트.
Future<void> showCheerReportSheet(
  BuildContext context,
  WidgetRef ref, {
  required Team team,
  required CheerPost post,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    isScrollControlled: true,
    builder: (_) => _ReportSheet(team: team, post: post),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.team, required this.post});

  final Team team;
  final CheerPost post;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _detail = TextEditingController();
  CheerReportReason? _reason;
  bool _alsoBlock = false;

  static const _maxDetail = 200;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  /// 사유를 골랐고, "기타"면 무엇이 문제인지도 적어야 보낼 수 있다.
  bool get _canSubmit {
    final reason = _reason;
    if (reason == null) return false;
    return !reason.needsDetail || _detail.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final needsDetail = _reason?.needsDetail ?? false;

    return _Sheet(
      maxHeightFactor: 0.92,
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 12, MhSpacing.gutter, MhSpacing.gutter),
      gap: 18,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('응원글 신고',
                style: MhText.custom(
                    size: 20, weight: FontWeight.w800, color: c.text)),
            const SizedBox(height: MhSpacing.xs2),
            Text('신고 사유를 골라주세요. 신고한 사람은 상대에게 알려지지 않아요.',
                style: MhText.custom(
                    size: 13, weight: FontWeight.w400, color: c.textSub)),
          ],
        ),
        // 무엇을 신고하는지 다시 보여준다. 목록에서 잘못 누를 수 있다.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.post.author,
                  style: MhText.custom(
                      size: 12, weight: FontWeight.w700, color: c.text)),
              const SizedBox(height: 4),
              Text(widget.post.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MhText.custom(
                      size: 13, weight: FontWeight.w400, color: c.textSub)),
            ],
          ),
        ),
        Column(
          children: [
            for (final reason in CheerReportReason.values) ...[
              _ReasonRow(
                reason: reason,
                selected: _reason == reason,
                onTap: () => setState(() => _reason = reason),
              ),
              if (reason != CheerReportReason.values.last)
                const SizedBox(height: MhSpacing.xs),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 76),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _detail,
                maxLines: null,
                maxLength: _maxDetail,
                onChanged: (_) => setState(() {}),
                cursorColor: MhColors.brand,
                style: MhText.custom(
                    size: 13, weight: FontWeight.w400, color: c.text),
                decoration: InputDecoration(
                  counterText: '',
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: needsDetail
                      ? '어떤 문제인지 적어주세요 (필수, 최대 200자)'
                      : '자세한 내용을 적어주세요 (선택, 최대 200자)',
                  hintStyle: MhText.custom(
                      size: 13, weight: FontWeight.w400, color: c.textFaint),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('${_detail.text.characters.length}/$_maxDetail',
                style: MhText.custom(
                    size: 11, weight: FontWeight.w500, color: c.textFaint)),
          ],
        ),
        MhTap(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _alsoBlock = !_alsoBlock),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _alsoBlock ? MhColors.brand : Colors.transparent,
                  border: Border.all(
                    color: _alsoBlock ? MhColors.brand : c.textFaint,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _alsoBlock
                    ? const Icon(Icons.check_rounded,
                        size: 15, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Text('이 사용자의 글도 보지 않기',
                  style: MhText.custom(
                      size: 14, weight: FontWeight.w600, color: c.text)),
            ],
          ),
        ),
        Column(
          children: [
            MhTap(
              haptic: _canSubmit ? MhHaptic.impact : MhHaptic.none,
              onTap: _canSubmit ? _submit : null,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _canSubmit ? _danger : c.textFaint,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text('신고하기',
                    style: MhText.custom(
                        size: 16,
                        weight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: MhSpacing.xs),
            Text('신고한 글은 바로 숨겨지고, 운영정책에 따라 24시간 안에 검토해요.',
                textAlign: TextAlign.center,
                style: MhText.custom(
                    size: 11, weight: FontWeight.w400, color: c.textSub)),
          ],
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop();
    ref.read(teamDetailViewModelProvider(widget.team).notifier).reportCheer(
          widget.post,
          reason: _reason!,
          detail: _detail.text,
          alsoBlock: _alsoBlock,
        );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final CheerReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? MhColors.brand.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border.all(
            color: selected ? MhColors.brand : c.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? MhColors.brand : c.textFaint,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: MhColors.brand,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(reason.label,
                style: MhText.custom(
                    size: 15, weight: FontWeight.w600, color: c.text)),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MhTap(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 8),
            MhIcon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(label,
                style: MhText.custom(
                    size: 15, weight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MhTap(
      haptic: MhHaptic.impact,
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          border: border == null ? null : Border.all(color: border!),
          borderRadius: BorderRadius.circular(MhRadius.button),
        ),
        child: Text(label,
            style: MhText.custom(
                size: 15, weight: FontWeight.w700, color: foreground)),
      ),
    );
  }
}

/// 시안 바텀시트 껍데기 — 핸들 + 배경 + 모서리.
class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.children,
    required this.padding,
    this.gap = 0,
    this.maxHeightFactor = 0.9,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double gap;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      ),
      padding: padding,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            SizedBox(height: gap == 0 ? MhSpacing.xs : gap),
            for (final (i, child) in children.indexed) ...[
              if (i > 0 && gap > 0) SizedBox(height: gap),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// 시안이 신고·차단·삭제에 쓰는 빨강.
const _danger = Color(0xFFE5484D);
