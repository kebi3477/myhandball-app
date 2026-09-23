import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../domain/models/season.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/external_actions.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/sub_page_scaffold.dart';
import '../view_models/settings_view_model.dart';

/// 설정 화면. 시안 SETTINGS PAGE.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final vm = ref.read(settingsViewModelProvider.notifier);

    return SubPageScaffold(
      title: '설정',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, MhSpacing.xs, 20, MhSpacing.xl),
        children: [
          _Group(children: [
            _SwitchRow(
              label: '다크 모드',
              value: state.darkMode,
              onChanged: (_) => vm.toggleDarkMode(),
            ),
            _Divider(),
            _LinkRow(
              label: '조회 시즌',
              trailing: '${state.season.label} >',
              onTap: () async {
                final picked = await showSeasonPicker(context, state.season);
                if (picked != null) await vm.setSeason(picked);
              },
            ),
          ]),
          const SizedBox(height: MhSpacing.sm),
          _Group(children: [
            _SwitchRow(
              label: '알림',
              value: state.notificationsOn,
              onChanged: (_) => vm.toggleNotifications(),
            ),
          ]),
          const SizedBox(height: MhSpacing.sm),
          _Group(children: [
            // 문구는 웹에서 관리한다. 앱에 넣으면 고칠 때마다 심사를
            // 다시 받아야 한다.
            _LinkRow(
              label: '개인정보 처리방침',
              trailing: '>',
              onTap: () => openExternalUrl(context, AppConfig.privacyUrl),
            ),
            _Divider(),
            _LinkRow(
              label: '서비스 이용약관',
              trailing: '>',
              onTap: () => openExternalUrl(context, AppConfig.termsUrl),
            ),
            _Divider(),
            _LinkRow(
              label: '앱 버전',
              trailing:
                  '${AppConfig.appVersion} (${AppConfig.buildNumber})',
            ),
          ]),
        ],
      ),
    );
  }
}

/// 조회 시즌 선택 다이얼로그. 시안 SEASON PICKER (280px 카드).
Future<Season?> showSeasonPicker(BuildContext context, Season current) {
  final c = context.mh;
  return showDialog<Season>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => Center(
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(MhSpacing.sm),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Text('조회 시즌 선택',
                  style: MhText.custom(
                      size: 15, weight: FontWeight.w700, color: c.text)),
            ),
            for (final season in Season.all) ...[
              MhTap(
                onTap: () => Navigator.of(context).pop(season),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: season == current ? MhColors.brand : c.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${season.label} 시즌',
                    style: MhText.custom(
                      size: 14,
                      weight: FontWeight.w600,
                      color: season == current ? Colors.white : c.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MhSpacing.xs),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.mh.card,
        borderRadius: BorderRadius.circular(MhRadius.chip),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.mh.borderSubtle);
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Padding(
      padding: const EdgeInsets.all(MhSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: MhText.custom(
                  size: 15, weight: FontWeight.w600, color: c.text)),
          // 시안은 44x26 트랙에 22px 노브를 쓴다.
          MhTap(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(2),
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? MhColors.brand : c.border,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.trailing,
    this.onTap,
  });

  final String label;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(MhSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: MhText.custom(
                    size: 15, weight: FontWeight.w600, color: c.text)),
            Text(trailing,
                style: MhText.custom(
                    size: 13, weight: FontWeight.w400, color: c.textFaint)),
          ],
        ),
      ),
    );
  }
}
