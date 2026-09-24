import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/repositories/user_records_repository.dart';
import 'package:myhandball/data/services/api_client.dart';
import 'package:myhandball/data/services/mock_handball_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 직관 기록·관심 선수·가이드 진행도를 서버와 맞추는 규칙.
///
/// **기기에만 있던 기록을 잃으면 안 된다.** 앱을 쓰다가 서버가 생긴
/// 상황이라 첫 동기화는 합집합이고, 오프라인에서 찍은 도장은 대기열에
/// 남았다가 다시 올라간다.
class _OfflineApi extends MockHandballApiService {
  const _OfflineApi() : super(latency: Duration.zero);

  static const _down = ApiException('서버에 연결하지 못했어요');

  @override
  Future<void> addAttendance(int matchSeq) async => throw _down;

  @override
  Future<void> removeAttendance(int matchSeq) async => throw _down;

  @override
  Future<List<int>> fetchAttendance() async => throw _down;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MockHandballApiService.resetUserContent();
  });

  Future<(ProviderContainer, PreferencesRepository)> make([
    MockHandballApiService api = const MockHandballApiService(
        latency: Duration.zero),
  ]) async {
    final prefs = PreferencesRepository();
    await prefs.load();
    final container = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(prefs),
      handballApiServiceProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    return (container, prefs);
  }

  test('첫 동기화는 기기와 서버를 합친다', () async {
    // 앱을 쓰다가 서버가 생긴 상황. 어느 쪽도 버리면 안 된다.
    const api = MockHandballApiService(latency: Duration.zero);
    await api.addAttendance(1111);

    final (container, prefs) = await make();
    await prefs.setAttended('g2222', on: true);

    await container.read(userRecordsRepositoryProvider).sync();

    expect(prefs.attendedGameIds, {'g1111', 'g2222'});
    // 기기에만 있던 것은 서버로 올라간다.
    expect(await api.fetchAttendance(), containsAll([1111, 2222]));
    expect(prefs.syncedOnce, isTrue);
  });

  test('두 번째부터는 서버가 정본이다', () async {
    const api = MockHandballApiService(latency: Duration.zero);
    final (container, prefs) = await make();
    final repo = container.read(userRecordsRepositoryProvider);

    await repo.setAttended('g1111', on: true);
    await repo.setAttended('g2222', on: true);
    await repo.sync();
    expect(prefs.attendedGameIds, {'g1111', 'g2222'});

    // 다른 기기에서 하나를 뺀 셈.
    await api.removeAttendance(2222);
    await repo.sync();

    expect(prefs.attendedGameIds, {'g1111'});
  });

  test('서버에 보낼 수 없는 id는 기기에 남는다', () async {
    // 상세가 없는 경기는 `g{matchSeq}` 꼴이 아니라 날짜로 만든 키를 쓴다.
    final (container, prefs) = await make();
    final repo = container.read(userRecordsRepositoryProvider);

    await repo.setAttended('2026-11-14-두산-SK호크스', on: true);
    await repo.sync();

    expect(prefs.attendedGameIds, {'2026-11-14-두산-SK호크스'});
  });

  test('오프라인에서 찍은 도장은 대기열에 남았다가 올라간다', () async {
    final (container, prefs) = await make(const _OfflineApi());
    final repo = container.read(userRecordsRepositoryProvider);
    await repo.setAttended('g3333', on: true);
    // 서버로 보내는 건 화면을 막지 않으므로 따로 기다린다.
    await repo.settled();

    // 기기에는 바로 보인다. 화면이 기기 값을 읽기 때문이다.
    expect(prefs.didAttend('g3333'), isTrue);
    expect(prefs.pendingSync, ['a+3333']);

    // 연결이 돌아오면 그대로 올라간다.
    const api = MockHandballApiService(latency: Duration.zero);
    final online = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(prefs),
      handballApiServiceProvider.overrideWithValue(api),
    ]);
    addTearDown(online.dispose);

    await online.read(userRecordsRepositoryProvider).sync();

    expect(prefs.pendingSync, isEmpty);
    expect(await api.fetchAttendance(), [3333]);
    expect(prefs.didAttend('g3333'), isTrue);
  });

  test('같은 대상을 여러 번 바꾸면 마지막 것만 보낸다', () async {
    final (container, prefs) = await make(const _OfflineApi());
    final repo = container.read(userRecordsRepositoryProvider);

    await repo.setAttended('g4444', on: true);
    await repo.setAttended('g4444', on: false);
    await repo.settled();

    expect(prefs.pendingSync, ['a-4444']);
  });

  test('진행도는 줄지 않는다', () async {
    // 늦게 도착한 서버 응답이 그 사이에 끝낸 레슨을 되돌리면 안 된다.
    final (_, prefs) = await make();
    await prefs.setGuideDoneCount(4);
    await prefs.applyGuideProgress(2, null);

    expect(prefs.guideDoneCount, 4);
  });
}
