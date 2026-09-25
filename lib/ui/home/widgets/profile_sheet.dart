import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models/gender.dart';
import '../../../domain/models/nickname.dart';
import '../../../domain/models/prediction.dart';
import '../../../domain/models/team.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/external_actions.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../../my/view_models/nickname_provider.dart';

/// 시안 `pf.open` — 승부예측 프로필 시트 (`spec/sheets.md`).
///
/// 랭킹에 올라갈 **닉네임과 응원팀만** 정한다. 회원가입이 아니다.
///
/// **동의는 여기서 받지 않는다.** 온보딩의 닉네임 스텝(`obConsent`)이
/// 받는다 — 닉네임을 이미 정해 놓고 또 묻는 꼴이라 2026-09-25에 옮겼다.
/// 이 시트는 그 뒤의 편집용이고, `랭킹 참여 중단`으로 지운 사람이 다시
/// 만들 때도 쓴다.
///
/// 저장에 성공하면 만들어진 프로필을, 닫으면 `null`을 돌려준다.
Future<PredictionProfile?> showProfileSheet(BuildContext context) =>
    showModalBottomSheet<PredictionProfile>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (_) => const _ProfileSheet(),
    );

const _danger = Color(0xFFE5484D);

class _ProfileSheet extends ConsumerStatefulWidget {
  const _ProfileSheet();

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  final _controller = TextEditingController();

  late final PredictionProfile? _existing =
      ref.read(profileProvider).valueOrNull;

  late Gender _gender;
  Team? _team;

  /// 서버가 돌려준 중복 안내. 닉네임을 고치면 지운다.
  String? _serverError;

  bool _saving = false;

