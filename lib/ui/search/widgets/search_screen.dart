import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../../player_detail/widgets/player_detail_sheet.dart';
import '../../team_detail/widgets/team_detail_screen.dart';
import '../view_models/search_view_model.dart';

/// 검색. 시안 SEARCH — 홈·분석 헤더의 돋보기에서 열린다.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
    );
  }

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _use(String query) {
    _controller.text = query;
    ref.read(searchViewModelProvider.notifier).setQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final async = ref.watch(searchViewModelProvider);
    final vm = ref.read(searchViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 66,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                child: Row(
                  children: [
                    MhTap(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: MhIcon(MhIcons.chevLeft,
                            size: 18, color: c.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: Row(
                          children: [
                            MhIcon(MhIcons.searchSmall,
                                size: 16, color: c.textSub),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                autofocus: true,
                                onChanged: vm.setQuery,
                                // 시안 `onSearchKey` — 엔터에서 남긴다.
                                // 결과를 눌러야만 남기면 검색해 놓고 그냥
                                // 나간 경우가 기록되지 않는다.
                                onSubmitted: vm.remember,
                                textInputAction: TextInputAction.search,
                                style: MhText.custom(
                                    size: 15,
                                    weight: FontWeight.w400,
                                    color: c.text),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: '팀, 선수 이름 검색',
                                  hintStyle: MhText.custom(
                                      size: 15,
                                      weight: FontWeight.w400,
                                      color: c.textFaint),
                                ),
                              ),
                            ),
                            if (_controller.text.isNotEmpty)
                              MhTap(
                                onTap: () {
                                  _controller.clear();
                                  vm.setQuery('');
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: c.textFaint,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text('✕',
                                      style: MhText.custom(
                                          size: 11,
                                          weight: FontWeight.w700,
                                          color: c.bg)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: MhColors.brand)),
                error: (e, _) => Center(
                  child: Text(mhErrorMessage(e), style: MhText.meta(c.textSub)),
                ),
                data: (state) => state.isIdle
                    ? _IdleView(state: state, onUse: _use, vm: vm)
                    : _ResultsView(state: state, vm: vm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.state,
    required this.onUse,
    required this.vm,
  });

  final SearchState state;
  final ValueChanged<String> onUse;
  final SearchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return ListView(
      // 시안 `padding: 4px 24px 40px`
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 4, MhSpacing.gutter, MhSpacing.xl),
      children: [
        if (state.recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('최근 검색',
                  style: MhText.custom(
                      size: 14, weight: FontWeight.w700, color: c.text)),
              MhTap(
                onTap: vm.clearRecent,
                child: Text('전체 삭제', style: MhText.meta(c.textFaint)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: MhSpacing.xs,
            runSpacing: MhSpacing.xs,
            children: [
              for (final q in state.recent)
                Container(
                  height: 32,
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MhTap(
                        onTap: () => onUse(q),
                        child: Text(q,
                            style: MhText.custom(
                                size: 13,
                                weight: FontWeight.w400,
                                color: c.text)),
                      ),
                      const SizedBox(width: 6),
                      MhTap(
                        onTap: () => vm.removeRecent(q),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: Icon(Icons.close_rounded,
                              size: 12, color: c.textFaint),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: MhSpacing.md),
        ],
        Text('추천 검색어',
            style: MhText.custom(
                size: 14, weight: FontWeight.w700, color: c.text)),
        const SizedBox(height: 10),
        Wrap(
          spacing: MhSpacing.xs,
          runSpacing: MhSpacing.xs,
          children: [
            for (final q in state.suggestions)
              MhTap(
                onTap: () => onUse(q),
                // alignment를 주면 Container가 제약만큼 넓어져 칩이 한 줄을
                // 다 차지한다. 시안처럼 글자 폭에 맞춰야 하므로 쓰지 않는다.
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(q,
                        style: MhText.custom(
                            size: 13, weight: FontWeight.w400, color: c.text)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.state, required this.vm});

  final SearchState state;
  final SearchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final teams = state.teamResults;
    final players = state.playerResults;

    if (!state.hasResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(MhSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MhIcon(MhIcons.searchOff, size: 28, color: c.textSub),
              const SizedBox(height: 10),
              Text("'${state.query}' 검색 결과가 없어요",
                  style: MhText.custom(
                      size: 14, weight: FontWeight.w600, color: c.text)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 12, MhSpacing.gutter, MhSpacing.xl),
      children: [
        if (teams.isNotEmpty) ...[
          Text('팀 ${teams.length}',
              style: MhText.custom(
                  size: 13, weight: FontWeight.w700, color: c.textSub)),
          for (final t in teams)
            _ResultRow(
              logoUrl: t.logoUrl,
              title: t.name,
              subtitle: t.gender.divisionLabel,
              onTap: () {
                vm.remember(state.query);
                TeamDetailScreen.open(context, t);
              },
            ),
          const SizedBox(height: 20),
        ],
        if (players.isNotEmpty) ...[
          Text('선수 ${players.length}',
              style: MhText.custom(
                  size: 13, weight: FontWeight.w700, color: c.textSub)),
          for (final p in players)
            _ResultRow(
              logoUrl: p.teamLogoUrl,
              title: p.name,
              subtitle: '${p.teamName} · ${p.positionFull}',
              onTap: () {
                vm.remember(state.query);
                showPlayerDetailSheet(context, p);
              },
            ),
        ],
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.logoUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String? logoUrl;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.borderSubtle)),
        ),
        child: Row(
          children: [
            TeamLogo(size: 40, logoUrl: logoUrl, inset: 0.78),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: MhText.custom(
                          size: 15, weight: FontWeight.w700, color: c.text)),
                  Text(subtitle, style: MhText.caption(c.textSub)),
                ],
              ),
            ),
            Text('›',
                style: MhText.custom(
                    size: 14, weight: FontWeight.w400, color: c.textFaint)),
          ],
        ),
      ),
    );
  }
}
