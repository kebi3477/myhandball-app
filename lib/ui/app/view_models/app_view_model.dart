import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../core/themes/tokens.dart';

/// 앱 전체에 걸리는 상태 — 테마와 온보딩 통과 여부.
class AppState {
  const AppState({required this.themeMode, required this.onboarded});

  final ThemeMode themeMode;

  /// 시안 `inApp`.
  final bool onboarded;

  AppState copyWith({ThemeMode? themeMode, bool? onboarded}) => AppState(
        themeMode: themeMode ?? this.themeMode,
        onboarded: onboarded ?? this.onboarded,
      );

  MhPalette get palette =>
      themeMode == ThemeMode.light ? MhPalette.light : MhPalette.dark;
}

class AppViewModel extends Notifier<AppState> {
  PreferencesRepository get _prefs => ref.read(preferencesRepositoryProvider);

  @override
  AppState build() => AppState(
        themeMode: _prefs.themeMode,
        onboarded: _prefs.onboarded,
      );

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setThemeMode(mode);
  }

  /// 시안 MY 탭의 테마 토글.
  Future<void> toggleTheme() => setThemeMode(
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );

  /// 온보딩 마지막 스텝의 "시작하기".
  Future<void> completeOnboarding() async {
    state = state.copyWith(onboarded: true);
    await _prefs.setOnboarded(value: true);
  }

  /// 시안 `restartOnboarding` — MY 탭에서 온보딩 다시 보기.
  Future<void> restartOnboarding() async {
    state = state.copyWith(onboarded: false);
    await _prefs.setOnboarded(value: false);
  }
}

final appViewModelProvider =
    NotifierProvider<AppViewModel, AppState>(AppViewModel.new);

/// 화면이 색을 꺼내 쓰는 통로.
final paletteProvider =
    Provider<MhPalette>((ref) => ref.watch(appViewModelProvider).palette);
