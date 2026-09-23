import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/player.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../../core/ui/mh_tap.dart';
import '../../core/ui/sub_page_scaffold.dart';
import '../../core/ui/team_logo.dart';

/// 선수 비교. 시안 PLAYER COMPARE.
///
/// 두 선수를 고르면 5개 축 레이더 차트로 비교한다. **축 값은 `/api/player`가
/// 주는 실제 시즌 기록**이고, 비교 대상 중 최대값을 1로 잡아 상대 비교로
/// 읽는다 (골 몇 개가 만점인지에 대한 절대 기준이 없다).
class PlayerCompareScreen extends ConsumerStatefulWidget {
  const PlayerCompareScreen({super.key, required this.candidates});

  final List<Player> candidates;

  static Future<void> open(BuildContext context, List<Player> candidates) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerCompareScreen(candidates: candidates),
      ),
    );
  }

  @override
  ConsumerState<PlayerCompareScreen> createState() =>
      _PlayerCompareScreenState();
}

class _PlayerCompareScreenState extends ConsumerState<PlayerCompareScreen> {
  static const _axes = ['득점', '어시스트', '출전', '성공률', '수비'];
  static const _awayColor = Color(0xFFFF7A45);

  Player? _a;
  Player? _b;

  /// 어느 슬롯을 고르는 중인지. null이면 목록을 숨긴다.
  int? _picking = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final ready = _a != null && _b != null;

    return SubPageScaffold(
      title: '선수 비교',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            MhSpacing.gutter, 4, MhSpacing.gutter, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: _Slot(
                  player: _a,
                  color: MhColors.brand,
                  selected: _picking == 0,
                  onTap: () => setState(() => _picking = 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Slot(
                  player: _b,
                  color: _awayColor,
                  selected: _picking == 1,
                  onTap: () => setState(() => _picking = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: MhSpacing.sm),
          if (ready) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(MhRadius.card),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 236,
                    child: _RadarChart(
                      axes: _axes,
                      valuesA: _valuesOf(_a!),
                      valuesB: _valuesOf(_b!),
                      palette: c,
                    ),
                  ),
                  const SizedBox(height: MhSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Legend(color: MhColors.brand, label: _a!.name),
                      const SizedBox(width: 16),
                      _Legend(color: _awayColor, label: _b!.name),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('같은 부 선수 중 최고 기록 대비 비율',
                      style: MhText.custom(
                          size: 10,
                          weight: FontWeight.w400,
                          color: c.textFaint)),
                ],
              ),
            ),
            const SizedBox(height: MhSpacing.sm),
          ],
          if (_picking != null) ...[
            Text(_picking == 0 ? '왼쪽 선수 고르기' : '오른쪽 선수 고르기',
                style: MhText.custom(
                    size: 14, weight: FontWeight.w700, color: c.text)),
            const SizedBox(height: MhSpacing.xs),
            for (final p in widget.candidates) ...[
              _CandidateRow(
                player: p,
                selected: (_picking == 0 ? _a : _b)?.id == p.id,
                onTap: () => setState(() {
                  if (_picking == 0) {
                    _a = p;
                  } else {
                    _b = p;
                  }
                  // 한쪽을 고르면 자동으로 빈 슬롯으로 넘어간다.
                  _picking = _a == null ? 0 : (_b == null ? 1 : null);
                }),
              ),
              const SizedBox(height: MhSpacing.xs),
            ],
          ],
        ],
      ),
    );
  }

  /// 다섯 축을 **실제 시즌 기록**으로 만든다.
  ///
  /// 예전에는 득점·어시스트만 `statLine` 문자열에서 뽑고 나머지 셋은
  /// 등번호·포지션으로 지어냈다. `/api/player`가 기록을 통째로 주므로
  /// 더 이상 그럴 이유가 없다.
  ///
  /// 각 축은 **비교 대상 중 최대값 기준**으로 0~1이 된다. 절대 기준이 없어
  /// (골 200이 만점인지 알 수 없다) 상대 비교로 읽는 게 맞다.
  List<double> _valuesOf(Player p) {
    final stats = p.stats;
    if (stats == null) return List.filled(_axes.length, 0.05);

    double axis(num Function(PlayerSeasonSummary s) pick) {
      final mine = pick(stats).toDouble();
      final max = widget.candidates
          .map((x) => x.stats == null ? 0.0 : pick(x.stats!).toDouble())
          .fold<double>(0, (a, b) => a > b ? a : b);
      if (max <= 0) return 0.05;
      return (mine / max).clamp(0.05, 1.0);
    }

    return [
      axis((s) => s.goals),
      axis((s) => s.assists),
      axis((s) => s.playMinutes ?? 0),
      // 골키퍼는 슛 성공률이 없어 방어율로 대신한다.
      axis((s) => s.goalRate ?? s.saveRate ?? 0),
      axis((s) => s.defense),
    ];
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.player,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Player? player;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(MhRadius.card),
        ),
        child: player == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: color, width: 2, style: BorderStyle.solid),
                    ),
                    child: Text('+',
                        style: MhText.custom(
                            size: 22, weight: FontWeight.w600, color: color)),
                  ),
                  const SizedBox(height: MhSpacing.xs),
                  Text('선수 선택', style: MhText.meta(c.textSub)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TeamLogo(size: 24, logoUrl: player!.teamLogoUrl),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(player!.teamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MhText.caption(c.textSub)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(player!.numberText,
                          style: MhText.custom(
                              size: 34,
                              weight: FontWeight.w800,
                              color: color,
                              height: 1)),
                      Text(player!.positionText,
                          style: MhText.custom(
                              size: 11,
                              weight: FontWeight.w700,
                              color: c.textSub)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(player!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MhText.custom(
                          size: 17, weight: FontWeight.w800, color: c.text)),
                  Text('변경 ›', style: MhText.caption(c.textFaint)),
                ],
              ),
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.player,
    required this.selected,
    required this.onTap,
  });

  final Player player;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return MhTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(
              color: selected ? MhColors.brand : Colors.transparent,
              width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            TeamLogo(size: 36, logoUrl: player.teamLogoUrl, inset: 0.78),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.name,
                      style: MhText.custom(
                          size: 14, weight: FontWeight.w700, color: c.text)),
                  Text('${player.teamName} · ${player.positionFull}',
                      style: MhText.caption(c.textSub)),
                ],
              ),
            ),
            Text(player.statLine,
                style: MhText.custom(
                    size: 13, weight: FontWeight.w700, color: MhColors.brand)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: MhText.custom(
                size: 12, weight: FontWeight.w700, color: context.mh.text)),
      ],
    );
  }
}

