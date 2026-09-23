import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/team.dart';

/// 기기에 남는 사용자 설정의 source of truth.
///
/// 아직 메모리에만 들고 있다. [load]/[_persist]가 `shared_preferences`를
/// 붙일 자리이고, 키 이름은 시안이 쓰던 `localStorage` 키를 그대로 이어받는다
/// — `mh_onboarded`, `mh_guide`, `mh_preds`, `mh_mvp`, `mh_attended`,
/// `mh_recent_search`, `mh_cheer`, `mh_fav_players`.
///
/// 값을 동기로 읽을 수 있게 둔 건, 앱 시작 시 테마가 한 프레임 깜빡이는 걸
/// 막기 위해서다. [load]를 `runApp` 전에 한 번 await 한다.
class PreferencesRepository {
  bool _onboarded = AppConfig.skipOnboarding;
  ThemeMode _themeMode = ThemeMode.dark;
  Team? _myTeam;
  Gender _preferredGender = Gender.men;
  int _guideDoneCount = 0;

  /// 영구 저장소에서 한 번에 읽어온다. 지금은 할 일이 없다.
  Future<void> load() async {}

  Future<void> _persist() async {}

  /// 시안 `mh_onboarded`
  bool get onboarded => _onboarded;

  /// 시안은 다크로 시작한다 (`theme: 'dark'`). v1 웹은 라이트 기본이었다.
  ThemeMode get themeMode => _themeMode;

  Team? get myTeam => _myTeam;

  Gender get preferredGender => _preferredGender;

  /// 시안 `guideDone` — 총 [AppConfig.guideLessonCount] 중 완료 수.
  int get guideDoneCount => _guideDoneCount;

  Future<void> setOnboarded({required bool value}) async {
    _onboarded = value;
    await _persist();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _persist();
  }

  Future<void> setMyTeam(Team? team) async {
    _myTeam = team;
    await _persist();
  }

  Future<void> setPreferredGender(Gender gender) async {
    _preferredGender = gender;
    await _persist();
  }

  Future<void> setGuideDoneCount(int value) async {
    _guideDoneCount = value.clamp(0, AppConfig.guideLessonCount);
    await _persist();
  }
}

/// `main()`에서 [PreferencesRepository.load] 후 override 한다.
final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (_) => throw UnimplementedError('main()에서 override 해야 합니다'),
);
