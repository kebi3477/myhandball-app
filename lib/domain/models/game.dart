import 'team.dart';

/// 외부 중계 링크. API `GameItem.liveLinks[]`.
class LiveLink {
  const LiveLink({required this.provider, required this.url});

  /// `naver` / `daum` 등.
  final String provider;
  final String url;
}

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
    this.matchSeq,
    this.startsAt,
    this.liveLinks = const [],
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

  /// 연맹 사이트의 경기 번호. 경기 상세·예측·MVP·중계가 전부 이걸로 걸린다.
  ///
  /// 일정에 상세 링크가 없는 경기는 `null`이고, 그런 경기는 상세를 열 수
  /// 없다 (`../myhandball-api/docs/api-tasks/07-후속-작업.md` A-2).
  final int? matchSeq;

  /// 경기 시작 시각. API가 `startsAt`(ISO 8601, `+09:00`)으로 준다.
  final DateTime? startsAt;

  /// 외부 중계 링크. v1 웹이 그랬듯 네이버를 먼저 고른다.
  final List<LiveLink> liveLinks;

  /// 시안 `g.dateLabel` — 일정 카드 맨 위의 날짜·시각. `11.09 (일) 14:00`
  ///
  /// **[meta]를 그대로 쓰면 안 된다.** 경기 중에는 `전반 18'`로 바뀌어서
  /// 날짜 자리에 경과 시간이 찍힌다. 시작 시각이 있으면 그걸로 만들고,
  /// 없을 때만 [meta]로 떨어진다.
  String get dateLabel {
    final at = startsAt;
    if (at == null) return meta;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(at.month)}.${two(at.day)} (${weekdays[at.weekday - 1]}) '
        '${two(at.hour)}:${two(at.minute)}';
  }

  /// `D-5` / `D-DAY` / 이미 지났으면 `D+3`. 시작 시각을 모르면 `null`.
  String? get ddayLabel {
    final at = startsAt;
    if (at == null) return null;
    final now = DateTime.now();
    final days = DateTime(at.year, at.month, at.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days == 0) return 'D-DAY';
    return days > 0 ? 'D-$days' : 'D+${-days}';
  }

  /// 서버 기능(예측·MVP·중계)을 걸 수 있는 경기인지.
  bool get hasDetail => matchSeq != null;

  /// "중계 보기"가 열 주소. 경기별 링크가 없으면 `null`이고,
  /// 그때는 연맹 중계 편성표([AppConfig.broadcastUrl])로 간다.
  String? get liveUrl {
    for (final provider in const ['naver', 'daum']) {
      for (final link in liveLinks) {
        if (link.provider == provider) return link.url;
      }
    }
    return liveLinks.isEmpty ? null : liveLinks.first.url;
  }

  bool get hasScore => status != GameStatus.pre;

  String get scoreHomeText => scoreHome?.toString() ?? '-';
  String get scoreAwayText => scoreAway?.toString() ?? '-';

  String get broadcastText => broadcast.join(', ');

  String get watchLabel => status == GameStatus.live ? '중계 보기' : '중계 정보';
}
