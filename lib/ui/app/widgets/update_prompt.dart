import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../../data/services/app_update_service.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/external_actions.dart';
import '../../core/ui/mh_tap.dart';

/// 새 버전이 있을 때 띄우는 안내.
///
/// 배포본(`ContentView.swift`)의 "업데이트 안내" 알럿을 옮긴 것이다.
/// 시안에 없는 화면이라 모양은 시즌 선택 다이얼로그(280px 카드)를 따른다.
///
/// **강제하지 않는다.** "나중에"를 고르면 그 버전은 다시 묻지 않는다.
Future<void> showUpdatePrompt(
  BuildContext context,
  WidgetRef ref,
  AppUpdate update,
) {
  final c = context.mh;

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    // showDialog는 Material을 자동으로 주지 않는다. 없으면 글자가 노란
    // 이중밑줄로 그려진다 (시즌 선택에서 한 번 겪었다).
    builder: (dialogContext) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('업데이트 안내',
                  style: MhText.custom(
                      size: 16, weight: FontWeight.w800, color: c.text)),
              const SizedBox(height: MhSpacing.xs),
              Text(
                '새로운 버전이 나왔어요.\n'
                '${AppConfig.appVersion} → ${update.version}',
                style: MhText.custom(
                    size: 13,
                    weight: FontWeight.w500,
                    color: c.textSub,
                    height: 1.6),
              ),
              const SizedBox(height: MhSpacing.sm),
              MhTap(
                haptic: MhHaptic.impact,
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  openExternalUrl(context, update.storeUrl);
                },
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MhColors.brand,
                    borderRadius: BorderRadius.circular(MhRadius.button),
                  ),
                  child: Text('업데이트',
                      style: MhText.custom(
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: MhSpacing.xs),
              MhTap(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // 같은 버전으로는 다시 묻지 않는다.
                  ref
                      .read(preferencesRepositoryProvider)
                      .skipUpdateVersion(update.version);
                  Navigator.of(dialogContext).pop();
                },
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: Text('나중에',
                        style: MhText.custom(
                            size: 14,
                            weight: FontWeight.w600,
                            color: c.textSub)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
