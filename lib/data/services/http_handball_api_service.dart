import '../../domain/models/game.dart';
import '../../domain/models/game_detail.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_stat.dart';
import '../../domain/models/rank_row.dart';
import '../../domain/models/schedule_day.dart';
import '../../domain/models/team.dart';
import '../../domain/models/team_detail.dart';
import 'api_client.dart';
import 'handball_api_service.dart';

/// `myhandball-api` 연동 구현체.
///
/// 응답 스펙은 `../myhandball-api/docs/api-tasks/`에 있고, 문서와 실제
/// 응답이 다른 부분은 `07-후속-작업.md` C절에 정리돼 있다. 이 파일의
/// 매핑은 **실제 응답을 받아 맞춘 것**이다.
///
/// 파싱은 서버가 이미 한 번 했으므로 여기서는 타입만 맞춘다. 서버는 파싱에
/// 실패해도 500 대신 `null`/`[]`을 주므로, 필드가 비는 걸 정상으로 다룬다.
class HttpHandballApiService implements HandballApiService {
  HttpHandballApiService({
    required this.client,
    required this.gender,
    required this.season,
  });

  final ApiClient client;

  /// 마이 설정의 관심 부. 인자로 성별을 받지 않는 메서드가 쓴다.
  final Gender Function() gender;

  /// 조회 시즌 (시작 연도 문자열). 설정 > 시즌에서 바뀐다.
  final String Function() season;

  /// 정규리그. 포스트시즌은 `2`지만 지금 화면에 진입점이 없다.
  static const _leagueType = '1';

  // 팀 번호는 일정·순위 응답에 없다. 팀 상세로 넘어가려면 필요해서
  // 팀 목록을 한 번 받아 이름으로 맞춘다. 서버도 24시간 캐시한다.
  final _teamsByKey = <String, Map<String, Team>>{};

  /// 이름 매칭 키. 공백을 뺀다.
  ///
  /// 한때 엔드포인트마다 이름이 달랐다 — `/api/team`은 `상무피닉스`,
  /// 일정·순위는 `상무 피닉스`. **서버가 2026-09-23에 통일했으므로 지금은
  /// 그냥 일치한다.** 그래도 공백을 빼 두는 건, 배포된 서버가 구버전일 때
  /// 이 불일치가 **조용한 실패**로 나타나기 때문이다: `Team`은 이름으로 같은
  /// 팀인지 판단해서, 마이팀이 상무인 사용자의 달력과 다음 경기가 에러 없이
  /// 그냥 빈다. 한 줄짜리 안전망이라 남겨 둔다.
  static String _key(String name) => name.replaceAll(RegExp(r'\s+'), '');

  Map<String, String?> _query(Gender g, {String? month}) => {
        'gender': g.code,
        'season': season(),
        'type': _leagueType,
        // 비어 있으면 _uri가 알아서 뺀다. 월을 빼면 시즌 전체가 온다.
        'month': month,
      };

  // --- 일정 ---

  @override
  Future<List<Game>> fetchUpcomingGames() async {
    final days = await _fetchSchedule(gender());
    final games = [for (final d in days) ...d.games];
    if (games.isEmpty) return const [];

    // 홈 상단은 "가까운 경기"다. 진행 중 → 예정 → 최근 끝난 순으로 고른다.
    final live = games.where((g) => g.status == GameStatus.live).toList();
    final upcoming = games.where((g) => g.status == GameStatus.pre).toList()
      ..sort((a, b) => _compareStart(a, b));
    final finished = games.where((g) => g.status == GameStatus.finished).toList()
      ..sort((a, b) => _compareStart(b, a));

    return [...live, ...upcoming, ...finished].take(6).toList();
  }

  int _compareStart(Game a, Game b) {
    final x = a.startsAt, y = b.startsAt;
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }

  @override
  Future<List<ScheduleDay>> fetchMonthlySchedule(
    Gender g,
    DateTime month,
  ) =>
      _fetchSchedule(g, month: month.month.toString());

