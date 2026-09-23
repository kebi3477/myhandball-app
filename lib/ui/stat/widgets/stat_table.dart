import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';

/// 분석 탭 표의 숫자 열 하나.
class StatColumn {
  const StatColumn(this.label, this.width);

  final String label;
  final double width;
}

/// 시안의 표 헤더 줄 — 좌측 라벨 + 우측 정렬 숫자 열들.
class StatTableHeader extends StatelessWidget {
  const StatTableHeader({
    super.key,
    required this.first,
    required this.columns,
  });

  final String first;
  final List<StatColumn> columns;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    final style = MhText.custom(
        size: 11, weight: FontWeight.w600, color: c.textMuted);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(child: Text(first, style: style)),
          for (final col in columns) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: col.width,
              child: Text(col.label, textAlign: TextAlign.right, style: style),
            ),
          ],
        ],
      ),
    );
  }
}

/// 표의 한 줄. 카드 배경에 좌측 위젯 + 우측 정렬 숫자들.
class StatTableRow extends StatelessWidget {
  const StatTableRow({
    super.key,
    required this.columns,
    required this.values,
    required this.leading,
    this.valueColors,
  });

  final List<StatColumn> columns;
  final List<String> values;
  final Widget leading;

  /// 열별 색 지정. 시안은 득실차만 브랜드 블루로 쓴다.
  final List<Color?>? valueColors;

  @override
  Widget build(BuildContext context) {
    final c = context.mh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: leading),
          for (var i = 0; i < columns.length; i++) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: columns[i].width,
              child: Text(
                values[i],
                textAlign: TextAlign.right,
                style: MhText.custom(
                  size: 13,
                  weight: FontWeight.w700,
                  color: valueColors?[i] ?? c.text,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
