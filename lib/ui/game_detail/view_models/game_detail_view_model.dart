import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/game_detail.dart';

/// 시안 `gdTab` — 경기 상세의 서브탭.
enum GameDetailTab {
  live('중계'),
  stats('기록'),
  predict('예측'),
  mvp('MVP');

  const GameDetailTab(this.label);

  final String label;
}

class GameDetailState {
  const GameDetailState({
    required this.detail,
    required this.tab,
    required this.attended,
    this.prediction,
    this.mvpVote,
  });

  final GameDetail detail;
  final GameDetailTab tab;
  final bool attended;
  final PredictionPick? prediction;
  final String? mvpVote;

  Game get game => detail.game;

  bool get hasVotedMvp => mvpVote != null;

  /// 직관 기록은 이미 치러진 경기에만 남길 수 있다.
  bool get canAttend => game.status != GameStatus.pre;

  /// 예측 결과 판정. 경기가 끝나야 나온다.
  bool? get predictionHit {
    final pick = prediction;
    if (pick == null || game.status != GameStatus.finished) return null;
    final h = game.scoreHome ?? 0;
    final a = game.scoreAway ?? 0;
    final actual = h > a
        ? PredictionPick.home
        : (h < a ? PredictionPick.away : PredictionPick.draw);
    return pick == actual;
  }

  GameDetailState copyWith({
    GameDetail? detail,
    GameDetailTab? tab,
    bool? attended,
    PredictionPick? prediction,
    String? mvpVote,
  }) =>
      GameDetailState(
        detail: detail ?? this.detail,
        tab: tab ?? this.tab,
        attended: attended ?? this.attended,
        prediction: prediction ?? this.prediction,
        mvpVote: mvpVote ?? this.mvpVote,
      );
}

class GameDetailViewModel
    extends AutoDisposeFamilyAsyncNotifier<GameDetailState, Game> {
  @override
  Future<GameDetailState> build(Game game) async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final detail =
        await ref.read(handballApiServiceProvider).fetchGameDetail(game);

    return GameDetailState(
      detail: detail,
      // 시안은 경기 전이면 예측 탭, 아니면 중계 탭으로 연다.
      tab: game.status == GameStatus.pre
          ? GameDetailTab.predict
          : GameDetailTab.live,
      attended: prefs.didAttend(game.id),
      prediction: prefs.predictionFor(game.id),
      mvpVote: prefs.mvpVoteFor(game.id),
    );
  }

  void selectTab(GameDetailTab tab) {
    final current = state.valueOrNull;
    if (current == null || current.tab == tab) return;
    state = AsyncData(current.copyWith(tab: tab));
  }

  /// 시안 `toggleAttend`.
  Future<void> toggleAttended() async {
    final current = state.valueOrNull;
    if (current == null || !current.canAttend) return;
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.toggleAttended(current.game.id);
    state = AsyncData(current.copyWith(attended: !current.attended));
  }

  /// 시안 `pickPred` — 경기 시작 전까지만 바꿀 수 있다.
  Future<void> pick(PredictionPick pick) async {
    final current = state.valueOrNull;
    if (current == null || !current.detail.predictionOpen) return;
    await ref
        .read(preferencesRepositoryProvider)
        .setPrediction(current.game.id, pick);
    state = AsyncData(current.copyWith(prediction: pick));
  }

  /// 시안 `voteMvp` — 한 번 뽑으면 바꿀 수 없다.
  Future<void> voteMvp(String candidateId) async {
    final current = state.valueOrNull;
    if (current == null || current.hasVotedMvp) return;
    await ref
        .read(preferencesRepositoryProvider)
        .voteMvp(current.game.id, candidateId);
    state = AsyncData(current.copyWith(mvpVote: candidateId));
  }
}

final gameDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<GameDetailViewModel, GameDetailState, Game>(
  GameDetailViewModel.new,
);
