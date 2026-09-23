import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/schedule_repository.dart';

/// 푸시 구독을 지금 설정과 맞춘다.
///
/// **마이팀이 바뀌거나 알림을 켜고 끌 때마다 불러야 한다.** 서버는 등록된
/// `teamNum`이 뛰는 경기에만 알림을 보내므로, 팀을 바꿨는데 다시 등록하지
/// 않으면 이전 팀 알림이 계속 온다.
///
/// 마이팀이 없거나 알림이 꺼져 있으면 구독을 해제한다.
Future<void> syncPushSubscription(WidgetRef ref) =>
    syncPushSubscriptionWith(ref.read);

/// `WidgetRef`가 없는 자리(뷰모델 등)에서 쓰는 형태.
Future<void> syncPushSubscriptionWith(T Function<T>(ProviderListenable<T>) read) async {
  final push = read(pushServiceProvider);
  if (push == null) return;

  final prefs = read(preferencesRepositoryProvider);
  final team = prefs.myTeam;

  await push.sync(
    notificationsOn: prefs.notificationsOn,
    teamNum: team?.teamNum,
    // 서버가 teamNum이 그 부에 있는지 확인한다. 마이팀의 부를 그대로 쓴다.
    gender: (team?.gender ?? prefs.preferredGender).code,
  );
}
