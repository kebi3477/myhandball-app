import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';
import '../../domain/models/game_detail.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/nickname.dart';
import '../../domain/models/prediction.dart';
import '../../domain/models/season.dart';
import '../../domain/models/team.dart';
import '../services/device_id_store.dart';
import '../services/mock_handball_api_service.dart';

/// 기기에 남는 사용자 설정의 source of truth.
///
/// `shared_preferences`에 저장하고, 키 이름은 시안이 쓰던 `localStorage`
/// 키를 그대로 이어받는다 — `mh_onboarded`, `mh_guide`, `mh_attended`,
/// `mh_recent_search`, `mh_fav_players`.
///
/// **승부 예측·MVP 투표·응원글은 여기 없다.** 서버로 올라갔다
/// (`/api/game/:matchSeq/{prediction,mvp}`, `/api/team/:teamNum/cheer`).
/// 기기에 쌓여 있던 기존 값은 그때 기기 ID가 없었으므로 옮기지 않는다
/// (`../myhandball-api/docs/api-tasks/05-사용자-콘텐츠.md`).
///
/// 값을 동기로 읽을 수 있게 둔 건, 앱 시작 시 테마가 한 프레임 깜빡이는 걸
/// 막기 위해서다. [load]를 `runApp` 전에 한 번 await 한다.
class PreferencesRepository {
  PreferencesRepository({DeviceIdStore? deviceIds})
      : _deviceIds = deviceIds ?? DeviceIdStore();

  final DeviceIdStore _deviceIds;

  bool _onboarded = AppConfig.skipOnboarding;
  ThemeMode _themeMode =
      AppConfig.initialTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
  /// 개발용 스킵 플래그로 들어올 땐 마이팀도 채워둔다.
  /// 안 그러면 MY팀 달력이 항상 "팀을 골라주세요"로만 보인다.
  Team? _myTeam =
      AppConfig.skipOnboarding ? MockHandballApiService.skHawks : null;
  Gender _preferredGender = Gender.men;
  int _guideDoneCount = 0;

  /// 입문 가이드를 다 끝낸 시각. 수료 배지가 `2026.09.24 수료`로 쓴다.
  ///
  /// **나중에 서버 기준으로 바뀐다.** 지금은 5개를 처음 채운 순간을 적어
  /// 둔다. 그 전에 이미 수료한 사용자는 값이 없고, 그때는 날짜 없이 쓴다.
  DateTime? _guideCompletedAt;

  /// 차단한 작성자의 닉네임. `authorId` → 이름.
  ///
  /// **서버는 차단 목록에 `authorId`와 시각만 준다.** 작성자의 닉네임을
  /// 모르기 때문인데, 그러면 "차단한 사용자" 화면이 해시값 목록이 된다.
  /// 차단하는 순간에는 이름을 알고 있으니 그때 적어 둔다.
  final _blockedNames = <String, String>{};

  /// 업데이트 안내에서 "나중에"를 고른 버전.
  ///
  /// 같은 버전으로는 다시 묻지 않는다. 켤 때마다 알럿이 뜨면 안내가 아니라
  /// 방해가 된다.
  String _skippedUpdateVersion = '';

  /// 시안 `mh_nick` — 경기장에서 불릴 닉네임. 온보딩 5스텝에서 정한다.
  ///
  /// 랭킹에 올리려면 서버에도 있어야 한다 ([cachedProfile]). 이 값은
  /// 프로필을 안 만든 사람에게도 있는 **기기 안의 이름**이다.
  String _nickname = '';

  /// 시안 `mh_profile` — 서버에 올린 랭킹 프로필의 마지막 사본.
  ///
  /// **오프라인에서 "프로필 만들기"로 되돌아가지 않게 하려고 둔다.**
  /// 프로필이 있는데 `GET /api/profile`이 실패했을 때 이 값이 없으면
  /// 화면이 아직 안 만든 사람과 똑같아진다.
  PredictionProfile? _cachedProfile;

  /// 시안 `{{ pv.since }} 가입` — 프로필을 처음 만든 달.
  ///
  /// 서버에 계정이 없으니 "가입"은 닉네임을 정한 시점이다.
  DateTime? _profileCreatedAt;

  /// 시안 `mh_fav_players`
  final _favoritePlayerIds = <String>{};

