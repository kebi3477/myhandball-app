# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

마이핸드볼(MyHandball) 앱. 한국 핸드볼 리그(H리그)의 일정·순위·팀 정보를 제공한다.

기존에 **React 웹 + WKWebView 래퍼**로 iOS 스토어에 배포돼 있던 것을(v1.1.0, 빌드 3) **Flutter 네이티브 앱**으로 전환하는 작업이다. 백엔드(NestJS)는 기존 것을 그대로 쓴다.

- v1 웹: `/Users/kebi/projects/_legercy/myhandball/apps/web` (React 18 + Vite + SCSS Modules + Recoil, 화면 7개)
- v1 iOS: `/Users/kebi/projects/_legercy/myhandball-ios` (SwiftUI + WKWebView 껍데기)
- API: `../myhandball-api` (NestJS, **이 저장소에서 직접 수정하지 않는다** — 아래 참조)

### 구현 현황

**시안의 화면은 모두 이식됐다.** `lib/`에 `TODO`가 남아 있지 않다.

| 영역 | 상태 |
|---|---|
| 디자인 토큰 · 테마 (`lib/ui/core/themes/`) | 다크/라이트 2벌, 시안 `c.*` 키와 1:1 |
| 온보딩 6스텝 (닉네임 포함) | 완료 |
| 메인 4탭 — 홈 / 일정 / 분석 / MY | 완료 |
| 홈 하위 3탭 — 홈 / 승부예측 / 직관 | 완료 (랭킹·팬덤은 서버 대기) |
| 경기 상세 (중계·기록·예측·MVP) | 완료 |
| 팀 상세 (소개·전적·선수·응원) | 완료 |
| 규칙 가이드 (레슨 5개 + 퀴즈) | 완료 |
| 검색 · 선수 상세 · 선수 비교 | 완료 |
| 설정 · 시즌 선택 · 팀 선택 · 연·월 선택 | 완료 |
| 오프라인 · 서버 오류 · 비시즌 화면 | 완료 (시안 `demoState` 4종) |
| 데이터 계층 (repository + service) | 완료 — 목업 / HTTP 두 구현체 |
| **실제 API 연동** | **완료** — `API_BASE_URL`이 있으면 `HttpHandballApiService` |

### 2026-09-24 시안 개편

세 덩어리가 들어왔다.

**닉네임.** 온보딩에 5번째 스텝(인덱스 4)이 생겨 `stepCount`가 5 -> 6이 됐고,
MY 맨 위에 프로필 카드가 붙어 그 자리에서 고친다. 규칙은
`domain/models/nickname.dart` 한 곳에 있다 — 2~10자, 한글·영문·숫자.
**한 글자를 1로 세므로 `length`가 아니라 `runes.length`를 쓴다.**

저장 키는 `mh_nick`, 처음 정한 달이 `mh_joined`("2026.09 가입")다.

**랭킹에 올라가는 이름은 따로다.** `PUT /api/profile`에 닉네임과 응원팀을
올려야 적중률 랭킹에 뜬다(`ui/home/widgets/profile_sheet.dart`, `spec/sheets.md`).
`mh_nick`은 프로필을 안 만든 사람에게도 있는 기기 안의 이름이고, 프로필을
만들거나 MY에서 이름을 바꾸면 **둘이 같이 바뀐다** — 한쪽만 바꾸면 랭킹에
옛 이름이 남아 두 화면이 다른 사람처럼 보인다.

**중복은 서버만 안다.** `Nickname`이 막는 건 길이·문자·사칭 단어까지고,
이미 쓰는 이름은 저장할 때 409로 돌아온다. 그 문구는 서버가 주는 것을
그대로 띄운다.

**홈이 3탭이 됐다** (`HomeTab`, `ui/home/view_models/home_tab.dart`).
하단 4탭(`ShellTab`)과는 다른 층이다.

- **승부예측** — 프로필 · 이번 주 예측 · 적중률 랭킹 · 팬덤 적중률 · 내 예측 기록.
  **전부 서버 집계다.** 이번 주 예측은 `/api/prediction/week` 하나로 받는다 —
  예전에는 시즌 일정을 통째로 받아 경기마다 집계를 따로 불러서 6경기로
  잘라 보여줬다. **프로필이 없는 채로 예측을 고르면 시트가 먼저 열리고,
  만들고 나면 그 선택이 이어서 저장된다** (시안 `pfPending`)
- **직관** — 시즌 요약 · 경기장 도장깨기 · 다음 직관 · 직관 일지.
  직관 여부는 서버(`/api/attendance`)와 맞추고 나머지는 시즌 일정으로
  계산한다

승부예측 탭의 빨간 점은 **홈이 이미 받아 둔 경기**만 본다
(`_predictionDotProvider`). 점 하나 찍자고 시즌 일정을 미리 받으면 홈이
그만큼 늦게 뜬다.

**MY의 "내 배지"**(`my_badges_section.dart`)가 예전의 수료 배지 카드 한 장을
대신한다. **승리 요정 · 예측 고수 · 입문 수료 3종, 순서 고정**이고 못 딴 것도
흑백으로 깔고 진행바를 보여준다.

판정은 `domain/badge_service.dart` 한 곳에 있다. **조건과 획득일이 나중에
서버 기준으로 바뀌기 때문**이다. 규칙은 `spec/badges.md`와 `spec/logic.js`의
`buildBadges`에서 가져왔다.

**승리 요정만 시안과 다르다. 되돌리지 말 것.** 시안은 "응원 경기 3회 +
직관 승률 > 팀 시즌 승률"인데, 그러면 **팀이 전승일 때 영영 안 열린다** —
내 직관 승률도 100%라 차이가 0이다. 잘하는 팀을 응원할수록 불리한 조건이라
2026-09-24에 사용자가 **"직관 승리 3회"**로 바꿨다. 승률 차이는 조건에서
빠졌지만 **양수일 때만** 획득 문구에 남긴다 (`+0%p`는 말이 안 된다).

`test/badge_service_test.dart`가 이걸 포함해 판정을 고정한다.

재료(직관 기록·가이드 진행도·적중 수)는 이제 **서버에도 있어서 재설치해도
돌아온다** — 셸 진입 때 `UserRecordsRepository.sync()`가 맞춘다. 수료일은
서버 것을 쓰고 `mh_guide_done_at`에도 남기며, 그 전에 수료한 사용자는 날짜
없이 "가이드 완료"로 적는다.

같은 개편에서 직관 요약 카드의 "행운의 직관러" 배지는 **빠졌다.**

**가이드 완료 화면**(`guide_done_view.dart`)이 생겼다. 퀴즈를 맞히면 목록으로
바로 돌아가는 대신 마스코트 · 퀴즈 결과 · (마지막이면) 수료 배지를 보여주고
다음 레슨으로 넘긴다.

그 밖에 같이 맞춘 것: 셸 상단 오프라인 띠(`ApiClient.offline`), 분석 탭의
"시즌 종료" 배너(`offseasonProvider`), 팀 전적의 "득점 유형"
(`seasonRecords` — **서버가 이미 주고 있었는데 매핑만 없었다**),
선수 시트의 팀 보기·비교 버튼, 마이팀 선택 시트의 남자팀/여자팀 라벨.