  @override
  Future<List<ScheduleDay>> fetchSeasonSchedule(Gender g) => _fetchSchedule(g);

  Future<List<ScheduleDay>> _fetchSchedule(Gender g, {String? month}) async {
    final json = await client.get('/schedule', _query(g, month: month));
    final teamNums = await _teamNumbers(g);
    final days = _list(_map(json)['days']);
    return [
      for (final raw in days)
        if (_map(raw) case final day) _scheduleDay(day, g, teamNums),
    ];
  }

  ScheduleDay _scheduleDay(
    Map<String, dynamic> day,
    Gender g,
    Map<String, Team> teamNums,
  ) {
    final label = _str(day['dateLabel']) ?? '';
    final date = _date(day['dateISO']);
    return ScheduleDay(
      label: label,
      date: date,
      games: [
        for (final raw in _list(day['games']))
          _game(_map(raw), g, teamNums, label),
      ],
    );
  }

  Game _game(
    Map<String, dynamic> j,
    Gender g,
    Map<String, Team> teamNums,
    String dayLabel,
  ) {
    final matchSeq = _int(j['matchSeq']);
    final startsAt = _date(j['startsAt']);
    final status = _status(j['status'], startsAt);
    final home = _team(j['home'], g, teamNums);
    final away = _team(j['away'], g, teamNums);

    return Game(
      // 상세 링크가 없는 경기도 목록에는 나와야 하므로 대체 id를 만든다.
      id: matchSeq != null
          ? 'g$matchSeq'
          : '${_str(j['containerId']) ?? dayLabel}-${home.name}-${away.name}',
      matchSeq: matchSeq,
      startsAt: startsAt,
      home: home,
      away: away,
      status: status,
      meta: _meta(status, dayLabel, _str(j['time']), startsAt),
      broadcast: [
        for (final b in _list(j['broadcast'])) ?_str(b),
      ],
      scoreHome: _int(j['scoreHome']),
      scoreAway: _int(j['scoreAway']),
      venue: _str(j['venue']),
      liveLinks: [
        for (final raw in _list(j['liveLinks']))
          if (_map(raw) case final l)
            if (_str(l['url']) case final url?)
              LiveLink(provider: _str(l['provider']) ?? '', url: url),
      ],
    );
  }

  /// 서버가 `status`를 준다. 04번 폴링이 한 번도 안 돈 경기는 `pre`로
  /// 남아 있을 수 있어서, 값이 없을 때만 시각으로 추정한다.
  GameStatus _status(Object? raw, DateTime? startsAt) {
    switch (_str(raw)) {
      case 'live':
        return GameStatus.live;
      case 'finished':
        return GameStatus.finished;
      case 'pre':
        return GameStatus.pre;
    }
    if (startsAt == null) return GameStatus.pre;
    final elapsed = DateTime.now().difference(startsAt);
    if (elapsed.isNegative) return GameStatus.pre;
    return elapsed.inMinutes > 150 ? GameStatus.finished : GameStatus.live;
  }

  /// 카드 우상단 문구.
  ///
  /// 진행 중일 때 시안은 `전반 18'`을 보여주지만, 일정 응답에는 경기 시계가
  /// 없다. 경과 시간으로 추정하고, 정확한 시계는 경기 상세(중계)에서 준다.
  String _meta(
    GameStatus status,
    String dayLabel,
    String? time,
    DateTime? startsAt,
  ) {
    if (status == GameStatus.live && startsAt != null) {
      final minutes = DateTime.now().difference(startsAt).inMinutes;
      if (minutes < 30) return "전반 $minutes'";
      if (minutes < 45) return '하프타임';
      final second = (minutes - 15).clamp(30, 60);
      return "후반 $second'";
    }
    final short = _shortDate(dayLabel);
    return time == null || time.isEmpty ? short : '$short $time';
  }

  /// `2025.11.15 (토)` → `11.15 (토)`
  String _shortDate(String label) {
    final m = RegExp(r'^\d{4}\.(\d{2}\.\d{2}.*)$').firstMatch(label);
    return m?.group(1) ?? label;
  }

