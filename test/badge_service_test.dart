import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/badge_service.dart';
import 'package:myhandball/domain/models/badge.dart';

/// 배지 판정은 [BadgeService] 한 곳에 있다. 화면만 봐서는 규칙이 틀린 건지
/// 데이터가 없는 건지 구분이 안 되므로 여기서 잡는다.
void main() {
  const service = BadgeService();

  MhBadge badge(
    MhBadgeKind kind, {
    int guideDone = 0,
    DateTime? guideCompletedAt,
    int wins = 0,
    int draws = 0,
    int losses = 0,
    int teamWins = 0,
    int teamDraws = 0,
    int teamLosses = 0,
    int hits = 0,
  }) =>
      service
          .evaluate(
            guideDone: guideDone,
            guideCompletedAt: guideCompletedAt,
            attendanceWins: wins,
            attendanceDraws: draws,
            attendanceLosses: losses,
            teamWins: teamWins,
            teamDraws: teamDraws,
            teamLosses: teamLosses,
            predictionHits: hits,
          )
          .firstWhere((b) => b.kind == kind);

  test('순서는 승리 요정 · 예측 고수 · 입문 수료로 고정이다', () {
    final all = service.evaluate(
      guideDone: 0,
      guideCompletedAt: null,
      attendanceWins: 0,
      attendanceDraws: 0,
      attendanceLosses: 0,
      teamWins: 0,
      teamDraws: 0,
      teamLosses: 0,
      predictionHits: 0,
    );
    expect(all.map((b) => b.kind).toList(), MhBadgeKind.values);
    expect(MhBadge.countLabel(all), '0/3 획득');
  });

  group('승리 요정', () {
    // 시안은 "응원 경기 3회 + 승률이 팀보다 높을 때"였는데, 그러면 전승
    // 팀을 응원하는 사람은 영영 못 딴다. 승리 횟수로 바꿨다.
    test('3승을 채우면 열린다', () {
      expect(badge(MhBadgeKind.winFairy, wins: 2).earned, isFalse);
      expect(badge(MhBadgeKind.winFairy, wins: 2).subtitle, '승리 2/3');
      expect(badge(MhBadgeKind.winFairy, wins: 3).earned, isTrue);
    });

    test('무승부와 패배는 승리로 치지 않는다', () {
      final b = badge(MhBadgeKind.winFairy, wins: 1, draws: 3, losses: 5);
      expect(b.earned, isFalse);
      expect(b.subtitle, '승리 1/3');
    });

    test('팀이 전승이어도 열린다', () {
      // 예전 규칙이 막던 경우다 — 내 승률 100%, 팀 승률 100%라 차이가 0.
      final b = badge(MhBadgeKind.winFairy,
          wins: 3, teamWins: 20, teamLosses: 0);
      expect(b.earned, isTrue);
      expect(b.subtitle, '직관 3승 달성');
    });

    test('팀보다 승률이 높으면 그 차이를 적는다', () {
      // 직관 3전 3승(100%) vs 팀 10승 10패(50%)
      final b = badge(MhBadgeKind.winFairy,
          wins: 3, teamWins: 10, teamLosses: 10);
      expect(b.subtitle, '내가 가면 승률 +50%p');
    });

    test('팀보다 낮으면 승률 대신 승수를 적는다', () {
      // "+-20%p"처럼 읽히면 안 된다.
      final b = badge(MhBadgeKind.winFairy,
          wins: 3, losses: 5, teamWins: 18, teamLosses: 2);
      expect(b.earned, isTrue);
      expect(b.subtitle, '직관 3승 달성');
    });

    test('기록이 없으면 0승부터 시작한다', () {
      final b = badge(MhBadgeKind.winFairy, teamWins: 10, teamLosses: 10);
      expect(b.subtitle, '승리 0/3');
      expect(b.ratio, 0);
    });
  });

  group('예측 고수', () {
    test('10회를 채워야 열린다', () {
      expect(badge(MhBadgeKind.predictor, hits: 9).earned, isFalse);
      expect(badge(MhBadgeKind.predictor, hits: 9).subtitle, '적중 9/10');
      expect(badge(MhBadgeKind.predictor, hits: 10).earned, isTrue);
    });

    test('넘겨도 진행바가 1을 안 넘고 실제 횟수를 적는다', () {
      final b = badge(MhBadgeKind.predictor, hits: 24);
      expect(b.ratio, 1.0);
      expect(b.subtitle, '적중 24회 달성');
    });
  });

  group('입문 수료', () {
    test('레슨 5개를 채워야 열린다', () {
      expect(badge(MhBadgeKind.graduate, guideDone: 4).subtitle, '레슨 4/5');
      expect(badge(MhBadgeKind.graduate, guideDone: 4).earned, isFalse);
    });

    test('수료일을 날짜로 적는다', () {
      final b = badge(MhBadgeKind.graduate,
          guideDone: 5, guideCompletedAt: DateTime(2026, 9, 4));
      expect(b.subtitle, '2026.09.04 수료');
    });

    test('날짜를 저장하기 전에 수료한 사용자는 다른 문구를 쓴다', () {
      final b = badge(MhBadgeKind.graduate, guideDone: 5);
      expect(b.earned, isTrue);
      expect(b.subtitle, '가이드 완료');
    });
  });
}