### 시안 대비 단순화한 것

**규칙 가이드의 삽화.** 시안은 씬마다 320x180 인라인 SVG에 `@keyframes`
26개를 걸어 둔다. `lib/ui/guide/widgets/guide_scene_view.dart`가 **원본 SVG의
좌표·색·글자 크기를 그대로 옮겨** `CustomPainter`로 그리고, 같은 키프레임을
다시 계산한다 (2026-09-23에 시안과 대조해 다시 맞췄다).

씬을 고칠 때는 원본 SVG를 먼저 뽑아 좌표를 확인한다:

```python
# /tmp/v2.html 을 받아둔 뒤
import re
pat = re.compile(r'<sc-if value="\{\{ sc\.(\w+) \}\}"[^>]*>(<svg.*?</svg>)', re.S)
```

컨트롤러가 둘이다. `_loop`는 `infinite` 애니메이션용이고, `_entrance`는
`ghPop`·`ghCard`처럼 **한 번만 재생되고 그 자리에 멈추는**(CSS `fill-mode: both`)
등장용이다. 하나로 합쳐 반복시키면 등장이 주기마다 다시 튀어나온다.

**규칙 가이드 레슨 문구는 이제 원문이다.** 한때 파일이 잘려 4·5번 레슨을
씬 이름만 보고 지어냈는데, 2026-09-24에 `spec/lessons.md`로 원문을 받아
맞췄다. `test/guide_lesson_copy_test.dart`가 어긋나면 잡는다.

**팀 상세의 "시즌 추이" 순위 모드는 앱이 계산한다.** 연맹이 라운드별 순위를
주지 않아서, 시즌 일정의 전 경기 결과를 시간순으로 넣으며 순위표를 다시
세운다 (`HttpHandballApiService._rankTrend`). 승점 → 득실차 → 다득점 순으로
매기고, **값은 그 팀이 경기를 치른 직후에만 남긴다** — 승점 모드가 그 팀의
경기마다 한 점을 찍으므로 다른 팀만 뛴 날까지 넣으면 두 모드의 가로축
길이가 달라진다 (`test/rank_trend_test.dart`).

### 자주 밟은 함정

**`Container`에 `alignment`를 주면 제약이 허용하는 만큼 넓어진다.** `Wrap`이나
`ListView` 안의 칩에 `alignment: Alignment.center`를 주면 한 줄을 다 차지한다
(추천 검색어 칩이 그랬다). 글자 폭에 맞추려면 `alignment`를 빼고 필요하면
`Center(widthFactor: 1)`을 쓴다.

**오류 문구에 `'$e'`를 쓰지 않는다.** `ApiException`의 `toString()`이
`ApiException(null /ranking): 서버에 연결하지 못했어요`처럼 내부 정보를
그대로 노출한다. `mhErrorMessage(e)`(`ui/core/ui/error_message.dart`)를 쓴다.

**Pretendard에 `✕`(U+2715) 글리프가 없다.** 시안이 이 문자를 닫기 버튼에
쓰는데 그대로 옮기면 네모(두부)로 찍힌다. `Icons.close_rounded`로 그린다.
(`>`꼴 홑화살괄호와 하트 기호는 Pretendard에 있어서 그대로 써도 된다.)

**`MhIcon`은 부모가 크기를 조여도 `size`를 지킨다.** `SvgPicture`가 tight
제약을 받으면 자기 width/height를 버리고 부모 크기로 늘어나서, 안쪽을
`Center` + `SizedBox`로 감싸 뒀다. Material `Icon`은 글리프라 이 문제가
없어서 시안 아이콘으로 갈아끼운 뒤에야 드러났다 (`test/mh_icon_test.dart`).

**골든 프리뷰는 폰트 폴백이 없다.** 글리프가 깨진 건지 테스트 환경 탓인지
구분이 안 되므로 `tool/design_preview_test.dart`가 Pretendard와 MaterialIcons를
직접 올린다. 그래도 **글리프 문제는 시뮬레이터에서 한 번 더 확인**한다.

### 시안에서 의도적으로 뺀 것

시안은 375x812 목업 프레임 안에 **가짜 상태바(`9:41`, 배터리)와 다이나믹
아일랜드**를 그려둔다. 시안을 브라우저에서 보여주려는 장식이므로 옮기지
않았다. 실제 기기에서는 `SafeArea`가 그 자리를 차지한다.

스코어 숫자의 `font-family: Impact, Pretendard, sans-serif`도 iOS/Android에
Impact가 없어 실제로는 Pretendard로 떨어진다. `MhText.score()`가 가장 무거운
웨이트(w800)로 대신한다.

## 아키텍처

**Flutter 공식 아키텍처 가이드**(docs.flutter.dev/app-architecture)의 MVVM +
Repository 구조를 따른다.

```
lib/
├── config/              # 빌드 타임 설정 (dart-define)
├── domain/models/       # 앱 도메인 모델
├── data/
│   ├── services/        # 외부 소스 래퍼, 무상태
│   └── repositories/    # source of truth, 캐시·에러 처리
└── ui/
    ├── core/themes/     # 토큰, ThemeData, 텍스트 스타일
    ├── core/ui/         # 공유 위젯 (TeamLogo, 아이콘 페인터 등)
    └── <feature>/
        ├── view_models/
        └── widgets/
```

규칙:

- **View는 상태를 만들지 않는다.** 화면 상태는 ViewModel이 갖는다. 위젯 내부
  `State`는 애니메이션 컨트롤러·`PageController`처럼 순수 UI 자원만 둔다
- **View는 repository를 직접 부르지 않는다.** 반드시 ViewModel을 거친다
- ViewModel은 `Notifier` / `AsyncNotifier`로 구현한다. 가이드의 예제는
  `ChangeNotifier`를 쓰지만 이 프로젝트는 Riverpod을 쓰므로 역할만 같게 맞춘다
- **빈 ViewModel은 만들지 않는다.** 화면에 실제 상태가 생길 때 같이 만든다.
  지금 `schedule` / `stat` / `my` 탭에 `view_models/`가 없는 이유다
- **`GestureDetector`를 직접 쓰지 않는다. `MhTap`을 쓴다** —
  모든 탭에 진동을 걸어 두었고, 한 곳(`lib/ui/core/ui/mh_tap.dart`)에서
  정책을 바꾼다. 주요 확정 버튼은 `haptic: MhHaptic.impact`.
  `test/haptics_test.dart`가 `GestureDetector` 직접 사용을 막는다
- `routing/`은 아직 없다. 화면 전환이 4탭 `IndexedStack` + 조건부 `home`뿐이라
  라우터가 필요 없다. 경기 상세·가이드처럼 전체화면이 붙을 때 go_router를 넣는다

## 작업 경계: API 변경은 프롬프트로 넘긴다

**이 세션이 메인이다.** Flutter 앱 쪽 작업은 직접 한다.

**API(`../myhandball-api`) 코드는 직접 수정하지 않는다.** 읽는 것은 자유롭게 하되(계약 확인용), 변경이 필요하면 **API 저장소에서 작업할 다른 Claude 세션에 넘길 프롬프트를 작성**한다.