/// 시안의 SVG polygon 레이더를 옮긴 차트.
class _RadarChart extends StatelessWidget {
  const _RadarChart({
    required this.axes,
    required this.valuesA,
    required this.valuesB,
    required this.palette,
  });

  final List<String> axes;
  final List<double> valuesA;
  final List<double> valuesB;
  final MhPalette palette;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarPainter(
        axes: axes,
        valuesA: valuesA,
        valuesB: valuesB,
        gridColor: palette.border,
        labelColor: palette.textSub,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.axes,
    required this.valuesA,
    required this.valuesB,
    required this.gridColor,
    required this.labelColor,
  });

  final List<String> axes;
  final List<double> valuesA;
  final List<double> valuesB;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = math.min(size.width, size.height) / 2 - 28;
    final n = axes.length;

    Offset pointAt(int i, double t) {
      // 12시 방향부터 시계방향.
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      return center +
          Offset(math.cos(angle), math.sin(angle)) * (radius * t);
    }

    // 거미줄 4겹
    final grid = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var ring = 1; ring <= 4; ring++) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = pointAt(i, ring / 4);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path..close(), grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, pointAt(i, 1), grid);
    }

    void drawPolygon(List<double> values, Color color) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = pointAt(i, values[i]);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.22));
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drawPolygon(valuesB, const Color(0xFFFF7A45));
    drawPolygon(valuesA, MhColors.brand);

    // 축 라벨
    for (var i = 0; i < n; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: axes[i],
          style: MhText.custom(
              size: 11, weight: FontWeight.w700, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = pointAt(i, 1.18);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.valuesA != valuesA ||
      old.valuesB != valuesB ||
      old.gridColor != gridColor;
}
