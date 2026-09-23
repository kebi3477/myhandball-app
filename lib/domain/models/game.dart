import 'team.dart';

/// 경기 상태. 시안 위젯 명세의 `pre / live / final`과 같다.
///
/// 현재 API(`/api/schedule`)는 상태를 직접 주지 않고 `scoreText`와 경기
/// 시작 시각만 준다. v1 웹은 "시작~2시간"을 LIVE로 보는 규칙을 클라이언트에서
/// 계산했다 (`Main.tsx`의 `getGameStatus`). 이 판정은 API로 올리는 게 맞다.
enum GameStatus {
  pre('오늘 경기'),
  live('LIVE'),
  finished('경기 종료');

  const GameStatus(this.chipLabel);

  final String chipLabel;
}

class Game {
  const Game({
    required this.id,
    required this.home,
    required this.away,
    required this.status,
    required this.meta,
    this.broadcast = const [],
    this.scoreHome,
    this.scoreAway,
    this.venue,
    this.canBook = false,
  });

  final String id;
  final Team home;
  final Team away;
  final GameStatus status;

  /// 카드 우상단 문구. 예: `11.14 (토) 14:00`, `전반 18'`
  final String meta;

  /// `/api/schedule`의 `broadcast` 배열.
  final List<String> broadcast;

  final int? scoreHome;
  final int? scoreAway;
  final String? venue;

  /// 예매 링크를 띄울지.
  final bool canBook;

  bool get hasScore => status != GameStatus.pre;

  String get scoreHomeText => scoreHome?.toString() ?? '-';
  String get scoreAwayText => scoreAway?.toString() ?? '-';

  String get broadcastText => broadcast.join(', ');

  String get watchLabel => status == GameStatus.live ? '중계 보기' : '중계 정보';
}
