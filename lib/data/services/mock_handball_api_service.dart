import '../../domain/models/game.dart';
import '../../domain/models/game_detail.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_stat.dart';
import '../../domain/models/rank_row.dart';
import '../../domain/models/season.dart';
import '../../domain/models/schedule_day.dart';
import '../../domain/models/team.dart';
import '../../domain/models/team_detail.dart';
import 'api_client.dart';
import 'handball_api_service.dart';

/// 디자인 확인용 고정 데이터.
///
/// 로고 URL은 시안이 쓰던 한국핸드볼연맹 주소다. 시안(`MyHandball Widget.dc.html`)
/// 에서 확인된 3팀만 실제 id를 갖고, 나머지는 null이라 플레이스홀더가 그려진다.
class MockHandballApiService implements HandballApiService {
  /// 목업이 즉시 반환되면 스켈레톤을 눈으로 볼 수 없어, 시안의
  /// `simulateLoad(500ms)`와 같은 지연을 기본값으로 준다.
  /// 테스트는 [Duration.zero]를 넣어 대기 없이 돌린다.
  const MockHandballApiService({this.latency = const Duration(milliseconds: 500)});

  final Duration latency;

  /// `Duration.zero`면 타이머를 아예 만들지 않는다 —
  /// 위젯 테스트에 pending timer가 남지 않게 하려는 것.
  Future<void> _delay() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  static const _logoBase = 'https://www.koreahandball.com/static/images/logo';

  // 팀 번호와 로고 URL은 koreahandball.com의 팀 소개 페이지에서 확인한 값이다
  // (`/introduce/team_men.php`, `/introduce/team_women.php` — API가 긁는 곳과 동일).
  static const skHawks = Team(
      name: 'SK호크스', teamNum: 132, logoUrl: '$_logoBase/logo_m_132.png');
  static const doosan = Team(
      name: '두산', teamNum: 149, logoUrl: '$_logoBase/logo_m_149.png');
  static const incheon = Team(
      name: '인천도시공사', teamNum: 120, logoUrl: '$_logoBase/logo_m_120.png');
  static const chungnam = Team(
      name: '충남도청', teamNum: 113, logoUrl: '$_logoBase/logo_m_113.png');
  static const sangmu = Team(
      name: '상무피닉스', teamNum: 22, logoUrl: '$_logoBase/logo_m_22.png');
  static const hanam = Team(
      name: '하남시청', teamNum: 150, logoUrl: '$_logoBase/logo_m_150.png');

  static const _mensTeams = [
    doosan,
    sangmu,
    incheon,
    chungnam,
    hanam,
    skHawks,
  ];

  static const skSugar = Team(
      name: 'SK슈가글라이더즈',
      gender: Gender.women,
      teamNum: 123,
      logoUrl: '$_logoBase/logo_w_123.png');
  static const seoul = Team(
      name: '서울시청',
      gender: Gender.women,
      teamNum: 107,
      logoUrl: '$_logoBase/logo_w_107.png');
  static const busan = Team(
      name: '부산시설공단',
      gender: Gender.women,
      teamNum: 100,
      logoUrl: '$_logoBase/logo_w_100.png');
  static const samcheok = Team(
      name: '삼척시청',
      gender: Gender.women,
      teamNum: 93,
      logoUrl: '$_logoBase/logo_w_93.png');
  static const gyeongnam = Team(
      name: '경남개발공사',
      gender: Gender.women,
      teamNum: 102,
      logoUrl: '$_logoBase/logo_w_102.png');
  static const incheonW = Team(
      name: '인천광역시청',
      gender: Gender.women,
      teamNum: 127,
      logoUrl: '$_logoBase/logo_w_127.png');
  static const gwangju = Team(
      name: '광주도시공사',
      gender: Gender.women,
      teamNum: 110,
      logoUrl: '$_logoBase/logo_w_110.png');
  static const daegu = Team(
      name: '대구광역시청',
      gender: Gender.women,
      teamNum: 23,
      logoUrl: '$_logoBase/logo_w_23.png');

