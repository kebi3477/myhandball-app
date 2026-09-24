import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/handball_api_service.dart';
import 'preferences_repository.dart';
import 'schedule_repository.dart' show handballApiServiceProvider;

/// 직관 기록 · 관심 선수 · 가이드 진행도를 서버와 맞춘다.
///
/// 셋 다 **기기에도 있고 서버에도 있는** 값이라 규칙이 같고, 그래서 한
/// 곳에 둔다. 따로 짜면 한쪽만 대기열을 안 비우는 식으로 어긋난다.
///
/// 규칙:
///
/// - **화면은 언제나 기기 값을 읽는다** (`PreferencesRepository`). 서버를
///   기다렸다 그리면 도장을 찍고 나서 한 박자 뒤에 체크가 들어온다
/// - 쓰기는 기기에 적고 **서버 응답은 기다리지 않는다.** 기다리면 체크
///   하나 켜는 데 최대 8초(요청 타임아웃)가 걸린다. 실패하면 대기열에
///   남긴다 (시안 토스트: "기기에 저장했어요. 연결되면 자동으로 동기화돼요.")
/// - **첫 동기화만 합집합**이다. 앱을 쓰다 로그인 없이 서버가 생긴 상황이라
///   기기에 쌓인 기록을 버리면 안 된다. 그 뒤로는 서버가 정본이다
/// - 서버 값을 덮어쓴 뒤 **대기열을 다시 얹는다.** 안 그러면 오프라인에서
///   찍은 도장이 화면에서 잠깐 사라진다
///
/// `matchSeq`/`playerSeq`가 없는 항목은 서버에 보낼 수 없다 — 경기 id가
/// `g5490` 꼴이 아니거나 선수 id가 `n:이름` 꼴인 경우다. 기기에만 남긴다.
class UserRecordsRepository {
  UserRecordsRepository(this._service, this._prefs);

  final HandballApiService _service;
  final PreferencesRepository _prefs;

  bool _syncing = false;

  /// 아직 서버 응답을 기다리는 쓰기.
  ///
  /// 화면은 기기 값을 읽고 바로 넘어가므로 평소에는 아무도 안 기다린다.
  /// 테스트가 "대기열에 남았는지"를 확인하려면 이게 끝나야 한다.
  Future<void> _inFlight = Future.value();

  @visibleForTesting
  Future<void> settled() => _inFlight;

