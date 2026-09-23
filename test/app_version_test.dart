import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/config/app_config.dart';

/// 설정 화면이 보여주는 버전이 pubspec과 어긋나지 않게 잡는다.
void main() {
  test('AppConfig 버전이 pubspec.yaml과 같다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*(\S+)\+(\S+)\s*$', multiLine: true)
            .firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml에서 version을 못 찾았다');
    expect(AppConfig.appVersion, match!.group(1));
    expect(AppConfig.buildNumber, match.group(2));
  });
}
