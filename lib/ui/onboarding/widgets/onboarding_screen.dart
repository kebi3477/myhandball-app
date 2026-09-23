import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../domain/models/gender.dart';
import '../../../domain/models/team.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/nav_icons.dart';
import '../view_models/onboarding_view_model.dart';
import 'interest_card.dart';
import 'team_picker_row.dart';

/// 온보딩 5스텝.
///
/// 시안은 `width:500%` 컨테이너를 `transform: translateX(-N%)`로 밀고
/// `transition: transform .5s ease-in-out`을 건다. 여기서는 PageView를
/// ViewModel의 `step`에 맞춰 애니메이션한다.
///
/// 이 화면은 시안에서 테마와 무관하게 항상 다크 리터럴(#111/#222/#333)을 쓴다.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _slide = Duration(milliseconds: 500);

  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(onboardingViewModelProvider.notifier);
    final state = ref.watch(onboardingViewModelProvider);

    // step이 바뀌면 PageView를 따라가게 한다.
    ref.listen(onboardingViewModelProvider.select((s) => s.step), (_, step) {
      if (!_pageController.hasClients) return;
      _pageController.animateToPage(
        step,
        duration: _slide,
        curve: Curves.easeInOut,
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            if (state.showProgress) _ProgressBar(state: state, onBack: vm.back),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const _IntroStep(),
                  _InterestStep(state: state, onSelect: vm.selectInterest),
                  _ProfileStep(
                    state: state,
                    onGender: vm.selectGender,
                    onAge: vm.selectAgeGroup,
                  ),
                  _TeamStep(
                    state: state,
                    onTeamGender: vm.selectTeamGender,
                    onTeam: vm.selectTeam,
                  ),
                  const _WelcomeStep(),
                ],
              ),
            ),
            _PrimaryButton(state: state, onTap: vm.submit),
          ],
        ),
      ),
    );
  }
}

/// height 64, 뒤로가기 24px + 트랙 5px/#333, 채움 #0068FF
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.state, required this.onBack});

  final OnboardingState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            MhTap(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CustomPaint(
                    painter: MhChevronLeftPainter(Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 5,
                  backgroundColor: MhColors.onboardTrack,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(MhColors.brand),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/design/logo-symbol.svg',
              width: 46, height: 60),
          const SizedBox(height: 8),
          SvgPicture.asset('assets/design/logo-wordmark.svg',
              width: 120, height: 27),
          const SizedBox(height: MhSpacing.md),
          Text(
            '마이팀 경기,\n이제 놓치지 않기',
            textAlign: TextAlign.center,
            style: MhText.onboardTitle(Colors.white),
          ),
        ],
      ),
    );
  }
}

class _InterestStep extends StatelessWidget {
  const _InterestStep({required this.state, required this.onSelect});

