import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/preferences_repository.dart';
import 'ui/app/widgets/my_handball_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 테마가 첫 프레임에 깜빡이지 않도록 설정을 먼저 읽는다.
  final preferences = PreferencesRepository();
  await preferences.load();

  runApp(
    ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(preferences),
      ],
      child: const MyHandballApp(),
    ),
  );
}
