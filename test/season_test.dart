import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/domain/models/season.dart';

/// H리그는 11월에 개막해 이듬해 봄에 끝난다. 시즌은 **11월에 넘어간다.**
///
/// 비시즌(5~10월)에는 직전에 끝난 시즌을 본다 — 개막 전에 빈 화면을
/// 보여주는 것보다 방금 끝난 시즌을 보여주는 쪽이 맞다.
void main() {
  group('오늘 날짜로 시즌을 고른다', () {
    void expectSeason(DateTime now, String year, String label) {
      final s = Season.at(now);
      expect(s.year, year, reason: '$now → $label 이어야 한다');
      expect(s.label, label);
    }

    test('개막(11월)에 새 시즌으로 넘어간다', () {
      expectSeason(DateTime(2025, 10, 31), '2024', '24-25');
      expectSeason(DateTime(2025, 11, 1), '2025', '25-26');
    });

    test('25년 후반 · 26년 초반은 25-26', () {
      expectSeason(DateTime(2025, 11, 15), '2025', '25-26');
      expectSeason(DateTime(2025, 12, 25), '2025', '25-26');
      expectSeason(DateTime(2026, 1, 3), '2025', '25-26');
      expectSeason(DateTime(2026, 4, 19), '2025', '25-26');
    });

    test('24년 후반 · 25년 초반은 24-25', () {
      expectSeason(DateTime(2024, 11, 2), '2024', '24-25');
      expectSeason(DateTime(2025, 2, 10), '2024', '24-25');
    });

    test('비시즌에는 직전 시즌을 본다', () {
      // 문서를 쓴 날. 25-26이 끝났고 26-27은 아직 일정이 없다.
      expectSeason(DateTime(2026, 9, 23), '2025', '25-26');
      expectSeason(DateTime(2026, 5, 1), '2025', '25-26');
    });
  });

  test('라벨은 두 자리로 맞춘다', () {
    expect(Season.ofYear(2009).label, '09-10');
    expect(Season.ofYear(2099).label, '99-00');
  });

  test('선택 목록은 현재 시즌부터 과거로 5개', () {
    final all = Season.all;
    expect(all, hasLength(5));
    expect(all.first, Season.current);
    for (var i = 1; i < all.length; i++) {
      expect(all[i].startYear, all[i - 1].startYear - 1);
    }
  });

  test('저장된 값이 깨져 있으면 현재 시즌으로 돌아온다', () {
    expect(Season.fromYear('2024'), Season.ofYear(2024));
    expect(Season.fromYear('알 수 없음'), Season.current);
  });
}
