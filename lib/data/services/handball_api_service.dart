import '../../domain/models/game.dart';
import '../../domain/models/game_detail.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_stat.dart';
import '../../domain/models/rank_row.dart';
import '../../domain/models/schedule_day.dart';
import '../../domain/models/sync_models.dart';
import '../../domain/models/team.dart';
import '../../domain/models/prediction.dart';
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

  /// 응원글 신고. 같은 글을 다시 신고하면 `409`.
  ///
  /// **스토어 심사가 요구하는 기능이다** (App Store Guideline 1.2 — 사용자
  /// 생성 콘텐츠가 있으면 앱 안에 신고 수단이 있어야 한다).
  Future<void> reportCheer(
    Team team,
    String cheerId, {
    required CheerReportReason reason,
    String? detail,
  });

  /// 차단한 작성자 목록.
  Future<List<BlockedAuthor>> fetchBlocks();

  /// 작성자 차단. 이미 차단했어도 성공으로 본다(멱등).
  Future<void> blockAuthor(String authorId);

  Future<void> unblockAuthor(String authorId);

  // --- 승부예측 프로필·랭킹 ---

  /// 내 프로필. 아직 안 만들었으면 `null` (서버가 200 + null을 준다).
  Future<PredictionProfile?> fetchProfile();

  /// 프로필 저장. 닉네임이 겹치면 `409`, 팀과 부가 안 맞으면 `404`.
  Future<PredictionProfile> saveProfile({
    required String nickname,
    required int teamNum,
    required Gender gender,
  });

  /// 랭킹 참여 중단. 예측 기록 자체는 서버에 남는다.
  Future<void> deleteProfile();

  Future<Leaderboard> fetchLeaderboard({
    required LeaderboardScope scope,
    int? teamNum,
  });

  Future<List<FandomRow>> fetchFandom(Gender gender);

  /// 내 예측 집계와 최근 목록.
  Future<MyPredictions> fetchMyPredictions({int limit});

  /// 이번 주 예측 대상 경기 + 집계 + 내 선택.
  ///
  /// **시작 전 경기만 담는다.** 비어 있으면 이번 주에 예측할 경기가 없다.
  Future<List<WeekPrediction>> fetchPredictionWeek();

  // --- 기기 대신 서버에 두는 내 기록 ---
  //
  // 전부 `X-Device-Id` 기준이다. 앱을 지웠다 깔아도 iOS는 Keychain 덕에
  // 같은 사람으로 남아 이 값들이 돌아온다.

  /// 직관한 경기의 `matchSeq` 목록.
  Future<List<int>> fetchAttendance();

  /// 직관 기록. 이미 기록했어도 성공으로 본다(멱등).
  /// 앞으로 할 경기는 `400`, 없는 경기는 `404`.
  Future<void> addAttendance(int matchSeq);

  Future<void> removeAttendance(int matchSeq);

  /// 가이드 진행도. `completedAt`은 수료한 적 없으면 `null`.
  Future<GuideProgress> fetchGuideProgress();

  /// **서버가 더 큰 값을 갖고 있으면 그대로 둔다.** 진행도는 줄지 않는다.
  Future<GuideProgress> saveGuideProgress(int doneCount);

  /// 관심 선수의 `playerSeq` 목록.
  Future<List<int>> fetchFavoritePlayers();

  Future<void> addFavoritePlayer(int playerSeq);

  Future<void> removeFavoritePlayer(int playerSeq);

  /// 시즌 상태. 개막·종료 시각과 다음 시즌 개막일을 서버가 판정해서 준다.
  Future<SeasonStatus> fetchSeasonStatus(Gender gender);
}