프롬프트는 **파일로 쓰지 않고 사용자에게 채팅으로 바로 준다.** 그대로 복사해 붙일 수 있게 코드블럭 하나로 감싼다. 프롬프트 본문에 마크다운 제목·코드블럭이 들어가므로 바깥 펜스는 백틱 4개(````)를 쓴다.

**예외 — 이미 파일로 나가 있는 것:** 2026-09-23에 분량이 커서(7건) 사용자 승인
하에 `../myhandball-api/docs/api-tasks/`에 파일로 작성했다. 그 문서들의 후속
수정은 파일을 고치고, **새 요청은 다시 채팅 코드블럭이 기본**이다.

프롬프트는 API 저장소만 열어둔 세션이 **이 저장소를 보지 않고도** 수행할 수 있도록 자기완결적으로 쓴다. 최소 다음을 포함한다:

- **배경** — 왜 필요한지, 앱의 어느 화면/기능이 요구하는지
- **엔드포인트** — `METHOD /api/...`, 쿼리 파라미터와 기본값
- **응답 스펙** — TypeScript 타입으로. 기존 타입 확장이면 어느 파일의 무엇인지 명시
- **하위 호환** — 기존 웹(v1)이 같은 엔드포인트를 쓰므로 필드 추가는 되지만 제거·타입 변경은 안 된다 (웹을 내린 뒤라면 그 사실을 명시)
- **검증** — curl 예시와 기대 응답

프롬프트를 준 뒤에는 API 쪽 작업이 끝나 배포될 때까지 앱에서 해당 기능을 목업/스텁으로 둔다.

### API 연동 상태 — 끝났다

`../myhandball-api/docs/api-tasks/`의 00~06이 전부 구현돼 있고, 앱도 붙어 있다.
`/api/player/:playerSeq`까지 연결돼서 **앱이 안 쓰는 엔드포인트는 위젯·푸시뿐**이고
그 둘은 네이티브 작업이 선행돼야 한다.

**API는 모두 배포돼 있다** (`../myhandball-api/docs/app-integration.md`, 2026-09-24).
그 문서에 엔드포인트별 **실제 응답 원문**이 있으니 매핑을 고칠 때 먼저 읽는다.

앱이 붙인 것:

| 엔드포인트 | 앱에서 쓰는 곳 |
|---|---|
| `GET/PUT/DELETE /api/profile` | 승부예측 프로필 시트 · MY 닉네임 편집 |
| `GET /api/prediction/leaderboard` | 승부예측 · 적중률 랭킹 (`scope=all\|team`) |
| `GET /api/prediction/fandom` | 승부예측 · 팬덤 적중률 |
| `GET /api/prediction/my` | 승부예측 · 내 예측 기록, MY의 참여·적중·적중률 |
| `POST /api/team/:teamNum/cheer/:cheerId/report` · `POST/GET/DELETE /api/block` | 응원글 신고·차단, 설정 > 차단한 사용자 |
| `GET /api/app/version` | 업데이트 안내 (iOS만 설정됨, android는 404) |
| `GET /api/prediction/week` | 승부예측 · 이번 주 예측 (경기 + 집계 + 내 선택을 한 번에) |
| `GET/PUT/DELETE /api/attendance` | 직관 기록 |
| `GET/PUT /api/progress/guide` | 가이드 진행도 · 수료일 |
| `GET/PUT/DELETE /api/favorites/players` | 관심 선수 |
| `GET /api/season` | 비시즌 카드의 다음 시즌 개막일 (`nextOpensAt`) |

**앱이 안 쓰는 건 위젯·푸시 엔드포인트뿐이고**, 그 둘은 네이티브 작업이
선행돼야 한다.

- **선수의 최근 경기별 기록** — 시안 선수 시트에 "최근 5경기"가 있는데
  `/api/player/:playerSeq`는 시즌 단위만 준다. 경기별은 `/api/game/:matchSeq`를
  경기마다 받아야 해서 시트에 넣기엔 무겁다. 아직 구현하지 않았다

### 기기와 서버에 같이 있는 기록 — `UserRecordsRepository`

직관 기록 · 관심 선수 · 가이드 진행도는 규칙이 같아서 **한 곳**에서 맞춘다
(`data/repositories/user_records_repository.dart`). 따로 짜면 한쪽만 대기열을
안 비우는 식으로 어긋난다. 셸에 들어올 때 `sync()`를 한 번 부른다.

- **화면은 언제나 기기 값을 읽는다.** 서버를 기다렸다 그리면 도장을 찍고
  한 박자 뒤에 체크가 들어온다
