import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/ics.dart';
import '../../../domain/models/game.dart';

/// 앱 밖으로 나가는 동작 — 외부 링크 열기, 일정 내보내기.
///
/// 실패해도 조용히 아무 일도 안 일어나면 안 된다. 눌렀는데 반응이 없는 걸
/// 사용자는 버그로 읽는다. 그래서 전부 실패 시 안내를 띄운다.

/// 브라우저로 링크를 연다.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  var ok = false;
  if (uri != null) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      ok = false;
    }
  }
  if (!ok && context.mounted) {
    _notify(context, '링크를 열지 못했어요');
  }
}

/// 경기 일정을 `.ics`로 공유한다. iOS는 공유 시트에서 캘린더에 넣을 수 있다.
///
/// 서버의 `/api/schedule/ics/my-team`은 시즌 전체만 주므로, 경기 하나만
/// 넣는 경우까지 한 경로로 다루려고 앱에서 만든다 ([Ics] 참조).
Future<void> exportGamesToCalendar(
  BuildContext context,
  List<Game> games, {
  required String calendarName,
  required String fileName,
}) async {
  final withTime = games.where((g) => g.startsAt != null).toList();
  if (withTime.isEmpty) {
    _notify(context, '추가할 예정 경기가 없어요');
    return;
  }

  final ics = Ics.forGames(withTime, calendarName: calendarName);
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(ics),
            mimeType: 'text/calendar',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
        subject: calendarName,
      ),
    );
    if (context.mounted) {
      _notify(context, '캘린더 파일을 저장했어요 (${withTime.length}경기)');
    }
  } on Exception {
    if (context.mounted) _notify(context, '캘린더에 추가하지 못했어요');
  }
}

/// 화면 아래 짧은 안내. 시안의 토스트 자리다.
void showMhToast(BuildContext context, String message) =>
    _notify(context, message);

void _notify(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
