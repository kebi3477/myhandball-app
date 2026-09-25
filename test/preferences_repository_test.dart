import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/domain/models/season.dart';
import 'package:myhandball/domain/models/team.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 설정이 **실제로 기기에 남는지** 본다.
///
/// 한동안 `PreferencesRepository`가 메모리에만 들고 있어서 앱을 끄면
/// 마이팀·테마·최근 검색이 전부 날아갔다. 그게 다시 생기지 않게 막는다.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// 저장 → 새 인스턴스로 다시 읽기. 앱을 껐다 켠 것과 같다.
  Future<PreferencesRepository> reopen(
    Future<void> Function(PreferencesRepository prefs) write,
  ) async {
    final first = PreferencesRepository();
    await first.load();
    await write(first);

    final second = PreferencesRepository();
    await second.load();
    return second;
  }

  test('최근 검색어가 남는다', () async {
    final prefs = await reopen((p) async {
      await p.addRecentSearch('SK호크스');
      await p.addRecentSearch('이요셉');
    });

    // 최신이 앞이다.
    expect(prefs.recentSearches, ['이요셉', 'SK호크스']);
  });

  test('같은 검색어를 다시 치면 맨 앞으로 올라간다', () async {
    final prefs = await reopen((p) async {
      await p.addRecentSearch('두산');
      await p.addRecentSearch('하남시청');
      await p.addRecentSearch('두산');
    });

    expect(prefs.recentSearches, ['두산', '하남시청']);
  });

  test('최근 검색어는 10개까지만 남는다', () async {
    final prefs = await reopen((p) async {
      for (var i = 0; i < 13; i++) {
        await p.addRecentSearch('검색$i');
      }
    });

    expect(prefs.recentSearches, hasLength(10));
    expect(prefs.recentSearches.first, '검색12');
  });

  test('삭제와 전체 삭제가 남는다', () async {
    final prefs = await reopen((p) async {
      await p.addRecentSearch('가');
      await p.addRecentSearch('나');
      await p.removeRecentSearch('가');
    });
    expect(prefs.recentSearches, ['나']);

    await prefs.clearRecentSearches();
    final again = PreferencesRepository();
    await again.load();
    expect(again.recentSearches, isEmpty);
  });

  test('마이팀 · 테마 · 부 · 시즌이 남는다', () async {
    final prefs = await reopen((p) async {
      await p.setMyTeam(const Team(
          name: 'SK호크스', teamNum: 132, gender: Gender.men, logoUrl: 'x'));
      await p.setThemeMode(ThemeMode.dark);
      await p.setPreferredGender(Gender.women);
      await p.setSeason(Season.ofYear(2024));
      await p.setNotificationsOn(value: false);
      await p.setGuideDoneCount(3);
    });

    expect(prefs.myTeam?.name, 'SK호크스');
    expect(prefs.myTeam?.teamNum, 132);
    // 기본이 라이트라 **다크**를 넣어야 저장을 실제로 검사한다.
    expect(prefs.themeMode, ThemeMode.dark);
    expect(prefs.preferredGender, Gender.women);
    expect(prefs.season, Season.ofYear(2024));
    expect(prefs.notificationsOn, isFalse);
    expect(prefs.guideDoneCount, 3);
  });

  test('처음 켜면 라이트로 시작한다', () async {
    // 시안은 다크지만 2026-09-25에 사용자가 라이트를 기본으로 정했다.
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesRepository();
    await prefs.load();
    expect(prefs.themeMode, ThemeMode.light);
  });

  test('저장된 다크는 그대로 유지된다', () async {
    // 이미 쓰던 사람의 선택을 기본값 변경이 덮어쓰면 안 된다.
    SharedPreferences.setMockInitialValues({'mh_theme': 'dark'});
    final prefs = PreferencesRepository();
    await prefs.load();
    expect(prefs.themeMode, ThemeMode.dark);
  });

  test('기기 ID는 한 번 만들어지고 바뀌지 않는다', () async {
    final first = PreferencesRepository();
    await first.load();
    final id = first.deviceId;

    // 서버가 받는 형식: 영문·숫자·하이픈 8~64자
    expect(RegExp(r'^[A-Za-z0-9-]{8,64}$').hasMatch(id), isTrue,
        reason: 'X-Device-Id 형식이 아니다: $id');

    final second = PreferencesRepository();
    await second.load();
    expect(second.deviceId, id);
  });

  test('저장소가 비어 있어도 기본값으로 뜬다', () async {
    final prefs = PreferencesRepository();
    await prefs.load();

    expect(prefs.myTeam, isNull);
    expect(prefs.recentSearches, isEmpty);
    expect(prefs.season, Season.current);
    expect(prefs.notificationsOn, isTrue);
  });
}