  /// 셸에 들어올 때 한 번 부른다. 실패해도 조용히 넘어간다 —
  /// 동기화 때문에 앱이 멈추면 안 된다.
  Future<void> sync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _flushPending();
      await _pull();
    } on Exception {
      // 다음 기회에 다시 한다. 기기 값은 그대로다.
    } finally {
      _syncing = false;
    }
  }

  Future<void> setAttended(String gameId, {required bool on}) async {
    await _prefs.setAttended(gameId, on: on);
    final seq = _seq(gameId, 'g');
    if (seq == null) return;
    unawaited(_push(
      'a${on ? '+' : '-'}$seq',
      () => on ? _service.addAttendance(seq) : _service.removeAttendance(seq),
    ));
  }

  Future<void> setFavoritePlayer(String playerId, {required bool on}) async {
    await _prefs.setFavoritePlayer(playerId, on: on);
    final seq = _seq(playerId, 'p');
    if (seq == null) return;
    unawaited(_push(
      'f${on ? '+' : '-'}$seq',
      () => on
          ? _service.addFavoritePlayer(seq)
          : _service.removeFavoritePlayer(seq),
    ));
  }

  Future<void> setGuideDone(int doneCount) async {
    await _prefs.setGuideDoneCount(doneCount);
    unawaited(_push('g$doneCount', () async {
      final progress = await _service.saveGuideProgress(doneCount);
      // 서버가 더 큰 값을 갖고 있으면 그걸 따른다.
      await _prefs.applyGuideProgress(progress.doneCount, progress.completedAt);
    }));
  }

  /// 서버에 보내고, 실패하면 대기열에 남긴다.
  Future<void> _push(String op, Future<void> Function() send) {
    // 순서를 지킨다 — 같은 경기를 켰다 끄면 그 순서대로 나가야 한다.
    return _inFlight = _inFlight.then((_) async {
      try {
        await send();
      } on Exception {
        await _prefs.addPendingSync(op);
      }
    });
  }

  Future<void> _flushPending() async {
    final done = <String>[];
    for (final op in _prefs.pendingSync) {
      try {
        await _apply(op);
        done.add(op);
      } on Exception {
        // 하나가 막히면 나머지도 어차피 막힌다. 순서를 지켜 멈춘다.
        break;
      }
    }
    if (done.isNotEmpty) await _prefs.clearPendingSync(done);
  }

  Future<void> _apply(String op) async {
    if (op.startsWith('g')) {
      await _service.saveGuideProgress(int.parse(op.substring(1)));
      return;
    }
    final on = op[1] == '+';
    final seq = int.parse(op.substring(2));
    switch (op[0]) {
      case 'a':
        await (on
            ? _service.addAttendance(seq)
            : _service.removeAttendance(seq));
      case 'f':
        await (on
            ? _service.addFavoritePlayer(seq)
            : _service.removeFavoritePlayer(seq));
    }
  }

  Future<void> _pull() async {
    final (attendance, favorites, guide) = await (
      _service.fetchAttendance(),
      _service.fetchFavoritePlayers(),
      _service.fetchGuideProgress(),
    ).wait;

    final serverGames = {for (final seq in attendance) 'g$seq'};
    final serverPlayers = {for (final seq in favorites) 'p$seq'};

    if (!_prefs.syncedOnce) {
      // 첫 동기화 — 어느 쪽도 버리지 않고 기기에만 있던 것을 올린다.
      await _pushLocalOnly(serverGames, serverPlayers, guide.doneCount);
      await _prefs.replaceSynced(
        attended: {..._prefs.attendedGameIds, ...serverGames},
        favoritePlayers: {..._prefs.favoritePlayerIds, ...serverPlayers},
      );
      // 진행도는 큰 쪽이 이긴다 (서버도 같은 규칙이다).
      if (guide.doneCount > _prefs.guideDoneCount) {
        await _prefs.applyGuideProgress(guide.doneCount, guide.completedAt);
      }
      return;
    }

    await _prefs.replaceSynced(
      // 서버가 모르는 id(직접 만든 경기 키)는 그대로 둔다.
      attended: {
        ...serverGames,
        ..._prefs.attendedGameIds.where((id) => _seq(id, 'g') == null),
      },
      favoritePlayers: {
        ...serverPlayers,
        ..._prefs.favoritePlayerIds.where((id) => _seq(id, 'p') == null),
      },
    );
    await _prefs.applyGuideProgress(guide.doneCount, guide.completedAt);
    await _replayPending();
  }

  /// 기기에만 있던 기록을 서버로 올린다. 하나 실패해도 나머지는 계속한다.
  Future<void> _pushLocalOnly(
    Set<String> serverGames,
    Set<String> serverPlayers,
    int serverGuide,
  ) async {
    for (final id in _prefs.attendedGameIds) {
      if (serverGames.contains(id)) continue;
      if (_seq(id, 'g') case final seq?) {
        await _push('a+$seq', () => _service.addAttendance(seq));
      }
    }
    for (final id in _prefs.favoritePlayerIds) {
      if (serverPlayers.contains(id)) continue;
      if (_seq(id, 'p') case final seq?) {
        await _push('f+$seq', () => _service.addFavoritePlayer(seq));
      }
    }
    if (_prefs.guideDoneCount > serverGuide) {
      await _push('g${_prefs.guideDoneCount}',
          () => _service.saveGuideProgress(_prefs.guideDoneCount));
    }
  }

  /// 서버 값으로 덮어쓴 뒤, 아직 못 보낸 변경을 화면에 다시 얹는다.
  Future<void> _replayPending() async {
    for (final op in _prefs.pendingSync) {
      if (op.startsWith('g')) continue;
      final on = op[1] == '+';
      final id = '${op[0] == 'a' ? 'g' : 'p'}${op.substring(2)}';
      if (op[0] == 'a') {
        await _prefs.setAttended(id, on: on);
      } else {
        await _prefs.setFavoritePlayer(id, on: on);
      }
    }
  }

  /// `g5490` → 5490. 접두어가 다르거나 숫자가 아니면 `null`.
  static int? _seq(String id, String prefix) {
    if (!id.startsWith(prefix)) return null;
    return int.tryParse(id.substring(prefix.length));
  }
}

final userRecordsRepositoryProvider = Provider<UserRecordsRepository>(
  (ref) => UserRecordsRepository(
    ref.watch(handballApiServiceProvider),
    ref.watch(preferencesRepositoryProvider),
  ),
);
