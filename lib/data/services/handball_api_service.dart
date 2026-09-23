import '../../domain/models/game.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/player_stat.dart';
import '../../domain/models/rank_row.dart';
import '../../domain/models/team.dart';

/// 외부 데이터 소스 래퍼. 상태를 갖지 않는다.
///
/// 구현체는 현재 [MockHandballApiService] 하나뿐이다. 실제 연동 시
/// `/api/schedule`, `/api/ranking`, `/api/team`을 치는 구현을 추가하고
/// repository가 보는 타입은 그대로 둔다.
abstract interface class HandballApiService {
  /// `GET /api/schedule` — 홈 상단에 띄울 가까운 경기들.
  Future<List<Game>> fetchUpcomingGames();

  /// `GET /api/ranking?gender=`
  Future<List<RankRow>> fetchRanking(Gender gender);

  /// `GET /api/team?gender=`
  Future<List<Team>> fetchTeams(Gender gender);

  /// 대응 엔드포인트 없음 — `docs/api-requests/` 참조.
  Future<List<PlayerStat>> fetchTopPlayers(Gender gender, StatCategory category);
}
