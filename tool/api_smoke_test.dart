// 손으로 돌려 눈으로 읽는 스크립트라 결과를 그대로 찍는다.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/services/api_client.dart';
import 'package:myhandball/data/services/http_handball_api_service.dart';
import 'package:myhandball/domain/models/game.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/domain/models/prediction.dart';
import 'package:myhandball/domain/models/player_stat.dart';

/// **실제 서버에 붙는 점검 스크립트.** 네트워크가 필요해서 `test/`가 아니라
/// 여기 둔다 (CI가 돌리지 않는다). `test/http_handball_api_service_test.dart`
/// 쪽은 픽스처만 쓰므로 그게 회귀 테스트고, 이건 손으로 돌리는 확인이다.
///
/// ```
/// flutter test tool/api_smoke_test.dart \
///   --dart-define=API_BASE_URL=http://localhost:3000
/// ```
///
/// 서버가 안 떠 있으면 전부 실패한다. 그게 정상이다.
void main() {
  const baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://localhost:3000');

  late HttpHandballApiService api;

  setUp(() {
    api = HttpHandballApiService(
      client: ApiClient(
        baseUrl: baseUrl,
        deviceId: 'smoke-test-0001-0002-0003',
        timeout: const Duration(seconds: 30),
      ),
      gender: () => Gender.men,
      season: () => '2025',
    );
  });

  test('일정', () async {
    final days = await api.fetchMonthlySchedule(Gender.men, DateTime(2025, 11));
    final games = [for (final d in days) ...d.games];
    print('일정 ${days.length}일 / ${games.length}경기');
    for (final g in games.take(3)) {
      print('  ${g.meta}  ${g.home.name} ${g.scoreHomeText}'
          ':${g.scoreAwayText} ${g.away.name}'
          '  [${g.status.name}] seq=${g.matchSeq}');
    }
    expect(games, isNotEmpty);
    expect(games.every((g) => g.home.name.isNotEmpty), isTrue);
  });

  test('순위', () async {
    final rows = await api.fetchRanking(Gender.men);
    for (final r in rows.take(3)) {
      print('  ${r.rank}위 ${r.team.name} ${r.points}점'
          ' (teamNum=${r.team.teamNum})');
    }
    expect(rows, isNotEmpty);
    // 팀 번호가 안 붙으면 팀 상세로 넘어갈 수 없다.
    expect(rows.every((r) => r.team.teamNum != null), isTrue,
        reason: '순위의 팀 이름이 팀 목록과 맞지 않는다');
  });

  test('선수 · 기록', () async {
    final players = await api.fetchPlayers(Gender.men);
    print('선수 ${players.length}명, 첫 줄: ${players.first.name}'
        ' ${players.first.statLine}');
    expect(players, isNotEmpty);

    // 선수 상세 — 목록에 없는 경기 수·프로필이 채워지는지
    final withSeq = players.firstWhere((p) => p.playerSeq != null);
    final detail = await api.fetchPlayerDetail(withSeq);
    print('  상세: ${detail.player.name} '
        '${detail.heightCm}cm/${detail.weightKg}kg ${detail.school}');
    print('    25-26: ${detail.statsForSeason('2025').summaryCells}');
    print('    통산: ${detail.career.summaryCells}');
    print('    시즌별 ${detail.seasons.length}행');
    expect(detail.seasons, isNotEmpty);
    expect(detail.career.games, isNotNull,
        reason: '통산 경기 수는 상세에서만 온다');

    for (final cat in StatCategory.values) {
      final top = await api.fetchTopPlayers(Gender.men, cat);
      print('  ${cat.label}: ${top.take(2).map((p) => '${p.name} ${p.value}')}');
      expect(top, isNotEmpty, reason: '${cat.label} 랭킹이 비었다');
    }
  });

  test('경기 상세 · 중계', () async {
    final days = await api.fetchMonthlySchedule(Gender.men, DateTime(2025, 11));
    final game = [for (final d in days) ...d.games]
        .firstWhere((g) => g.hasDetail && g.status == GameStatus.finished);

    final d = await api.fetchGameDetail(game);
    print('${d.game.home.name} ${d.game.scoreHome}:${d.game.scoreAway}'
        ' ${d.game.away.name}');
    print('  전반 ${d.firstHalfHome}:${d.firstHalfAway}'
        ' / 후반 ${d.secondHalfHome}:${d.secondHalfAway}');
    print('  기록 ${d.stats.length}항목, 중계 ${d.events.length}건,'
        ' 맞대결 ${d.headToHead.total}경기');

    expect(d.stats, isNotEmpty);
    expect(d.events, isNotEmpty, reason: 'PBP 중계가 비었다');

    // 선수별 기록에서 합산한 득점이 최종 스코어와 맞는지 (서버 불변식).
    expect(d.firstHalfHome + d.secondHalfHome, d.game.scoreHome);
    expect(d.firstHalfAway + d.secondHalfAway, d.game.scoreAway);
  });

  test('팀 상세', () async {
    final teams = await api.fetchTeams(Gender.men);
    final detail = await api.fetchTeamDetail(teams.first);
    print('${detail.team.name}: ${detail.rank.rank}위'
        ' ${detail.rank.points}점, 선수 ${detail.players.length}명,'
        ' 연혁 ${detail.history.length}건, 전적 ${detail.results.length}경기');
    print('  facts: ${detail.facts}');
    expect(detail.intro, isNotEmpty);
  });

  test('예측 · MVP · 응원글', () async {
    final days = await api.fetchMonthlySchedule(Gender.men, DateTime(2025, 11));
    final game = [for (final d in days) ...d.games]
        .firstWhere((g) => g.hasDetail && g.status == GameStatus.finished);

    final tally = await api.fetchPrediction(game);
    print('예측: ${tally.total}표, open=${tally.open}');
    // 끝난 경기는 예측이 닫혀 있어야 한다.
    expect(tally.open, isFalse);

    final board = await api.fetchMvp(game);
    print('MVP: ${board.candidates.length}명, open=${board.open}');
    expect(board.open, isTrue, reason: '끝난 경기인데 MVP가 안 열렸다');
    expect(board.candidates, isNotEmpty);

    final teams = await api.fetchTeams(Gender.men);
    final posts = await api.fetchCheers(teams.first);
    print('응원글: ${posts.length}건');
  });

  test('승부예측 프로필 · 랭킹 · 팬덤', () async {
    final profile = await api.fetchProfile();
    print('프로필: ${profile?.nickname ?? '(없음)'}');

    final board =
        await api.fetchLeaderboard(scope: LeaderboardScope.all);
    print('랭킹: ${board.rows.length}줄 / 참여 ${board.total}명'
        ' (확정 ${board.minSettled}경기 이상)');
    print('  meHint=${board.meHint} meTopPercent=${board.meTopPercent}');
    // 순위는 1부터 빠짐없이 올라가야 한다.
    for (var i = 0; i < board.rows.length; i++) {
      expect(board.rows[i].rank, i + 1);
    }

    final fandom = await api.fetchFandom(Gender.men);
    print('팬덤: ${fandom.length}팀');
    expect(fandom, isNotEmpty);

    final mine = await api.fetchMyPredictions();
    print('내 예측: 참여 ${mine.count} · 확정 ${mine.settled}'
        ' · 적중 ${mine.hits} (${mine.rateLabel})');
    // 확정보다 많이 맞힐 수는 없다.
    expect(mine.hits, lessThanOrEqualTo(mine.settled));
    expect(mine.settled, lessThanOrEqualTo(mine.count));

    final week = await api.fetchPredictionWeek();
    print('이번 주 예측: ${week.length}경기');
    for (final w in week) {
      expect(w.game.matchSeq, isNotNull);
      expect(w.tally.total,
          w.tally.home + w.tally.draw + w.tally.away,
          reason: '분포 합이 총합과 다르다');
    }
  });

  test('직관 · 가이드 진행도 · 관심 선수 · 시즌', () async {
    print('직관: ${(await api.fetchAttendance()).length}경기');
    print('관심 선수: ${(await api.fetchFavoritePlayers()).length}명');

    final guide = await api.fetchGuideProgress();
    print('가이드: ${guide.doneCount}/5, 수료 ${guide.completedAt}');

    for (final gender in Gender.values) {
      final status = await api.fetchSeasonStatus(gender);
      print('${gender.divisionLabel}: ${status.season} 시즌'
          ' 개막 ${status.opensAt} 종료 ${status.closesAt}'
          ' / 비시즌=${status.isOffseason}'
          ' / 다음 ${status.nextSeason} ${status.nextOpensAt}');
      expect(status.season, isNotEmpty);
    }
  });
}