  // --- 순위 · 팀 ---

  @override
  Future<List<RankRow>> fetchRanking(Gender g) async {
    final json = await client.get('/ranking', _query(g));
    final teamNums = await _teamNumbers(g);
    final items = _list(_map(json)['items']);
    return [
      for (var i = 0; i < items.length; i++)
        if (_map(items[i]) case final row)
          RankRow(
            rank: _int(row['rank']) ?? i + 1,
            team: _team(row['team'], g, teamNums),
            points: _int(row['points']) ?? 0,
            played: _int(row['played']) ?? 0,
            wins: _int(row['wins']) ?? 0,
            draws: _int(row['draws']) ?? 0,
            losses: _int(row['losses']) ?? 0,
            goalsFor: _int(row['goalsFor']) ?? 0,
            goalsAgainst: _int(row['goalsAgainst']) ?? 0,
            last5: [
              for (final r in _list(row['last5'])) ?_str(r),
            ],
          ),
    ];
  }

  @override
  Future<List<Team>> fetchTeams(Gender g) async {
    final json = await client.get('/team', {'gender': g.code});
    final teams = [
      for (final raw in _list(_map(json)['teams']))
        if (_map(raw) case final t)
          if (_str(t['name']) case final name?)
            Team(
              name: name,
              logoUrl: _str(t['logoUrl']),
              gender: g,
              teamNum: _int(t['teamNum']),
            ),
    ];
    _teamsByKey[g.code] = {for (final t in teams) _key(t.name): t};
    return teams;
  }

  /// 일정·순위 응답에는 `teamNum`이 없어서 팀 목록에서 붙인다.
  Future<Map<String, Team>> _teamNumbers(Gender g) async {
    final hit = _teamsByKey[g.code];
    if (hit != null) return hit;
    try {
      await fetchTeams(g);
    } on ApiException {
      // 팀 번호가 없으면 팀 상세로만 못 넘어간다. 목록은 그대로 보여준다.
      return _teamsByKey[g.code] ??= const {};
    }
    return _teamsByKey[g.code] ?? const {};
  }

  Team _team(Object? raw, Gender g, Map<String, Team> known) {
    final j = _map(raw);
    final name = _str(j['name']) ?? '';
    final canonical = known[_key(name)];
    return Team(
      // 팀 목록의 이름으로 통일한다. 못 찾으면 받은 이름을 그대로 쓴다.
      name: canonical?.name ?? name,
      logoUrl: _str(j['logoUrl']) ?? canonical?.logoUrl,
      gender: g,
      teamNum: _int(j['teamNum']) ?? canonical?.teamNum,
    );
  }

  // --- 선수 ---

  @override
  Future<List<Player>> fetchPlayers(Gender g) async {
    final json = await client.get('/player', _query(g));
    return [
      for (final raw in _list(_map(json)['players']))
        if (_map(raw) case final p)
          if (_str(p['name']) case final name?) _player(p, name),
    ];
  }

  Player _player(Map<String, dynamic> p, String name) {
    final seq = _int(p['playerSeq']);
    final stats = _stats(p['stats']);
    return Player(
      id: seq != null ? 'p$seq' : 'n:$name',
      playerSeq: seq,
      name: name,
      teamName: _str(p['teamName']) ?? '',
      teamLogoUrl: _str(p['teamLogoUrl']),
      photoUrl: _str(p['photoUrl']),
      number: _int(p['number']),
      position: _str(p['position']),
      stats: stats,
      statLine: stats.line,
    );
  }

  PlayerSeasonSummary _stats(Object? raw) {
    final s = _map(raw);
    return PlayerSeasonSummary(
      games: _int(s['games']),
      goals: _int(s['goals']) ?? 0,
      shots: _int(s['shots']) ?? 0,
      goalRate: _num(s['goalRate'])?.toDouble(),
      assists: _int(s['assists']) ?? 0,
      steals: _int(s['steals']) ?? 0,
      blocks: _int(s['blocks']) ?? 0,
      turnovers: _int(s['turnovers']) ?? 0,
      saves: _int(s['saves']),
      saveRate: _num(s['saveRate'])?.toDouble(),
      playMinutes: PlayerSeasonSummary.minutesFromLabel(_str(s['playTime'])),
    );
  }

