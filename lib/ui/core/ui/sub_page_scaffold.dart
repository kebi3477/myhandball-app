import 'package:flutter/material.dart';

import '../themes/theme.dart';
import 'mh_icons.dart';
import 'mh_tap.dart';

/// 전체화면으로 덮는 하위 페이지의 공통 골격.
///
/// 시안은 이런 화면을 `position:absolute; inset:0`으로 덮고 56px 헤더에
/// 뒤로가기 화살표와 제목을 둔다.
class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;

  /// 헤더 우측에 붙는 선택적 위젯.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    MhTap(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: MhIcon(MhIcons.chevLeft,
                            size: 18, color: c.text),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MhText.custom(
                            size: 18, weight: FontWeight.w700, color: c.text),
                      ),
                    ),
                    ?action,
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
