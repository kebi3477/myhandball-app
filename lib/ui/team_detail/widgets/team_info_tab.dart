import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../view_models/team_detail_view_model.dart';

/// 팀 상세 — 소개 탭. 구단 소개 / 기본 정보 / 연혁 / 찾아오시는 길.
class TeamInfoTab extends ConsumerWidget {
  const TeamInfoTab({super.key, required this.state});

  final TeamDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final d = state.detail;
    final vm = ref.read(teamDetailViewModelProvider(d.team).notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 20, MhSpacing.gutter, MhSpacing.xl),
      children: [
        _Card(
          title: '구단 소개',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.intro,
                maxLines: state.introExpanded ? null : 3,
                overflow: state.introExpanded ? null : TextOverflow.ellipsis,
                style: MhText.custom(
                    size: 14,
                    weight: FontWeight.w400,
                    color: c.text,
                    height: 1.7),
              ),
              const SizedBox(height: 10),
              MhTap(
                onTap: vm.toggleIntro,
                child: Text(state.introExpanded ? '접기' : '더보기',
                    style: MhText.custom(
                        size: 12,
                        weight: FontWeight.w600,
                        color: MhColors.brand)),
              ),
            ],
          ),
        ),
        const SizedBox(height: MhSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            for (final (label, value) in d.facts)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(MhRadius.chip),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: MhText.caption(c.textMuted)),
                    const SizedBox(height: 4),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MhText.custom(
                            size: 15,
                            weight: FontWeight.w700,
                            color: c.text)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: MhSpacing.sm),
        _Card(
          title: '연혁',
          child: Column(
            children: [
              for (final h in d.history)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 76,
                        child: Text(h.year,
                            style: MhText.custom(
                                size: 13,
                                weight: FontWeight.w700,
                                color: MhColors.brand)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: const BoxDecoration(
                          color: MhColors.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(h.text,
                            style: MhText.custom(
                                size: 13,
                                weight: FontWeight.w400,
                                color: c.text,
                                height: 1.5)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: MhSpacing.sm),
        _Card(
          title: '찾아오시는 길',
          child: Text(d.address,
              style: MhText.custom(
                  size: 13,
                  weight: FontWeight.w400,
                  color: c.textSub,
                  height: 1.5)),
        ),
        const SizedBox(height: MhSpacing.sm),
        Text('출처: 한국핸드볼연맹 구단 소개',
            textAlign: TextAlign.center,
            style: MhText.custom(
                size: 11, weight: FontWeight.w400, color: c.textFaint)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(MhRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: MhText.custom(
                  size: 15, weight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