  @override
  Future<PlayerDetail> fetchPlayerDetail(Player player) async {
    final seq = player.playerSeq;
    if (seq == null) {
      throw const ApiException('이 선수는 상세 기록이 없어요');
    }
    final j = _map(await client.get('/player/$seq'));

    return PlayerDetail(
      player: Player(
        id: player.id,
        playerSeq: seq,
        name: _str(j['name']) ?? player.name,
        teamName: _str(j['teamName']) ?? player.teamName,
        teamLogoUrl: _str(j['teamLogoUrl']) ?? player.teamLogoUrl,
        photoUrl: _str(j['photoUrl']) ?? player.photoUrl,
        number: _int(j['number']) ?? player.number,
        position: _str(j['position']) ?? player.position,
        stats: player.stats,
        statLine: player.statLine,
      ),
      nameEn: _str(j['nameEn']),
      birthLabel: _str(j['birthLabel']),
      heightCm: _int(j['heightCm']),
      weightKg: _int(j['weightKg']),
      school: _str(j['school']),
      career: _stats(j['careerStats']),
      seasons: [
        for (final raw in _list(j['seasonStats']))
          if (_map(raw) case final row)
            PlayerSeasonRow(
              season: _str(row['season']) ?? '',
              postseason: row['postseason'] == true,
              stats: _stats(row['stats']),
            ),
      ],
    );
  }

  @override
  Future<List<PlayerStat>> fetchTopPlayers(
    Gender g,
    StatCategory category,
  ) async {
    final json = await client.get('/player/ranking', {
      ..._query(g),
      'category': category.name,
    });
    final body = _map(json);
    final unit = _str(body['unit']) ?? category.unit;
    final items = _list(body['items']);
    return [
      for (var i = 0; i < items.length; i++)
        if (_map(items[i]) case final p)
          PlayerStat(
            rank: _int(p['rank']) ?? i + 1,
            name: _str(p['name']) ?? '',
            teamName: _str(p['teamName']) ?? '',
            position: _str(p['position']) ?? '-',
            value: '${_num(p['value']) ?? 0}',
            unit: unit,
            logoUrl: _str(p['teamLogoUrl']),
          ),
    ];
  }

  // --- 경기 상세 ---

  @override
  Future<GameDetail> fetchGameDetail(Game game) async {
    final seq = game.matchSeq;
    if (seq == null) {
      throw const ApiException('이 경기는 상세 기록이 없어요');
    }

    // 기록과 중계는 서로 독립이라 동시에 받는다.
    // MVP는 화면이 따로 요청한다 ([fetchMvp]) — 여기서 또 받지 않는다.
    final results = await Future.wait([
      client.get('/game/$seq'),
      client.get('/game/$seq/live'),
    ]);
    final detail = _map(results[0]);
    final live = _map(results[1]);

    final scoreHome = _int(detail['scoreHome']) ?? game.scoreHome;
    final scoreAway = _int(detail['scoreAway']) ?? game.scoreAway;

    return GameDetail(
      game: Game(
        id: game.id,
        matchSeq: seq,
        startsAt: _date(detail['startsAt']) ?? game.startsAt,
        home: game.home,
        away: game.away,
        status: _status(live['status'], game.startsAt),
        meta: game.meta,
        broadcast: game.broadcast,
        scoreHome: scoreHome,
        scoreAway: scoreAway,
        venue: _str(detail['venue']) ?? game.venue,
      ),
      firstHalfHome: _int(detail['firstHalfHome']) ?? 0,
      firstHalfAway: _int(detail['firstHalfAway']) ?? 0,
      events: _events(_list(live['events'])),
      stats: [
        for (final raw in _list(detail['stats']))
          if (_map(raw) case final s)
            TeamStatLine(
              label: _str(s['label']) ?? '',
              home: _num(s['home']) ?? 0,
              away: _num(s['away']) ?? 0,
              isPercent: _str(s['unit']) == 'percent',
            ),
      ],
      headToHead: await _headToHead(game),
    );
  }

