import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/services/api_client.dart';
import 'package:myhandball/data/services/handball_api_service.dart';
import 'package:myhandball/data/services/mock_handball_api_service.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/domain/models/player.dart';
import 'package:myhandball/domain/models/rank_row.dart';
import 'package:myhandball/ui/my/view_models/my_view_model.dart';

/// 통신이 끊겨도 MY는 살아 있어야 한다.
///
/// 예전에는 순위 하나만 못 받아도 화면 전체가 문구 한 줄로 바뀌었다.
/// 마이팀·닉네임·직관 기록은 기기에 있는데 그것까지 못 보게 되고,
/// **다시 시도할 방법도 없었다.**
class _FlakyApi extends MockHandballApiService {
  const _FlakyApi() : super(latency: Duration.zero);

  @override
  Future<List<RankRow>> fetchRanking(Gender gender) async =>
      throw const ApiException('서버에 연결하지 못했어요');

  @override
  Future<List<Player>> fetchPlayers(Gender gender) async =>
      throw const ApiException('서버에 연결하지 못했어요');
}

void main() {
  test('일부를 못 받아도 상태가 만들어지고 원인이 남는다', () async {
    const api = _FlakyApi();
    final team = (await const MockHandballApiService(latency: Duration.zero)
            .fetchTeams(Gender.men))
        .first;

    final prefs = PreferencesRepository();
    await prefs.setMyTeam(team);

    final container = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(prefs),
      handballApiServiceProvider.overrideWithValue(api as HandballApiService),
    ]);
    addTearDown(container.dispose);

    final state = await container.read(myViewModelProvider.future);

    // 오류 화면으로 튕기지 않는다.
    expect(state.hasError, isTrue);
    expect(state.error, isA<ApiException>());
    // 기기에 있는 값은 그대로 보인다.
    expect(state.team?.name, team.name);
    // 못 받은 것만 빈다.
    expect(state.rank, isNull);
    expect(state.favoritePlayers, isEmpty);
  });
}
