import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 가이드 레슨 문구가 시안 원문(`spec/lessons.md`)과 같은지 본다.
///
/// 한때 디자인 파일이 256KiB에서 잘려 **5번 레슨을 씬 이름만 보고 지어냈다.**
/// 화면만 봐서는 틀린 줄 모르는 종류라, 원문이 손에 들어온 김에 고정해 둔다.
void main() {
  test('레슨 문구가 spec/lessons.md와 일치한다', () {
    final spec = File('spec/lessons.md').readAsStringSync();
    final dart =
        File('lib/domain/models/guide_lesson.dart').readAsStringSync();

    // Dart는 긴 문장을 인접 리터럴로 쪼개 둔다. 먼저 이어 붙인다.
    final joined = dart.replaceAll(RegExp(r"'\s*\n?\s*'"), '');
    String squash(String v) => v.replaceAll(RegExp(r'\s+'), '');
    final flat = squash(joined);

    final expected = <String>[
      for (final m in RegExp(r'^- (?:title|body|question|explain): (.+)$',
              multiLine: true)
          .allMatches(spec))
        m.group(1)!.trim(),
      for (final m
          in RegExp(r'^## \d+\. (.+?) \(`l\d`\)$', multiLine: true)
              .allMatches(spec))
        m.group(1)!,
      for (final m in RegExp(r'^  \d+\. (.+)$', multiLine: true).allMatches(spec))
        m.group(1)!,
    ];

    expect(expected, isNotEmpty, reason: 'spec/lessons.md를 못 읽었다');
    for (final line in expected) {
      expect(flat, contains(squash(line)), reason: '원문과 다르다: $line');
    }
  });
}
