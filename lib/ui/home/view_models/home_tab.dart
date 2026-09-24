import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 홈 안의 탭. 시안 `homeTabs`.
///
/// 2026-09-24 시안 개편에서 들어왔다. 하단 4탭(`ShellTab`)과 다른 층이다 —
/// 이건 홈 화면 **안**에서만 바뀐다.
enum HomeTab {
  home('홈'),
  prediction('승부예측'),
  attendance('직관');

  const HomeTab(this.label);

  final String label;
}

class HomeTabViewModel extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.home;

  void select(HomeTab tab) => state = tab;
}

final homeTabProvider =
    NotifierProvider<HomeTabViewModel, HomeTab>(HomeTabViewModel.new);
