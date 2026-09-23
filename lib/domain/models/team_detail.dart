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
class CheerPost {
  const CheerPost({
    required this.id,
    required this.author,
    required this.text,
    required this.dateLabel,
    required this.likes,
    this.isMine = false,
    this.liked = false,
  });

  final String id;
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
        author: author,
        text: text,
        dateLabel: dateLabel,
        likes: likes ?? this.likes,
        isMine: isMine,
        liked: liked ?? this.liked,
      );
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
