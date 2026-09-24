import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/services/mock_handball_api_service.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/ui/my/view_models/my_view_model.dart';

/// MY는 **마이팀의 부**를 봐야 한다.
///
/// `preferredGender`는 홈 순위의 남자부/여자부 토글이 바꾼다. 그걸 그대로
/// 쓰면 여자부 팀을 응원하는 사람이 홈에서 남자부를 한 번 누른 순간
/// MY의 순위·시즌 기록·직관 기록이 통째로 빈다. 화면만 봐서는 데이터가
/// 없는 건지 잘못 본 건지 알 수 없다.
void main() {
  test('홈에서 부를 바꿔도 MY는 마이팀 순위를 찾는다', () async {
    const api = MockHandballApiService(latency: Duration.zero);
    final women = (await api.fetchTeams(Gender.women)).first;

    final prefs = PreferencesRepository();
    await prefs.setMyTeam(women);
    // 홈에서 남자부를 눌러 둔 상태.
    await prefs.setPreferredGender(Gender.men);

    final container = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(prefs),
      handballApiServiceProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);

    final state = await container.read(myViewModelProvider.future);

    expect(state.team?.name, women.name);
    expect(state.rank, isNotNull,
        reason: '마이팀이 여자부인데 남자부 순위에서 찾고 있다');
    expect(state.seasonStats, isNotEmpty);
  });
}
