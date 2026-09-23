import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/ui/core/ui/mh_tap.dart';

/// 앱의 모든 탭은 [MhTap]을 거쳐 진동을 낸다.
///
/// `GestureDetector`를 직접 쓰면 그 화면만 조용히 진동이 빠지는데, 눈으로는
/// 알 수 없다. 그래서 테스트로 막는다.
void main() {
  test('lib/ui 안에서 GestureDetector를 직접 쓰지 않는다', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // MhTap 자신은 GestureDetector를 감싸는 유일한 자리다.
      if (entity.path.endsWith('ui/core/ui/mh_tap.dart')) continue;
      if (entity.readAsStringSync().contains('GestureDetector(')) {
        offenders.add(entity.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'MhTap을 대신 쓰세요 — 탭 진동이 빠집니다:\n${offenders.join('\n')}',
    );
  });

  testWidgets('탭하면 햅틱이 나간다', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add('${call.arguments}');
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      home: MhTap(
        onTap: () => tapped++,
        child: const ColoredBox(
          color: Color(0xFF000000),
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    ));

    await tester.tap(find.byType(MhTap));
    await tester.pump();

    expect(tapped, 1);
    expect(calls, hasLength(1),
        reason: '탭 한 번에 햅틱 한 번이어야 한다');
  });

  testWidgets('haptic: none이면 진동이 없다', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') calls.add('x');
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(MaterialApp(
      home: MhTap(
        haptic: MhHaptic.none,
        onTap: () {},
        child: const ColoredBox(
          color: Color(0xFF000000),
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    ));

    await tester.tap(find.byType(MhTap));
    await tester.pump();

    expect(calls, isEmpty);
  });

  testWidgets('onTap이 null이면 진동도 안 난다', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') calls.add('x');
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(const MaterialApp(
      home: MhTap(
        child: ColoredBox(
          color: Color(0xFF000000),
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    ));

    await tester.tap(find.byType(MhTap), warnIfMissed: false);
    await tester.pump();

    expect(calls, isEmpty);
  });
}