  /// 시안 `mh_preds` — 경기 id → 내 예측.
  ///
  /// **집계의 source of truth는 서버다.** 이건 MY 화면이 "내가 예측한
  /// 경기들"을 한 번에 보여주려고 두는 로컬 캐시다. 서버에 그런 목록
  /// 엔드포인트가 없어서, 경기마다 요청하는 대신 내가 고른 값만 적어 둔다.
  /// 서버가 받아들인 뒤에만 쓴다.
  final _predictions = <String, PredictionPick>{};

  /// 서버와 아직 못 맞춘 변경. `a+5490` / `a-5490` / `f+69` / `g5` 꼴.
  ///
  /// **오프라인에서 찍은 도장을 잃지 않으려고 둔다.** 다음에 연결되면
  /// [UserRecordsRepository]가 순서대로 다시 보낸다.
  final _pendingSync = <String>[];

  /// 서버와 한 번이라도 맞춰 봤는지.
  ///
  /// 처음 한 번은 기기 값과 서버 값을 **합친다**(어느 쪽도 버리지 않는다).
  /// 그 뒤로는 서버가 정본이다.
  bool _syncedOnce = false;

  /// 시안 `mh_attended` — 직관한 경기 id
  final _attendedGameIds = <String>{};

  /// 시안 `mh_recent_search`
  final _recentSearches = <String>[];

  Season _season = Season.current;

  /// 시안 설정의 알림 토글 (`notifOn`).
  bool _notificationsOn = true;

  /// 서버 쓰기 요청에 붙이는 익명 기기 ID (`X-Device-Id`).
  ///
  /// 회원가입이 없는 앱이라 이걸로 사람을 구분한다. 개인정보가 아닌 난수
  /// UUID v4이고, **iOS에서는 Keychain에 있어 앱을 지워도 남는다**
  /// ([DeviceIdStore]). 안 그러면 재설치할 때마다 새 사람이 돼서 내
  /// 기록을 잃고 MVP를 다시 투표할 수 있게 된다.
  String _deviceId = '';

  String get deviceId => _deviceId;

  SharedPreferences? _prefs;