- **쓰기는 서버 응답을 기다리지 않는다.** 기다리면 체크 하나에 최대 8초
  (요청 타임아웃)가 걸린다. 실패하면 `mh_sync_pending`에 남고 다음 동기화
  때 다시 올라간다 (시안 토스트: "기기에 저장했어요. 연결되면 자동으로
  동기화돼요."). 테스트는 `settled()`로 그 쓰기를 기다린다
- **첫 동기화만 합집합**이다(`mh_synced`). 앱을 쓰다 서버가 생긴 상황이라
  기기에 쌓인 기록을 버리면 안 된다. 그 뒤로는 서버가 정본이고, **덮어쓴
  다음 대기열을 다시 얹는다** — 안 그러면 오프라인에서 찍은 도장이 화면에서
  잠깐 사라진다
- **진행도는 줄지 않는다.** 응답이 늦게 도착하므로 그대로 덮어쓰면 그 사이에
  끝낸 레슨이 되돌아간다 (`applyGuideProgress`가 큰 값을 지킨다). 서버도
  같은 규칙이다
- `matchSeq`/`playerSeq`가 없는 항목은 서버에 못 보낸다 — 상세가 없는 경기
  (`g{matchSeq}` 꼴이 아닌 id)나 `n:이름` 꼴의 선수다. 기기에만 남기고
  동기화가 지우지 않는다

`test/user_records_sync_test.dart`가 이 규칙들을 고정한다.

### 서버 값과 기기 값이 갈리지 않게 하기

프로필·예측 기록은 **서버가 정본**이고 기기 값은 **못 받았을 때만** 쓰는
사본이다. 조회 실패를 "없음"으로 다루면 안 된다:

- 프로필 조회가 실패했는데 `null`로 두면, 지하철에서 앱을 연 사람에게
  "프로필을 만들어 보세요"가 뜨고 거기서 저장하면 닉네임 중복(409)으로
  막힌다. `ProfileRepository`가 마지막 응답을 `mh_profile`에 적어 두고
  실패하면 그걸 쓴다
- 적중 수를 화면마다 따로 세면 승부예측 탭과 MY의 「예측 고수」 배지가 다른
  숫자를 말한다. 둘 다 `MyPredictions`(서버 집계)를 먼저 보고, 없을 때만
  기기의 `mh_preds`로 센다
- 랭킹·팬덤을 **못 받았을 때 빈 목록을 그리지 않는다.** "아직 아무도 없다"와
  "연결이 안 됐다"가 같은 화면이 되면 안 된다 (`PredictionState.leaderboard`가
  `null`이면 그 섹션만 "다시 시도"를 띄운다)

### 푸시 (마이팀 경기)

`firebase_messaging`으로 FCM 토큰을 받아 `POST /api/push/register`에 등록한다.
받는 알림은 **경기 시작 10분 전 · 득점(120초로 묶임) · 경기 종료** 세 가지다.

**"내 팀만"은 서버가 한다.** 서버가 `teamNum: In([홈, 원정])`으로 대상을 고르므로
앱은 **마이팀 번호를 정확히 등록하고 바뀌면 다시 등록**하면 된다. 구독을 맞추는
자리는 `syncPushSubscription`(`ui/core/ui/push_sync.dart`) 하나이고, 세 곳에서 부른다:

| 시점 | 동작 |
|---|---|
| 셸 진입(온보딩 후) | 권한 요청 → 토큰 등록 |
| 마이팀 변경 | 재등록 — 안 하면 이전 팀 알림이 계속 온다 |
| 알림 토글 끔 | `DELETE /push/register` — 서버에서 토큰을 지운다 |

마이팀이 없거나 권한이 거부되면 등록하지 않고 해제한다.
알림을 누르면 payload의 `data.matchSeq`로 경기를 찾아 상세를 연다.

**Firebase 설정 파일이 없으면 조용히 꺼진다.** `Firebase.initializeApp()` 실패를
잡아 `PushService.available = false`로 두고 전부 no-op 한다 — 푸시 때문에 앱이
안 뜨면 안 된다. 실제로 알림을 받으려면:

1. Firebase 프로젝트 → `GoogleService-Info.plist`(iOS) · `google-services.json`(Android)
2. Android: `google-services` Gradle 플러그인 추가
3. iOS: Push Notifications + Background Modes(Remote notifications) capability,
   **APNs 인증 키(.p8)를 Firebase 콘솔에 등록**
4. 서버 `.env`의 `FCM_*` — 없으면 서버가 드라이런(로그만)이다

### 외부로 나가는 동작

`url_launcher`(링크)와 `share_plus`(.ics 공유)를 쓴다. **눌렀는데 아무 일도
안 일어나는 상태를 만들지 않는다** — 실패하면 `ui/core/ui/external_actions.dart`가
스낵바로 알린다.

| 동작 | 대상 |
|---|---|
| 중계 보기 | 경기별 네이버 중계 링크(`liveLinks`), 없으면 `AppConfig.broadcastUrl` |
| 예매하기 | `AppConfig.ticketUrl` (티켓링크) |
| 개인정보 처리방침 · 이용약관 | `https://myhandball.lab241.com/privacy` · `/terms` |
| 캘린더에 추가 · 내보내기 | 앱에서 만든 `.ics` (`domain/ics.dart`) |

**정책 문구는 앱에 넣지 않는다.** 고칠 때마다 심사를 다시 받아야 해서 서버로
뺐다. API가 같은 원본으로 JSON(`/api/policy/{privacy,terms}`)과 웹페이지
(`.../page`)를 주고, **짧은 주소 `/privacy`·`/terms`는 Caddy가 rewrite** 한다.

그래서 이 두 URL은 `apiBaseUrl`에서 파생시키지 않는다 — NestJS 직통
(로컬 `:3000`)에는 짧은 주소가 없어서 404다. 로컬 API로 개발할 때도 정책
링크는 운영 페이지를 연다.

`.ics`는 서버에도 `/api/schedule/ics/my-team`이 있지만 **시즌 전체만** 준다.
경기 하나만 넣는 버튼과 경로를 하나로 두려고 앱에서 만든다. `test/ics_test.dart`가
형식을 잡아 준다 — 한 글자 틀리면 캘린더가 통째로 안 연다.

남은 후속 과제는 앱이 아니라 서버 쪽이고 `../myhandball-api/docs/api-tasks/07-후속-작업.md`에 있다.
그중 **앱에 직접 영향 있는 것**:

- **경기 중 PBP가 실시간으로 갱신되는지 아직 확인 못 했다** (조사 시점이 비시즌).
  틀리면 LIVE 뱃지·중계 탭·득점 푸시가 조용히 안 나온다. 개막(11월) 첫 경기에
  확인이 필요하다
- 서버는 인증서를 수동 갱신한다. **앱은 만료되면 통째로
  먹통이 된다** (아래 "서버 상태")

## 커밋

**작업이 한 단락 끝나면 커밋까지 알아서 한다.** 따로 요청을 기다리지 않는다.

- 커밋 전에 `flutter analyze`와 `flutter test`가 통과하는지 확인한다
- **메시지는 한국어 한 줄만 쓴다.** 본문·불릿·부연 설명을 붙이지 않는다
- 푸시는 하지 않는다 (요청받았을 때만)

## 명령어

```bash
flutter analyze                          # 정적 분석
flutter test                             # 전체 테스트 (test/ 만)
flutter test test/widget_test.dart       # 파일 단위
flutter test --plain-name "테스트 이름"    # 단일 테스트
flutter run                              # 개발 실행
flutter build ios --no-codesign --debug  # iOS 빌드 검증 (서명 없이)

# 개발용 플래그 (lib/config/app_config.dart)
flutter run \
  --dart-define=MH_SKIP_ONBOARDING=true \  # 온보딩 건너뛰기 (마이팀도 자동 지정)
  --dart-define=MH_INITIAL_TAB=stat \      # home / schedule / stat / my
  --dart-define=MH_INITIAL_THEME=light \   # 기본은 시안대로 dark
  --dart-define=MH_OPEN_GUIDE=true         # 규칙 가이드를 바로 연다

# 화면 전체를 PNG로 떠서 레이아웃 확인 (tool/preview/*.png, gitignore됨)
flutter test --update-goldens tool/design_preview_test.dart
```

`tool/`은 `flutter test`의 기본 대상(`test/`)에 없으므로 CI를 깨지 않는다.
프리뷰 PNG는 테스트 환경이라 **본문이 네모로 렌더된다** — 커스텀 폰트가
로드되지 않아서다. 레이아웃 확인용이고, 타이포 확인은 시뮬레이터로 한다.

**기본 API 서버는 `https://myhandball.lab241.com`이다** (`AppConfig.apiBaseUrl`).
dart-define 없이 빌드하면 운영 서버를 본다.

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000   # 로컬 API
flutter run --dart-define=MH_USE_MOCK=true                     # 목업
```

예전에는 기본값이 비어 있어 **dart-define을 빠뜨리면 목업이 배포되는** 구조였다.
잊기 쉬운 쪽이 망가지면 안 되므로 뒤집었다. 목업은 이제 명시적으로 켠다.
"데이터가 이상하다" 싶으면 기동 로그의 `[MyHandball] 데이터 소스:` 줄을 본다.

```bash
# 실제 서버에 붙여 전 엔드포인트 점검 (네트워크 필요, CI는 안 돌린다)
flutter test tool/api_smoke_test.dart --dart-define=API_BASE_URL=http://localhost:3000
```

### 실기기에서 로컬 API에 붙이기

**`localhost`를 그대로 쓰면 안 된다.** 실기기에서 `localhost`는 폰 자신이라
맥의 서버에 닿지 않는다. 맥의 LAN IP를 넣는다.

```bash
ipconfig getifaddr en0                       # 예: 192.168.45.37
flutter run -d <기기> \
  --dart-define=API_BASE_URL=http://192.168.45.37:3000
```

전제:

- 폰과 맥이 **같은 Wi-Fi**에 있어야 한다 (게스트망·AP 격리 주의)
- API 서버는 `0.0.0.0:3000`에 바인딩돼 있다 (`myhandball-api/src/main.ts`) —
  따로 손댈 것 없다
- iOS 16+는 **설정 > 개인정보 보호 및 보안 > 개발자 모드**를 켜야 기기가 잡힌다
- 첫 실행 때 **"로컬 네트워크 기기 검색" 권한 팝업**이 뜬다. 거부하면 요청이
  전부 실패한다. 실수로 거부했으면 설정 > 마이핸드볼에서 다시 켠다

**`NSAllowsLocalNetworking`은 2026-09-24에 뺐다.** 남겨 두면 앱을 처음 켤 때
"로컬 네트워크 기기 검색" 권한 팝업이 뜬다 — 운영은 https라 쓰지도 않는
권한을 묻는 꼴이다. 실기기로 로컬 API를 칠 일이 있으면 `Info.plist`의
주석에 적어 둔 두 키를 잠깐 되살리고 **커밋하지 않는다.**

**주의 — 번들 ID가 스토어 배포본과 같다**(`com.kebi.myhandball-ios`).
실기기에 디버그 빌드를 깔면 **스토어에서 받은 앱을 덮어쓴다.** 원래대로
되돌리려면 지우고 App Store에서 다시 받아야 한다.

**Android는 아직 빌드 불가** — `flutter doctor`가 cmdline-tools 누락을 보고한다. Android Studio에서 SDK Command-line Tools 설치 후 `flutter doctor --android-licenses` 필요.

## API 계약

전 엔드포인트가 `/api` 프리픽스를 가진다. 인증 없음. 모든 데이터는 koreahandball.com을 cheerio로 스크래핑해 Redis에 캐시한 결과다(팀 목록 TTL 24h).

| 엔드포인트 | 쿼리 | 응답 |
|---|---|---|
| `GET /api/schedule` | `gender`(`W`/`M`/``), `season`, `type`, `month` | `ScheduleResponse` — `days[].games[]` |
| `GET /api/schedule/ics/my-team` | `gender`, `season`, `type`, `teamName`(필수) | `text/calendar` ICS 본문 |
| `GET /api/ranking` | `gender`(`W`/`M`), `season`, `type` | `RankingResponse` — `items[]` |
| `GET /api/team` | `gender` | `TeamListResponse` — `teams[]` |
| `GET /api/game/:matchSeq` | — | `GameDetailResponse` — 전·후반, 팀 기록, 선수별 기록 |
| `GET /api/game/:matchSeq/live` | — | `GameLiveResponse` — 중계 이벤트, 경기 상태 |
| `GET /api/game/:matchSeq/prediction` | — | 예측 분포 + 내 선택 |
| `POST /api/game/:matchSeq/prediction` | `{ pick }` | 시작 후면 `409` |
| `GET/POST /api/game/:matchSeq/mvp` | `{ playerSeq, playerName }` | 종료 전·재투표면 `409` |
| `GET /api/player` | `gender`, `season`, `type` | 선수 목록 + 시즌 기록 |
| `GET /api/player/:playerSeq` | — | 프로필 + 통산·시즌별 기록 |
| `GET /api/player/ranking` | `+ category` | 카테고리별 TOP5 |
| `GET /api/team/:teamNum` | `gender`, `season`, `type` | 구단 소개·코칭스태프·명단·전적 |
| `GET/POST/DELETE /api/team/:teamNum/cheer` | `gender`, `page` | 응원글. 하루 5개 초과 `429` |
| `GET /api/widget/my-team` | `teamNum`, `gender` | 위젯용 경량 응답 (네이티브 위젯이 쓴다) |
| `POST /api/push/register` | `{ token, platform, teamNum, gender }` | FCM 토큰 등록 |
| `POST /api/welcome/submissions` | — | 온보딩 선택값을 Postgres에 기록 |

쓰기 엔드포인트는 **인증이 없고 익명 기기 UUID를 `X-Device-Id` 헤더로** 받는다
(영문·숫자·하이픈 8~64자). `ApiClient`가 모든 요청에 붙인다.

**이 값은 iOS Keychain에 있다** (`data/services/device_id_store.dart`).
`shared_preferences`에만 두면 앱을 지웠다 깔 때마다 새 사람이 되는데, 그러면

- 서버에 남은 내 예측·응원글을 다시 못 찾고
- **같은 경기에 MVP를 다시 투표할 수 있어 집계가 오염된다**

Keychain은 앱을 지워도 항목이 남는다 (Apple이 문서로 보장하진 않지만 실제로
그렇게 동작한다). 예전 버전에서 올라온 사용자는 `shared_preferences`에 있던
값을 그대로 이어받는다. **안드로이드는 이걸로 해결되지 않는다** — 암호화
저장소도 앱을 지우면 같이 지워진다.

문서와 실제 응답이 다른 부분은 `../myhandball-api/docs/api-tasks/07-후속-작업.md`
**C절**에 표로 정리돼 있다. 매핑을 고칠 때 먼저 읽는다.

`season`은 **시작 연도 문자열**이다: `"2025"` = 25-26 시즌. `type`은 리그 구분(`"1"`, `"2"`).

주의할 필드:
- `GameItem.scoreText` — `"28 : 26"` 또는 `"- : -"` 같은 **문자열**이다. 숫자가 아니고, 실시간 갱신도 아니다.
- `GameItem.liveLinks[]` — 네이버 등 외부 중계 링크. v1은 `provider === "naver"`를 우선 선택했다.
- `DayBlock.dateISO`는 null일 수 있다. `dateLabel`(원문)만 있는 경우가 있다.

정확한 타입 정의는 `../myhandball-api/src/{schedule,ranking,team}/types.ts`를 직접 읽는다.

### 팀 로고

로고 URL은 `https://www.koreahandball.com/static/images/logo/logo_{m|w}_{teamNum}.png`
형식이다. 목업의 팀 번호는 연맹 사이트의 팀 소개 페이지
(`/introduce/team_men.php`, `/introduce/team_women.php`)에서 확인한 실제 값이다.

### 경기 상태와 중계

`GameItem.status`(`pre`/`live`/`finished`)를 **서버가 판정해서 준다.** v1 웹이
클라이언트에서 시각으로 추정하던 걸 서버로 올린 결과다. 앱은 값이 없을 때만
`startsAt`으로 추정한다 (`HttpHandballApiService._status`).

중계는 연맹의 PBP(`playbyplay.php`)를 서버가 60초마다 폴링해 쌓은 것이다.
`GameLiveResponse.source`가 `polling`이면 경기 중 수집분, `final`이면 종료 후
확정 기록이다.

**단, 경기 중에 PBP가 실제로 갱신되는지는 아직 검증되지 않았다.** 개막 후
첫 경기에서 확인해야 하고, 안 되면 LIVE 관련 기능을 줄여야 한다 (API 07 A-1).

### 일정 탭의 연·월 선택

시안이 2026-09-24에 바뀌어 월 라벨이 **연·월 선택 바텀시트를 여는 칩**이
됐다 (`year_month_picker.dart`). 같은 개편에서 설정의 **"튜토리얼 다시 보기"가
빠졌다** (`restartOnboarding`도 같이 지웠다).

**연도를 고르면 시즌도 같이 바뀐다.** API의 `month`는 "시즌 안의 월"이라
연도만 바꾸면 엉뚱한 시즌을 조회한다 — 2024년 12월은 24-25 시즌, 2026년 4월은
25-26 시즌이다. `ScheduleViewModel.setYearMonth`가 `Season.at`으로 시즌을
정하고 `prefs.season`까지 갱신해 다른 탭과 어긋나지 않게 한다.

경기가 없는 달은 흐리게 보여주는데, **받아둔 시즌의 달만** 그렇게 한다.
다른 시즌은 경기가 있는지 모르므로 흐리게 하지 않는다.

### 분석 탭의 "시즌 종료" 안내

**순위 탭에만 띄운다.** 비시즌에 순위표만 덩그러니 있으면 진행 중인 시즌으로
읽히지만, 기록·팀·선수는 애초에 시즌 합계라 오해할 여지가 없다. 네 탭 모두에
띄우면 같은 문장이 탭을 옮길 때마다 따라다니며 목록 자리만 먹는다
(2026-09-24에 사용자가 정했다).

### 비시즌 "가까운 경기" 카드

시안은 **개막일을 이미 아는 경우만** 그려 놨다 (`D-53`·`11월 14일(토)`이
전부 리터럴이고 `logic.js`에도 로직이 없다). 그런데 **연맹이 다음 시즌
일정을 올리기 전에는 개막일을 알 방법이 없고**, 비시즌 내내 그 상태다.

2026-09-24에 디자인이 정해 준 규칙(B안)대로 큰 자리가 셋으로 갈린다
(`offseason_card.dart`의 `_Headline`):

| 상황 | 큰 자리 | 아래 한 줄 |
|---|---|---|
| 개막일을 안다 | `D-53` (디스플레이 44) | `… · 11월 14일(토) 개막 예정이에요` |
| 개막 달만 안다 | `11` + `월` (44 + 20/800) | `… · 일정이 나오면 알려드릴게요` |
| 개막 달에 들어섰다 | `이번 달` (32/800) | 위와 같음 |

- **개막 달은 마이팀의 부를 따른다** — 남자부 11월, 여자부 1월.
  마이팀이 없으면 남자부다
- **알림이 꺼져 있으면** 아래 줄이 `… · 개막 일정 발표 전이에요`로 바뀐다.
  지킬 수 없는 약속을 하지 않는다
- **숫자와 "월"을 따로 그린다.** 디스플레이 폰트(Anton)에 한글이 없어서 한
  덩어리로 쓰면 "월"만 다른 글꼴로 대체되고 크기가 어긋난다
- 날짜를 추정해 D-day를 만들지 않는다. 일주일만 어긋나도 카운트다운이 계속
  틀린 채로 떠 있는다
- 개막일은 **`GET /api/season`의 `nextOpensAt`이 먼저**고, 서버도 모르면
  다음 시즌 일정에서 첫 경기를 찾는다. 둘 다 없으면 `null`이다
  (2026-09-24 현재 `nextOpensAt`은 null — 연맹이 26-27 일정을 안 올렸다)
- **개막일은 마이팀의 부로 찾는다.** 순위 토글(`HomeState.gender`)로 찾으면
  여자부 팀을 응원하는 사람이 홈에서 남자부를 한 번 누른 순간 11월 개막일이
  1월 개막 문구 옆에 붙는다

### 시즌은 날짜로 정해진다

**H리그는 11월에 개막한다**(여자부는 1월). 그래서 시즌은 11월에 넘어간다:

| 시점 | 시즌 |
|---|---|
| 2025.11 ~ 2026.10 | `2025` (25-26) |
| 2024.11 ~ 2025.10 | `2024` (24-25) |

비시즌(5~10월)에는 **직전에 끝난 시즌**을 본다. 개막 전에 빈 화면을 주는
것보다 방금 끝난 시즌을 보여주는 쪽이 맞다. `Season.current`가 이걸 계산하고
`test/season_test.dart`가 경계를 고정한다.

**일정 탭은 오늘 달을 그냥 열지 않는다.** 비시즌이면 빈 달이 되므로,
`ScheduleRepository.getFocusMonth`가 시즌에서 **경기가 있는 달** 중 오늘에
가장 가까운 달을 고른다. 남자부 11월 / 여자부 1월로 개막이 달라서, 부를
바꿀 때도 시작 달을 다시 고른다.

### 팀 이름 — 서버가 통일한다

**팀 이름의 정본은 `/api/team` 목록의 이름이다** (`상무피닉스`, 공백 없음).
한때 일정·순위만 `상무 피닉스`로 공백이 있어 어긋났는데, 2026-09-23에 서버가
`TeamService.canonicalNames()`로 통일했다. 못 찾으면 원본을 두고 warn한다.

`HttpHandballApiService._key`도 공백을 빼고 매칭하지만 **지금은 안전망일 뿐**이다.
남겨 둔 이유는 배포된 서버가 구버전일 때 이 불일치가 **조용한 실패**로 나타나기
때문이다 — `Team`은 이름으로 같은 팀인지 판단하므로, 마이팀이 상무인 사용자의
달력과 다음 경기가 에러 없이 그냥 빈다.

**여자부 25-26 시즌은 1월 개막이다** (남자부는 11월). 11·12월 일정을 조회하면
정상적으로 0경기가 나온다 — 버그가 아니다.

## 디자인 원본

### `spec/` — 스크립트 추출본을 먼저 본다

**`get_file`은 256KiB에서 자른다. `MyHandball v2.dc.html`이 그걸 넘어서
`<script>`는 한 글자도 못 읽는다.** 마크업(~1839줄)까지만 온다. 그래서
배지·레슨·문구·계산 규칙처럼 **마크업이 `{{ }}`로 참조만 하고 값은
스크립트에 있는 것**은 도구로 못 가져온다. 여기서 값을 지어내면 안 된다 —
실제로 배지 6종과 레슨 두 개를 지어냈다가 전부 다시 만들었다.

디자인 세션이 뽑아 준 추출본이 저장소의 `spec/`에 있다:

| 파일 | 내용 |
|---|---|
| `spec/logic.js` | 로직 클래스 원문 전체(~134KiB). **`renderVals()`가 모든 `{{ }}` 값을 만든다.** 아래 문서에 없는 값은 여기서 변수명으로 grep |
| `spec/lessons.md` | 입문 가이드 레슨 5개 (스텝·퀴즈) |
| `spec/copy.md` | 스크립트가 만드는 문구와 분기 |
| `spec/rules.md` | 랭킹·팬덤·승률·비시즌·경기 상태 계산 규칙 |
| `spec/badges.md` | MY 탭 배지 3종 |

`spec/copy.md`의 문구와 `spec/lessons.md`의 레슨은 **테스트가 파일을 직접
읽어 대조한다** (`test/copy_spec_test.dart`, `test/guide_lesson_copy_test.dart`).
아직 구현 안 한 기능의 문구는 `copy_spec_test.dart`의 `pending`에 이유와 함께
적혀 있다 — 기능이 생기면 거기서 지운다.

**시안 값이 필요하면 `spec/`을 먼저 찾는다. 없으면 멈추고, 디자인 세션에
넘길 프롬프트를 만들어 사용자에게 준다.** 추측해서 채우지 않는다.

프롬프트는 API 요청과 같은 방식으로 — **파일이 아니라 채팅 코드블럭**(바깥
펜스는 백틱 4개)으로 주고, 무엇이 필요한지 **변수명까지** 적고 "요약 말고
실제 문자열 그대로" 달라고 명시한다. 사용자가 디자인 세션에 전달해 추출본을
받아다 `spec/`에 넣어 준다.

추측해서 두 번 버렸다 — MY 배지를 6종으로 만들었는데 실제는 3종이었고,
가이드 4·5번 레슨 문구를 씬 이름만 보고 채웠는데 원문과 달랐다.
**화면만 봐서는 틀린 줄 모르는 종류**라 사용자가 직접 지적할 때까지 남는다.
원본을 받으면 `spec/`을 직접 읽어 대조하는 테스트를 붙인다
(`test/guide_lesson_copy_test.dart`).

claude.ai/design 프로젝트 `35487a25-4404-4bd0-b14e-61e54038f816` ("마이핸드볼").

`claude.ai/design/p/<uuid>` 링크는 WebFetch로 403이고 Artifact 도구도 거부한다. **DesignSync 도구의 read 메서드로 읽는다** (권한 프롬프트 없음):

```
DesignSync(method="list_files", projectId="35487a25-4404-4bd0-b14e-61e54038f816")
DesignSync(method="get_file",  projectId="...", path="MyHandball v2.dc.html")
```

주요 파일:
- `MyHandball v2.dc.html` (258KB, ~1,970줄) — 앱 전체 시안. 단일 React 유사 컴포넌트에 전 화면이 들어있다
- `MyHandball Widget.dc.html` — 홈스크린 위젯 시안
- `figassets/`, `assets/` — 아이콘, 스티커 8종, 하이라이트 이미지

`get_file` 결과가 크면 tool-results 파일로 떨어진다. python으로 JSON 언이스케이프 후 grep하면 된다.

**주의 — `get_file`은 256KiB에서 잘린다.** `MyHandball v2.dc.html`이 이 상한을
넘어서, **스크립트 뒷부분(`renderVals` 상당 부분과 `LESSONS` 뒤쪽)이 잘린 채
온다.** `truncated: false`로 와도 실제로는 잘려 있다. 마크업(1~1665줄)은
온전하므로 레이아웃·색상 리터럴은 거기서 읽으면 된다.

에셋은 `get_file`이 base64를 인라인으로 뱉어 컨텍스트를 크게 먹는다.
**v2.html을 로컬에 받아둔 뒤 python으로 인라인 SVG를 추출**하는 쪽이 싸다
(`assets/design/*.svg`가 그렇게 만들어졌다). 별도 파일로 존재하는
일러스트(`figassets/*.svg`, `*.png`)는 사용자가 내보내 넣는다 —
`assets/figassets/README.md` 참조.

**에셋이 큰 PNG면 `get_file` 결과가 tool-results 파일로 떨어진다.** 그때는
base64를 컨텍스트로 들이지 말고 파일에서 바로 디코딩한다:

```python
d = json.load(open('<tool-results 경로>'))
open('assets/figassets/' + d['path'].split('/')[-1], 'wb').write(
    base64.b64decode(d['content']))
```

에셋 누락은 화면만 봐서는 플레이스홀더와 구분이 안 되므로
`test/assets_test.dart`가 번들 포함 여부를 검사한다.

## v2 범위

v1(화면 7개)보다 훨씬 크다. 시안 기준:

- 온보딩 5스텝 — 관심사(flow/cheer/highlight/rank), 성별, 연령, 마이팀 선택
- 4탭 — home / schedule / stat / my
- 경기 상세 — 라이브 이벤트 피드, 승부예측, MVP 투표
- **핸드볼 규칙 가이드** — 레슨 + 퀴즈 + 수료. 레슨마다 애니메이션 SVG 씬. CSS `@keyframes` 26개(`ghShot7`, `ghSave`, `ghCard`, `ghHop`, `ghZone` 등)가 `AnimationController` + `Interval`로 이식 대상
- 선수 카드 에디터 — 스티커 드래그 배치 후 이미지 저장(`RepaintBoundary.toImage()`)
- 응원 보드, 선수 즐겨찾기, 팀 비교, 순위 추이 그래프, 검색
- 인라인 SVG 70개

시안이 **다크 테마 기본**이다. v1 웹은 라이트 기본이었다.

### 로컬 저장 키

시안이 쓰는 `localStorage` 키를 `shared_preferences`에서 그대로 이어받는다:

```
mh_onboarded  mh_guide  mh_attended  mh_recent_search  mh_fav_players
mh_theme  mh_gender  mh_season  mh_notif  mh_my_team
mh_preds      # 내 예측만. 집계와 목록은 서버가 갖는다
mh_device_id  # 익명 기기 UUID (X-Device-Id)
mh_nick       # 닉네임 (2026-09-24 시안 개편)
mh_joined     # 닉네임을 처음 정한 시각. 가입 월로 보여준다
mh_profile    # 랭킹 프로필(닉네임·응원팀)의 서버 응답 사본
mh_guide_done_at   # 가이드 수료일
mh_blocked_names   # 차단한 authorId → 그때 본 닉네임 (서버는 id만 준다)
mh_update_skipped  # 업데이트 안내에서 "나중에"를 고른 버전
mh_sync_pending    # 서버에 아직 못 보낸 변경 (a+5490 / a-5490 / f+69 / g5)
mh_synced          # 서버와 한 번이라도 맞췄는지. 첫 동기화만 합집합이다
```

**`mh_mvp`·`mh_cheer`는 없어졌다.** MVP 투표와 응원글은 서버로 갔다.
`mh_attended`·`mh_guide`·`mh_fav_players`·`mh_preds`도 이제 **서버가 정본**이고
기기 쪽은 화면이 바로 읽는 사본이다 (위 `UserRecordsRepository` 참조).

기기에 쌓여 있던 예측·투표·응원글은 **서버로 옮기지 않는다.** 그때는 기기 ID가
없었기 때문이다 (API 05 문서).

v1 웹이 쓰던 키는 별개다: `themePreference`, 마이팀/시즌/튜토리얼 상태(`src/state/` 참조). 웹과 앱은 저장소를 공유하지 않으므로 마이그레이션 대상이 아니다.

### 디자인 토큰

v1의 CSS 변수 세트가 `_legercy/myhandball/apps/web/src/assets/styles/globals.scss`에 라이트/다크 2벌로 정의돼 있다. 브랜드 메인은 `#0068FF`(라이트) / `#4D8DFF`(다크). v2 시안은 자체 토큰(`figassets/fig-tokens.css`)을 쓰므로 **v2 쪽을 기준으로 삼고** v1은 참고만 한다.

## 배포 제약

스토어에 이미 올라간 앱을 갱신하는 것이므로 식별자가 고정이다. 아래 값은
실제 배포된 프로젝트(`_legercy/myhandball-ios`)에서 그대로 가져왔다.

| 항목 | 값 |
|---|---|
| iOS 번들 ID | `com.kebi.myhandball-ios` (하이픈 포함 — Flutter 기본값에서 수정함) |
| 서명 팀 | `R36UYT2XU8` / CODE_SIGN_STYLE Automatic |
| 표시 이름 | 마이핸드볼 |
| 앱 카테고리 | `public.app-category.entertainment` |
| 버전 | `1.2.0+5` — 스토어 현재 값은 1.1.0 (빌드 3). 2026-09-24 출시 준비에서 올렸다 |
| 지원 기기 | iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) |
| 방향 | **세로 고정** — Info.plist·AndroidManifest·`SystemChrome` 세 곳 |
| iOS 최소 버전 | 15.0 (배포본은 26.0이었으나 잘못된 설정으로 판단해 낮춤) |
| Android applicationId | `com.myhandball.app` (Play Console 실제 값, 2026-09-23 확인). `namespace`·`MainActivity` 패키지도 같은 값 |
| iOS 번들 ID | `com.kebi.myhandball-ios` (App Store 실제 값). 두 플랫폼의 ID가 다른 건 기존 배포본 그대로라서다. 바꾸면 새 앱이 된다 |

