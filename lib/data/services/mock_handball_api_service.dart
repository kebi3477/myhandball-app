import '../../domain/models/game.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/player_stat.dart';
import '../../domain/models/rank_row.dart';
import '../../domain/models/schedule_day.dart';
import '../../domain/models/team.dart';
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

  @override
  Future<List<ScheduleDay>> fetchMonthlySchedule(
    Gender gender,
    DateTime month,
  ) async {
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
      RankRow(rank: 1, team: skHawks, points: 34),
      RankRow(rank: 2, team: doosan, points: 31),
      RankRow(rank: 3, team: incheon, points: 27),
      RankRow(rank: 4, team: chungnam, points: 22),
      RankRow(rank: 5, team: sangmu, points: 18),
      RankRow(rank: 6, team: hanam, points: 13),
    ];
    const womens = [
      RankRow(rank: 1, team: skSugar, points: 36),
      RankRow(rank: 2, team: seoul, points: 30),
      RankRow(rank: 3, team: busan, points: 28),
      RankRow(rank: 4, team: samcheok, points: 21),
      RankRow(rank: 5, team: gyeongnam, points: 17),
      RankRow(rank: 6, team: incheonW, points: 12),
    ];
    return gender == Gender.women ? womens : mens;
  }

  @override
  Future<List<PlayerStat>> fetchTopPlayers(
    Gender gender,
    StatCategory category,
  ) async {
    await _delay();
    return switch (category) {
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
    };
  }
}
