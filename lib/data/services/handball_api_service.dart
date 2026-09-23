import '../../domain/models/game.dart';
import '../../domain/models/game_detail.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_stat.dart';
import '../../domain/models/rank_row.dart';
import '../../domain/models/schedule_day.dart';
import '../../domain/models/team.dart';
import '../../domain/models/team_detail.dart';

/// 외부 데이터 소스 래퍼. 상태를 갖지 않는다.
///
/// 구현체가 둘이다.
///
/// - [MockHandballApiService] — 목업. `API_BASE_URL`이 비어 있을 때 쓴다
/// - [HttpHandballApiService] — `myhandball-api` 연동
///
/// 어느 쪽을 쓸지는 `schedule_repository.dart`의
/// `handballApiServiceProvider`가 고른다.
abstract interface class HandballApiService {
  /// `GET /api/schedule` — 홈 상단에 띄울 가까운 경기들.
  Future<List<Game>> fetchUpcomingGames();

  /// `GET /api/schedule?gender=&season=&type=&month=` — 월 단위 일정.
  ///
  /// [season]을 주면 그 시즌을, 안 주면 설정의 조회 시즌을 본다.
  Future<List<ScheduleDay>> fetchMonthlySchedule(
    Gender gender,
    DateTime month, {
    String? season,
  });

  /// `GET /api/schedule?gender=&season=&type=` — **월을 빼면 시즌 전체**가 온다.
  ///
  /// 일정 탭이 "경기가 있는 달"로 열려면 시즌의 달 목록을 먼저 알아야 하고,
  /// 홈은 다음 시즌 개막일을 보려고 **다른 시즌**을 묻는다. 그래서 시즌을
  /// 인자로 받는다 — 설정 값만 보면 무엇을 물어도 같은 답이 온다.
  Future<List<ScheduleDay>> fetchSeasonSchedule(Gender gender, {String? season});

  /// `GET /api/ranking?gender=`
  Future<List<RankRow>> fetchRanking(Gender gender);

  /// `GET /api/team?gender=`
  Future<List<Team>> fetchTeams(Gender gender);

  /// `GET /api/player/ranking?gender=&category=`
  Future<List<PlayerStat>> fetchTopPlayers(Gender gender, StatCategory category);

  /// `GET /api/player?gender=`
  Future<List<Player>> fetchPlayers(Gender gender);

  /// `GET /api/player/:playerSeq` — 프로필 + 통산·시즌별 기록.
  Future<PlayerDetail> fetchPlayerDetail(Player player);

  /// `GET /api/game/:matchSeq` + `GET /api/game/:matchSeq/live`
  ///
  /// 맞대결 기록은 대응 엔드포인트가 없어서 일정에서 계산한다.
  Future<GameDetail> fetchGameDetail(Game game);

  /// `GET /api/team/:teamNum`
  Future<TeamDetail> fetchTeamDetail(Team team);

  // --- 사용자 콘텐츠 (서버 집계) ---
  //
  // 예전에는 기기에만 쌓였다. 시안이 "다른 사람 예측 분포"와 "득표율"을
  // 보여주도록 그려져 있어서 서버로 올렸다.
  // `../myhandball-api/docs/api-tasks/05-사용자-콘텐츠.md`

  /// `GET /api/game/:matchSeq/prediction`
  Future<PredictionTally> fetchPrediction(Game game);

  /// `POST /api/game/:matchSeq/prediction`
  ///
  /// 경기가 시작됐으면 `409`. 시작 전이면 몇 번이든 덮어쓸 수 있다.
  Future<PredictionTally> submitPrediction(Game game, PredictionPick pick);

  /// `GET /api/game/:matchSeq/mvp`
  Future<MvpBoard> fetchMvp(Game game);

  /// `POST /api/game/:matchSeq/mvp`
  ///
  /// 경기가 끝나기 전이거나 이미 투표했으면 `409`.
  Future<MvpBoard> submitMvpVote(Game game, MvpCandidate candidate);

  /// `GET /api/team/:teamNum/cheer`
  Future<List<CheerPost>> fetchCheers(Team team, {int page});

  /// `POST /api/team/:teamNum/cheer`
  ///
  /// 200자를 넘으면 `400`, 팀별 하루 5개를 넘으면 `429`.
  Future<List<CheerPost>> submitCheer(Team team, String text);

  /// `DELETE /api/team/:teamNum/cheer/:cheerId` — 내가 쓴 글만.
  Future<List<CheerPost>> deleteCheer(Team team, String cheerId);

  /// `POST /api/team/:teamNum/cheer/:cheerId/like` — 토글.
  Future<List<CheerPost>> toggleCheerLike(Team team, String cheerId);
}