  bool get _isEdit => _existing != null;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesRepositoryProvider);
    final profile = _existing;
    _controller.text = profile?.nickname ?? prefs.nickname;
    _gender = profile?.gender ?? prefs.myTeam?.gender ?? prefs.preferredGender;
    // 기존 프로필의 팀은 이름만 아는 상태로 시작한다. 목록이 오면
    // 같은 번호의 팀으로 바꿔 로고까지 맞춘다.
    _team = prefs.myTeam;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _nickname => Nickname.normalize(_controller.text);

  /// 시안 `nickCheck` — 통과하면 파란 안내, 아니면 빨간 안내.
  (bool ok, String message) get _check {
    if (_serverError case final message?) return (false, message);
    if (_nickname.isEmpty) return (false, '');
    if (Nickname.validate(_controller.text) case final message?) {
      return (false, message);
    }
    return (true, '사용할 수 있는 닉네임이에요');
  }

  bool get _canSave => _check.$1 && _team?.teamNum != null && !_saving;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final (ok, message) = _check;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        // 키보드가 올라오면 입력칸이 가린다.
        padding: EdgeInsets.fromLTRB(MhSpacing.gutter, 12, MhSpacing.gutter,
            28 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(_isEdit ? '프로필 편집' : '승부예측 프로필 만들기',
                style: MhText.custom(
                    size: 20, weight: FontWeight.w800, color: c.text)),
            const SizedBox(height: 6),
            Text('랭킹에서 나를 구분할 닉네임과 응원팀만 있으면 돼요',
                style: MhText.custom(
                    size: 13,
                    weight: FontWeight.w400,
                    color: c.textSub,
                    height: 1.5)),
            const SizedBox(height: 20),
            _Label(
              text: '닉네임',
              trailing: '${_nickname.runes.length}/${Nickname.maxLength}',
            ),
            const SizedBox(height: 8),
            _NicknameField(
              controller: _controller,
              borderColor: _nickname.isEmpty
                  ? Colors.transparent
                  : (ok ? MhColors.brand : _danger),
              onChanged: () => setState(() => _serverError = null),
              onSuggest: () {
                _controller.text = Nickname.suggest();
                setState(() => _serverError = null);
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 16,
              child: Text(message,
                  style: MhText.custom(
                      size: 12,
                      weight: FontWeight.w500,
                      color: ok ? MhColors.brand : _danger)),
            ),
            const SizedBox(height: 20),
            const _Label(text: '응원팀', trailing: 'MY 팀과 함께 바뀌어요'),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final g in Gender.values) ...[
                  if (g != Gender.values.first) const SizedBox(width: 8),
                  _Pill(
                    label: g == Gender.women ? '여자부' : '남자부',
                    selected: _gender == g,
                    onTap: () => setState(() => _gender = g),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _TeamGrid(
              gender: _gender,
              selected: _team,
              onPick: (team) => setState(() => _team = team),
              onLoaded: _adoptTeam,
            ),
            const SizedBox(height: 20),
            const _DisclosureCard(),
            const SizedBox(height: 20),
            MhTap(
              haptic: MhHaptic.impact,
              onTap: _canSave ? _save : null,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _canSave ? MhColors.brand : const Color(0xFF9A9A9A),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(_isEdit ? '저장' : '랭킹 참여하기',
                    style: MhText.custom(
                        size: 15,
                        weight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            MhTap(
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                height: 40,
                child: Center(
                  child: Text('닫기',
                      style: MhText.custom(
                          size: 13,
                          weight: FontWeight.w600,
                          color: c.textSub)),
                ),
              ),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 10),
              MhTap(
                onTap: _confirmLeave,
                child: SizedBox(
                  height: 24,
                  child: Center(
                    child: Text('랭킹 참여 중단 · 프로필 삭제',
                        style: MhText.custom(
                            size: 12,
                            weight: FontWeight.w500,
                            color: _danger)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 팀 목록이 오면 같은 팀의 **완전한** 값으로 바꾼다.
  ///
  /// 저장에는 `teamNum`이 필요한데 기기에 적힌 마이팀에는 없을 수 있고,
  /// 기존 프로필은 이름만 들고 있다.
  void _adoptTeam(List<Team> teams) {
    if (teams.isEmpty) return;
    final wanted = _existing?.teamName ?? _team?.name;
    final match = teams.where((t) {
      if (_team?.teamNum != null && t.teamNum == _team!.teamNum) return true;
      return _key(t.name) == _key(wanted ?? '');
    }).firstOrNull;
    final next = match ?? (_team?.gender == _gender ? null : teams.first);
    if (next == null || next.teamNum == _team?.teamNum) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _team = next);
    });
  }

  static String _key(String name) => name.replaceAll(' ', '');

  Future<void> _save() async {
    final team = _team;
    if (team?.teamNum == null) return;
    setState(() => _saving = true);

    try {
      final profile = await ref.read(profileProvider.notifier).save(
            nickname: _nickname,
            teamNum: team!.teamNum!,
            gender: _gender,
          );
      // MY 프로필 카드와 승부예측 카드가 같은 이름을 보게 한다.
      await ref.read(nicknameProvider.notifier).set(profile.nickname);
      if (!mounted) return;
      Navigator.of(context).pop(profile);
      showMhToast(
        context,
        _isEdit ? '프로필을 저장했어요' : '${profile.nickname}님, 랭킹에 참여했어요',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        // 409는 중복이고, 그 문구는 서버가 준다. 나머지는 시트를 닫지 않고
        // 토스트로 알린다 — 입력을 날리지 않는다.
        if (e.statusCode == 409 || e.statusCode == 400) {
          _serverError = e.message;
        }
      });
      if (_serverError != null) return;
      showMhToast(
        context,
        e.isOffline
            ? '오프라인 상태라 프로필을 저장하지 못했어요. 연결을 확인해 주세요.'
            : '일시적인 오류로 프로필을 저장하지 못했어요. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  /// 시안에는 확인 단계가 없다. 되돌릴 수 없는 삭제라 한 번 묻는다.
  Future<void> _confirmLeave() async {
    final c = context.mh;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: c.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('랭킹 참여를 중단할까요?',
                  style: MhText.custom(
                      size: 17, weight: FontWeight.w800, color: c.text)),
              const SizedBox(height: 8),
              Text('닉네임과 응원팀이 서버에서 지워지고 랭킹에서 내려가요. 예측 기록은 기기에 남아요.',
                  style: MhText.custom(
                      size: 13,
                      weight: FontWeight.w400,
                      color: c.textSub,
                      height: 1.5)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: '취소',
                      background: c.card,
                      foreground: c.text,
                      onTap: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DialogButton(
                      label: '중단하기',
                      background: _danger,
                      foreground: Colors.white,
                      onTap: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await ref.read(profileProvider.notifier).leave();
      if (!mounted) return;
      Navigator.of(context).pop();
      showMhToast(context, '랭킹 참여를 중단했어요. 예측 기록은 기기에 남아요');
    } on ApiException catch (e) {
      if (!mounted) return;
      showMhToast(
        context,
        e.isOffline
            ? '오프라인 상태라 프로필을 삭제하지 못했어요. 연결을 확인해 주세요.'
            : '일시적인 오류로 프로필을 삭제하지 못했어요. 잠시 후 다시 시도해 주세요.',
      );
    }
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.trailing});

  final String text;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text,
            style: MhText.custom(
                size: 13, weight: FontWeight.w700, color: c.text)),
        Text(trailing,
            style: MhText.custom(
                size: 11, weight: FontWeight.w400, color: c.textFaint)),
      ],
    );
  }
}

class _NicknameField extends StatelessWidget {
  const _NicknameField({
    required this.controller,
    required this.borderColor,
    required this.onChanged,
    required this.onSuggest,
  });

  final TextEditingController controller;
  final Color borderColor;
  final VoidCallback onChanged;
  final VoidCallback onSuggest;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      height: 50,
      padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: Nickname.maxLength,
              onChanged: (_) => onChanged(),
              textInputAction: TextInputAction.done,
              style: MhText.custom(
                  size: 15, weight: FontWeight.w600, color: c.text),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                border: InputBorder.none,
                hintText: '2~10자 · 한글, 영문, 숫자',
                hintStyle: MhText.custom(
                    size: 15, weight: FontWeight.w500, color: c.textFaint),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MhTap(
            onTap: onSuggest,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                widthFactor: 1,
                child: Text('추천',
                    style: MhText.custom(
                        size: 12, weight: FontWeight.w700, color: c.text)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? MhColors.brand : c.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(label,
              style: MhText.custom(
                  size: 13,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : c.textSub)),
        ),
      ),
    );
  }
}

/// 4열 팀 그리드. 팀 목록은 `/api/team`에서 온다.
class _TeamGrid extends ConsumerWidget {
  const _TeamGrid({
    required this.gender,
    required this.selected,
    required this.onPick,
    required this.onLoaded,
  });

  final Gender gender;
  final Team? selected;
  final ValueChanged<Team> onPick;
  final ValueChanged<List<Team>> onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final async = ref.watch(_profileTeamsProvider(gender));

    return async.when(
      loading: () => const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator(color: MhColors.brand)),
      ),
      error: (e, _) => SizedBox(
        height: 96,
        child: Center(
          child: Text('팀 목록을 불러오지 못했어요',
              style: MhText.meta(c.textSub)),
        ),
      ),
      data: (teams) {
        onLoaded(teams);
        return GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.82,
          children: [
            for (final team in teams)
              _TeamCell(
                team: team,
                selected: team.teamNum != null &&
                    team.teamNum == selected?.teamNum,
                onTap: () => onPick(team),
              ),
          ],
        );
      },
    );
  }
}

