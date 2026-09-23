import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/team.dart';
import '../../app/view_models/app_view_model.dart';

/// 시안 온보딩 1스텝의 관심사 선택지.
enum Interest {
  flow('경기흐름', 'assets/figassets/icon-flow.svg', 66, 62),
  cheer('팀응원', 'assets/figassets/icon-cheer.svg', 56, 63),
  highlight('하이라이트', 'assets/figassets/onboard-highlight.png', 72, 54),
  rank('기록/순위', 'assets/figassets/onboard-record.png', 57, 50);

  const Interest(this.label, this.asset, this.assetWidth, this.assetHeight);

  final String label;
  final String asset;
  final double assetWidth;
  final double assetHeight;
}

class OnboardingState {
  const OnboardingState({
    this.step = 0,
    this.interest,
    this.gender,
    this.ageGroup,
    this.teamGender = Gender.men,
    this.team,
    this.teams = const [],
    this.loadingTeams = false,
  });

  static const stepCount = 5;
  static const ageGroups = ['10대', '20대', '30대', '40대', '50대', '60대+'];

  final int step;
  final Interest? interest;

  /// 사용자 본인의 성별 (팀 성별과 다르다).
  final Gender? gender;
  final String? ageGroup;

  /// 시안 `teamGender` — 어느 부의 팀을 고를지.
  final Gender teamGender;
  final Team? team;
  final List<Team> teams;
  final bool loadingTeams;

  /// 시안 `showProgress` — 첫 화면(로고)에는 진행바가 없다.
  bool get showProgress => step > 0;

  bool get isLastStep => step == stepCount - 1;

  String get primaryLabel => isLastStep ? '시작하기' : '다음';

  double get progress => (step + 1) / stepCount;

  /// 시안 `primaryOpacity` — 필수 선택이 비면 버튼이 흐려진다.
  bool get canAdvance => switch (step) {
        1 => interest != null,
        2 => gender != null && ageGroup != null,
        3 => team != null,
        _ => true,
      };

  OnboardingState copyWith({
    int? step,
    Interest? interest,
    Gender? gender,
    String? ageGroup,
    Gender? teamGender,
    Team? team,
    bool clearTeam = false,
    List<Team>? teams,
    bool? loadingTeams,
  }) =>
      OnboardingState(
        step: step ?? this.step,
        interest: interest ?? this.interest,
        gender: gender ?? this.gender,
        ageGroup: ageGroup ?? this.ageGroup,
        teamGender: teamGender ?? this.teamGender,
        team: clearTeam ? null : (team ?? this.team),
        teams: teams ?? this.teams,
        loadingTeams: loadingTeams ?? this.loadingTeams,
      );
}

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    Future.microtask(_loadTeams);
    return const OnboardingState();
  }

  Future<void> _loadTeams() async {
    state = state.copyWith(loadingTeams: true);
    final teams = await ref
        .read(teamRepositoryProvider)
        .getTeams(state.teamGender);
    state = state.copyWith(teams: teams, loadingTeams: false);
  }

  void goTo(int step) {
    if (step < 0 || step >= OnboardingState.stepCount) return;
    state = state.copyWith(step: step);
  }

  void back() => goTo(state.step - 1);

  void selectInterest(Interest value) =>
      state = state.copyWith(interest: value);

  void selectGender(Gender value) => state = state.copyWith(gender: value);

  void selectAgeGroup(String value) => state = state.copyWith(ageGroup: value);

  void selectTeamGender(Gender value) {
    if (state.teamGender == value) return;
    state = state.copyWith(teamGender: value, clearTeam: true);
    _loadTeams();
  }

  void selectTeam(Team value) => state = state.copyWith(team: value);

  /// 시안 `primaryAction` — 마지막 스텝에서만 앱으로 진입한다.
  Future<void> submit() async {
    if (!state.canAdvance) return;
    if (!state.isLastStep) {
      goTo(state.step + 1);
      return;
    }
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setMyTeam(state.team);
    await prefs.setPreferredGender(state.teamGender);
    await ref.read(appViewModelProvider.notifier).completeOnboarding();
  }
}

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
  OnboardingViewModel.new,
);
