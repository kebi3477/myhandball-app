import 'package:flutter/material.dart';

import '../../../domain/models/team.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/nav_icons.dart';
import '../../core/ui/team_logo.dart';

/// 온보딩 3스텝의 팀 한 줄. 높이 80, 선택 시 브랜드 테두리 + 체크 배지.
class TeamPickerRow extends StatelessWidget {
  const TeamPickerRow({
    super.key,
    required this.team,
    required this.selected,
    required this.onTap,
  });

  final Team team;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MhColors.onboardCard,
          borderRadius: BorderRadius.circular(MhRadius.listItem),
          border: Border.all(
            color: selected ? MhColors.brand : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            TeamLogo(size: 48, logoUrl: team.logoUrl, borderRadius: 10),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                team.name,
                style: MhText.custom(
                  size: 16,
                  weight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.014 * 16,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: MhColors.brand,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 11,
                  height: 7,
                  child: CustomPaint(painter: MhCheckIconPainter()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
