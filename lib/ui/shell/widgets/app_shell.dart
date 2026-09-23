import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/nav_icons.dart';
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
    if (!AppConfig.openGuide) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GuideScreen.open(context);
    });
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
