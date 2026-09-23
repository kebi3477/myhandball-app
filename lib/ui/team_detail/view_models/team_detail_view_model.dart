import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../domain/models/team.dart';
import '../../../domain/models/team_detail.dart';

/// 시안 `teamDetailTab`.
enum TeamDetailTab {
  info('소개'),
  record('전적'),
  players('선수'),
  cheer('응원');

  const TeamDetailTab(this.label);

  final String label;
}

/// 전적 탭의 추이 그래프 모드.
enum TrendMode {
  rank('순위'),
  points('승점');

  const TrendMode(this.label);

  final String label;
}

class TeamDetailState {
  const TeamDetailState({
    required this.detail,
    required this.tab,
    required this.trendMode,
    required this.isMyTeam,
    required this.cheers,
    required this.likedCheerIds,
    required this.favoritePlayerIds,
    this.introExpanded = false,
    this.cheerDraft = '',
  });

  final TeamDetail detail;
  final TeamDetailTab tab;
  final TrendMode trendMode;
  final bool isMyTeam;
  final List<CheerPost> cheers;
  final Set<String> likedCheerIds;
  final Set<String> favoritePlayerIds;
  final bool introExpanded;
  final String cheerDraft;

  bool get canSubmitCheer => cheerDraft.trim().isNotEmpty;

  TeamDetailState copyWith({
    TeamDetailTab? tab,
    TrendMode? trendMode,
    List<CheerPost>? cheers,
    Set<String>? likedCheerIds,
    Set<String>? favoritePlayerIds,
    bool? introExpanded,
    String? cheerDraft,
  }) =>
      TeamDetailState(
        detail: detail,
        tab: tab ?? this.tab,
        trendMode: trendMode ?? this.trendMode,
        isMyTeam: isMyTeam,
        cheers: cheers ?? this.cheers,
        likedCheerIds: likedCheerIds ?? this.likedCheerIds,
        favoritePlayerIds: favoritePlayerIds ?? this.favoritePlayerIds,
        introExpanded: introExpanded ?? this.introExpanded,
        cheerDraft: cheerDraft ?? this.cheerDraft,
      );
}

class TeamDetailViewModel
    extends AutoDisposeFamilyAsyncNotifier<TeamDetailState, Team> {
  @override
  Future<TeamDetailState> build(Team team) async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final detail =
        await ref.read(handballApiServiceProvider).fetchTeamDetail(team);

    return TeamDetailState(
      detail: detail,
      tab: TeamDetailTab.info,
      trendMode: TrendMode.rank,
      isMyTeam: prefs.myTeam?.name == team.name,
      cheers: prefs.cheersFor(team.name),
      likedCheerIds: {
        for (final p in prefs.cheersFor(team.name))
          if (prefs.isCheerLiked(p.id)) p.id,
      },
      favoritePlayerIds: prefs.favoritePlayerIds,
    );
  }

  void selectTab(TeamDetailTab tab) {
    final c = state.valueOrNull;
    if (c == null || c.tab == tab) return;
    state = AsyncData(c.copyWith(tab: tab));
  }

  void setTrendMode(TrendMode mode) {
    final c = state.valueOrNull;
    if (c == null || c.trendMode == mode) return;
    state = AsyncData(c.copyWith(trendMode: mode));
  }

  void toggleIntro() {
    final c = state.valueOrNull;
    if (c == null) return;
    state = AsyncData(c.copyWith(introExpanded: !c.introExpanded));
  }

  void setCheerDraft(String value) {
    final c = state.valueOrNull;
    if (c == null) return;
    // 시안 maxlength 200
    state = AsyncData(c.copyWith(
      cheerDraft: value.length > 200 ? value.substring(0, 200) : value,
    ));
  }

  Future<void> submitCheer() async {
    final c = state.valueOrNull;
    if (c == null || !c.canSubmitCheer) return;
    final prefs = ref.read(preferencesRepositoryProvider);
    final now = DateTime.now();

    await prefs.addCheer(
      c.detail.team.name,
      CheerPost(
        id: 'cheer-${now.microsecondsSinceEpoch}',
        author: '나',
        text: c.cheerDraft.trim(),
        dateLabel: '${now.month}.${now.day}',
        likes: 0,
        isMine: true,
      ),
    );
    state = AsyncData(c.copyWith(
      cheers: prefs.cheersFor(c.detail.team.name),
      cheerDraft: '',
    ));
  }

  Future<void> deleteCheer(String postId) async {
    final c = state.valueOrNull;
    if (c == null) return;
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.removeCheer(c.detail.team.name, postId);
    state = AsyncData(c.copyWith(cheers: prefs.cheersFor(c.detail.team.name)));
  }

  Future<void> toggleCheerLike(String postId) async {
    final c = state.valueOrNull;
    if (c == null) return;
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.toggleCheerLike(postId);
    final liked = {...c.likedCheerIds};
    if (!liked.remove(postId)) liked.add(postId);
    state = AsyncData(c.copyWith(likedCheerIds: liked));
  }

  Future<void> toggleFavoritePlayer(String playerId) async {
    final c = state.valueOrNull;
    if (c == null) return;
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.toggleFavoritePlayer(playerId);
    state = AsyncData(c.copyWith(favoritePlayerIds: prefs.favoritePlayerIds));
  }
}

final teamDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<TeamDetailViewModel, TeamDetailState, Team>(
  TeamDetailViewModel.new,
);
