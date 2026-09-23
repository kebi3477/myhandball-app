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
  });

  final String id;
  final String name;
  final String teamName;
  final String statLine;
  final int votes;
  final String? teamLogoUrl;
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
    required this.mvpCandidates,
  });

  final Game game;
  final int firstHalfHome;
  final int firstHalfAway;
  final List<GameEvent> events;
  final List<TeamStatLine> stats;
  final HeadToHead headToHead;
  final List<MvpCandidate> mvpCandidates;

  int get secondHalfHome => (game.scoreHome ?? 0) - firstHalfHome;
  int get secondHalfAway => (game.scoreAway ?? 0) - firstHalfAway;

  /// MVP 투표는 경기가 끝나야 열린다.
  bool get mvpOpen => game.status == GameStatus.finished;

  /// 예측은 경기 시작 전까지만 바꿀 수 있다.
  bool get predictionOpen => game.status == GameStatus.pre;
}

/// 승부 예측 선택지.
enum PredictionPick {
  home('홈 승'),
  draw('무승부'),
  away('원정 승');

  const PredictionPick(this.label);

  final String label;
}