  /// 서버 이벤트는 최신순이고 종류가 앱보다 많다. 시안 타임라인이 그리는
  /// 것만 남긴다 (득점·선방·2분 퇴장·시작/하프타임/종료).
  List<GameEvent> _events(List<Object?> raw) {
    final events = <GameEvent>[];
    for (final item in raw) {
      final e = _map(item);
      final action = _str(e['action']) ?? '';
      final type = switch (_str(e['type'])) {
        'goal' => GameEventType.goal,
        'save' => GameEventType.save,
        'twoMinutes' => GameEventType.twoMinutes,
        'period' => _periodType(action),
        _ => null,
      };
      if (type == null) continue;

      final side = _str(e['side']);
      events.add(GameEvent(
        type: type,
        minute: _int(e['minute']) ?? 0,
        isHome: side == null ? null : side == 'home',
        playerName: _str(e['playerName']),
        sevenMeter: action.contains('7m'),
        scoreHome: _int(e['scoreHome']),
        scoreAway: _int(e['scoreAway']),
      ));
    }
    return events;
  }

  GameEventType? _periodType(String action) {
    if (action.contains('경기시작') || action.contains('전반시작')) {
      return GameEventType.start;
    }
    if (action.contains('전반종료')) return GameEventType.halfTime;
    if (action.contains('경기종료')) return GameEventType.end;
    return null;
  }

  List<MvpCandidate> _mvpCandidates(List<Object?> raw) => [
        for (final item in raw)
          if (_map(item) case final c)
            if (_str(c['playerName']) case final name?)
              MvpCandidate(
                id: MvpCandidate.idFor(_int(c['playerSeq']), name),
                playerSeq: _int(c['playerSeq']),
                name: name,
                teamName: _str(c['teamName']) ?? '',
                statLine: _str(c['statLine']) ?? '',
                votes: _int(c['votes']) ?? 0,
                number: _int(c['number']),
                isHome: _str(c['side']) == 'home',
              ),
      ];

  /// 맞대결 기록은 대응 엔드포인트가 없다. 시즌 일정에서 두 팀 경기를
  /// 골라 직접 만든다. 일정은 서버가 캐시하고 있어 비싸지 않다.
  Future<HeadToHead> _headToHead(Game game) async {
    final List<ScheduleDay> days;
    try {
      days = await _fetchSchedule(game.home.gender);
    } on ApiException {
      return const HeadToHead(
          homeWins: 0, draws: 0, awayWins: 0, avgHome: 0, avgAway: 0, games: []);
    }

    var homeWins = 0, draws = 0, awayWins = 0, sumHome = 0, sumAway = 0;
    final rows = <HeadToHeadGame>[];

    for (final day in days) {
      for (final g in day.games) {
        if (g.status != GameStatus.finished) continue;
        final sameOrder = g.home.name == game.home.name &&
            g.away.name == game.away.name;
        final reversed = g.home.name == game.away.name &&
            g.away.name == game.home.name;
        if (!sameOrder && !reversed) continue;

        final h = g.scoreHome, a = g.scoreAway;
        if (h == null || a == null) continue;

        // 항상 이번 경기의 홈 팀을 왼쪽에 둔다.
        final mine = sameOrder ? h : a;
        final theirs = sameOrder ? a : h;
        sumHome += mine;
        sumAway += theirs;
        if (mine > theirs) {
          homeWins++;
        } else if (mine < theirs) {
          awayWins++;
        } else {
          draws++;
        }

        rows.add(HeadToHeadGame(
          season: season(),
          date: day.shortLabel,
          score: '$mine : $theirs',
          resultLabel: mine > theirs
              ? '승'
              : mine < theirs
                  ? '패'
                  : '무',
          homeWon: mine > theirs,
        ));
      }
    }

    final n = rows.length;
    return HeadToHead(
      homeWins: homeWins,
      draws: draws,
      awayWins: awayWins,
      avgHome: n == 0 ? 0 : sumHome / n,
      avgAway: n == 0 ? 0 : sumAway / n,
      games: rows.reversed.toList(),
    );
  }