앱 아이콘과 런치 스크린도 배포본에서 가져왔다 — 런치 스크린은 `#0068FF`
바탕에 흰 로고(`LaunchImage`), 아이콘은 배포본 1024px 원본에서 리사이즈.

### 배포본에서 일부러 안 가져온 것

`NSAppTransportSecurity.NSAllowsArbitraryLoadsInWebContent = true`.
기존 앱이 WKWebView로 웹을 띄우느라 넣은 예외인데, Flutter 앱은 WebView를
쓰지 않는다. 그대로 두면 ATS를 이유 없이 약화시키므로 뺐다.

### 업데이트 안내

배포본의 `AppUpdateChecker.swift`를 옮겼다
(`data/services/app_update_service.dart`). 셸에 들어온 뒤 iTunes Lookup API로
최신 버전을 확인하고, 더 높으면 안내를 띄운다.

- **강제하지 않는다.** "나중에"를 고른 버전은 다시 묻지 않는다
  (`mh_update_skipped`). 그래도 설정의 "앱 버전" 줄에는 계속 남는다
- 버전 비교는 점으로 끊어 **숫자로** 본다. 문자열 비교면 `1.10.0`이
  `1.9.0`보다 낮다고 나온다 (`test/app_update_test.dart`)
- 확인에 실패해도 예외를 올리지 않는다. 업데이트 확인 때문에 앱이 멈추면 안 된다
- **안드로이드는 확인할 방법이 없다.** Play 스토어에 공개 조회 API가 없다.
  서버에 버전 엔드포인트가 생기면 그때 붙인다

