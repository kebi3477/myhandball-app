import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models/nickname.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/external_actions.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/team_logo.dart';
import '../view_models/my_view_model.dart';
import '../view_models/nickname_provider.dart';

/// MY 맨 위의 프로필 카드. 시안 `myProf`.
///
/// 닉네임을 **그 자리에서** 고친다. 설정 화면으로 보내지 않는 이유는
/// 시안이 연필 아이콘 → 입력칸 → 저장 순으로 한 카드 안에서 끝내기
/// 때문이다. 취소하면 원래 값으로 돌아간다.
class MyProfileCard extends ConsumerStatefulWidget {
  const MyProfileCard({super.key, required this.state});

  final MyState state;

  @override
  ConsumerState<MyProfileCard> createState() => _MyProfileCardState();
}

class _MyProfileCardState extends ConsumerState<MyProfileCard> {
  final _controller = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEdit(String current) {
    _controller.value = TextEditingValue(
      text: current,
      selection: TextSelection.collapsed(offset: current.length),
    );
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    if (!Nickname.isValid(_controller.text)) return;
    final nickname = Nickname.normalize(_controller.text);

    // **랭킹에 올라가 있으면 서버 이름부터 바꾼다.** 기기에만 바꾸면
    // 랭킹에는 옛 이름이 남아 두 화면이 다른 사람처럼 보인다.
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null && profile.nickname != nickname) {
      try {
        await ref.read(profileProvider.notifier).save(
              nickname: nickname,
              teamNum: profile.teamNum,
              gender: profile.gender,
            );
      } on ApiException catch (e) {
        if (!mounted) return;
        showMhToast(
          context,
          // 중복 닉네임 문구는 서버가 준다.
          e.statusCode == 409 || e.statusCode == 400
              ? e.message
              : e.isOffline
                  ? '오프라인 상태라 닉네임을 바꾸지 못했어요. 연결을 확인해 주세요.'
                  : '일시적인 오류로 닉네임을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.',
        );
        return;
      }
    }

    // 저장소에 직접 쓰면 승부예측 탭의 프로필이 안 따라온다 — 저장소는
    // `Provider`라 내부 값이 바뀌어도 아무도 다시 그리지 않는다.
    await ref.read(nicknameProvider.notifier).set(nickname);
    if (!mounted) return;
    setState(() => _editing = false);
    showMhToast(context, '닉네임을 바꿨어요');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final nickname = ref.watch(nicknameProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: MhSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(MhRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TeamLogo(
                  size: 48,
                  logoUrl: widget.state.team?.logoUrl,
                  inset: 0.74,
                ),
                const SizedBox(width: 12),
                Expanded(child: _editing ? _editor(c) : _viewer(c, nickname)),
              ],
            ),
            if (_editing) ...[
              const SizedBox(height: MhSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Nickname.validate(_controller.text) ??
                            '적중률 랭킹에 이 이름으로 올라가요',
                        style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w500,
                          color: Nickname.validate(_controller.text) == null
                              ? c.textSub
                              : const Color(0xFFFF4D6A),
                        ),
                      ),
                    ),
                    MhTap(
                      onTap: () => setState(() => _editing = false),
                      child: Text(
                        '취소',
                        style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w600,
                          color: c.textSub,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _viewer(MhPalette c, String nickname) {
    final set = nickname.isNotEmpty;
    return Row(
      children: [
        Flexible(
          child: Text(
            set ? nickname : '닉네임을 정해 주세요',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MhText.custom(
              size: 16,
              weight: FontWeight.w800,
              color: set ? c.text : c.textSub,
            ),
          ),
        ),
        MhTap(
          behavior: HitTestBehavior.opaque,
          onTap: () => _startEdit(nickname),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(Icons.edit_outlined, size: 16, color: c.textSub),
          ),
        ),
      ],
    );
  }

  Widget _editor(MhPalette c) {
    final valid = Nickname.isValid(_controller.text);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(MhRadius.button),
              border: Border.all(
                color: valid ? MhColors.brand : c.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: Nickname.maxLength,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                    cursorColor: MhColors.brand,
                    style: MhText.custom(
                      size: 15,
                      weight: FontWeight.w700,
                      color: c.text,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '2~10자',
                      hintStyle: MhText.custom(
                        size: 15,
                        weight: FontWeight.w500,
                        color: c.textFaint,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${Nickname.normalize(_controller.text).runes.length}'
                  '/${Nickname.maxLength}',
                  style: MhText.custom(
                    size: 11,
                    weight: FontWeight.w500,
                    color: c.textFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        MhTap(
          haptic: valid ? MhHaptic.impact : MhHaptic.none,
          onTap: valid ? _save : null,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: valid ? MhColors.brand : c.border,
              borderRadius: BorderRadius.circular(MhRadius.button),
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                '저장',
                style: MhText.custom(
                  size: 13,
                  weight: FontWeight.w700,
                  color: valid ? Colors.white : c.textSub,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
