import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/gender.dart';
import '../../domain/models/prediction.dart';
import '../services/handball_api_service.dart';
import 'preferences_repository.dart';
import 'schedule_repository.dart' show handballApiServiceProvider;

/// 승부예측 랭킹 프로필의 source of truth. `GET/PUT/DELETE /api/profile`.
///
/// 회원가입이 아니다. 서버는 `X-Device-Id`로 사람을 구분하고, 닉네임과
/// 응원팀만 갖는다.
///
/// **조회 실패는 "프로필 없음"이 아니다.** 그렇게 다루면 지하철에서 앱을
/// 연 사람에게 "프로필을 만들어 보세요"가 뜨고, 거기서 저장하면 닉네임
/// 중복(409)으로 막힌다. 그래서 마지막 응답을 기기에 적어 두고
/// ([PreferencesRepository.cachedProfile]) 실패하면 그걸 쓴다.
class ProfileRepository {
  ProfileRepository(this._service, this._prefs);

  final HandballApiService _service;
  final PreferencesRepository _prefs;

  bool _loaded = false;

  /// 서버에서 한 번 확인한 뒤로는 세션 동안 다시 묻지 않는다.
  Future<PredictionProfile?> get({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return _prefs.cachedProfile;
    try {
      final profile = await _service.fetchProfile();
      _loaded = true;
      await _prefs.setCachedProfile(profile);
      return profile;
    } on Exception {
      return _prefs.cachedProfile;
    }
  }

  /// 저장은 실패를 감추지 않는다. 중복 닉네임(409)은 그대로 올려 보낸다.
  Future<PredictionProfile> save({
    required String nickname,
    required int teamNum,
    required Gender gender,
  }) async {
    final profile = await _service.saveProfile(
      nickname: nickname,
      teamNum: teamNum,
      gender: gender,
    );
    _loaded = true;
    await _prefs.setCachedProfile(profile);
    return profile;
  }

  /// 랭킹 참여 중단. 예측 기록은 기기에도 서버에도 남는다.
  Future<void> leave() async {
    await _service.deleteProfile();
    _loaded = true;
    await _prefs.setCachedProfile(null);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(handballApiServiceProvider),
    ref.watch(preferencesRepositoryProvider),
  ),
);

/// 프로필을 보는 화면들이 같은 값을 보게 하는 통로.
///
/// 시트에서 저장하면 승부예측 탭 카드와 MY 프로필 카드가 같이 바뀐다.
class ProfileNotifier extends AsyncNotifier<PredictionProfile?> {
  @override
  Future<PredictionProfile?> build() =>
      ref.watch(profileRepositoryProvider).get();

  Future<PredictionProfile> save({
    required String nickname,
    required int teamNum,
    required Gender gender,
  }) async {
    final profile = await ref.read(profileRepositoryProvider).save(
          nickname: nickname,
          teamNum: teamNum,
          gender: gender,
        );
    state = AsyncData(profile);
    return profile;
  }

  Future<void> leave() async {
    await ref.read(profileRepositoryProvider).leave();
    state = const AsyncData(null);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, PredictionProfile?>(
  ProfileNotifier.new,
);