final _profileTeamsProvider =
    FutureProvider.family<List<Team>, Gender>((ref, gender) {
  return ref.read(teamRepositoryProvider).getTeams(gender);
});

class _TeamCell extends StatelessWidget {
  const _TeamCell({
    required this.team,
    required this.selected,
    required this.onTap,
  });

  final Team team;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? MhColors.brand.withValues(alpha: 0.1) : c.card,
          border: Border.all(
            color: selected ? MhColors.brand : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TeamLogo(size: 40, logoUrl: team.logoUrl),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                team.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: MhText.custom(
                  size: 10,
                  weight: FontWeight.w600,
                  color: selected ? MhColors.brand : c.text,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 무엇을 공개하고 무엇을 받지 않는지. 심사에서도 보는 자리다.
class _DisclosureCard extends StatelessWidget {
  const _DisclosureCard();

  static const _rows = [
    ('공개', '닉네임 · 응원팀 · 예측 적중 기록'),
    ('받지 않음', '이름 · 이메일 · 전화번호 · 위치'),
    ('구분 방법', '기기마다 익명 ID가 자동 생성돼요'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value) in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(label,
                        style: MhText.custom(
                            size: 12,
                            weight: FontWeight.w700,
                            color: c.text,
                            height: 1.5)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(value,
                        style: MhText.custom(
                            size: 12,
                            weight: FontWeight.w400,
                            color: c.textSub,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          MhTap(
            onTap: () => openExternalUrl(context, AppConfig.privacyUrl),
            child: Text(
              '개인정보 처리방침',
              style: MhText.custom(
                size: 11,
                weight: FontWeight.w600,
                color: c.textNeutral,
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MhTap(
      haptic: MhHaptic.impact,
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: MhText.custom(
                size: 14, weight: FontWeight.w700, color: foreground)),
      ),
    );
  }
}