### 남은 배포 과제

- **Android 빌드가 안 된다.** `~/Library/Android/sdk`에 `cmdline-tools`가 없다.
  Android Studio에서 SDK Command-line Tools를 설치하고
  `flutter doctor --android-licenses`를 돌려야 한다 (여기서는 설치할 수 없다)
- 개인정보 처리방침·이용약관 웹 페이지는 API 저장소가 제공한다 (`/privacy`, `/terms` → Caddy → API).
  미니 PC 서버에 배포되면 링크가 살아난다
- **출시 전 남은 것** — 개인정보 처리방침에 Keychain 식별자와 **랭킹 공개
  항목(닉네임·응원팀·적중 기록)** 명시

## 서버 상태

**`myhandball.lab241.com`** — 회사 도메인 `lab241.com`의 하위 도메인(DNS 가비아),
집 미니 PC에 도커로 올린다. `api + postgres + redis + caddy` 네 컨테이너이고
**HTTPS는 Caddy가 인증서를 자동 발급·갱신**한다. 구성과 순서는 API 저장소의
`deploy/README.md`에 있다.

예전 `myhandball.kro.kr`은 Let's Encrypt의 `kro.kr` 공용 발급 한도에 걸려
인증서를 못 받아 옮겼다.

### 같은 와이파이에서는 도메인으로 못 붙는다 — 중요