  // --- 팀 상세 ---

  @override
  Future<TeamDetail> fetchTeamDetail(Team team) async {
    final num_ = team.teamNum;
    if (num_ == null) {
      throw const ApiException('이 팀은 상세 정보가 없어요');
    }
    final json = await client.get('/team/$num_', _query(team.gender));
    final t = _map(json);

    final results = [
      for (final r in _list(t['results']))
        switch (_str(r)) {
          'W' => MatchResult.win,
          'L' => MatchResult.loss,
          _ => MatchResult.draw,
        },
    ];

    final intro = _str(t['intro']) ?? '';
    final coaches = _list(t['coaches']).map(_map).toList();
    final headCoach = coaches
        .where((c) => (_str(c['role']) ?? '').contains('감독'))
        .map((c) => _str(c['name']))
        .whereType<String>()
        .firstOrNull;

    return TeamDetail(
      team: Team(
        name: _str(t['name']) ?? team.name,
        logoUrl: _str(t['logoUrl']) ?? team.logoUrl,
        gender: team.gender,
        teamNum: num_,
      ),
      rank: RankRow(
        rank: _int(t['rank']) ?? 0,
        team: team,
        points: _int(t['points']) ?? 0,
        played: _int(t['played']) ?? 0,
        wins: _int(t['wins']) ?? 0,
        draws: _int(t['draws']) ?? 0,
        losses: _int(t['losses']) ?? 0,
        goalsFor: _int(t['goalsFor']) ?? 0,
        goalsAgainst: _int(t['goalsAgainst']) ?? 0,
      ),
      // 원본에 슬로건 항목이 없다. 소개 본문 첫 문장을 쓴다.
      slogan: _firstSentence(intro),
      intro: intro,
      facts: [
        if (_int(t['foundedYear']) case final y?) ('창단', '$y년'),
        if (_str(t['homeTown']) case final v?) ('연고지', v),
        if (_str(t['homeStadium']) case final v?) ('홈구장', v),
        if (headCoach case final v?) ('감독', v),
      ],
      history: [
        for (final h in _list(t['history']))
          if (_map(h) case final e)
            TeamHistoryEntry(_str(e['year']) ?? '', _str(e['text']) ?? ''),
      ],
      address: _str(t['address']) ?? '',
      players: [
        for (final s in _list(t['squad']))
          if (_map(s) case final p)
            if (_str(p['name']) case final name?)
              Player(
                id: MvpCandidate.idFor(_int(p['playerSeq']), name),
                name: name,
                teamName: _str(t['name']) ?? team.name,
                teamLogoUrl: _str(t['logoUrl']) ?? team.logoUrl,
                number: _int(p['number']),
                position: _str(p['position']),
                statLine: '',
              ),
      ],
      // 라운드별 순위는 연맹이 주지 않는다. 전적 탭은 누적 승점으로 그린다.
      rankTrend: const [],
      results: results,
    );
  }

