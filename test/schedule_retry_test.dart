import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/services/api_client.dart';
import 'package:myhandball/data/services/mock_handball_api_service.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/domain/models/schedule_day.dart';
import 'package:myhandball/ui/schedule/view_models/schedule_view_model.dart';

/// 오류 화면의 "다시 시도"가 실제로 다시 받아와야 한다.
///
/// 예전에는 `refresh()`가 첫 줄에서 `state.valueOrNull`이 null이면 그냥
/// 돌아갔다. **오류 화면에는 이전 값이 없으므로** 버튼을 눌러도 아무 일도
/// 일어나지 않았다 — 연결이 돌아와도 앱을 껐다 켜야 했다.
class _FlakyApi extends MockHandballApiService {
  _FlakyApi() : super(latency: Duration.zero);

  bool down = true;

  @override
  Future<List<ScheduleDay>> fetchSeasonSchedule(Gender gender,
      {String? season}) async {
    if (down) throw const ApiException('서버에 연결하지 못했어요');
    return super.fetchSeasonSchedule(gender, season: season);
  }

  @override
  Future<List<ScheduleDay>> fetchMonthlySchedule(Gender gender, DateTime month,
      {String? season}) async {
    if (down) throw const ApiException('서버에 연결하지 못했어요');
    return super.fetchMonthlySchedule(gender, month, season: season);
  }
}

void main() {
  test('오류 상태에서 다시 시도하면 새로 받아온다', () async {
    final api = _FlakyApi();
    final container = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(PreferencesRepository()),
      handballApiServiceProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);

    await expectLater(
        container.read(scheduleViewModelProvider.future), throwsA(anything));
    expect(container.read(scheduleViewModelProvider).hasError, isTrue);

    // 연결이 돌아왔다.
    api.down = false;
    await container.read(scheduleViewModelProvider.notifier).refresh();

    expect(container.read(scheduleViewModelProvider).hasError, isFalse);
    expect(container.read(scheduleViewModelProvider).valueOrNull, isNotNull);
  });
}