  final OnboardingState state;
  final ValueChanged<Interest> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = Interest.values;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '스포츠를 볼 때 어떤 점이\n가장 재밌나요?',
            style: MhText.onboardQuestion(Colors.white),
          ),
          const SizedBox(height: MhSpacing.lg),
          // 시안: 172px 두 줄, gap 8
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: MhSpacing.xs),
            SizedBox(
              height: 172,
              child: Row(
                children: [
                  for (var col = 0; col < 2; col++) ...[
                    if (col > 0) const SizedBox(width: MhSpacing.xs),
                    Expanded(
                      child: InterestCard(
                        interest: items[row * 2 + col],
                        selected: state.interest == items[row * 2 + col],
                        onTap: () => onSelect(items[row * 2 + col]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.state,
    required this.onGender,
    required this.onAge,
  });

  final OnboardingState state;
  final ValueChanged<Gender> onGender;
  final ValueChanged<String> onAge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '성별/연령대를\n알려주세요!',
            style: MhText.custom(
              size: 24,
              weight: FontWeight.w700,
              color: Colors.white,
              height: 28 / 24,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  label: '남성',
                  asset: 'assets/design/icon-male.svg',
                  selected: state.gender == Gender.men,
                  onTap: () => onGender(Gender.men),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _GenderCard(
                  label: '여성',
                  asset: 'assets/design/icon-female.svg',
                  selected: state.gender == Gender.women,
                  onTap: () => onGender(Gender.women),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 시안: 3열 그리드, gap 12
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              for (final age in OnboardingState.ageGroups)
                _AgeChip(
                  label: age,
                  selected: state.ageGroup == age,
                  onTap: () => onAge(age),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : const Color(0xFF808080);
    return MhTap(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: selected ? MhColors.brand : Colors.transparent,
          border: Border.all(color: MhColors.onboardBorder),
          borderRadius: BorderRadius.circular(MhRadius.button),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              asset,
              width: 21,
              height: 39,
              colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
            ),
            const SizedBox(height: MhSpacing.xs),
            Text(label,
                style:
                    MhText.custom(size: 14, weight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}

class _AgeChip extends StatelessWidget {
  const _AgeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MhTap(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? MhColors.brand : Colors.transparent,
          border: Border.all(
            color: selected ? MhColors.brand : MhColors.onboardBorder,
          ),
          borderRadius: BorderRadius.circular(MhRadius.button),
        ),
        child: Text(
          label,
          style: MhText.custom(
            size: 12,
            weight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF808080),
          ),
        ),
      ),
    );
  }
}

class _TeamStep extends StatelessWidget {
  const _TeamStep({
    required this.state,
    required this.onTeamGender,
    required this.onTeam,
  });

  final OnboardingState state;
  final ValueChanged<Gender> onTeamGender;
  final ValueChanged<Team> onTeam;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: MhSpacing.md),
          Text(
            '본인이 좋아하는 핸드볼\n팀을 골라주세요',
            style: MhText.onboardQuestion(Colors.white),
          ),
          const SizedBox(height: MhSpacing.sm),
          // 좌우가 붙은 세그먼트 (10px 0 0 10px / 0 10px 10px 0)
          Row(
            children: [
              for (final g in Gender.values)
                _TeamGenderTab(
                  label: g.teamLabel,
                  selected: state.teamGender == g,
                  left: g == Gender.men,
                  onTap: () => onTeamGender(g),
                ),
            ],
          ),
          const SizedBox(height: MhSpacing.sm),
          Expanded(
            child: state.loadingTeams
                ? const Center(
                    child: CircularProgressIndicator(color: MhColors.brand),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: MhSpacing.sm),
                    itemCount: state.teams.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MhSpacing.xs),
                    itemBuilder: (_, i) => TeamPickerRow(
                      team: state.teams[i],
                      selected: state.team == state.teams[i],
                      onTap: () => onTeam(state.teams[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TeamGenderTab extends StatelessWidget {
  const _TeamGenderTab({
    required this.label,
    required this.selected,
    required this.left,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool left;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = left
        ? const BorderRadius.horizontal(left: Radius.circular(10))
        : const BorderRadius.horizontal(right: Radius.circular(10));
    return MhTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? MhColors.brand : MhColors.onboardCard,
          borderRadius: radius,
        ),
        child: Text(
          label,
          style: MhText.custom(
            size: 14,
            weight: FontWeight.w800,
            color: selected ? Colors.white : const Color(0xFF808080),
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('환영합니다!',
            style: MhText.custom(
                size: 24, weight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 30),
        Text(
          '이제부터 여러분의 최애팀을\n응원해보세요.',
          textAlign: TextAlign.center,
          style: MhText.custom(
            size: 16,
            weight: FontWeight.w600,
            color: MhColors.brand,
            height: 24 / 16,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.state, required this.onTap});

  final OnboardingState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.md, MhSpacing.sm, MhSpacing.md, MhSpacing.md),
      child: Opacity(
        opacity: state.canAdvance ? 1 : 0.4,
        child: MhTap(
        haptic: MhHaptic.impact,
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MhColors.brand,
              borderRadius: BorderRadius.circular(MhRadius.button),
            ),
            child: Text(
              state.primaryLabel,
              style: MhText.custom(
                  size: 15, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