  /// 영구 저장소에서 한 번에 읽어온다.
  ///
  /// 테마가 첫 프레임에 깜빡이지 않도록 `runApp` 전에 한 번 await 한다.
  /// 저장소를 열지 못해도 앱은 기본값으로 떠야 하므로 예외를 삼킨다.
  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } on Exception {
      _deviceId = await _deviceIds.read();
      return;
    }
    final prefs = _prefs!;

    // **Keychain이 먼저다.** 앱을 지웠다 깔아도 같은 사람으로 남아야
    // 서버에 있는 예측·MVP·응원글이 다시 내 것이 된다. 예전 값은
    // `shared_preferences`에 있으므로 넘겨서 이어받는다.
    _deviceId = await _deviceIds.read(
      legacy: DeviceIdStore.legacyFrom(prefs),
    );
    // Keychain을 못 쓰는 경우를 대비해 같은 값을 여기에도 남긴다.
    await prefs.setString(_kDeviceId, _deviceId);

    // 개발용 dart-define이 켜져 있으면 저장값보다 우선한다.
    _onboarded = AppConfig.skipOnboarding
        ? true
        : prefs.getBool(_kOnboarded) ?? false;

    if (AppConfig.initialTheme.isEmpty) {
      _themeMode =
          prefs.getString(_kTheme) == 'light' ? ThemeMode.light : ThemeMode.dark;
    }

    _preferredGender = Gender.fromCode(prefs.getString(_kGender));
    _guideDoneCount =
        (prefs.getInt(_kGuide) ?? 0).clamp(0, AppConfig.guideLessonCount);
    _notificationsOn = prefs.getBool(_kNotifications) ?? true;
    _nickname = prefs.getString(_kNickname) ?? '';
    final profile = prefs.getString(_kProfile);
    _cachedProfile = profile == null ? null : _decodeProfile(profile);
    _skippedUpdateVersion = prefs.getString(_kSkippedUpdate) ?? '';
    for (final entry in prefs.getStringList(_kBlockedNames) ?? const []) {
      final sep = entry.indexOf(':');
      if (sep > 0) _blockedNames[entry.substring(0, sep)] = entry.substring(sep + 1);
    }
    final graduated = prefs.getString(_kGuideCompletedAt);
    _guideCompletedAt =
        graduated == null ? null : DateTime.tryParse(graduated);
    final joined = prefs.getString(_kProfileCreatedAt);
    _profileCreatedAt = joined == null ? null : DateTime.tryParse(joined);
    _season = Season.fromYear(prefs.getString(_kSeason) ?? Season.current.year);

    for (final entry in prefs.getStringList(_kPredictions) ?? const []) {
      final sep = entry.lastIndexOf(':');
      if (sep <= 0) continue;
      final pick = PredictionPick.fromCode(entry.substring(sep + 1));
      if (pick != null) _predictions[entry.substring(0, sep)] = pick;
    }

    _favoritePlayerIds.addAll(prefs.getStringList(_kFavPlayers) ?? const []);
    _attendedGameIds.addAll(prefs.getStringList(_kAttended) ?? const []);
    _pendingSync.addAll(prefs.getStringList(_kPendingSync) ?? const []);
    _syncedOnce = prefs.getBool(_kSyncedOnce) ?? false;
    _recentSearches.addAll(prefs.getStringList(_kRecentSearch) ?? const []);

    final team = prefs.getString(_kMyTeam);
    if (team != null) _myTeam = _decodeTeam(team) ?? _myTeam;
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await Future.wait([
      prefs.setBool(_kOnboarded, _onboarded),
      prefs.setString(_kTheme, _themeMode == ThemeMode.light ? 'light' : 'dark'),
      prefs.setString(_kGender, _preferredGender.code),
      prefs.setInt(_kGuide, _guideDoneCount),
      prefs.setBool(_kNotifications, _notificationsOn),
      prefs.setString(_kNickname, _nickname),
      if (_cachedProfile case final p?)
        prefs.setString(_kProfile, _encodeProfile(p))
      else
        prefs.remove(_kProfile),
      prefs.setString(_kSkippedUpdate, _skippedUpdateVersion),
      prefs.setStringList(_kBlockedNames,
          [for (final e in _blockedNames.entries) '${e.key}:${e.value}']),
      if (_guideCompletedAt case final at?)
        prefs.setString(_kGuideCompletedAt, at.toIso8601String())
      else
        prefs.remove(_kGuideCompletedAt),
      if (_profileCreatedAt case final at?)
        prefs.setString(_kProfileCreatedAt, at.toIso8601String())
      else
        prefs.remove(_kProfileCreatedAt),
      prefs.setString(_kSeason, _season.year),
      prefs.setStringList(_kFavPlayers, _favoritePlayerIds.toList()),
      prefs.setStringList(_kPredictions,
          [for (final e in _predictions.entries) '${e.key}:${e.value.code}']),
      prefs.setStringList(_kAttended, _attendedGameIds.toList()),
      prefs.setStringList(_kPendingSync, _pendingSync),
      prefs.setBool(_kSyncedOnce, _syncedOnce),
      prefs.setStringList(_kRecentSearch, _recentSearches),
      if (_myTeam case final team?)
        prefs.setString(_kMyTeam, _encodeTeam(team))
      else
        prefs.remove(_kMyTeam),
    ]);
  }

  static String _encodeProfile(PredictionProfile p) => jsonEncode({
        'nickname': p.nickname,
        'teamNum': p.teamNum,
        'teamName': p.teamName,
        'gender': p.gender.code,
        'teamLogoUrl': p.teamLogoUrl,
        'createdAt': p.createdAt?.toIso8601String(),
      });

  static PredictionProfile? _decodeProfile(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map || map['nickname'] is! String) return null;
      return PredictionProfile(
        nickname: map['nickname'] as String,
        teamNum: map['teamNum'] as int? ?? 0,
        teamName: map['teamName'] as String? ?? '',
        gender: Gender.fromCode(map['gender'] as String?),
        teamLogoUrl: map['teamLogoUrl'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      );
    } on FormatException {
      return null;
    }
  }

  static String _encodeTeam(Team team) => jsonEncode({
        'name': team.name,
        'gender': team.gender.code,
        'teamNum': team.teamNum,
        'logoUrl': team.logoUrl,
      });

  static Team? _decodeTeam(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map || map['name'] is! String) return null;
      return Team(
        name: map['name'] as String,
        gender: Gender.fromCode(map['gender'] as String?),
        teamNum: map['teamNum'] as int?,
        logoUrl: map['logoUrl'] as String?,
      );
    } on FormatException {
      return null;
    }
  }

  static const _kDeviceId = 'mh_device_id';
  static const _kOnboarded = 'mh_onboarded';
  static const _kTheme = 'mh_theme';
  static const _kGender = 'mh_gender';
  static const _kGuide = 'mh_guide';
  static const _kNotifications = 'mh_notif';
  static const _kSeason = 'mh_season';
  static const _kMyTeam = 'mh_my_team';
  static const _kFavPlayers = 'mh_fav_players';
  static const _kAttended = 'mh_attended';
  static const _kPendingSync = 'mh_sync_pending';
  static const _kSyncedOnce = 'mh_synced';
  static const _kRecentSearch = 'mh_recent_search';
  static const _kPredictions = 'mh_preds';
  static const _kNickname = 'mh_nick';
  static const _kSkippedUpdate = 'mh_update_skipped';
  static const _kGuideCompletedAt = 'mh_guide_done_at';
  static const _kBlockedNames = 'mh_blocked_names';
  static const _kProfileCreatedAt = 'mh_joined';
  static const _kProfile = 'mh_profile';

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

  Map<String, PredictionPick> get predictions => Map.unmodifiable(_predictions);

  PredictionPick? predictionFor(String gameId) => _predictions[gameId];

  Future<void> setPrediction(String gameId, PredictionPick pick) async {
    _predictions[gameId] = pick;
    await _persist();
  }

  Set<String> get attendedGameIds => Set.unmodifiable(_attendedGameIds);

  // --- 서버 동기화용 ---

  bool get syncedOnce => _syncedOnce;

  List<String> get pendingSync => List.unmodifiable(_pendingSync);

  /// 같은 대상에 대한 앞선 변경은 지운다 — 마지막 것만 보내면 된다.
  ///
  /// **부호는 대상의 일부가 아니다.** `a+4444` 다음에 `a-4444`가 오면
  /// 둘 다 보내는 게 아니라 뒤엣것만 남아야 한다.
  Future<void> addPendingSync(String op) async {
    final target = _syncTarget(op);
    _pendingSync.removeWhere((e) => _syncTarget(e) == target);
    _pendingSync.add(op);
    await _persist();
  }

  /// `a+4444` → `a4444`, `g5` → `g`. 가이드 진행도는 대상이 하나뿐이다.
  static String _syncTarget(String op) =>
      op.startsWith('g') ? 'g' : '${op[0]}${op.substring(2)}';

  Future<void> clearPendingSync(Iterable<String> done) async {
    _pendingSync.removeWhere(done.contains);
    await _persist();
  }

  /// 서버가 준 목록으로 통째로 바꾼다. 동기화가 끝난 뒤에만 부른다.
  Future<void> replaceSynced({
    Set<String>? attended,
    Set<String>? favoritePlayers,
  }) async {
    if (attended != null) {
      _attendedGameIds
        ..clear()
        ..addAll(attended);
    }
    if (favoritePlayers != null) {
      _favoritePlayerIds
        ..clear()
        ..addAll(favoritePlayers);
    }
    _syncedOnce = true;
    await _persist();
  }

  /// 서버가 준 가이드 진행도를 적는다.
  ///
  /// **진행도는 줄지 않는다.** 서버 응답은 늦게 도착하므로 그대로 덮어쓰면
  /// 그 사이에 끝낸 레슨이 되돌아간다 — 3번을 끝내고 4번까지 끝냈는데
  /// 3번의 응답이 도착해 다시 3이 되는 식이다. 서버도 같은 규칙으로
  /// 큰 값을 유지한다.
  ///
  /// 수료일은 서버 것을 쓴다 — 기기를 바꿨다고 수료일이 오늘로 밀리면
  /// 배지의 "2026.09.24 수료"가 거짓이 된다.
  Future<void> applyGuideProgress(int doneCount, DateTime? completedAt) async {
    final next = doneCount.clamp(0, AppConfig.guideLessonCount);
    if (next > _guideDoneCount) _guideDoneCount = next;
    if (completedAt != null) _guideCompletedAt = completedAt;
    await _persist();
  }

  bool didAttend(String gameId) => _attendedGameIds.contains(gameId);

  /// 켜고 끄기를 명시적으로. 서버에 같은 동작을 보내야 해서, 부르는 쪽이
  /// 결과를 알아야 한다 ([UserRecordsRepository]).
  Future<void> setAttended(String gameId, {required bool on}) async {
    if (on) {
      _attendedGameIds.add(gameId);
    } else {
      _attendedGameIds.remove(gameId);
    }
    await _persist();
  }

  Future<void> toggleAttended(String gameId) async {
    if (!_attendedGameIds.remove(gameId)) _attendedGameIds.add(gameId);
    await _persist();
  }

  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  Future<void> addRecentSearch(String query) async {
    _recentSearches
      ..remove(query)
      ..insert(0, query);
    // 시안과 같이 최근 것만 남긴다.
    if (_recentSearches.length > 10) _recentSearches.removeLast();
    await _persist();
  }

  Future<void> removeRecentSearch(String query) async {
    _recentSearches.remove(query);
    await _persist();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    await _persist();
  }

  Season get season => _season;

  Future<void> setSeason(Season value) async {
    _season = value;
    await _persist();
  }

  bool get notificationsOn => _notificationsOn;

  Future<void> setNotificationsOn({required bool value}) async {
    _notificationsOn = value;
    await _persist();
  }

  Set<String> get favoritePlayerIds => Set.unmodifiable(_favoritePlayerIds);

  bool isFavoritePlayer(String id) => _favoritePlayerIds.contains(id);

  Future<void> setFavoritePlayer(String id, {required bool on}) async {
    if (on) {
      _favoritePlayerIds.add(id);
    } else {
      _favoritePlayerIds.remove(id);
    }
    await _persist();
  }

  Future<void> toggleFavoritePlayer(String id) async {
    if (!_favoritePlayerIds.remove(id)) _favoritePlayerIds.add(id);
    await _persist();
  }

  /// 마지막으로 확인된 랭킹 프로필. 서버가 정본이고 이건 사본이다.
  PredictionProfile? get cachedProfile => _cachedProfile;

  /// 서버 응답을 그대로 적어 둔다. `null`이면 지운다(랭킹 참여 중단).
  ///
  /// 닉네임도 같이 맞춰 둔다 — 프로필을 만들면 MY 화면의 이름도 그 이름이다.
  Future<void> setCachedProfile(PredictionProfile? profile) async {
    _cachedProfile = profile;
    if (profile != null) {
      _nickname = profile.nickname;
      _profileCreatedAt = profile.createdAt ?? _profileCreatedAt ?? DateTime.now();
    }
    await _persist();
  }

  /// 시안 `nick`. 아직 안 정했으면 빈 문자열이다.
  String get nickname => _nickname;

  bool get hasNickname => _nickname.isNotEmpty;

  /// `2026.09 가입` — 프로필을 만든 달.
  String? get joinedLabel {
    final at = _profileCreatedAt;
    if (at == null) return null;
    return '${at.year}.${at.month.toString().padLeft(2, '0')}';
  }

  /// 닉네임을 저장한다. 빈 값을 주면 지운다.
  ///
  /// 처음 정하는 순간을 가입 시점으로 잡아 둔다. 이미 있으면 덮어쓰지
  /// 않는다 — 닉네임을 바꿨다고 가입일이 오늘로 밀리면 안 된다.
  Future<void> setNickname(String value) async {
    final next = Nickname.normalize(value);
    _nickname = next;
    if (next.isEmpty) {
      _profileCreatedAt = null;
    } else {
      _profileCreatedAt ??= DateTime.now();
    }
    await _persist();
  }

  /// 업데이트 안내를 미룬 버전. 아직 미룬 적 없으면 빈 문자열.
  String get skippedUpdateVersion => _skippedUpdateVersion;

  Future<void> skipUpdateVersion(String version) async {
    _skippedUpdateVersion = version;
    await _persist();
  }

  DateTime? get guideCompletedAt => _guideCompletedAt;

  /// 차단한 사람이 있는지. **서버가 "숨긴 글 n개"를 주지 않아서**
  /// 응원글 탭이 이걸로 "숨긴 글이 있다"를 판단한다.
  bool get hasBlockedAuthors => _blockedNames.isNotEmpty;

  /// 차단할 때 봤던 닉네임. 모르면 `null`.
  String? blockedName(String authorId) => _blockedNames[authorId];

  Future<void> rememberBlockedName(String authorId, String nickname) async {
    _blockedNames[authorId] = nickname;
    await _persist();
  }

  Future<void> forgetBlockedName(String authorId) async {
    _blockedNames.remove(authorId);
    await _persist();
  }

  Future<void> setGuideDoneCount(int value) async {
    _guideDoneCount = value.clamp(0, AppConfig.guideLessonCount);
    // 처음 다 채운 순간만 적는다. 다시 들어가도 날짜가 오늘로 밀리면 안 된다.
    if (_guideDoneCount >= AppConfig.guideLessonCount) {
      _guideCompletedAt ??= DateTime.now();
    }
    await _persist();
  }
}

/// `main()`에서 [PreferencesRepository.load] 후 override 한다.
final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (_) => throw UnimplementedError('main()에서 override 해야 합니다'),
);
