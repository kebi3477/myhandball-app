import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/team_detail.dart';
import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../view_models/team_detail_view_model.dart';

/// 팀 상세 — 전적 탭. 승·무·패 바, 시즌 추이 그래프, 경기별 결과.
class TeamRecordTab extends ConsumerWidget {
  const TeamRecordTab({super.key, required this.state});

  final TeamDetailState state;

  static const _lossColor = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mh;
    final d = state.detail;
    final r = d.rank;
    final vm = ref.read(teamDetailViewModelProvider(d.team).notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          MhSpacing.gutter, 20, MhSpacing.gutter, MhSpacing.xl),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(MhRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('25-26 정규리그',
                      style: MhText.custom(
                          size: 15, weight: FontWeight.w700, color: c.text)),
                  Text('${r.rank}위 · 승점 ${r.points}',
                      style: MhText.custom(
                          size: 13,
                          weight: FontWeight.w700,
                          color: MhColors.brand)),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      Expanded(
                          flex: r.wins + 1,
                          child: Container(color: MhColors.brand)),
                      Expanded(
                          flex: r.draws + 1,
                          child: Container(color: MhColors.closed)),
                      Expanded(
                          flex: r.losses + 1,
                          child: Container(color: _lossColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MhSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${r.wins}승',
                      style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w600,
                          color: MhColors.brand)),
                  Text('${r.draws}무',
                      style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w600,
                          color: c.textSub)),
                  Text('${r.losses}패',
                      style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w600,
                          color: _lossColor)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Row(
                  children: [
                    for (final (label, value) in [
                      ('득점', '${r.goalsFor}'),
                      ('실점', '${r.goalsAgainst}'),
                      ('경기당 득점',
                          r.played == 0
                              ? '-'
                              : (r.goalsFor / r.played).toStringAsFixed(1)),
                    ])
                      Expanded(
                        child: Column(
                          children: [
                            Text(value,
                                style: MhText.custom(
                                    size: 18,
                                    weight: FontWeight.w800,
                                    color: c.text)),
                            const SizedBox(height: 2),
                            Text(label, style: MhText.caption(c.textSub)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MhSpacing.sm),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(MhRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('시즌 추이',
                      style: MhText.custom(
                          size: 15, weight: FontWeight.w700, color: c.text)),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: BorderRadius.circular(MhRadius.chip),
                    ),
                    child: Row(
                      children: [
                        for (final mode in TrendMode.values)
                          GestureDetector(
                            onTap: () => vm.setTrendMode(mode),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: state.trendMode == mode
                                    ? MhColors.brand
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Text(
                                mode.label,
                                style: MhText.custom(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: state.trendMode == mode
                                      ? Colors.white
                                      : c.textSub,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 160,
                child: _TrendChart(
                  values: _trendValues(),
                  invertY: state.trendMode == TrendMode.rank,
                  palette: c,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('경기별 결과 · 승 파랑 / 무 회색 / 패 빨강',
                        style: MhText.caption(c.textSub)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 14,
                      child: Row(
                        children: [
                          for (final res in d.results) ...[
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: switch (res) {
                                    MatchResult.win => MhColors.brand,
                                    MatchResult.draw => MhColors.closed,
                                    MatchResult.loss => _lossColor,
                                  },
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final (label, value) in [
                    ('최다 연승', '${d.longestWinStreak}'),
                    ('최근 5경기', d.recentForm),
                    ('현재 순위', '${r.rank}위'),
                  ])
                    Expanded(
                      child: Column(
                        children: [
                          Text(value,
                              style: MhText.custom(
                                  size: 16,
                                  weight: FontWeight.w800,
                                  color: c.text)),
                          const SizedBox(height: 2),
                          Text(label, style: MhText.caption(c.textSub)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 승점 모드는 라운드마다 누적 승점을 만들어 보여준다.
  List<int> _trendValues() {
    if (state.trendMode == TrendMode.rank) return state.detail.rankTrend;
    var acc = 0;
    return [
      for (final r in state.detail.results)
        acc += switch (r) {
          MatchResult.win => 2,
          MatchResult.draw => 1,
          MatchResult.loss => 0,
        },
    ];
  }
}

/// 시안의 SVG polyline + area를 그대로 옮긴 꺾은선 그래프.
class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.values,
    required this.invertY,
    required this.palette,
  });

  final List<int> values;

  /// 순위는 작을수록 위에 와야 한다.
  final bool invertY;

  final MhPalette palette;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return Center(
        child: Text('표시할 기록이 아직 없어요', style: MhText.meta(palette.textSub)),
      );
    }
    return CustomPaint(
      painter: _TrendPainter(
        values: values,
        invertY: invertY,
        gridColor: palette.border,
        cardColor: palette.card,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.invertY,
    required this.gridColor,
    required this.cardColor,
  });

  final List<int> values;
  final bool invertY;
  final Color gridColor;
  final Color cardColor;

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV) == 0 ? 1 : maxV - minV;

    const padTop = 12.0;
    final h = size.height - padTop - 12;

    double yOf(int v) {
      final t = (v - minV) / span;
      return padTop + (invertY ? t : 1 - t) * h;
    }

    double xOf(int i) => i * size.width / (values.length - 1);

    // 가로 그리드 4줄
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = padTop + h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final path = Path()..moveTo(xOf(0), yOf(values.first));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(xOf(i), yOf(values[i]));
    }

    // 면적
    final area = Path.from(path)
      ..lineTo(xOf(values.length - 1), padTop + h)
      ..lineTo(xOf(0), padTop + h)
      ..close();
    canvas.drawPath(area, Paint()..color = MhColors.brand.withValues(alpha: 0.12));

    canvas.drawPath(
      path,
      Paint()
        ..color = MhColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // 마지막 점
    final last = Offset(xOf(values.length - 1), yOf(values.last));
    canvas.drawCircle(last, 8, Paint()..color = cardColor);
    canvas.drawCircle(last, 5, Paint()..color = MhColors.brand);
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values ||
      old.invertY != invertY ||
      old.gridColor != gridColor;
}