개발 맥과 서버가 **같은 공유기 뒤에 있고, 이 공유기는 NAT 루프백(헤어핀)을
지원하지 않는다.** 내부에서 `myhandball.lab241.com`을 치면 공인 IP로 나갔다가
돌아오지 못하고 공유기 자신이 응답한다:

- 80 → 공유기 관리 웹서버(`Server: micro_httpd`)의 404
- 443 → TCP는 붙지만 TLS ServerHello가 오지 않고 멈춤

**서버가 죽은 게 아니다.** 판별법: 맥의 공인 IP(`curl ifconfig.me`)가 도메인의
A 레코드와 같으면 루프백 상황이다. 그러므로

- **실기기 테스트는 셀룰러로 하거나**, 와이파이면 `API_BASE_URL`에 서버의
  **LAN IP**를 넣는다
- 이 저장소에서 운영 도메인으로 스모크 테스트를 돌릴 수 없다.
  `tool/api_smoke_test.dart`는 로컬 API(`localhost:3000`)를 기준으로 둔다

### 그 밖에

- **앱은 웹과 달리 인증서가 만료되면 완전히 먹통이 된다** (iOS ATS).
  Caddy가 자동 갱신하지만, 갱신이 멈춘 걸 앱 쪽에서 알 방법은 없다
