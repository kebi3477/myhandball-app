import 'game.dart';

/// 문자중계 이벤트 종류. 시안 `mkEvent`의 type과 같다.
enum GameEventType { start, goal, save, twoMinutes, halfTime, end }

class GameEvent {
  const GameEvent({
    required this.type,
    required this.minute,
    this.isHome,
    this.playerName,
    this.sevenMeter = false,
    this.scoreHome,
    this.scoreAway,
  });

  final GameEventType type;
  final int minute;

  /// 어느 팀 이벤트인지. 시작·하프타임·종료는 null.
  final bool? isHome;

  final String? playerName;

  /// 7m 드로 득점.
  final bool sevenMeter;

  /// 득점 시점의 누적 스코어.
  final int? scoreHome;
  final int? scoreAway;

  bool get hasTeam => isHome != null;

  String get minuteLabel {
    if (type == GameEventType.start) return '시작';
    if (type == GameEventType.halfTime) return 'HT';
    if (type == GameEventType.end) return '종료';
    return "$minute'";
  }

  String get title => switch (type) {
        GameEventType.start => '경기 시작',
        GameEventType.halfTime => '전반 종료',
        GameEventType.end => '경기 종료',
        GameEventType.goal => sevenMeter ? '7m 드로 득점' : '득점',
        GameEventType.save => '선방',
        GameEventType.twoMinutes => '2분 퇴장',
      };
}

/// 기록 탭의 팀 비교 항목 하나.
class TeamStatLine {
  const TeamStatLine({
    required this.label,
    required this.home,
    required this.away,
    this.isPercent = false,
  });

  final String label;
  final num home;
  final num away;
  final bool isPercent;

  String get homeText => isPercent ? '$home%' : '$home';
  String get awayText => isPercent ? '$away%' : '$away';

  /// 양쪽 바의 비율. 둘 다 0이면 반반.
  double get homeRatio {
    final total = home + away;
    return total == 0 ? 0.5 : home / total;
  }

  double get awayRatio => 1 - homeRatio;
}

/// 맞대결 기록.
class HeadToHead {
  const HeadToHead({
    required this.homeWins,
    required this.draws,
    required this.awayWins,
    required this.avgHome,
    required this.avgAway,
    required this.games,
  });

  final int homeWins;
  final int draws;
  final int awayWins;
  final double avgHome;
  final double avgAway;
  final List<HeadToHeadGame> games;

  int get total => homeWins + draws + awayWins;

  double ratio(int n) => total == 0 ? 0 : n / total;
}

class HeadToHeadGame {
  const HeadToHeadGame({
    required this.season,
    required this.date,
    required this.score,
    required this.resultLabel,
    required this.homeWon,
  });

  final String season;
  final String date;
  final String score;
  final String resultLabel;
  final bool homeWon;
}

/// MVP 투표 후보.
class MvpCandidate {
  const MvpCandidate({
    required this.id,
    required this.name,
    required this.teamName,
    required this.statLine,
    required this.votes,
    this.teamLogoUrl,
    this.playerSeq,
    this.number,
    this.isHome,
  });

  final String id;
  final String name;
  final String teamName;
  final String statLine;
  final int votes;
  final String? teamLogoUrl;

  /// 연맹 선수 번호. 경기 기록에는 `player_seq`가 없어서 서버가 로스터에서
  /// 찾아 붙인다. 못 찾으면 `null`이고 그때는 이름으로 투표한다
  /// (`../myhandball-api/docs/api-tasks/07-후속-작업.md` C절).
  final int? playerSeq;

  final int? number;

  /// 홈 팀 선수인지. 서버 `side`.
  final bool? isHome;

  /// 서버 응답에서 후보를 식별하는 키.
  ///
  /// `playerSeq`가 없을 수 있으므로 이름으로도 만들 수 있게 해 둔다.
  static String idFor(int? playerSeq, String playerName) =>
      playerSeq != null ? 'p$playerSeq' : 'n:$playerName';
}

