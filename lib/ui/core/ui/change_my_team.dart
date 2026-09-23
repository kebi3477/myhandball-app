import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../domain/models/team.dart';
import '../../home/view_models/home_view_model.dart';
import '../../my/view_models/my_view_model.dart';
import '../../schedule/view_models/schedule_view_model.dart';
import 'push_sync.dart';
import 'team_picker_sheet.dart';

/// 마이팀 변경. MY 탭과 일정 탭(MY팀 달력)이 같이 쓴다.
///
/// 마이팀이 바뀌면 홈·일정·MY가 전부 달라지므로 **세 화면을 모두 무효화**한다.
/// 한 곳만 갱신하면 다른 탭이 이전 팀을 그대로 보여준다.
Future<void> changeMyTeam(
  BuildContext context,
  WidgetRef ref, {
  Team? current,
}) async {
  final prefs = ref.read(preferencesRepositoryProvider);
  final picked = await showTeamPickerSheet(
    context,
    initialGender: prefs.preferredGender,
    selected: current ?? prefs.myTeam,
  );
  if (picked == null) return;

  await prefs.setMyTeam(picked);
  await prefs.setPreferredGender(picked.gender);

  ref.invalidate(myViewModelProvider);
  ref.invalidate(homeViewModelProvider);
  ref.invalidate(scheduleViewModelProvider);

  // 서버는 등록된 teamNum이 뛰는 경기에만 알림을 보낸다. 다시 등록하지
  // 않으면 이전 팀 알림이 계속 온다.
  await syncPushSubscription(ref);
}
