import '../../ui/core/ui/mh_icons.dart';

/// MY "내 배지" 한 칸의 정의. 시안 `myBadges`.
///
/// **조건은 전부 앱이 이미 가진 값으로 센다** — 가이드 진행도, 직관 기록,
/// 예측 적중. 서버에 배지 테이블을 따로 두지 않는 이유는, 그랬다면 규칙을
/// 고칠 때마다 서버 배포가 필요하고 오프라인에서는 배지가 안 보이기
/// 때문이다.
///
/// 다만 **재료가 기기에만 있으면 재설치할 때 배지도 같이 사라진다.**
/// 가이드 진행도와 직관 기록을 서버로 옮기는 작업이 그래서 필요하다.
class MhBadgeSpec {
  const MhBadgeSpec({
    required this.id,
    required this.name,
    required this.glyph,
    required this.goal,
    required this.unit,
    required this.earnedLabel,
    required this.target,
    required this.colors,
  });

  /// 저장·식별용 키.
  final String id;

  /// 칸에 크게 들어가는 이름.
  final String name;

  /// 메달 안에 그릴 SVG path. 좌표계는 메달과 같은 `0 0 60 72`다.
  final String glyph;

  /// 메달 색 한 벌. 시안이 배지마다 따로 준다 (`b.r1`, `b.c1` …).
  ///
  /// **아직 시안 값이 아니다.** 디자인 파일의 배지 정의가 256KiB 상한
  /// 뒤쪽 `<script>`에 있어 읽지 못했다. 원본을 받으면 이 값들을 바꾼다.
  final MhMedalColors colors;

  /// 이 수치를 채우면 획득.
  final int goal;

  /// `3/5 레슨`의 "레슨".
  final String unit;

  /// 획득한 뒤 이름 밑에 붙는 한 줄.
  final String earnedLabel;

  /// 눌렀을 때 갈 곳.
  final MhBadgeTarget target;
}

/// 배지를 누르면 여는 화면.
enum MhBadgeTarget { guide, attendance, prediction }

/// 정의 + 지금 진행도.
class MhBadge {
  const MhBadge({required this.spec, required this.progress});

  final MhBadgeSpec spec;

  /// 지금까지 쌓인 수치. [MhBadgeSpec.goal] 이상이면 획득이다.
  final int progress;

  bool get earned => progress >= spec.goal;

  /// 진행바 비율. 0~1.
  double get ratio => (progress / spec.goal).clamp(0.0, 1.0);

  /// 시안 `b.sub` — 획득했으면 한 줄, 아니면 `3/5 레슨`.
  String get subtitle =>
      earned ? spec.earnedLabel : '$progress/${spec.goal} ${spec.unit}';
}

/// 배지 목록. 순서가 화면 순서다.
abstract final class MhBadges {
  /// 시안 메달과 같은 `0 0 60 72` 좌표계. 안쪽 원의 중심이 (30, 28)이다.
  static const _star =
      'M30 17 l3.2 6.6 7.2.9-5.3 5 1.4 7.1-6.5-3.6-6.5 3.6 1.4-7.1-5.3-5 7.2-.9z';
  static const _pin =
      'M30 15c-4.6 0-8.4 3.8-8.4 8.4 0 6.3 8.4 13.6 8.4 13.6s8.4-7.3 '
      '8.4-13.6c0-4.6-3.8-8.4-8.4-8.4zm0 11.4a3 3 0 110-6 3 3 0 010 6z';
  static const _ticket =
      'M19 21h22a2 2 0 012 2v2.5a3 3 0 000 6V34a2 2 0 01-2 2H19a2 2 0 '
      '01-2-2v-2.5a3 3 0 000-6V23a2 2 0 012-2z';
  static const _flag = 'M22 14v26M22 16h15l-3.2 5 3.2 5H22z';
  static const _check = 'M21 28l6.5 6.5L40 21';
  static const _bolt = 'M33 14l-11 16.5h7.5L27 42l11-16.5h-7.5z';

  static const all = <MhBadgeSpec>[
    MhBadgeSpec(
      id: 'guide',
      name: '핸드볼 입문',
      glyph: _star,
      goal: 5,
      unit: '레슨',
      earnedLabel: '수료 완료',
      target: MhBadgeTarget.guide,
      colors: MhMedalColors.gold,
    ),
    MhBadgeSpec(
      id: 'first_attend',
      name: '첫 직관',
      glyph: _pin,
      goal: 1,
      unit: '경기',
      earnedLabel: '첫 도장',
      target: MhBadgeTarget.attendance,
      colors: MhMedalColors.gold,
    ),
    MhBadgeSpec(
      id: 'attend_5',
      name: '직관 5경기',
      glyph: _ticket,
      goal: 5,
      unit: '경기',
      earnedLabel: '5경기 달성',
      target: MhBadgeTarget.attendance,
      colors: MhMedalColors.gold,
    ),
    MhBadgeSpec(
      id: 'venue_3',
      name: '경기장 3곳',
      glyph: _flag,
      goal: 3,
      unit: '곳',
      earnedLabel: '3곳 방문',
      target: MhBadgeTarget.attendance,
      colors: MhMedalColors.goldOutlined,
    ),
    MhBadgeSpec(
      id: 'first_hit',
      name: '첫 적중',
      glyph: _check,
      goal: 1,
      unit: '적중',
      earnedLabel: '첫 적중',
      target: MhBadgeTarget.prediction,
      colors: MhMedalColors.goldOutlined,
    ),
    MhBadgeSpec(
      id: 'hit_10',
      name: '적중 10회',
      glyph: _bolt,
      goal: 10,
      unit: '적중',
      earnedLabel: '10회 적중',
      target: MhBadgeTarget.prediction,
      colors: MhMedalColors.gold,
    ),
  ];

  /// 지금 진행도로 배지를 채운다.
  ///
  /// 진행도는 **목표를 넘어도 그대로 둔다** — `12/10`처럼 보이지 않도록
  /// 문구는 [MhBadge.subtitle]이 처리한다.
  static List<MhBadge> evaluate({
    required int guideDone,
    required int attended,
    required int venues,
    required int predictionHits,
  }) =>
      [
        for (final spec in all)
          MhBadge(
            spec: spec,
            progress: switch (spec.id) {
              'guide' => guideDone,
              'first_attend' || 'attend_5' => attended,
              'venue_3' => venues,
              _ => predictionHits,
            },
          ),
      ];

  /// 시안 `myBadgeCount` — `2/6`
  static String countLabel(List<MhBadge> badges) =>
      '${badges.where((b) => b.earned).length}/${badges.length}';
}
