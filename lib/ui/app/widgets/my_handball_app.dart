import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/theme.dart';
import '../../onboarding/widgets/onboarding_screen.dart';
import '../../shell/widgets/app_shell.dart';
import '../view_models/app_view_model.dart';

class MyHandballApp extends ConsumerWidget {
  const MyHandballApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appViewModelProvider);

    return MaterialApp(
      title: '마이핸드볼',
      debugShowCheckedModeBanner: false,
      theme: buildMhTheme(app.palette),
      // 시안은 온보딩을 마쳐야 앱 본체로 들어간다 (`inApp`).
      // 화면이 더 늘면 go_router로 옮긴다.
      home: app.onboarded ? const AppShell() : const OnboardingScreen(),
    );
  }
}
