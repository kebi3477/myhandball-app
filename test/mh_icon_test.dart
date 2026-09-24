import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/ui/core/ui/mh_icons.dart';

/// 아이콘이 부모 크기를 따라가면 안 된다.
///
/// `SizedBox(width: 48, height: 36, child: MhIcon(size: 18))`처럼 부모가
/// 크기를 꽉 조이면 `SvgPicture`는 자기 width/height를 버리고 그 크기로
/// 늘어난다 — 18로 부른 아이콘이 36으로 그려져 버튼 밖으로 삐져나왔다.
/// Material의 `Icon`은 글리프라 이 문제가 없어서, 시안 아이콘으로 갈아끼운
/// 뒤에야 드러났다.
void main() {
  Size sizeOfIcon(WidgetTester tester) =>
      tester.getSize(find.byType(SvgPicture));

  testWidgets('부모가 크기를 조여도 size를 지킨다', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 48,
            height: 36,
            child: MhIcon(MhIcons.chevLeft, size: 18, color: Colors.white),
          ),
        ),
      ),
    );

    expect(sizeOfIcon(tester), const Size(18, 18));
  });

  testWidgets('제약이 없어도 size를 지킨다', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: MhIcon(MhIcons.heartFilled, size: 30, color: Colors.white),
        ),
      ),
    );

    expect(sizeOfIcon(tester), const Size(30, 30));
  });

  testWidgets('메달도 부모 크기를 따라가지 않는다', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.square(dimension: 80, child: MhMedal(size: 40)),
        ),
      ),
    );

    // 시안 메달은 60x72 비율이다.
    expect(sizeOfIcon(tester), const Size(40, 48));
  });
}
