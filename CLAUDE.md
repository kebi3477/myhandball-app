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
| 온보딩 5스텝 | 완료 |
| 메인 4탭 — 홈 / 일정 / 분석 / MY | 완료 |
| 경기 상세 (중계·기록·예측·MVP) | 완료 |
| 팀 상세 (소개·전적·선수·응원) | 완료 |
| 규칙 가이드 (레슨 5개 + 퀴즈) | 완료 |
| 검색 · 선수 상세 · 선수 비교 | 완료 |
| 설정 · 시즌 선택 · 팀 선택 · 연·월 선택 | 완료 |
| 오프라인 · 서버 오류 · 비시즌 화면 | 완료 (시안 `demoState` 4종) |
| 데이터 계층 (repository + service) | 완료 — 목업 / HTTP 두 구현체 |
| **실제 API 연동** | **완료** — `API_BASE_URL`이 있으면 `HttpHandballApiService` |

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

**규칙 가이드 5번 레슨 문구.** 디자인 파일이 256KiB 상한에서 잘려 원문을 보지
못했다. 남아 있던 씬 이름(`cards`, `twomin`)에 맞춰 내용을 채웠으므로
원문 확인이 필요하다 (`lib/domain/models/guide_lesson.dart`).

**응원글·선수 비교 축.** 응원글은 서버가 없어 기기에만 쌓인다. 선수 비교의
레이더 축 5개 중 3개는 실제 세부 기록이 없어 근사치다.

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

**새로 API 작업이 필요한 건 아래 세 개뿐이다.**

- **내 예측 목록** — 서버는 경기별 집계만 준다. MY 화면이 "내가 예측한 경기"를
  모아 보여주려면 목록이 필요한데, 지금은 내 선택만 기기에 캐시해 대신하고 있다
  (`PreferencesRepository._predictions`)
- **응원글 신고·차단** — `cheers.hidden`을 DB에서 손으로 켜는 것뿐이다.
  스토어 심사에서 UGC 신고 수단을 요구할 수 있다 (API 07 B-1)
- **선수의 최근 경기별 기록** — 시안 선수 시트에 "최근 5경기"가 있는데
  `/api/player/:playerSeq`는 시즌 단위만 준다. 경기별은 `/api/game/:matchSeq`를
  경기마다 받아야 해서 시트에 넣기엔 무겁다. 아직 구현하지 않았다

### 외부로 나가는 동작

`url_launcher`(링크)와 `share_plus`(.ics 공유)를 쓴다. **눌렀는데 아무 일도
안 일어나는 상태를 만들지 않는다** — 실패하면 `ui/core/ui/external_actions.dart`가
스낵바로 알린다.

| 동작 | 대상 |
|---|---|
| 중계 보기 | 경기별 네이버 중계 링크(`liveLinks`), 없으면 `AppConfig.broadcastUrl` |
| 예매하기 | `AppConfig.ticketUrl` (티켓링크) |
| 개인정보 처리방침 · 이용약관 | `MH_PRIVACY_URL` / `MH_TERMS_URL` dart-define |
| 캘린더에 추가 · 내보내기 | 앱에서 만든 `.ics` (`domain/ics.dart`) |

**정책 문구는 앱에 넣지 않는다.** 고칠 때마다 심사를 다시 받아야 해서 웹으로
뺐다. 기본 URL은 `myhandball.kro.kr/privacy`·`/terms`이고 dart-define으로 바꾼다.

`.ics`는 서버에도 `/api/schedule/ics/my-team`이 있지만 **시즌 전체만** 준다.
경기 하나만 넣는 버튼과 경로를 하나로 두려고 앱에서 만든다. `test/ics_test.dart`가
형식을 잡아 준다 — 한 글자 틀리면 캘린더가 통째로 안 연다.

남은 후속 과제는 앱이 아니라 서버 쪽이고 `../myhandball-api/docs/api-tasks/07-후속-작업.md`에 있다.
그중 **앱에 직접 영향 있는 것**:

- **경기 중 PBP가 실시간으로 갱신되는지 아직 확인 못 했다** (조사 시점이 비시즌).
  틀리면 LIVE 뱃지·중계 탭·득점 푸시가 조용히 안 나온다. 개막(11월) 첫 경기에
  확인이 필요하다
- 서버는 `myhandball.kro.kr` 인증서를 수동 갱신한다. **앱은 만료되면 통째로
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

API 베이스 URL은 컴파일 타임에 주입한다. 웹 v1은 미지정 시 `window.location.origin`으로 폴백했지만 **앱에는 origin이 없으므로 항상 명시해야 한다.**

```bash
flutter run --dart-define=API_BASE_URL=https://myhandball.kro.kr
flutter run --dart-define=API_BASE_URL=http://localhost:3000   # 로컬 API
```

