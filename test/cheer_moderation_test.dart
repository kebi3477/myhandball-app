import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhandball/data/repositories/preferences_repository.dart';
import 'package:myhandball/data/repositories/schedule_repository.dart';
import 'package:myhandball/data/services/mock_handball_api_service.dart';
import 'package:myhandball/domain/models/gender.dart';
import 'package:myhandball/domain/models/team_detail.dart';
import 'package:myhandball/ui/team_detail/view_models/team_detail_view_model.dart';

/// 응원글 신고·차단.
///
/// **App Store Guideline 1.2가 요구하는 기능**이라 조용히 실패하면 안 된다.
/// 차단 목록 화면이 이름을 보여주려면 차단하는 순간의 닉네임을 기기에
/// 적어 둬야 한다 — 서버는 `authorId`만 준다.
void main() {
  Future<(ProviderContainer, PreferencesRepository)> setUp() async {
    const api = MockHandballApiService(latency: Duration.zero);
    final prefs = PreferencesRepository();
    final container = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(prefs),
      handballApiServiceProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    return (container, prefs);
  }

  test('차단하면 닉네임을 기기에 적어 둔다', () async {
    final (container, prefs) = await setUp();
    final team = (await const MockHandballApiService(latency: Duration.zero)
            .fetchTeams(Gender.men))
        .first;

    await container.read(teamDetailViewModelProvider(team).future);
    const post = CheerPost(
      id: '1',
      authorId: 'abc123',
      author: '날쌘피벗',
      text: '화이팅',
      dateLabel: '9.24',
      likes: 0,
    );

    await container
        .read(teamDetailViewModelProvider(team).notifier)
        .blockAuthor(post);

    expect(prefs.blockedName('abc123'), '날쌘피벗');
    expect(prefs.hasBlockedAuthors, isTrue);

    final state = container.read(teamDetailViewModelProvider(team)).value!;
    expect(state.notice, '날쌘피벗님의 글을 더 이상 보지 않아요');
  });

  test('같은 글을 두 번 신고하면 이미 신고했다고 알린다', () async {
    final (container, _) = await setUp();
    final team = (await const MockHandballApiService(latency: Duration.zero)
            .fetchTeams(Gender.men))
        .first;

    final state = await container.read(teamDetailViewModelProvider(team).future);
    final target = state.cheers.firstWhere((c) => !c.isMine);
    final vm = container.read(teamDetailViewModelProvider(team).notifier);

    await vm.reportCheer(target, reason: CheerReportReason.spam);
    expect(container.read(teamDetailViewModelProvider(team)).value!.notice,
        '신고가 접수됐어요. 검토 후 조치할게요');

    await vm.reportCheer(target, reason: CheerReportReason.spam);
    expect(container.read(teamDetailViewModelProvider(team)).value!.notice,
        '이미 신고한 응원글이에요');
  });

  test('신고하면서 차단도 고르면 문구가 달라진다', () async {
    final (container, prefs) = await setUp();
    final team = (await const MockHandballApiService(latency: Duration.zero)
            .fetchTeams(Gender.men))
        .last;

    final state = await container.read(teamDetailViewModelProvider(team).future);
    final target = state.cheers.firstWhere((c) => !c.isMine);

    await container
        .read(teamDetailViewModelProvider(team).notifier)
        .reportCheer(target,
            reason: CheerReportReason.abuse, alsoBlock: true);

    expect(container.read(teamDetailViewModelProvider(team)).value!.notice,
        '신고하고 이 사용자의 글을 숨겼어요');
    expect(prefs.blockedName(target.authorId), target.author);
  });

  test('기타 사유는 상세 입력을 요구한다', () {
    expect(CheerReportReason.other.needsDetail, isTrue);
    expect(CheerReportReason.spam.needsDetail, isFalse);
    // 서버가 받는 코드가 바뀌면 신고가 400으로 떨어진다.
    expect(CheerReportReason.values.map((r) => r.code).toList(),
        ['spam', 'abuse', 'sexual', 'other']);
  });
}
