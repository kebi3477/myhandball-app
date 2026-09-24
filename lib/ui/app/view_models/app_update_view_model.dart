import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../../data/services/app_update_service.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final service = AppUpdateService();
  ref.onDispose(service.close);
  return service;
});

/// 스토어에 새 버전이 있으면 그 정보를, 아니면 `null`.
///
/// **켤 때 한 번만 본다.** `FutureProvider`라 같은 세션에서는 결과를
/// 다시 받아오지 않는다. 안내 하나 때문에 앱을 쓰는 내내 스토어를 두드릴
/// 이유가 없다.
final appUpdateProvider = FutureProvider<AppUpdate?>((ref) async {
  final latest = await ref.read(appUpdateServiceProvider).fetchLatest();
  if (latest == null) return null;

  final isNewer = AppUpdateService.isNewer(
    current: AppConfig.appVersion,
    latest: latest.version,
  );
  return isNewer ? latest : null;
});

/// 안내를 지금 띄워야 하는지.
///
/// "나중에"를 고른 버전은 다시 묻지 않는다. 그래도 설정 화면에는 계속
/// "업데이트 있음"으로 남는다 — 미룬 것이지 없어진 게 아니다.
final shouldPromptUpdateProvider = Provider.family<bool, String>(
  (ref, version) =>
      ref.watch(preferencesRepositoryProvider).skippedUpdateVersion != version,
);
