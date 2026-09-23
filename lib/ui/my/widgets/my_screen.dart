import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/ui/coming_soon.dart';

/// MY 탭 — 아직 시안 이식 전.
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoon(
      palette: context.mh,
      title: 'MY',
      description: '마이팀 카드, 직관 기록, 설정',
    );
  }
}
