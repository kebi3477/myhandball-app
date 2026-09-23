import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/handball_api_service.dart';
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
    required this.favoritePlayerIds,
    this.introExpanded = false,
    this.cheerDraft = '',
    this.notice,
  });

  final TeamDetail detail;
  final TeamDetailTab tab;
  final TrendMode trendMode;
  final bool isMyTeam;
  /// 서버가 주는 응원글. 좋아요 여부(`liked`)와 내 글 여부(`isMine`)는
  /// 기기 ID로 서버가 판정한 값이다.
  final List<CheerPost> cheers;

  final Set<String> favoritePlayerIds;
  final bool introExpanded;
  final String cheerDraft;

  /// 쓰기가 거절됐을 때 띄울 문구 (하루 5개 제한, 200자 초과 등).
  final String? notice;

  bool get canSubmitCheer => cheerDraft.trim().isNotEmpty;

  TeamDetailState copyWith({
    TeamDetailTab? tab,
    TrendMode? trendMode,
    List<CheerPost>? cheers,
    Set<String>? favoritePlayerIds,
    bool? introExpanded,
    String? cheerDraft,
    String? notice,
  }) =>
      TeamDetailState(
        detail: detail,
        tab: tab ?? this.tab,
        trendMode: trendMode ?? this.trendMode,
        isMyTeam: isMyTeam,
        cheers: cheers ?? this.cheers,
        favoritePlayerIds: favoritePlayerIds ?? this.favoritePlayerIds,
        introExpanded: introExpanded ?? this.introExpanded,
        cheerDraft: cheerDraft ?? this.cheerDraft,
        notice: notice,
      );
}

class TeamDetailViewModel
    extends AutoDisposeFamilyAsyncNotifier<TeamDetailState, Team> {
  @override
  Future<TeamDetailState> build(Team team) async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final api = ref.read(handballApiServiceProvider);
    final detail = await api.fetchTeamDetail(team);

    // 응원글은 팀 상세와 독립이다. 실패해도 소개·전적은 보여준다.
    List<CheerPost> cheers;
    try {
      cheers = await api.fetchCheers(detail.team);
    } on ApiException {
      cheers = const [];
    }

    return TeamDetailState(
      detail: detail,
      tab: TeamDetailTab.info,
      trendMode: TrendMode.rank,
      isMyTeam: prefs.myTeam?.name == team.name,
      cheers: cheers,
      favoritePlayerIds: prefs.favoritePlayerIds,
    );
  }

  /// 안내 문구를 한 번 읽고 지운다.
  void clearNotice() {
    final c = state.valueOrNull;
    if (c?.notice == null) return;
    state = AsyncData(c!.copyWith());
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
    await _write(c, (api) => api.submitCheer(c.detail.team, c.cheerDraft.trim()),
        onDone: (next) => next.copyWith(cheerDraft: ''));
  }

  Future<void> deleteCheer(String postId) async {
    final c = state.valueOrNull;
    if (c == null) return;
    await _write(c, (api) => api.deleteCheer(c.detail.team, postId));
  }

  Future<void> toggleCheerLike(String postId) async {
    final c = state.valueOrNull;
    if (c == null) return;
    await _write(c, (api) => api.toggleCheerLike(c.detail.team, postId));
  }

  /// 응원글 쓰기는 전부 "서버에 보내고 목록을 다시 받는다"이다.
  /// 서버가 좋아요·내 글 여부를 판정하므로 화면에서 흉내 내지 않는다.
  Future<void> _write(
    TeamDetailState current,
    Future<List<CheerPost>> Function(HandballApiService api) run, {
    TeamDetailState Function(TeamDetailState next)? onDone,
  }) async {
    try {
      final cheers = await run(ref.read(handballApiServiceProvider));
      final next = current.copyWith(cheers: cheers);
      state = AsyncData(onDone == null ? next : onDone(next));
    } on ApiException catch (e) {
      state = AsyncData(current.copyWith(notice: _message(e)));
    }
  }

  String _message(ApiException e) {
    if (e.isRateLimited) return '오늘은 응원글을 더 쓸 수 없어요';
    if (e.isBadRequest) return e.message;
    return e.isOffline ? e.message : '응원글을 저장하지 못했어요';
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