- 마지막 응답을 저장소가 캐시해 서버 장애 시에도 일정·순위가 보인다
- 흰 화면 대신 `MhErrorView`가 오프라인/서버 오류를 구분해 띄운다.
  문구는 `spec/copy.md`의 `errTitle`/`errDesc` 그대로이고 **서버가 준 메시지를
  덧붙이지 않는다** — 사용자가 할 수 있는 일은 같은데 문구만 매번 달라진다
- **MY도 홈·일정·분석과 같은 오류 화면을 쓴다.** 시안은 MY만 위쪽 띠로
  알리게 그려 뒀는데, 연결이 끊기면 순위·기록·선수가 전부 비어서 띠만 떠
  있고 나머지는 빈 화면이 된다. 2026-09-24에 사용자가 다른 탭과 같게
  맞추라고 정했다. `MyViewModel`은 실패한 조각만 비우고 `MyState.error`에
  원인을 담는 구조를 유지하므로, 띠로 되돌리려면 화면만 바꾸면 된다
- **`refresh()`는 값이 없을 때도 다시 만들어야 한다.** 오류 화면에는
  이전 값이 없다. `state.valueOrNull`이 null이면 그냥 돌아가게 짜면
  "다시 시도"가 눌려도 아무 일이 없다 (일정 탭에서 실제로 그랬다 —
  `test/schedule_retry_test.dart`)
- **인증서 피닝은 하지 않는다.** 갱신 때마다 배포된 구버전 앱이 전부 죽는다

v1의 공지사항은 `AnnouncementBell.tsx`에 **하드코딩**돼 있어 공지 하나 띄우려면
재배포+심사가 필요했다. v2 시안에는 공지 UI가 없다.
