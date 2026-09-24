import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/services/device_id_store.dart';

/// 기기 ID가 바뀌면 서버가 다른 사람으로 본다 — 내 예측·응원글을 잃고
/// **같은 경기에 MVP를 다시 투표할 수 있게 된다.** 그래서 앱을 지웠다
/// 깔아도(=Keychain에 값이 남아 있는 상태) 같은 값이 나와야 한다.
class _FakeSecure implements SecureStore {
  _FakeSecure({Map<String, String> store = const {}, this.broken = false})
      : values = Map.of(store);

  final Map<String, String> values;
  final bool broken;

  @override
  Future<String?> read(String key) async {
    if (broken) throw Exception('keychain 사용 불가');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (broken) throw Exception('keychain 사용 불가');
    values[key] = value;
  }
}

void main() {
  test('Keychain에 값이 있으면 그대로 쓴다', () async {
    // 앱을 지웠다 다시 깐 상황. 예전 기록이 다시 내 것이 돼야 한다.
    final secure = _FakeSecure(
      store: const {'mh_device_id': '11111111-2222-3333-4444-555555555555'},
    );
    final id = await DeviceIdStore(secure: secure).read();

    expect(id, '11111111-2222-3333-4444-555555555555');
  });

  test('예전 값이 있으면 Keychain으로 옮겨 이어받는다', () async {
    // 이번 버전으로 올라온 기존 사용자. ID가 바뀌면 안 된다.
    final secure = _FakeSecure();
    const legacy = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

    final id = await DeviceIdStore(secure: secure).read(legacy: legacy);

    expect(id, legacy);
    expect(secure.values['mh_device_id'], legacy);
  });

  test('형식이 깨진 예전 값은 이어받지 않는다', () async {
    final secure = _FakeSecure();
    final id = await DeviceIdStore(secure: secure).read(legacy: 'short');

    expect(id, isNot('short'));
    expect(DeviceIdStore.isValid(id), isTrue);
  });

  test('처음이면 새로 만들어 Keychain에 남긴다', () async {
    final secure = _FakeSecure();
    final id = await DeviceIdStore(secure: secure).read();

    expect(DeviceIdStore.isValid(id), isTrue);
    expect(secure.values['mh_device_id'], id);
  });

  test('Keychain을 못 써도 앱은 떠야 한다', () async {
    final secure = _FakeSecure(broken: true);
    final id = await DeviceIdStore(secure: secure).read(legacy: null);

    expect(DeviceIdStore.isValid(id), isTrue);
  });
}
