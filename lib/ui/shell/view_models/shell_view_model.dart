import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 시안 `appScreen` — home / schedule / stat / my
enum ShellTab {
  home('홈'),
  schedule('일정'),
  stat('분석'),
  my('MY');

  const ShellTab(this.label);

  final String label;
}

class ShellViewModel extends Notifier<ShellTab> {
  @override
  ShellTab build() => ShellTab.home;

  void select(ShellTab tab) => state = tab;
}

final shellViewModelProvider =
    NotifierProvider<ShellViewModel, ShellTab>(ShellViewModel.new);
