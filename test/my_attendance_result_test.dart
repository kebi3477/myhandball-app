import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/services/mock_handball_api_service.dart';
import 'package:myhandball/domain/models/game.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/ui/my/view_models/my_view_model.dart';

/// 직관 승률은 **마이팀이 뛴 경기만** 센다.
///
/// 마이팀이 안 뛴 경기(관람)를 승·패로 세면 승률이 틀리고, 그 값이 그대로
/// "승리 요정" 배지 판정에 들어간다. 배지가 안 열리는 이유를 화면만 봐서는
/// 알 수 없다.
void main() {
  test('관람 경기는 승·패로 세지 않는다', () async {
    const api = MockHandballApiService(latency: Duration.zero);
    final teams = await api.fetchTeams(Gender.men);
    final myTeam = teams.first;

    final days = await api.fetchSeasonSchedule(Gender.men);
    final games = [for (final d in days) ...d.games]
        .where((g) => g.status == GameStatus.finished)
        .toList();

    // 마이팀이 안 뛴, 끝난 경기를 하나 골라 직관으로 기록한다.
    final other = games.firstWhere(
      (g) => g.home.name != myTeam.name && g.away.name != myTeam.name,
    );

    final prefs = PreferencesRepository();
    await prefs.setMyTeam(myTeam);
    await prefs.setPreferredGender(Gender.men);
    await prefs.toggleAttended(other.id);

    final container = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(prefs),
      handballApiServiceProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);

    final state = await container.read(myViewModelProvider.future);

    expect(state.attendance, hasLength(1));
    expect(state.attendance.single.result, '-',
        reason: '마이팀이 안 뛴 경기인데 승패를 매겼다');
    // 응원 경기가 0이므로 승률은 계산하지 않는다.
    expect(state.cheeredGames, 0);
    expect(state.attendanceRate, '-');
    expect(state.attendanceWdl, '0-0-0');
  });
}