  static const _womensTeams = [
    gyeongnam,
    gwangju,
    daegu,
    busan,
    samcheok,
    seoul,
    incheonW,
    skSugar,
  ];

  @override
  Future<List<Game>> fetchUpcomingGames() async {
    await _delay();
    return const [
      Game(
        id: 'g1',
        home: skHawks,
        away: incheon,
        status: GameStatus.live,
        meta: "전반 18'",
        broadcast: ['MAXPORTS', 'NAVER'],
        scoreHome: 9,
        scoreAway: 8,
        venue: '청주 SK호크스 아레나',
      ),
      Game(
        id: 'g2',
        home: doosan,
        away: skHawks,
        status: GameStatus.pre,
        meta: '11.21 (토) 16:00',
        broadcast: ['NAVER'],
        venue: '서울 SK핸드볼경기장',
        canBook: true,
      ),
      Game(
        id: 'g3',
        home: chungnam,
        away: hanam,
        status: GameStatus.finished,
        meta: '11.09 (일) 14:00',
        broadcast: ['MAXPORTS'],
        scoreHome: 28,
        scoreAway: 26,
      ),
    ];
  }

  /// 목업은 어느 달이든 경기를 만들어내므로 "시즌 전체"도 이번 달로 대신한다.
  /// 일정 탭이 시작 달을 고르는 데만 쓰는 값이다.
  @override
  Future<List<ScheduleDay>> fetchSeasonSchedule(Gender gender,
      {String? season}) {
    final now = DateTime.now();
    return fetchMonthlySchedule(gender, DateTime(now.year, now.month));
  }

  @override
  Future<List<ScheduleDay>> fetchMonthlySchedule(
    Gender gender,
    DateTime month, {
    String? season,
  }) async {
    await _delay();

    final teams = gender == Gender.women ? _womensTeams : _mensTeams;
    final days = <ScheduleDay>[];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();

    // 토·일에만 경기를 배치한다. 실제 H리그 편성과 비슷하게 하루 2경기.
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) {
        continue;
      }

      final seed = month.month * 100 + day;
      final games = <Game>[];
      for (var slot = 0; slot < 2; slot++) {
        final a = teams[(seed + slot * 2) % teams.length];
        final b = teams[(seed + slot * 2 + 3) % teams.length];
        if (a.name == b.name) continue;

        final past = date.isBefore(DateTime(today.year, today.month, today.day));
        final status = past ? GameStatus.finished : GameStatus.pre;
        final time = slot == 0 ? '14:00' : '16:00';

        games.add(Game(
          id: 'm${month.year}${month.month}-$day-$slot',
          home: a,
          away: b,
          status: status,
          meta: past ? '종료' : time,
          broadcast: const ['MAXPORTS'],
          scoreHome: past ? 22 + (seed + slot) % 10 : null,
          scoreAway: past ? 20 + (seed + slot * 3) % 10 : null,
          venue: '${a.name} 홈구장',
          canBook: !past,
        ));
      }
      if (games.isEmpty) continue;

