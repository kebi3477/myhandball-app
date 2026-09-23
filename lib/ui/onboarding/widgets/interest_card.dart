import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../view_models/onboarding_view_model.dart';

/// 온보딩 1스텝의 관심사 카드 (2x2).
class InterestCard extends StatelessWidget {
  const InterestCard({
    super.key,
    required this.interest,
    required this.selected,
    required this.onTap,
  });

  final Interest interest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: MhColors.onboardCard,
          borderRadius: BorderRadius.circular(MhRadius.card),
          border: Border.all(
            color: selected ? MhColors.brand : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(MhSpacing.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 76,
              child: Center(
                child: _AssetOrPlaceholder(
                  path: interest.asset,
                  width: interest.assetWidth,
                  height: interest.assetHeight,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              interest.label,
              textAlign: TextAlign.center,
              style: MhText.custom(
                size: 16,
                weight: FontWeight.w700,
                color: Colors.white,
                height: 26 / 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `assets/figassets/`가 아직 비어 있을 때 자리만 잡아준다.
class _AssetOrPlaceholder extends StatelessWidget {
  const _AssetOrPlaceholder({
    required this.path,
    required this.width,
    required this.height,
  });

  final String path;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: width,
        height: height,
        placeholderBuilder: (_) => fallback,
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
