import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 익명 기기 ID(`X-Device-Id`)를 **앱을 지워도 남는 자리**에 둔다.
///
/// 서버는 회원가입이 없어서 이 ID 하나로 사람을 구분한다. 예측·MVP 투표·
/// 응원글이 전부 여기 걸려 있다. 이 값이 `shared_preferences`에만 있으면
/// 앱을 지웠다 깔 때마다 새 사람이 되고, 그러면
///
/// - 서버에 남아 있는 내 예측·응원글을 다시 못 찾고
/// - **같은 경기에 MVP를 다시 투표할 수 있어 집계가 오염된다**
///
/// iOS Keychain은 앱을 지워도 항목이 남는다. Apple이 문서로 보장하는
/// 동작은 아니지만 실제로 그렇게 동작하고, 이런 용도로 널리 쓰인다.
///
/// **안드로이드는 이걸로 해결되지 않는다.** flutter_secure_storage가
/// EncryptedSharedPreferences를 쓰는데 앱을 지우면 같이 지워진다.
/// 안드로이드는 Auto Backup에 기대야 하고, 확실히 하려면 계정 로그인이
/// 필요하다.
/// 지워지지 않는 저장소. 테스트가 갈아끼울 수 있게 앱이 가진 인터페이스다.
///
/// `flutter_secure_storage`를 직접 상속하면 패키지가 메서드 시그니처를
/// 바꿀 때마다 테스트가 깨진다.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// iOS Keychain / 안드로이드 암호화 저장소를 쓰는 실제 구현.
class KeychainStore implements SecureStore {
  const KeychainStore();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      // 기기가 한 번 잠금 해제된 뒤라면 백그라운드에서도 읽힌다.
      // 기본값(unlocked)이면 잠긴 화면에서 푸시 등록이 실패한다.
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    // 안드로이드는 기본 암호화 저장소를 그대로 쓴다. 어차피 앱을 지우면
    // 같이 지워져서 여기서 더 할 수 있는 게 없다.
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class DeviceIdStore {
  DeviceIdStore({SecureStore? secure}) : _secure = secure ?? const KeychainStore();

  final SecureStore _secure;

  static const _key = 'mh_device_id';

  /// 서버는 영문·숫자·하이픈 8~64자만 받는다.
  static final _valid = RegExp(r'^[A-Za-z0-9-]{8,64}$');

  static bool isValid(String? value) =>
      value != null && _valid.hasMatch(value);

  /// 기기 ID를 읽어온다. 없으면 만들고, 예전 값이 있으면 옮겨 온다.
  ///
  /// [legacy]는 `shared_preferences`에 남아 있던 값이다. **이미 쓰던
  /// 사용자의 ID를 그대로 이어받아야** 서버에 쌓인 기록을 안 잃는다.
  Future<String> read({String? legacy}) async {
    final stored = await _readSecure();
    if (isValid(stored)) return stored!;

    // 지금까지 쓰던 값이 있으면 그걸 Keychain으로 옮긴다.
    if (isValid(legacy)) {
      await _writeSecure(legacy!);
      return legacy;
    }

    final fresh = newId();
    await _writeSecure(fresh);
    return fresh;
  }

  Future<String?> _readSecure() async {
    try {
      return await _secure.read(_key);
    } on Object catch (e) {
      // **Exception만 잡으면 안 된다.** 플러그인이 없는 환경에서는
      // `Error`(바인딩 미초기화, MissingPluginException)가 올라온다.
      // 기기 ID 하나 때문에 앱이 못 뜨는 일은 없어야 한다.
      if (kDebugMode) debugPrint('[MyHandball] 기기 ID 읽기 실패: $e');
      return null;
    }
  }

  Future<void> _writeSecure(String value) async {
    try {
      await _secure.write(_key, value);
    } on Object catch (e) {
      if (kDebugMode) debugPrint('[MyHandball] 기기 ID 저장 실패: $e');
    }
  }

  /// UUID v4. 이것 하나 때문에 uuid 패키지를 들이지 않는다.
  static String newId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  /// `shared_preferences`에 남아 있는 예전 값. 옮겨 온 뒤에도 지우지 않는다 —
  /// Keychain을 못 쓰는 상황에서 마지막으로 기댈 자리다.
  static String? legacyFrom(SharedPreferences prefs) =>
      prefs.getString(_key);
}