**비어 있으면 목업으로 떨어진다** (`handballApiServiceProvider`). 서버가 죽어도
디자인은 확인할 수 있게 남겨 둔 갈림길이고, 지운 적 없다고 착각하기 쉬우니
"데이터가 이상하다" 싶으면 이 값부터 확인한다.

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

`ios/Runner/Info.plist`에 `NSAllowsLocalNetworking`과
`NSLocalNetworkUsageDescription`을 넣어 뒀다. **로컬 네트워크에만 평문을
허용**하고 인터넷 구간 ATS는 그대로라, 배포본에서 뺐던
`NSAllowsArbitraryLoadsInWebContent`와는 범위가 다르다. 운영은 https라
영향이 없다. 실기기 테스트를 접으면 두 키는 지워도 된다.

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
(영문·숫자·하이픈 8~64자). `PreferencesRepository.deviceId`가 한 번 만들어
저장하고, `ApiClient`가 모든 요청에 붙인다. 앱을 지웠다 깔면 새 값이 된다 —
서버도 그렇게 본다.

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
mh_preds      # 내 예측만. 집계는 서버가 갖는다
mh_device_id  # 익명 기기 UUID (X-Device-Id)
```

**`mh_mvp`·`mh_cheer`는 없어졌다.** MVP 투표와 응원글은 서버로 갔다. 예측도
집계는 서버가 갖고, `mh_preds`는 MY 화면이 "내가 예측한 경기"를 모으려고 두는
캐시일 뿐이다 (서버에 그 목록 엔드포인트가 없다).

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
| 버전 | `1.1.0+4` — 스토어 현재 값(빌드 3)에서 하나 올려 둔 상태 |
| 지원 기기 | iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) |
| 방향 | **세로 고정** — Info.plist·AndroidManifest·`SystemChrome` 세 곳 |
| iOS 최소 버전 | 15.0 (배포본은 26.0이었으나 잘못된 설정으로 판단해 낮춤) |
| Android applicationId | **미확인.** 현재 `com.kebi.myhandball`. Play Console 실제 값과 대조 필요 |

앱 아이콘과 런치 스크린도 배포본에서 가져왔다 — 런치 스크린은 `#0068FF`
바탕에 흰 로고(`LaunchImage`), 아이콘은 배포본 1024px 원본에서 리사이즈.

### 배포본에서 일부러 안 가져온 것

`NSAppTransportSecurity.NSAllowsArbitraryLoadsInWebContent = true`.
기존 앱이 WKWebView로 웹을 띄우느라 넣은 예외인데, Flutter 앱은 WebView를
쓰지 않는다. 그대로 두면 ATS를 이유 없이 약화시키므로 뺐다.

### 아직 안 옮긴 기능

배포본의 `AppUpdateChecker.swift` — iTunes lookup API로 최신 버전을 확인해
"업데이트 안내" 알럿을 띄운다. 설정이 아니라 기능이라 이식하지 않았다.
Flutter에서는 `upgrader` 패키지나 원격 설정으로 대체하는 게 낫다.

### 남은 배포 과제

- **Android 빌드가 안 된다.** `~/Library/Android/sdk`에 `cmdline-tools`가 없다.
  Android Studio에서 SDK Command-line Tools를 설치하고
  `flutter doctor --android-licenses`를 돌려야 한다 (여기서는 설치할 수 없다)
- **Android `applicationId`가 `com.kebi.myhandball`인데 Play Console 실제 값과
  대조하지 못했다.** 다르면 업데이트가 아니라 새 앱으로 올라간다
- 개인정보 처리방침·이용약관 **웹 페이지를 실제로 올려야 한다.** 링크만 걸려 있다
- 실기기 테스트가 끝나면 `NSAllowsLocalNetworking`·`NSLocalNetworkUsageDescription`
  제거를 검토한다

## 서버 상태

`myhandball.kro.kr` — 가정 회선 자체 호스팅. 도커로 postgres / redis / api / web(nginx) 4개 컨테이너를 띄우고, **nginx가 443에서 TLS를 종료해 `/api/`를 `api:3000`으로 프록시**한다. API 프로세스 자체는 인증서를 갖지 않는다.

2026-09-23 기준 외부에서 443이 응답하지 않는 상태로 관측됐다(서버 측 작업은 사용자가 별도 진행 중). API 연동 코드를 짤 때는:

- 마지막 응답을 로컬 캐시해 서버 장애 시에도 일정·순위가 보이게 한다
- 흰 화면 대신 명시적 오류 화면을 띄운다 (v2 시안에 `오프라인` / `서버 오류` 상태가 이미 설계돼 있다)
- **인증서 피닝은 하지 않는다.** 갱신 때마다 배포된 구버전 앱이 전부 죽는다

v1의 공지사항은 `AnnouncementBell.tsx`에 **하드코딩**돼 있어 공지 하나 띄우려면 재배포+심사가 필요했다. v2에서는 원격에서 내려받는 구조로 간다.
