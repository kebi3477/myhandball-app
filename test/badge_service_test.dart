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
    int losses = 0,
    int teamWins = 0,
    int teamLosses = 0,
    int hits = 0,
  }) =>
      service
          .evaluate(
            guideDone: guideDone,
            guideCompletedAt: guideCompletedAt,
            attendanceWins: wins,
            attendanceLosses: losses,
            teamWins: teamWins,
            teamLosses: teamLosses,
            predictionHits: hits,
          )
          .firstWhere((b) => b.kind == kind);

  test('순서는 승리 요정 · 예측 고수 · 입문 수료로 고정이다', () {
    final all = service.evaluate(
      guideDone: 0,
      guideCompletedAt: null,
      attendanceWins: 0,
      attendanceLosses: 0,
      teamWins: 0,
      teamLosses: 0,
      predictionHits: 0,
    );
    expect(all.map((b) => b.kind).toList(), MhBadgeKind.values);
    expect(MhBadge.countLabel(all), '0/3 획득');
  });

  group('승리 요정', () {
    test('승패가 3경기 미만이면 경기 수를 센다', () {
      // 무승부는 분모에서 빠지므로 2승 1무는 2경기다.
      final b = badge(MhBadgeKind.winFairy,
          wins: 2, teamWins: 5, teamLosses: 15);
      expect(b.earned, isFalse);
      expect(b.subtitle, '응원 경기 2/3');
    });

    test('3경기를 채우고 팀보다 승률이 높으면 획득한다', () {
      // 직관 3전 3승(100%) vs 팀 10승 10패(50%)
      final b = badge(MhBadgeKind.winFairy,
          wins: 3, teamWins: 10, teamLosses: 10);
      expect(b.earned, isTrue);
      expect(b.subtitle, '내가 가면 승률 +50%p');
    });

    test('3경기를 채웠어도 승률이 낮으면 안 준다', () {
      // 직관 1승 2패(33%) vs 팀 18승 2패(90%)
      final b = badge(MhBadgeKind.winFairy,
          wins: 1, losses: 2, teamWins: 18, teamLosses: 2);
      expect(b.earned, isFalse);
      expect(b.subtitle, '직관 승률이 팀보다 높으면');
    });

    test('승률이 같으면 안 준다', () {
      final b = badge(MhBadgeKind.winFairy,
          wins: 2, losses: 2, teamWins: 10, teamLosses: 10);
      expect(b.earned, isFalse);
    });

    test('팀 승률도 무승부를 빼고 센다', () {
      // 팀이 5승 5무 5패일 때, 무승부를 분모에 넣으면 33%지만 빼면 50%다.
      // 내가 3전 2승 1패(67%)면 어느 쪽으로 세든 높지만, 격차가 달라진다.
      final b = badge(MhBadgeKind.winFairy,
          wins: 2, losses: 1, teamWins: 5, teamLosses: 5);
      expect(b.earned, isTrue);
      // 67% - 50% = 17%p. 무승부를 넣었다면 +33%p로 나왔을 것이다.
      expect(b.subtitle, '내가 가면 승률 +17%p');
    });

    test('기록이 없으면 0경기부터 시작한다', () {
      final b = badge(MhBadgeKind.winFairy, teamWins: 10, teamLosses: 10);
      expect(b.earned, isFalse);
      expect(b.subtitle, '응원 경기 0/3');
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

    test('날짜를 저장하기 전에 수료한 사용자는 날짜 없이 쓴다', () {
      final b = badge(MhBadgeKind.graduate, guideDone: 5);
      expect(b.earned, isTrue);
      expect(b.subtitle, '수료');
    });
  });
}
