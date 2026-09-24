import 'player.dart';
import 'rank_row.dart';
import 'team.dart';

/// 경기 결과 하나. 시즌 추이의 막대에 쓴다.
enum MatchResult { win, draw, loss }

/// 구단 연혁 한 줄.
class TeamHistoryEntry {
  const TeamHistoryEntry(this.year, this.text);

  final String year;
  final String text;
}

/// 응원글. 시안 `mh_cheer`에 팀별로 쌓인다.
/// 응원글 신고 사유. 값은 서버가 받는 코드다.
enum CheerReportReason {
  spam('spam', '스팸·광고'),
  abuse('abuse', '욕설·비방·혐오 표현'),
  sexual('sexual', '음란·선정적인 내용'),
  other('other', '기타');

  const CheerReportReason(this.code, this.label);

  final String code;
  final String label;

  /// 기타를 고르면 무엇이 문제인지 적어야 한다.
  bool get needsDetail => this == CheerReportReason.other;
}

/// 차단한 작성자 한 명.
///
/// 서버는 `authorId`와 차단 시각만 준다 — **닉네임을 모른다.** 차단하는
/// 순간의 이름을 기기에 적어 두고 목록에서 쓴다
/// (`PreferencesRepository.blockedName`).
class BlockedAuthor {
  const BlockedAuthor({
    required this.authorId,
    required this.blockedAt,
    this.nickname,
  });

  final String authorId;
  final DateTime? blockedAt;
  final String? nickname;

  String get displayName => nickname ?? '익명';

  /// `2026.09.24 차단`
  String get blockedLabel {
    final at = blockedAt;
    if (at == null) return '차단함';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${at.year}.${two(at.month)}.${two(at.day)} 차단';
  }
}

class CheerPost {
  const CheerPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.text,
    required this.dateLabel,
    required this.likes,
    this.isMine = false,
    this.liked = false,
  });

  final String id;

  /// 작성자 식별자. 서버가 기기 ID를 해싱해 만든 값이라 되돌릴 수 없다.
  /// **차단은 이걸로 한다** — 닉네임은 바뀔 수 있다.
  final String authorId;

  final String author;
  final String text;
  final String dateLabel;
  final int likes;
  final bool isMine;

  /// 내가 좋아요를 눌렀는지. 서버가 기기 ID로 판정해 준다.
  final bool liked;

  String get initial => author.isEmpty ? '?' : author.characters.first;

  CheerPost copyWith({int? likes, bool? liked}) => CheerPost(
        id: id,
        authorId: authorId,
        author: author,
        text: text,
        dateLabel: dateLabel,
        likes: likes ?? this.likes,
        isMine: isMine,
        liked: liked ?? this.liked,
      );
}

/// 연맹 "팀기록" 탭의 시즌 누적 기록. `/api/team/:teamNum`의 `seasonRecords`.
///
/// 득점을 유형별로 쪼개 준다 — 6m·윙·9m·7m·속공·돌파. 합이 [goals]와
/// 정확히 맞지 않을 수 있어서(원본이 그렇다) 막대는 [goals]가 아니라
/// **유형 중 최대값**을 기준으로 그린다.
class TeamSeasonRecord {
  const TeamSeasonRecord({
    required this.season,
    required this.goals,
    required this.goals6m,
    required this.goalsWing,
    required this.goals9m,
    required this.goals7m,
    required this.goalsFast,
    required this.goalsBreakthrough,
    required this.assists,
    required this.turnovers,
    required this.steals,
    required this.blocks,
    required this.yellowCards,
    required this.twoMinutes,
    required this.redCards,
  });

  final String season;
  final int goals;
  final int goals6m;
  final int goalsWing;
  final int goals9m;
  final int goals7m;
  final int goalsFast;
  final int goalsBreakthrough;
  final int assists;
  final int turnovers;
  final int steals;
  final int blocks;
  final int yellowCards;
  final int twoMinutes;
  final int redCards;

  /// 시안 `teamRecord.shotTypes` — 라벨 순서까지 시안 그대로.
  List<(String label, int value)> get shotTypes => [
        ('6m', goals6m),
        ('윙', goalsWing),
        ('9m', goals9m),
        ('7m', goals7m),
        ('속공', goalsFast),
        ('돌파', goalsBreakthrough),
      ];

  /// 시안 `teamRecord.extras` — 3열 6칸.
  List<(String label, String value)> get extras => [
        ('어시스트', '$assists'),
        ('스틸', '$steals'),
        ('블록', '$blocks'),
        ('턴오버', '$turnovers'),
        ('2분간 퇴장', '$twoMinutes'),
        ('경고·퇴장', '$yellowCards·$redCards'),
      ];

  /// 값이 전부 0이면 원본에 기록이 안 올라온 것이다. 0짜리 막대를 여섯 개
  /// 그려 두면 "기록이 0"인지 "아직 없는지" 구분이 안 된다.
  bool get hasDetail => shotTypes.any((t) => t.$2 > 0);
}

class TeamDetail {
  const TeamDetail({
    required this.team,
    required this.rank,
    required this.slogan,
    required this.intro,
    required this.facts,
    required this.history,
    required this.address,
    required this.players,
    required this.rankTrend,
    required this.results,
    this.seasonRecord,
  });

  final Team team;
  final RankRow rank;
  final String slogan;
  final String intro;

  /// 2열 카드로 나오는 (라벨, 값) 목록 — 창단, 연고지, 홈구장, 감독.
  final List<(String, String)> facts;

  final List<TeamHistoryEntry> history;
  final String address;
  final List<Player> players;

  /// 라운드별 순위 추이. 값이 작을수록 좋은 순위다.
  final List<int> rankTrend;

  final List<MatchResult> results;

  /// 이번 시즌 팀기록. 원본에 없으면 `null`이고, 시안은 그때
  /// "상세 팀 기록을 준비 중이에요"를 띄운다.
  final TeamSeasonRecord? seasonRecord;

  String get divisionLabel =>
      team.gender.divisionLabel;

  /// 상단 칩 4개.
  List<(String label, String value)> get summaryChips => [
        ('순위', '${rank.rank}위'),
        ('승점', '${rank.points}'),
        ('득실차', rank.goalDiff > 0 ? '+${rank.goalDiff}' : '${rank.goalDiff}'),
        ('경기', '${rank.played}'),
      ];

  int get longestWinStreak {
    var best = 0, run = 0;
    for (final r in results) {
      run = r == MatchResult.win ? run + 1 : 0;
      if (run > best) best = run;
    }
    return best;
  }

  /// 최근 5경기 승률.
  String get recentForm {
    final recent = results.length <= 5
        ? results
        : results.sublist(results.length - 5);
    if (recent.isEmpty) return '-';
    final wins = recent.where((r) => r == MatchResult.win).length;
    return '$wins승 ${recent.length - wins}패';
  }
}

extension on String {
  Iterable<String> get characters sync* {
    for (var i = 0; i < length; i++) {
      yield this[i];
    }
  }
}
