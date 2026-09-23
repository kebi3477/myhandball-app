import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'data/repositories/preferences_repository.dart';
import 'ui/app/widgets/my_handball_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 테마가 첫 프레임에 깜빡이지 않도록 설정을 먼저 읽는다.
  final preferences = PreferencesRepository();
  await preferences.load();

  // "데이터가 이상한데 API를 타는 게 맞나?"를 바로 확인할 수 있게 남긴다.
  // API_BASE_URL을 안 넣으면 목업으로 떨어지는데 화면만 봐서는 구분이 어렵다.
  if (kDebugMode) {
    final base = AppConfig.apiBaseUrl;
    debugPrint(base.isEmpty
        ? '[MyHandball] 데이터 소스: 목업 '
            '(--dart-define=API_BASE_URL=... 을 주면 실제 API를 탄다)'
        : '[MyHandball] 데이터 소스: $base · 시즌 ${preferences.season.label}');
  }

  runApp(
    ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(preferences),
      ],
      child: const MyHandballApp(),
    ),
  );
}
