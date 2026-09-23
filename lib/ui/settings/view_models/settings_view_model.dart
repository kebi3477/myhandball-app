import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../domain/models/season.dart';
import '../../app/view_models/app_view_model.dart';
import '../../core/ui/push_sync.dart';

class SettingsState {
  const SettingsState({
    required this.darkMode,
    required this.season,
    required this.notificationsOn,
  });

  final bool darkMode;
  final Season season;
  final bool notificationsOn;

  SettingsState copyWith({
    bool? darkMode,
    Season? season,
    bool? notificationsOn,
  }) =>
      SettingsState(
        darkMode: darkMode ?? this.darkMode,
        season: season ?? this.season,
        notificationsOn: notificationsOn ?? this.notificationsOn,
      );
}

class SettingsViewModel extends Notifier<SettingsState> {
  PreferencesRepository get _prefs => ref.read(preferencesRepositoryProvider);

  @override
  SettingsState build() {
    // 테마는 앱 전역 상태라 AppViewModel을 따라간다.
    final themeMode = ref.watch(appViewModelProvider).themeMode;
    return SettingsState(
      darkMode: themeMode != ThemeMode.light,
      season: _prefs.season,
      notificationsOn: _prefs.notificationsOn,
    );
  }

  Future<void> toggleDarkMode() =>
      ref.read(appViewModelProvider.notifier).toggleTheme();

  Future<void> setSeason(Season season) async {
    state = state.copyWith(season: season);
    await _prefs.setSeason(season);
  }

  Future<void> toggleNotifications() async {
    final next = !state.notificationsOn;
    state = state.copyWith(notificationsOn: next);
    await _prefs.setNotificationsOn(value: next);

    // 껐으면 서버에서 토큰을 지운다. 안 지우면 알림이 계속 간다.
    await syncPushSubscriptionWith(ref.read);
  }

}

final settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, SettingsState>(SettingsViewModel.new);
