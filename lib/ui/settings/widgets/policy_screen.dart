import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/sub_page_scaffold.dart';

/// 개인정보 처리방침. 시안 POLICY PAGE.
///
/// 본문은 v1 웹의 `Policy.tsx`에 있던 내용을 옮겨야 한다. 지금은 항목 구조만
/// 맞춰둔 자리표시 문구다 — 실제 배포 전 법무 문구로 교체해야 한다.
class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  static const _sections = <(String, String)>[
    (
      '1. 수집하는 개인정보',
      '마이핸드볼은 회원가입 없이 이용할 수 있습니다.\n'
          '온보딩에서 선택한 성별·연령대·관심 팀 정보가 서비스 개선 목적으로 저장됩니다.',
    ),
    (
      '2. 이용 목적',
      '수집한 정보는 관심 팀 기반 일정 표시와 서비스 개선 통계에만 사용합니다.',
    ),
    (
      '3. 보관 및 파기',
      '수집한 정보는 목적 달성 후 지체 없이 파기합니다.',
    ),
    (
      '4. 기기에 저장되는 정보',
      '마이팀, 테마, 관심 선수, 가이드 진행도 등은 기기 안에만 저장되며 서버로 전송되지 않습니다.\n'
          '앱을 삭제하면 함께 사라집니다.',
    ),
    (
      '5. 제3자 제공',
      '수집한 정보를 제3자에게 제공하지 않습니다.\n'
          '경기 일정·순위 정보는 대한핸드볼협회 공개 자료를 사용합니다.',
    ),
    (
      '6. 문의',
      '개인정보 관련 문의는 앱 개발자에게 연락해 주세요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return SubPageScaffold(
      title: '개인정보 처리방침',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, MhSpacing.xs, 20, MhSpacing.xl),
        children: [
          Text('시행일: 2026-01-01',
              style: MhText.custom(
                  size: 12, weight: FontWeight.w400, color: c.textFaint)),
          const SizedBox(height: MhSpacing.sm),
          for (final (title, body) in _sections) ...[
            Text(title,
                style: MhText.custom(
                    size: 14, weight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 6),
            Text(body,
                style: MhText.custom(
                    size: 13,
                    weight: FontWeight.w400,
                    color: c.textSub,
                    height: 22 / 13)),
            const SizedBox(height: MhSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// 서비스 이용약관. 시안 TERMS PAGE — 시안에서도 "준비 중" 상태다.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return SubPageScaffold(
      title: '서비스 이용약관',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text('서비스 이용약관 내용이 준비 중입니다.',
            style: MhText.custom(
                size: 13,
                weight: FontWeight.w400,
                color: c.textSub,
                height: 22 / 13)),
      ),
    );
  }
}