      const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final mm = month.month.toString().padLeft(2, '0');
      final dd = day.toString().padLeft(2, '0');
      days.add(ScheduleDay(
        label: '${month.year}.$mm.$dd (${weekdays[date.weekday - 1]})',
        date: date,
        games: games,
      ));
    }
    return days;
  }

  @override
  Future<List<Team>> fetchTeams(Gender gender) async {
    await _delay();
    return gender == Gender.women ? _womensTeams : _mensTeams;
  }

  @override
  Future<List<RankRow>> fetchRanking(Gender gender) async {
    await _delay();
    const mens = [
      RankRow(rank: 1, team: skHawks, points: 34, played: 20, wins: 16, draws: 2, losses: 2, goalsFor: 612, goalsAgainst: 524),
      RankRow(rank: 2, team: doosan, points: 31, played: 20, wins: 15, draws: 1, losses: 4, goalsFor: 598, goalsAgainst: 541),
      RankRow(rank: 3, team: incheon, points: 27, played: 20, wins: 13, draws: 1, losses: 6, goalsFor: 574, goalsAgainst: 552),
      RankRow(rank: 4, team: chungnam, points: 22, played: 20, wins: 10, draws: 2, losses: 8, goalsFor: 551, goalsAgainst: 563),
      RankRow(rank: 5, team: sangmu, points: 18, played: 20, wins: 8, draws: 2, losses: 10, goalsFor: 529, goalsAgainst: 574),
      RankRow(rank: 6, team: hanam, points: 13, played: 20, wins: 6, draws: 1, losses: 13, goalsFor: 498, goalsAgainst: 608),
    ];
    const womens = [
      RankRow(rank: 1, team: skSugar, points: 36, played: 21, wins: 17, draws: 2, losses: 2, goalsFor: 604, goalsAgainst: 498),
      RankRow(rank: 2, team: seoul, points: 30, played: 21, wins: 14, draws: 2, losses: 5, goalsFor: 571, goalsAgainst: 520),
      RankRow(rank: 3, team: busan, points: 28, played: 21, wins: 13, draws: 2, losses: 6, goalsFor: 559, goalsAgainst: 533),
      RankRow(rank: 4, team: samcheok, points: 21, played: 21, wins: 10, draws: 1, losses: 10, goalsFor: 538, goalsAgainst: 548),
      RankRow(rank: 5, team: gyeongnam, points: 17, played: 21, wins: 8, draws: 1, losses: 12, goalsFor: 512, goalsAgainst: 566),
      RankRow(rank: 6, team: incheonW, points: 12, played: 21, wins: 5, draws: 2, losses: 14, goalsFor: 487, goalsAgainst: 601),
    ];
    return gender == Gender.women ? womens : mens;
  }

  @override
  Future<List<PlayerStat>> fetchTopPlayers(
    Gender gender,
    StatCategory category,
  ) async {
    await _delay();
    // 단위는 목록을 만든 뒤 한 번에 붙인다. 항목마다 적으면 빠뜨리기 쉽다.
    return _withUnit(category, switch (category) {
      StatCategory.goals => const [
          PlayerStat(
              rank: 1,
              name: '정의경',
              teamName: 'SK호크스',
              position: 'LB',
              value: '142'),
          PlayerStat(
              rank: 2, name: '하민호', teamName: '두산', position: 'CB', value: '128'),
          PlayerStat(
              rank: 3,
              name: '박광순',
              teamName: '인천도시공사',
              position: 'RW',
              value: '119',
              isEstimated: true),
          PlayerStat(
              rank: 4,
              name: '김연빈',
              teamName: '충남도청',
              position: 'PV',
              value: '104'),
          PlayerStat(
              rank: 5,
              name: '이현식',
              teamName: '하남시청',
              position: 'LW',
              value: '97'),
        ],
      StatCategory.assists => const [
          PlayerStat(
              rank: 1, name: '하민호', teamName: '두산', position: 'CB', value: '88'),
          PlayerStat(
              rank: 2,
              name: '정의경',
              teamName: 'SK호크스',
              position: 'LB',
              value: '71'),
          PlayerStat(
              rank: 3,
              name: '김연빈',
              teamName: '충남도청',
              position: 'PV',
              value: '64'),
        ],
      StatCategory.saves => const [
          PlayerStat(
              rank: 1,
              name: '강태우',
              teamName: 'SK호크스',
              position: 'GK',
              value: '210'),
          PlayerStat(
              rank: 2, name: '문지호', teamName: '두산', position: 'GK', value: '186'),
          PlayerStat(
              rank: 3, name: '오세준', teamName: '상무피닉스', position: 'GK', value: '151'),
        ],
    });
  }

  /// 실제 API는 카테고리마다 단위를 따로 준다 (`골` `개` `회`).
  /// 목업도 같은 모양으로 맞춘다.
  List<PlayerStat> _withUnit(StatCategory category, List<PlayerStat> rows) => [
        for (final r in rows)
          PlayerStat(
            rank: r.rank,
            name: r.name,
            teamName: r.teamName,
            position: r.position,
            value: r.value,
            unit: category.unit,
            isEstimated: r.isEstimated,
            logoUrl: r.logoUrl,
          ),
      ];

  @override
  Future<List<Player>> fetchPlayers(Gender gender) async {
    await _delay();
    final teams = gender == Gender.women ? _womensTeams : _mensTeams;

    // 실명이 아니라 자리만 채우는 값이다. 실제 명단은 API 작업이 필요하다.
    const positions = ['LW', 'LB', 'CB', 'RB', 'RW', 'PV', 'GK'];
    const surnames = ['김', '이', '박', '정', '최', '강', '조', '윤', '장', '임'];
    const givenNames = [
      '민준', '서연', '도윤', '하은', '지후', '예린', '주원', '수아', '시우', '유진',
    ];

    final players = <Player>[];
    for (var t = 0; t < teams.length; t++) {
      final team = teams[t];
      for (var i = 0; i < 4; i++) {
        final seed = t * 7 + i * 3;
        final pos = positions[seed % positions.length];
        final goals = 40 + (seed * 13) % 110;
        final assists = 10 + (seed * 7) % 60;
        final stats = PlayerSeasonSummary(
          games: 18 + seed % 8,
          goals: pos == 'GK' ? 0 : goals,
          shots: pos == 'GK' ? 0 : goals + 40 + seed % 50,
          goalRate: pos == 'GK' ? null : 45 + (seed * 3) % 25,
          assists: assists,
          steals: 3 + seed % 20,
          blocks: 2 + seed % 15,
          turnovers: 5 + seed % 20,
          saves: pos == 'GK' ? 120 + seed % 90 : null,
          saveRate: pos == 'GK' ? 28 + (seed % 12).toDouble() : null,
          playMinutes: 300 + (seed * 37) % 900,
        );
        players.add(Player(
          id: 'p-${team.teamNum}-$i',
          name: '${surnames[seed % surnames.length]}'
              '${givenNames[(seed * 3) % givenNames.length]}',
          teamName: team.name,
          teamLogoUrl: team.logoUrl,
          number: 1 + (seed * 5) % 40,
          position: pos,
          stats: stats,
          statLine: stats.line,
        ));
      }
    }
    return players;
  }

  @override
  Future<PlayerDetail> fetchPlayerDetail(Player player) async {
    await _delay();
    final stats = player.stats ?? const PlayerSeasonSummary();
    return PlayerDetail(
      player: player,
      career: PlayerSeasonSummary(
        games: (stats.games ?? 20) * 5,
        goals: stats.goals * 5,
        shots: stats.shots * 5,
        goalRate: stats.goalRate,
        assists: stats.assists * 5,
        steals: stats.steals * 5,
        blocks: stats.blocks * 5,
        turnovers: stats.turnovers * 5,
        saves: stats.saves == null ? null : stats.saves! * 5,
        saveRate: stats.saveRate,
        playMinutes: (stats.playMinutes ?? 0) * 5,
      ),
      seasons: [
        for (var i = 0; i < 3; i++)
          PlayerSeasonRow(
            season: '${2025 - i}-${2026 - i}',
            postseason: false,
            stats: stats,
          ),
      ],
      birthLabel: '1997년 2월 3일',
      heightCm: 180,
      weightKg: 78,
      school: '한국체육대학교',
    );
  }

  @override
  Future<GameDetail> fetchGameDetail(Game game) async {
    await _delay();

    final home = game.scoreHome ?? 0;
    final away = game.scoreAway ?? 0;
    // 경기 id로 고정 시드를 만들어, 같은 경기는 항상 같은 중계가 나오게 한다.
    var seed = game.id.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) % 100000);
    int next(int max) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return max == 0 ? 0 : seed % max;
    }

    final roster = await fetchPlayers(game.home.gender);
    List<Player> of(String team) =>
        roster.where((p) => p.teamName == team).toList();
    final homeRoster = of(game.home.name);
    final awayRoster = of(game.away.name);
    String scorer(List<Player> list) =>
        list.isEmpty ? '선수' : list[next(list.length)].name;

    final events = <GameEvent>[
      const GameEvent(type: GameEventType.start, minute: 0),
    ];

    if (game.status != GameStatus.pre) {
      final upTo = game.status == GameStatus.live ? 30 : 60;
      final minutes = List.generate(home + away, (_) => 1 + next(upTo - 1))
        ..sort();
      var a = 0, b = 0, remA = home, remB = away;

      for (final m in minutes) {
        final isHome = remA > 0 && (remB == 0 || next(remA + remB) < remA);
        if (isHome) {
          a++;
          remA--;
        } else {
          b++;
          remB--;
        }
        events.add(GameEvent(
          type: GameEventType.goal,
          minute: m,
          isHome: isHome,
          playerName: scorer(isHome ? homeRoster : awayRoster),
          sevenMeter: next(100) < 12,
          scoreHome: a,
          scoreAway: b,
        ));
        if (next(100) < 14) {
          events.add(GameEvent(
            type: GameEventType.save,
            minute: m,
            isHome: !isHome,
            playerName: scorer(isHome ? awayRoster : homeRoster),
          ));
        }
        if (next(100) < 7) {
          final side = next(2) == 0;
          events.add(GameEvent(
            type: GameEventType.twoMinutes,
            minute: m,
            isHome: side,
            playerName: scorer(side ? homeRoster : awayRoster),
          ));
        }
      }
      if (upTo >= 30) {
        events.add(const GameEvent(type: GameEventType.halfTime, minute: 30));
      }
      if (game.status == GameStatus.finished) {
        events.add(const GameEvent(type: GameEventType.end, minute: 60));
      }
      events.sort((x, y) => x.minute.compareTo(y.minute));
    }

    final shots = home + 12 + next(8);
    final shotsAway = away + 12 + next(8);

    return GameDetail(
      game: game,
      firstHalfHome: (home / 2).round(),
      firstHalfAway: (away / 2).round(),
      events: events.reversed.toList(),
      stats: [
        TeamStatLine(label: '슛', home: shots, away: shotsAway),
        TeamStatLine(
          label: '슛 성공률',
          home: shots == 0 ? 0 : (home * 100 / shots).round(),
          away: shotsAway == 0 ? 0 : (away * 100 / shotsAway).round(),
          isPercent: true,
        ),
        TeamStatLine(label: '7m 드로', home: 2 + next(4), away: 2 + next(4)),
        TeamStatLine(label: '선방', home: 6 + next(8), away: 6 + next(8)),
        TeamStatLine(label: '실책', home: 5 + next(9), away: 5 + next(9)),
        TeamStatLine(label: '2분 퇴장', home: next(4), away: next(4)),
      ],
      headToHead: HeadToHead(
        homeWins: 3 + next(3),
        draws: next(2),
        awayWins: 2 + next(3),
        avgHome: 26 + next(6) / 2,
        avgAway: 25 + next(6) / 2,
        games: List.generate(4, (i) {
          final hs = 24 + next(8);
          final as_ = 23 + next(8);
          return HeadToHeadGame(
            season: '${2025 - i}',
            date: '${3 + i}.${10 + next(18)}',
            score: '$hs : $as_',
            resultLabel: hs > as_ ? '${game.home.name} 승' : '${game.away.name} 승',
            homeWon: hs > as_,
          );
        }),
      ),
      mvpCandidates: [
        for (var i = 0; i < 5; i++)
          () {
            final fromHome = i.isEven;
            final list = fromHome ? homeRoster : awayRoster;
            final p = list.isEmpty ? null : list[i % list.length];
            return MvpCandidate(
              id: 'mvp-${game.id}-$i',
              name: p?.name ?? '선수 ${i + 1}',
              teamName: fromHome ? game.home.name : game.away.name,
              teamLogoUrl:
                  fromHome ? game.home.logoUrl : game.away.logoUrl,
              statLine: p?.statLine ?? '-',
              votes: 40 - i * 7 + next(6),
            );
          }(),
      ],
    );
  }

  @override
  Future<TeamDetail> fetchTeamDetail(Team team) async {
    await _delay();

    final ranking = await fetchRanking(team.gender);
    final rank = ranking.firstWhere(
      (r) => r.team.name == team.name,
      orElse: () => RankRow(rank: ranking.length + 1, team: team, points: 0),
    );
    final players =
        (await fetchPlayers(team.gender)).where((p) => p.teamName == team.name);

    var seed = team.name.codeUnits.fold<int>(11, (a, b) => (a * 31 + b) % 99991);
    int next(int max) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return max == 0 ? 0 : seed % max;
    }

    // 순위 추이: 최종 순위 언저리에서 흔들리게 만든다.
    final trend = List.generate(10, (i) {
      final drift = next(3) - 1;
      return (rank.rank + drift).clamp(1, ranking.length);
    })
      ..add(rank.rank);

    final results = <MatchResult>[
      for (var i = 0; i < rank.wins; i++) MatchResult.win,
      for (var i = 0; i < rank.draws; i++) MatchResult.draw,
      for (var i = 0; i < rank.losses; i++) MatchResult.loss,
    ];
    // 승/무/패를 섞어 실제 경기 순서처럼 보이게 한다.
    for (var i = results.length - 1; i > 0; i--) {
      final j = next(i + 1);
      final tmp = results[i];
      results[i] = results[j];
      results[j] = tmp;
    }

    return TeamDetail(
      team: team,
      rank: rank,
      slogan: '함께 뛰는 우리 팀',
      intro: '${team.name}은(는) 한국핸드볼리그에 참가하는 구단입니다.\n'
          '구단 소개 본문은 연맹 구단 페이지에서 가져와야 합니다 — '
          '지금은 화면 확인용 자리표시 문구입니다.',
      facts: [
        ('창단', '${1980 + next(35)}년'),
        ('연고지', team.name.replaceAll(RegExp(r'(시청|도시공사|시설공단|개발공사)'), '')),
        ('홈구장', '${team.name} 체육관'),
        ('감독', '감독 미상'),
      ],
      history: [
        TeamHistoryEntry('${2024 - next(3)}', '정규리그 ${1 + next(4)}위'),
        TeamHistoryEntry('${2020 - next(3)}', '플레이오프 진출'),
        TeamHistoryEntry('${2015 - next(5)}', '리그 창단 멤버로 참가'),
      ],
      address: '연맹 구단 페이지의 주소 정보가 필요합니다.',
      players: players.toList(),
      rankTrend: trend,
      results: results,
      // 연맹 "팀기록"은 실제로는 득점 유형별로 쪼개져 온다. 목업에도 넣어야
      // 전적 탭의 "득점 유형"이 프리뷰에서 보인다.
      seasonRecord: TeamSeasonRecord(
        season: '${Season.current.startYear}-${Season.current.startYear + 1}',
        goals: rank.goalsFor,
        goals6m: (rank.goalsFor * 0.31).round(),
        goalsWing: (rank.goalsFor * 0.18).round(),
        goals9m: (rank.goalsFor * 0.21).round(),
        goals7m: (rank.goalsFor * 0.13).round(),
        goalsFast: (rank.goalsFor * 0.11).round(),
        goalsBreakthrough: (rank.goalsFor * 0.06).round(),
        assists: 120 + next(80),
        turnovers: 180 + next(60),
        steals: 90 + next(40),
        blocks: 40 + next(30),
        yellowCards: 20 + next(20),
        twoMinutes: 50 + next(40),
        redCards: next(4),
      ),
    );
  }

  // --- 사용자 콘텐츠 ---
  //
  // 서버 연동판은 DB에 쌓지만, 목업은 앱을 켜 둔 동안만 기억한다.
  // `const` 생성자를 유지하려고 static에 둔다.

  static final _predictions = <String, PredictionPick>{};
  static final _mvpVotes = <String, String>{};
  static final _cheers = <String, List<CheerPost>>{};

  @override
  Future<PredictionTally> fetchPrediction(Game game) async {
    await _delay();
    return _tallyFor(game);
  }

  @override
  Future<PredictionTally> submitPrediction(Game game, PredictionPick pick) async {
    await _delay();
    if (game.status != GameStatus.pre) {
      throw const ApiException('경기가 시작돼 예측을 바꿀 수 없어요', statusCode: 409);
    }
    _predictions[game.id] = pick;
    return _tallyFor(game);
  }

  /// 혼자 쓰면 분포가 100%만 나와 시안 막대를 볼 수 없어서, 경기 id로
  /// 고정 시드를 만들어 다른 사람 표가 있는 것처럼 꾸민다.
  PredictionTally _tallyFor(Game game) {
    final seed = game.id.codeUnits.fold<int>(11, (a, b) => (a * 31 + b) % 9973);
    final home = 40 + seed % 60;
    final draw = 5 + seed % 15;
    final away = 30 + (seed ~/ 7) % 55;
    final mine = _predictions[game.id];
    return PredictionTally(
      total: home + draw + away + (mine == null ? 0 : 1),
      home: home + (mine == PredictionPick.home ? 1 : 0),
      draw: draw + (mine == PredictionPick.draw ? 1 : 0),
      away: away + (mine == PredictionPick.away ? 1 : 0),
      open: game.status == GameStatus.pre,
      myPick: mine,
    );
  }

  @override
  Future<MvpBoard> fetchMvp(Game game) async {
    await _delay();
    return _boardFor(game, (await fetchGameDetail(game)).mvpCandidates);
  }

  @override
  Future<MvpBoard> submitMvpVote(Game game, MvpCandidate candidate) async {
    await _delay();
    if (game.status != GameStatus.finished) {
      throw const ApiException('경기가 끝나야 투표할 수 있어요', statusCode: 409);
    }
    if (_mvpVotes.containsKey(game.id)) {
      throw const ApiException('이미 투표했어요', statusCode: 409);
    }
    _mvpVotes[game.id] = candidate.id;
    return _boardFor(game, (await fetchGameDetail(game)).mvpCandidates);
  }

  MvpBoard _boardFor(Game game, List<MvpCandidate> candidates) {
    final mine = _mvpVotes[game.id];
    final voted = [
      for (final c in candidates)
        if (c.id == mine)
          MvpCandidate(
            id: c.id,
            name: c.name,
            teamName: c.teamName,
            statLine: c.statLine,
            votes: c.votes + 1,
            teamLogoUrl: c.teamLogoUrl,
            playerSeq: c.playerSeq,
            number: c.number,
            isHome: c.isHome,
          )
        else
          c,
    ]..sort((a, b) => b.votes.compareTo(a.votes));

    return MvpBoard(
      candidates: voted,
      total: voted.fold<int>(0, (a, c) => a + c.votes),
      open: game.status == GameStatus.finished,
      myVoteId: mine,
    );
  }

  @override
  Future<List<CheerPost>> fetchCheers(Team team, {int page = 1}) async {
    await _delay();
    return List.unmodifiable(_cheers[team.name] ?? const <CheerPost>[]);
  }

  @override
  Future<List<CheerPost>> submitCheer(Team team, String text) async {
    await _delay();
    if (text.length > 200) {
      throw const ApiException('200자까지 쓸 수 있어요', statusCode: 400);
    }
    final now = DateTime.now();
    (_cheers[team.name] ??= []).insert(
      0,
      CheerPost(
        id: 'cheer-${now.microsecondsSinceEpoch}',
        author: '나',
        text: text.trim(),
        dateLabel: '${now.month}.${now.day}',
        likes: 0,
        isMine: true,
      ),
    );
    return fetchCheers(team);
  }

  @override
  Future<List<CheerPost>> deleteCheer(Team team, String cheerId) async {
    await _delay();
    _cheers[team.name]?.removeWhere((p) => p.id == cheerId);
    return fetchCheers(team);
  }

  @override
  Future<List<CheerPost>> toggleCheerLike(Team team, String cheerId) async {
    await _delay();
    final list = _cheers[team.name];
    final i = list?.indexWhere((p) => p.id == cheerId) ?? -1;
    if (list != null && i >= 0) {
      final post = list[i];
      list[i] = post.copyWith(
        liked: !post.liked,
        likes: post.likes + (post.liked ? -1 : 1),
      );
    }
    return fetchCheers(team);
  }
}
