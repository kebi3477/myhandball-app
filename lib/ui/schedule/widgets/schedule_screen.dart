import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/ui/coming_soon.dart';

/// 일정 탭 — 아직 시안 이식 전.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoon(
      palette: context.mh,
      title: '일정',
      description: '리스트 / 달력 전환, 월 이동, 마이팀 필터',
    );
  }
}
