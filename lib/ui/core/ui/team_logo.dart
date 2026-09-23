import 'package:flutter/material.dart';

import '../themes/tokens.dart';

/// 시안의 팀 로고 배지.
///
/// 원형/둥근사각 흰 바탕 안에 로고를 `background-size: contain`으로 넣는
/// 패턴이 화면마다 반복된다 (홈 카드 64px 원형, 순위 40px 라운드,
/// 시상대 60px 원형, 팀선택 48px 라운드).
class TeamLogo extends StatelessWidget {
  const TeamLogo({
    super.key,
    required this.size,
    this.logoUrl,
    this.borderRadius,
    this.inset = 0.8,
  });

  final double size;
  final String? logoUrl;

  /// null이면 완전 원형.
  final double? borderRadius;

  /// 흰 배지 대비 로고가 차지하는 비율. 시안은 78~80%.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size / 2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: MhColors.logoBg,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: SizedBox(
        width: size * inset,
        height: size * inset,
        child: logoUrl == null
            ? _Placeholder(size: size * inset)
            : Image.network(
                logoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _Placeholder(size: size * inset),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _Placeholder(size: size * inset),
              ),
      ),
    );
  }
}

/// 로고가 없거나 로딩 중일 때. 시안의 `logoFallback`에 해당한다.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size * 0.55,
        height: size * 0.55,
        decoration: const BoxDecoration(
          color: Color(0xFFE3E3E3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