/// 경기 상세 한 덩어리.
class GameDetail {
  const GameDetail({
    required this.game,
    required this.firstHalfHome,
    required this.firstHalfAway,
    required this.events,
    required this.stats,
    required this.headToHead,
    this.mvpCandidates = const [],
  });

  final Game game;
  final int firstHalfHome;
  final int firstHalfAway;
  final List<GameEvent> events;
  final List<TeamStatLine> stats;
  final HeadToHead headToHead;
  /// MVP 후보. **연동판에서는 비어 있다** — 후보와 득표는
  /// `GET /api/game/:matchSeq/mvp`가 [MvpBoard]로 따로 준다.
  /// 목업이 화면을 채우려고 쓰는 자리다.
  final List<MvpCandidate> mvpCandidates;

  int get secondHalfHome => (game.scoreHome ?? 0) - firstHalfHome;
  int get secondHalfAway => (game.scoreAway ?? 0) - firstHalfAway;

  /// 예측이 아직 열려 있을지에 대한 추정.
  ///
  /// 실제 마감 판정은 서버가 `startsAt`으로 한다 ([PredictionTally.open]).
  /// 집계를 받아오기 전 초기값으로만 쓴다.
  bool get predictionOpen => game.status == GameStatus.pre;
}

/// 승부 예측 선택지.
enum PredictionPick {
  home('홈 승'),
  draw('무승부'),
  away('원정 승');

  const PredictionPick(this.label);

  final String label;

  /// API가 쓰는 값 (`{ pick: "home" | "draw" | "away" }`).
  String get code => name;

  static PredictionPick? fromCode(String? code) => switch (code) {
        'home' => PredictionPick.home,
        'draw' => PredictionPick.draw,
        'away' => PredictionPick.away,
        _ => null,
      };
}

/// 서버가 집계한 예측 분포. `GET /api/game/:matchSeq/prediction`.
///
/// 기기에만 있던 값이 서버로 올라오면서 생겼다. 다른 사람 예측을 보여주려면
/// 집계가 있어야 한다.
class PredictionTally {
  const PredictionTally({
    required this.total,
    required this.home,
    required this.draw,
    required this.away,
    required this.open,
    this.myPick,
  });

  const PredictionTally.empty({this.open = false})
      : total = 0,
        home = 0,
        draw = 0,
        away = 0,
        myPick = null;

  final int total;
  final int home;
  final int draw;
  final int away;

  /// 경기 시작 전까지만 true. 서버가 `startsAt`으로 판정한다.
  final bool open;

  final PredictionPick? myPick;

  int votesFor(PredictionPick pick) => switch (pick) {
        PredictionPick.home => home,
        PredictionPick.draw => draw,
        PredictionPick.away => away,
      };

  /// 0~1. 아무도 안 찍었으면 0.
  double ratioFor(PredictionPick pick) =>
      total == 0 ? 0 : votesFor(pick) / total;

  int percentFor(PredictionPick pick) => (ratioFor(pick) * 100).round();
}

/// 서버가 집계한 MVP 투표. `GET /api/game/:matchSeq/mvp`.
class MvpBoard {
  const MvpBoard({
    required this.candidates,
    required this.total,
    required this.open,
    this.myVoteId,
  });

  const MvpBoard.empty()
      : candidates = const [],
        total = 0,
        open = false,
        myVoteId = null;

  /// 득표 내림차순.
  final List<MvpCandidate> candidates;

  final int total;

  /// 경기가 끝나야 열린다. 서버가 경기 상태로 판정한다.
  final bool open;

  /// 내가 뽑은 후보의 [MvpCandidate.id].
  final String? myVoteId;

  bool get hasVoted => myVoteId != null;

  double ratioFor(MvpCandidate c) => total == 0 ? 0 : c.votes / total;
}
