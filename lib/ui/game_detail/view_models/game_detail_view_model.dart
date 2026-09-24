import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/user_records_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/game_detail.dart';
import '../../home/view_models/attendance_view_model.dart';
import '../../home/view_models/prediction_view_model.dart';
import '../../my/view_models/my_view_model.dart';

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
    required this.tally,
    required this.mvp,
    this.mvpFailed = false,
    this.notice,
  });

  final GameDetail detail;
  final GameDetailTab tab;

  /// 직관 기록. 개인 기록이라 서버로 보내지 않는다.
  final bool attended;

  /// 서버가 집계한 예측 분포.
  final PredictionTally tally;

  /// 서버가 집계한 MVP 투표.
  final MvpBoard mvp;

  /// MVP 집계를 못 받아왔는지.
  ///
  /// **"못 받았다"와 "아직 안 열렸다"를 구분해야 한다.** 빈 보드는
  /// `open == false`라서, 서버가 500을 주든 타임아웃이 나든 화면에는
  /// "아직 투표 전이에요"가 뜬다. 경기가 끝났는데 투표가 안 열린 것처럼
  /// 보이고, 사용자는 다시 시도할 방법도 없다.
  final bool mvpFailed;

  /// 쓰기가 거절됐을 때 띄울 문구 (마감·중복 투표·요청 제한).
  final String? notice;

  Game get game => detail.game;

  PredictionPick? get prediction => tally.myPick;

  String? get mvpVote => mvp.myVoteId;

  bool get hasVotedMvp => mvp.hasVoted;

  /// 마감 판정은 서버가 `startsAt`으로 한다. 기기 시계를 믿지 않는다.
  bool get predictionOpen => tally.open;

  bool get mvpOpen => mvp.open;

  /// 시안 `mvp.lockTitle` — 왜 아직 못 하는지 상태별로 말한다.
  String get mvpLockTitle => game.status == GameStatus.live
      ? '경기가 진행 중이에요'
      : '아직 경기 전이에요';

  /// 시안 `mvp.hint` — 표 수 옆에 붙는 한 줄.
  String get mvpHint => hasVotedMvp ? '투표 완료' : '한 명을 골라주세요';

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
    PredictionTally? tally,
    MvpBoard? mvp,
    bool? mvpFailed,
    String? notice,
  }) =>
      GameDetailState(
        detail: detail ?? this.detail,
        tab: tab ?? this.tab,
        attended: attended ?? this.attended,
        tally: tally ?? this.tally,
        mvp: mvp ?? this.mvp,
        mvpFailed: mvpFailed ?? this.mvpFailed,
        notice: notice,
      );
}

class GameDetailViewModel
    extends AutoDisposeFamilyAsyncNotifier<GameDetailState, Game> {
  @override
  Future<GameDetailState> build(Game game) async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final api = ref.read(handballApiServiceProvider);

    final detail = await api.fetchGameDetail(game);

    // 집계는 상세와 독립이다. 실패해도 기록·중계는 보여준다.
    var mvpFailed = false;
    final results = await Future.wait([
      _or(() => api.fetchPrediction(detail.game),
          PredictionTally.empty(open: detail.predictionOpen)),
      _or(() => api.fetchMvp(detail.game), const MvpBoard.empty(), () {
        mvpFailed = true;
      }),
    ]);

    return GameDetailState(
      detail: detail,
      // 시안은 경기 전이면 예측 탭, 아니면 중계 탭으로 연다.
      tab: game.status == GameStatus.pre
          ? GameDetailTab.predict
          : GameDetailTab.live,
      attended: prefs.didAttend(game.id),
      tally: results[0] as PredictionTally,
      mvp: results[1] as MvpBoard,
      mvpFailed: mvpFailed,
    );
  }

  Future<T> _or<T>(
    Future<T> Function() run,
    T fallback, [
    void Function()? onFail,
  ]) async {
    try {
      return await run();
    } on ApiException {
      onFail?.call();
      return fallback;
    }
  }

  void selectTab(GameDetailTab tab) {
    final current = state.valueOrNull;
    if (current == null || current.tab == tab) return;
    state = AsyncData(current.copyWith(tab: tab));
  }

  /// 안내 문구를 한 번 읽고 지운다. 스낵바가 두 번 뜨는 걸 막는다.
  void clearNotice() {
    final current = state.valueOrNull;
    if (current?.notice == null) return;
    state = AsyncData(current!.copyWith());
  }

  /// 시안 `retryGame` — 오류 화면의 "다시 시도".
  Future<void> refresh() async {
    state = const AsyncLoading<GameDetailState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => build(arg));
  }

  /// 시안 `toggleAttend`.
  Future<void> toggleAttended() async {
    final current = state.valueOrNull;
    if (current == null || !current.canAttend) return;
    final prefs = ref.read(preferencesRepositoryProvider);
    await ref.read(userRecordsRepositoryProvider).setAttended(
          current.game.id,
          on: !prefs.didAttend(current.game.id),
        );
    state = AsyncData(current.copyWith(attended: !current.attended));
    // 직관 탭·MY가 같은 값을 읽는다. 새로 만들어 두지 않으면 돌아갔을 때
    // 방금 찍은 도장이 없다 — 새로고침해야 나타난다.
    ref
      ..invalidate(attendanceViewModelProvider)
      ..invalidate(myViewModelProvider);
  }

  /// 시안 `pickPred` — 경기 시작 전까지만 바꿀 수 있다.
  ///
  /// 마감 판정은 서버가 하므로, 여기서 막지 않고 `409`를 문구로 바꾼다.
  Future<void> pick(PredictionPick pick) async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      final tally = await ref
          .read(handballApiServiceProvider)
          .submitPrediction(current.game, pick);
      // MY 화면이 "내가 예측한 경기"를 한 번에 보여주려면 목록이 필요한데
      // 서버에 그런 엔드포인트가 없다. 서버가 받아들인 뒤 로컬에도 적어 둔다.
      await ref
          .read(preferencesRepositoryProvider)
          .setPrediction(current.game.id, pick);
      state = AsyncData(current.copyWith(tally: tally));
      ref.read(predictionRevisionProvider.notifier).bump();
      ref
        ..invalidate(predictionViewModelProvider)
        ..invalidate(myViewModelProvider);
    } on ApiException catch (e) {
      state = AsyncData(current.copyWith(notice: _message(e, '예측을 저장하지 못했어요')));
    }
  }

  /// 시안 `voteMvp` — 한 번 뽑으면 바꿀 수 없다.
  Future<void> voteMvp(String candidateId) async {
    final current = state.valueOrNull;
    if (current == null || current.hasVotedMvp) return;

    final candidate = current.mvp.candidates
        .where((c) => c.id == candidateId)
        .firstOrNull;
    if (candidate == null) return;

    try {
      final board = await ref
          .read(handballApiServiceProvider)
          .submitMvpVote(current.game, candidate);
      state = AsyncData(current.copyWith(mvp: board));
    } on ApiException catch (e) {
      state = AsyncData(current.copyWith(notice: _message(e, '투표하지 못했어요')));
    }
  }

  String _message(ApiException e, String fallback) {
    if (e.isRateLimited) return '요청이 너무 잦아요. 잠시 뒤에 다시 시도해 주세요';
    // 409는 서버가 이유를 문구로 준다 (마감·중복 투표).
    if (e.isConflict || e.isBadRequest) return e.message;
    return e.isOffline ? e.message : fallback;
  }
}

final gameDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<GameDetailViewModel, GameDetailState, Game>(
  GameDetailViewModel.new,
);
