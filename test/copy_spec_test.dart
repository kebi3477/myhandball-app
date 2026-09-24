import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 시안이 정한 문구(`spec/copy.md`)가 앱에 그대로 있는지 본다.
///
/// 디자인 파일이 256KiB에서 잘려 이 문구들을 도구로 읽을 수 없었고, 한때
/// 여러 개를 지어냈다가 전부 고쳤다. **화면만 봐서는 틀린 줄 모르는**
/// 종류라 여기서 고정한다.
void main() {
  /// 아직 그 기능이 없어서 문구도 없는 것들.
  ///
  /// **목록을 비워 두면 "다 맞췄다"와 "검사를 안 한다"가 구분되지 않는다.**
  /// 기능이 생기면 여기서 지운다.
  const pending = <String>[
    // 쓰기 실패 문구는 화면마다 자체 문구를 쓴다 (경기 상세·팀 상세).
    '오프라인 상태라',
    '일시적인 오류로',
  ];

  /// 인접한 문자열 리터럴을 이어 붙이고 공백을 지운다.
  ///
  /// Dart는 긴 문장을 `'앞 '\n    '뒤'`로 쪼개 두므로 그대로 찾으면 못 찾는다.
  String squash(String code) => code
      .replaceAll(RegExp(r"'\s*'"), '')
      .replaceAll(RegExp(r'\s+'), '');

  test('시안 토스트 문구가 앱에 있다', () {
    final spec = File('spec/copy.md').readAsStringSync();

    final code = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    final flat = squash(code);

    // 토스트 표의 오른쪽 칸(문구)만 뽑는다. 헤더와 구분선은 걸러낸다.
    final rows = RegExp(r'^\| [^|]+ \| ([^|]+) \|\s*$', multiLine: true)
        .allMatches(spec)
        .map((m) => m.group(1)!.trim())
        .where((v) => v.isNotEmpty && v != '문구' && !v.startsWith('---'))
        .toList();

    // 표를 못 읽으면 검사가 통째로 헛돈다.
    expect(rows.length, greaterThanOrEqualTo(8),
        reason: 'spec/copy.md의 토스트 표를 못 읽었다');

    final missing = <String>[];
    for (final line in rows) {
      if (pending.any(line.contains)) continue;

      // `${...}`가 든 문구는 앞뒤 고정 부분만 본다.
      final parts = line
          .split(RegExp(r'\$\{[^}]*\}'))
          .map(squash)
          .where((p) => p.length >= 4)
          .toList();
      if (parts.isEmpty) continue;
      if (!parts.every(flat.contains)) missing.add(line);
    }

    expect(missing, isEmpty, reason: '시안 문구가 앱에 없다');
  });

  test('에러 화면 문구가 앱에 있다', () {
    final spec = File('spec/copy.md').readAsStringSync();
    final code =
        File('lib/ui/core/ui/mh_error_view.dart').readAsStringSync();
    final flat = squash(code);

    // `| 오프라인 | 제목 | 본문 | path |` 4칸 표.
    final rows = RegExp(r'^\| (?:오프라인|서버 오류) \| ([^|]+) \| ([^|]+) \|',
            multiLine: true)
        .allMatches(spec)
        .toList();
    expect(rows, hasLength(2), reason: 'spec/copy.md의 에러 표를 못 읽었다');

    for (final row in rows) {
      final title = squash(row.group(1)!);
      // 본문은 `\n`이 줄바꿈이라는 표기라 그 자리로 끊어 각 조각을 본다.
      final body = row.group(2)!.split(r'\n').map(squash);
      expect(flat, contains(title), reason: '제목이 다르다: $title');
      for (final piece in body) {
        if (piece.length < 4) continue;
        expect(flat, contains(piece), reason: '본문이 다르다: $piece');
      }
    }
  });
}
