import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/services/push_service.dart';
import '../../../domain/models/schedule_day.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_icons.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/nav_icons.dart';
import '../../core/ui/push_sync.dart';
import '../../game_detail/widgets/game_detail_screen.dart';
import '../../app/view_models/app_update_view_model.dart';
import '../../app/widgets/update_prompt.dart';
import '../../guide/widgets/guide_screen.dart';
import '../../home/widgets/home_screen.dart';
import '../../my/widgets/my_screen.dart';
import '../../schedule/widgets/schedule_screen.dart';
import '../../stat/widgets/stat_screen.dart';
import '../view_models/shell_view_model.dart';

/// 시안 MAIN APP 셸.
///
/// 시안에는 375x812 목업 프레임과 가짜 상태바(`9:41`), 다이나믹 아일랜드가
/// 그려져 있는데 그건 시안용 장식이라 옮기지 않는다. 실제 기기에서는
/// SafeArea가 그 역할을 한다.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

const _icons = {
  ShellTab.home: MhNavIcon.home,
  ShellTab.schedule: MhNavIcon.schedule,
  ShellTab.stat: MhNavIcon.stat,
  ShellTab.my: MhNavIcon.my,
};

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppConfig.openGuide) GuideScreen.open(context);
      _startPush();
      _checkUpdate();
    });
  }

  /// 스토어에 새 버전이 있으면 안내를 띄운다.
  ///
  /// 온보딩을 마친 뒤(=셸에 들어온 뒤)에 한다. 앱을 처음 켠 사람에게
  /// 업데이트부터 들이밀 이유가 없다. 확인에 실패하면 조용히 넘어간다.
  Future<void> _checkUpdate() async {
    final update = await ref.read(appUpdateProvider.future);
    if (update == null || !mounted) return;
    if (!ref.read(shouldPromptUpdateProvider(update.version))) return;
    if (!context.mounted) return;
    await showUpdatePrompt(context, ref, update);
  }

  /// 푸시를 붙이고 구독을 지금 설정과 맞춘다.
  ///
  /// 온보딩을 마친 뒤(=셸에 들어온 뒤)에 한다. 온보딩 도중에 권한을 물으면
  /// 무엇에 대한 알림인지 모르는 상태에서 묻는 셈이다.
  /// dispose에서 `ref`를 못 쓰므로 여기서 잡아 둔다.
  PushService? _push;

  Future<void> _startPush() async {
    final push = ref.read(pushServiceProvider);
    if (push == null) return;
    _push = push;

    await push.initialize();
    if (!mounted) return;
    await syncPushSubscription(ref);

    // 알림을 눌러 들어온 경우 그 경기를 연다.
    push.tappedMatchSeq.addListener(_openTappedGame);
    if (push.tappedMatchSeq.value != null) _openTappedGame();
  }

  Future<void> _openTappedGame() async {
    final seq = _push?.tappedMatchSeq.value;
    if (seq == null) return;
    _push!.tappedMatchSeq.value = null;

    final prefs = ref.read(preferencesRepositoryProvider);
    final gender = prefs.myTeam?.gender ?? prefs.preferredGender;
    final List<ScheduleDay> days;
    try {
      days = await ref
          .read(scheduleRepositoryProvider)
          .getSeasonSchedule(gender, prefs.season.year);
    } on Exception {
      return;
    }

    for (final day in days) {
      for (final game in day.games) {
        if (game.matchSeq == seq) {
          if (mounted) GameDetailScreen.open(context, game);
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    // Riverpod은 dispose 뒤 `ref` 사용을 막는다. initState에서 잡아 둔
    // 참조를 쓴다.
    _push?.tappedMatchSeq.removeListener(_openTappedGame);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final tab = ref.watch(shellViewModelProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _OfflineBar(),
            Expanded(
              child: IndexedStack(
                index: tab.index,
                children: const [
                  HomeScreen(),
                  ScheduleScreen(),
                  StatScreen(),
                  MyScreen(),
                ],
              ),
            ),
            _NavBar(current: tab, palette: c),
          ],
        ),
      ),
    );
  }
}

/// 시안 `isOffline` — 서버에 닿지 못할 때 화면 맨 위에 붙는 회색 띠.
///
/// 목업으로 돌 때는 붙일 클라이언트가 없어 아무것도 그리지 않는다.
class _OfflineBar extends ConsumerWidget {
  const _OfflineBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.useMock || AppConfig.apiBaseUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: ref.watch(apiClientProvider).offline,
      builder: (context, offline, _) {
        if (!offline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: MhSpacing.sm, vertical: 8),
          color: MhColors.offlineBar,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MhIcon(MhIcons.wifiOff, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text('인터넷 연결이 끊겼어요',
                  style: MhText.custom(
                      size: 12, weight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        );
      },
    );
  }
}

class _NavBar extends ConsumerWidget {
  const _NavBar({required this.current, required this.palette});

  final ShellTab current;
  final MhPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      height: MhSizes.navBar + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      color: palette.bg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final tab in ShellTab.values) ...[
            if (tab != ShellTab.values.first) const SizedBox(width: MhSpacing.xl),
            _NavItem(
              tab: tab,
              icon: _icons[tab]!,
              active: tab == current,
              palette: palette,
              onTap: () => ref.read(shellViewModelProvider.notifier).select(tab),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.icon,
    required this.active,
    required this.palette,
    required this.onTap,
  });

  final ShellTab tab;
  final MhNavIcon icon;
  final bool active;
  final MhPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 시안: 선택 시 브랜드 블루, 아니면 흐린 회색.
    final color = active ? MhColors.brand : palette.textFaint;
    return MhTap(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: MhSizes.navItem,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CustomPaint(
                  painter: MhNavIconPainter(
                    icon: icon,
                    color: color,
                    bg: palette.bg,
                  ),
                ),
              ),
            ),
            Text(
              tab.label,
              style: MhText.custom(
                size: 14,
                weight: FontWeight.w500,
                color: color,
                height: 24 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
