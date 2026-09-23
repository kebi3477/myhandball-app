import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myhandball/ui/onboarding/view_models/onboarding_view_model.dart';

/// 시안 에셋이 번들에 실제로 들어갔는지 확인한다.
///
/// 디자인 프로젝트에서 내보내는 걸 잊으면 온보딩 카드가 빈 채로 나가는데,
/// 화면만 봐서는 플레이스홀더와 구분이 안 돼 놓치기 쉽다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('온보딩 관심사 아이콘 4개가 모두 번들에 있다', () async {
    for (final interest in Interest.values) {
      final data = await rootBundle.load(interest.asset);
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: '${interest.name}: ${interest.asset} 가 비어 있다',
      );
    }
  });

  test('시안에서 추출한 SVG가 모두 번들에 있다', () async {
    const extracted = [
      'assets/design/logo-wordmark.svg',
      'assets/design/logo-symbol.svg',
      'assets/design/guide-mascot.svg',
      'assets/design/icon-male.svg',
      'assets/design/icon-female.svg',
    ];
    for (final path in extracted) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: '$path 가 비어 있다');
    }
  });
}
