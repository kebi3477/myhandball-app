import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/ui/coming_soon.dart';

/// 분석 탭 — 아직 시안 이식 전.
class StatScreen extends StatelessWidget {
  const StatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoon(
      palette: context.mh,
      title: '분석',
      description: '순위 · 기록 · 팀 · 선수 4개 서브탭',
    );
  }
}
