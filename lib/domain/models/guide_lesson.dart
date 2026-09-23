/// 레슨 한 스텝의 삽화 종류. 시안 `step.scene`과 같다.
enum GuideScene {
  intro,
  time,
  win,
  court,
  positions,
  steps3,
  sec3,
  seven,
  goalkeeper,
  cards,
  twoMinutes,
}

class GuideStep {
  const GuideStep({
    required this.scene,
    required this.title,
    required this.body,
  });

  final GuideScene scene;
  final String title;
  final String body;
}

class GuideQuiz {
  const GuideQuiz({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explain,
  });

  final String question;
  final List<String> options;
  final int answerIndex;
  final String explain;
}

class GuideLesson {
  const GuideLesson({
    required this.id,
    required this.title,
    required this.steps,
    required this.quiz,
  });

  final String id;
  final String title;
  final List<GuideStep> steps;
  final GuideQuiz quiz;

  /// 스텝들 + 퀴즈 1장.
  int get pageCount => steps.length + 1;

  String get subtitle => '${steps.length}단계 · 퀴즈 1문항';
}

/// 시안 `LESSONS`.
///
/// 5번 레슨은 디자인 파일이 256KiB 상한에서 잘려 원문을 보지 못했다.
/// 남아 있던 씬 이름(`cards`, `twomin`)에 맞춰 내용을 채웠으므로,
/// 원문을 확인하면 문구를 맞춰야 한다.
abstract final class HandballGuide {
  static const lessons = <GuideLesson>[
    GuideLesson(
      id: 'l1',
      title: '핸드볼 기본',
      steps: [
        GuideStep(
          scene: GuideScene.intro,
          title: '7명 vs 7명',
          body: '한 팀 7명(필드 6명 + 골키퍼 1명)이 공을 손으로 패스하고 던져서 '
              '상대 골대에 넣는 스포츠예요.',
        ),
        GuideStep(
          scene: GuideScene.time,
          title: '경기 시간은 60분',
          body: '전반 30분, 후반 30분이고 사이에 10분을 쉬어요. '
              '공수 전환이 쉴 새 없이 이어져서 정말 빨라요!',
        ),
        GuideStep(
          scene: GuideScene.win,
          title: '골을 더 많이 넣으면 승리',
          body: '공이 골라인을 완전히 넘으면 1점! '
              '한 경기에 두 팀 합쳐 50골 넘게 터지는 경우가 많아요.',
        ),
      ],
      quiz: GuideQuiz(
        question: '한 팀이 코트에서 동시에 뛰는 선수는 몇 명일까요?',
        options: ['6명', '7명', '11명'],
        answerIndex: 1,
        explain: '필드 플레이어 6명 + 골키퍼 1명, 총 7명이에요.',
      ),
    ),
    GuideLesson(
      id: 'l2',
      title: '코트와 포지션',
      steps: [
        GuideStep(
          scene: GuideScene.court,
          title: '골 에어리어는 골키퍼만',
          body: '골대 앞 6m 구역은 골키퍼만 들어갈 수 있어요. '
              '공격수는 선 밖에서 점프해 공중에서 슛을 던져요.',
        ),
        GuideStep(
          scene: GuideScene.positions,
          title: '7개의 포지션',
          body: '양쪽 윙(LW·RW), 백 3명(LB·CB·RB), 수비 사이를 파고드는 피벗(PV), '
              '그리고 골키퍼(GK). 센터백은 공격을 지휘하는 사령관이에요.',
        ),
      ],
      quiz: GuideQuiz(
        question: '골 에어리어(6m 안)에 들어갈 수 있는 선수는?',
        options: ['누구나', '골키퍼만', '공격수만'],
        answerIndex: 1,
        explain: '골 에어리어는 골키퍼만의 공간! '
            '공격수가 밟고 슛하면 골이 인정되지 않아요.',
      ),
    ),
    GuideLesson(
      id: 'l3',
      title: '공을 다루는 법',
      steps: [
        GuideStep(
          scene: GuideScene.steps3,
          title: '최대 3걸음',
          body: '공을 잡고 최대 3걸음까지 움직일 수 있어요. '
              '더 가고 싶다면 드리블하거나 패스해야 해요.',
        ),
        GuideStep(
          scene: GuideScene.sec3,
          title: '최대 3초',
          body: '공을 들고 있을 수 있는 시간은 3초! 빠르게 패스하거나 슛해야 해요.',
        ),
      ],
      quiz: GuideQuiz(
        question: '공을 들고 최대 몇 걸음까지 걸을 수 있을까요?',
        options: ['1걸음', '2걸음', '3걸음', '자유롭게'],
        answerIndex: 2,
        explain: '3걸음까지 OK! 4걸음째부터는 반칙이에요.',
      ),
    ),
    GuideLesson(
      id: 'l4',
      title: '7m 드로와 골키퍼',
      steps: [
        GuideStep(
          scene: GuideScene.seven,
          title: '7m 드로 = 핸드볼의 페널티킥',
          body: '명확한 득점 기회를 반칙으로 막으면, '
              '7m 라인에서 골키퍼와 1대1로 슛할 기회가 주어져요.',
        ),
        GuideStep(
          scene: GuideScene.goalkeeper,
          title: '골키퍼는 마지막 방어선',
          body: '골키퍼는 골 에어리어 안에서 몸 어디로든 공을 막을 수 있어요. '
              '선방 하나가 경기 흐름을 통째로 바꾸기도 해요.',
        ),
      ],
      quiz: GuideQuiz(
        question: '7m 드로는 어떤 상황에 주어질까요?',
        options: ['공이 선을 넘었을 때', '명확한 득점 기회를 반칙으로 막았을 때', '경기 시작할 때'],
        answerIndex: 1,
        explain: '확실한 득점 기회를 반칙으로 막으면 7m 드로! 골키퍼와 1대1이에요.',
      ),
    ),
    GuideLesson(
      id: 'l5',
      title: '반칙과 벌칙',
      steps: [
        GuideStep(
          scene: GuideScene.cards,
          title: '경고는 옐로카드',
          body: '거친 몸싸움이나 반복된 반칙에는 옐로카드가 나와요. '
              '한 팀이 받을 수 있는 옐로카드는 최대 3장이에요.',
        ),
        GuideStep(
          scene: GuideScene.twoMinutes,
          title: '2분 퇴장',
          body: '반칙이 심하면 2분 동안 코트 밖으로 나가야 해요. '
              '그동안 팀은 한 명 적게 싸워야 하니 아주 불리해져요.',
        ),
      ],
      quiz: GuideQuiz(
        question: '2분 퇴장을 받으면 어떻게 될까요?',
        options: ['교체 선수가 대신 들어간다', '2분 동안 한 명 적게 뛴다', '즉시 경기에서 빠진다'],
        answerIndex: 1,
        explain: '2분 동안 빈자리를 채울 수 없어요. 그래서 수적 열세가 됩니다.',
      ),
    ),
  ];
}
