import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/game.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../shell/view_models/shell_view_model.dart';
import 'game_card.dart';
import 'section_header.dart';

/// "가까운 경기" — 가로 스와이프 카드 + 페이지 도트.
class NearbyGamesSection extends ConsumerStatefulWidget {
  const NearbyGamesSection({super.key, required this.games});

  final List<Game> games;

  @override
  ConsumerState<NearbyGamesSection> createState() =>
      _NearbyGamesSectionState();
}

class _NearbyGamesSectionState extends ConsumerState<NearbyGamesSection> {
  /// 카드가 좌우로 24px 거터를 두고 다음 카드가 살짝 보이는 폭.
  /// 시안 `flex: 0 0 calc(100% - 24px)` + `padding: 0 24px` 조합.
  static const _cardPeek = 72.0;

  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '가까운 경기',
          trailing: GestureDetector(
            onTap: () => ref
                .read(shellViewModelProvider.notifier)
                .select(ShellTab.schedule),
            child: Text('전체일정 >', style: MhText.meta(c.textFaint)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: GameCard.height,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.games.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? MhSpacing.md : 0,
                right: 12,
              ),
              child: SizedBox(
                width: width - _cardPeek,
                child: GameCard(game: widget.games[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.games.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == _index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index ? MhColors.brand : c.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