  String _firstSentence(String intro) {
    if (intro.isEmpty) return '';
    final line = intro.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => '',
        );
    final end = line.indexOf('.');
    return (end > 0 ? line.substring(0, end + 1) : line).trim();
  }

  // --- 사용자 콘텐츠 ---

  @override
  Future<PredictionTally> fetchPrediction(Game game) async =>
      _tally(await client.get('/game/${_seq(game)}/prediction'));

  @override
  Future<PredictionTally> submitPrediction(Game game, PredictionPick pick) async =>
      _tally(await client.post('/game/${_seq(game)}/prediction',
          body: {'pick': pick.code}));

  PredictionTally _tally(Object? json) {
    final j = _map(json);
    return PredictionTally(
      total: _int(j['total']) ?? 0,
      home: _int(j['home']) ?? 0,
      draw: _int(j['draw']) ?? 0,
      away: _int(j['away']) ?? 0,
      open: j['open'] == true,
      myPick: PredictionPick.fromCode(_str(j['myPick'])),
    );
  }

  @override
  Future<MvpBoard> fetchMvp(Game game) async =>
      _board(await client.get('/game/${_seq(game)}/mvp'));

  @override
  Future<MvpBoard> submitMvpVote(Game game, MvpCandidate candidate) async =>
      _board(await client.post('/game/${_seq(game)}/mvp', body: {
        'playerSeq': candidate.playerSeq,
        'playerName': candidate.name,
      }));

  MvpBoard _board(Object? json) {
    final j = _map(json);
    final myVote = _int(j['myVote']);
    final myName = _str(j['myVoteName']);
    return MvpBoard(
      candidates: _mvpCandidates(_list(j['candidates'])),
      total: _int(j['total']) ?? 0,
      open: j['open'] == true,
      // playerSeq를 특정 못 한 선수는 이름으로 투표한다. 07 C절.
      myVoteId: myVote != null
          ? 'p$myVote'
          : (myName != null ? 'n:$myName' : null),
    );
  }

  int _seq(Game game) {
    final seq = game.matchSeq;
    if (seq == null) throw const ApiException('이 경기는 예측을 지원하지 않아요');
    return seq;
  }

  @override
  Future<List<CheerPost>> fetchCheers(Team team, {int page = 1}) async =>
      _cheers(await client.get('/team/${_teamNum(team)}/cheer', {
        'gender': team.gender.code,
        'page': '$page',
      }));

  @override
  Future<List<CheerPost>> submitCheer(Team team, String text) async {
    await client.post('/team/${_teamNum(team)}/cheer',
        query: {'gender': team.gender.code}, body: {'text': text});
    return fetchCheers(team);
  }

  @override
  Future<List<CheerPost>> deleteCheer(Team team, String cheerId) async {
    await client.delete('/team/${_teamNum(team)}/cheer/$cheerId',
        {'gender': team.gender.code});
    return fetchCheers(team);
  }

  @override
  Future<List<CheerPost>> toggleCheerLike(Team team, String cheerId) async {
    await client.post('/team/${_teamNum(team)}/cheer/$cheerId/like',
        query: {'gender': team.gender.code});
    return fetchCheers(team);
  }

  List<CheerPost> _cheers(Object? json) => [
        for (final raw in _list(_map(json)['items']))
          if (_map(raw) case final c)
            CheerPost(
              id: '${_int(c['id']) ?? ''}',
              // 닉네임이 없는 앱이다. 서버가 이름을 만들지 않는다.
              author: c['isMine'] == true ? '나' : '익명',
              text: _str(c['text']) ?? '',
              dateLabel: _cheerDate(_date(c['createdAt'])),
              likes: _int(c['likes']) ?? 0,
              liked: c['liked'] == true,
              isMine: c['isMine'] == true,
            ),
      ];

  String _cheerDate(DateTime? at) {
    if (at == null) return '';
    final local = at.toLocal();
    return '${local.month}.${local.day}';
  }

  int _teamNum(Team team) {
    final n = team.teamNum;
    if (n == null) throw const ApiException('이 팀은 응원글을 지원하지 않아요');
    return n;
  }

  // --- 안전한 형변환 ---
  //
  // 서버가 파싱에 실패하면 필드가 null로 온다. 앱이 죽지 않도록 전부 통과시킨다.

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : const {};

  static List<Object?> _list(Object? v) => v is List ? v : const [];

  static String? _str(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static int? _int(Object? v) => switch (v) {
        int() => v,
        double() => v.round(),
        String() => int.tryParse(v),
        _ => null,
      };

  static num? _num(Object? v) => switch (v) {
        num() => v,
        String() => num.tryParse(v),
        _ => null,
      };

  static DateTime? _date(Object? v) {
    final s = _str(v);
    return s == null ? null : DateTime.tryParse(s);
  }
}
