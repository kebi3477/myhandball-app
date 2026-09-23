import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/themes/tokens.dart';
import '../view_models/my_view_model.dart';

/// 통계 3칸 + 본문으로 이루어진 카드. 직관 기록과 승부 예측이 같은 꼴이다.
class _StatTrioCard extends StatelessWidget {
  const _StatTrioCard({
    required this.title,
    required this.tiles,
    required this.body,
  });

  final String title;

  /// (값, 라벨, 강조 여부)
  final List<(String, String, bool)> tiles;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MhSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: MhText.sectionTitle(c.text)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(MhRadius.card),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    for (final (value, label, highlight) in tiles)
                      Expanded(
                        child: Column(
                          children: [
                            Text(value,
                                style: MhText.custom(
                                  size: 20,
                                  weight: FontWeight.w800,
                                  color: highlight ? MhColors.brand : c.text,
                                )),
                            const SizedBox(height: 2),
                            Text(label,
                                style: MhText.custom(
                                    size: 11,
                                    weight: FontWeight.w400,
                                    color: c.textSub)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                body,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 나의 직관 기록.
class MyAttendanceCard extends StatelessWidget {
  const MyAttendanceCard({super.key, required this.state});

  final MyState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return _StatTrioCard(
      title: '나의 직관 기록',
      tiles: [
        ('${state.attendance.length}', '직관 경기', false),
        (state.attendanceWdl, 'MY팀 승·무·패', false),
        (state.attendanceRate, '직관 승률', true),
      ],
      body: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        padding: const EdgeInsets.only(top: 14),
        child: state.attendance.isEmpty
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined,
                      size: 16, color: MhColors.brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "경기장에 다녀왔다면 경기 상세에서 '직관 기록하기'를 눌러 저장해 보세요",
                      style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w400,
                          color: c.textSub,
                          height: 1.5),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  for (final a in state.attendance)
                    _RecordRow(
                      chip: a.result,
                      chipColor: switch (a.result) {
                        '승' => MhColors.brand,
                        '패' => const Color(0xFFE5484D),
                        _ => MhColors.closed,
                      },
                      title: a.matchLabel,
                      subtitle: '${a.dateLabel} · ${a.venue}',
                      trailing: Text(a.score, style: MhText.score(c.text, size: 16)),
                    ),
                ],
              ),
      ),
    );
  }
}

/// 나의 승부 예측.
class MyPredictionCard extends StatelessWidget {
  const MyPredictionCard({super.key, required this.state});

  final MyState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return _StatTrioCard(
      title: '나의 승부 예측',
      tiles: [
        ('${state.predictions.length}', '참여', false),
        ('${state.predictionHits}', '적중', false),
        (state.predictionRate, '적중률', true),
      ],
      body: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        padding: const EdgeInsets.only(top: 14),
        child: state.predictions.isEmpty
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.how_to_vote_outlined,
                      size: 16, color: MhColors.brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '경기 시작 전 경기 상세에서 승부를 예측해 보세요',
                      style: MhText.custom(
                          size: 12,
                          weight: FontWeight.w400,
                          color: c.textSub,
                          height: 1.5),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  for (final p in state.predictions)
                    _RecordRow(
                      chip: p.hit ? '적중' : '실패',
                      chipColor:
                          p.hit ? MhColors.brand : MhColors.closed,
                      title: p.matchLabel,
                      subtitle: '내 예측: ${p.pickLabel}',
                      trailing: Text(p.dateLabel,
                          style: MhText.caption(c.textFaint)),
                    ),
                ],
              ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.chip,
    required this.chipColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String chip;
  final Color chipColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            constraints: const BoxConstraints(minWidth: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(chip,
                style: MhText.custom(
                    size: 11, weight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MhText.custom(
                        size: 13, weight: FontWeight.w700, color: c.text)),
                Text(subtitle, style: MhText.caption(c.textSub)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
