# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

마이핸드볼(MyHandball) 앱. 한국 핸드볼 리그(H리그)의 일정·순위·팀 정보를 제공한다.

기존에 **React 웹 + WKWebView 래퍼**로 iOS 스토어에 배포돼 있던 것을(v1.1.0, 빌드 3) **Flutter 네이티브 앱**으로 전환하는 작업이다. 백엔드(NestJS)는 기존 것을 그대로 쓴다.

- v1 웹: `/Users/kebi/projects/_legercy/myhandball/apps/web` (React 18 + Vite + SCSS Modules + Recoil, 화면 7개)
- v1 iOS: `/Users/kebi/projects/_legercy/myhandball-ios` (SwiftUI + WKWebView 껍데기)
- API: `../myhandball-api` (NestJS, **이 저장소에서 직접 수정하지 않는다** — 아래 참조)

### 구현 현황

| 영역 | 상태 |
|---|---|
| 디자인 토큰 · 테마 (`lib/ui/core/themes/`) | 완료 — 다크/라이트 2벌, 시안 `c.*` 키와 1:1 |
| 온보딩 5스텝 | 완료 |
| 홈 탭 | 완료 (가까운 경기 / 가이드 배너 / 팀순위 / 시즌 TOP5) |
| 하단 4탭 셸 | 완료 |
| 일정 탭 | 완료 (목록 / MY팀 달력) |
| 분석 탭 | 4개 서브탭(순위/기록/팀/선수) 완료 |
| MY 탭 | 완료 (마이팀 / 수료 배지 / 관심 선수 / 직관 기록 / 승부 예측 / 다음 경기 / 시즌 기록 / 최근 5경기 / 주요 선수) |
| 팀 상세, 선수 상세, 선수 비교 | 미착수 — 분석 탭에서 진입만 막아둔 상태 |
| 경기 상세, 규칙 가이드, 검색, 팀 선택 모달, 설정 | 미착수 |

**메인 4탭은 모두 이식됐다.** 남은 건 거기서 열리는 화면들이다.
직관 기록(`mh_attended`)과 승부 예측(`mh_preds`)은 경기 상세에서 만들어지므로,
그 화면이 생기기 전까지 MY 탭에서 항상 빈 상태로 보인다.
| 데이터 계층 (repository + service) | 골격 완료 — 구현체가 `MockHandballApiService` 하나 |
| 실제 API 연동 | 미착수 — `HandballApiService`의 HTTP 구현만 추가하면 된다 |

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
- `routing/`은 아직 없다. 화면 전환이 4탭 `IndexedStack` + 조건부 `home`뿐이라
  라우터가 필요 없다. 경기 상세·가이드처럼 전체화면이 붙을 때 go_router를 넣는다

## 작업 경계: API 변경은 프롬프트로 넘긴다

**이 세션이 메인이다.** Flutter 앱 쪽 작업은 직접 한다.

**API(`../myhandball-api`) 코드는 직접 수정하지 않는다.** 읽는 것은 자유롭게 하되(계약 확인용), 변경이 필요하면 **API 저장소에서 작업할 다른 Claude 세션에 넘길 프롬프트를 작성**한다.

프롬프트는 **파일로 쓰지 않고 사용자에게 채팅으로 바로 준다.** 그대로 복사해 붙일 수 있게 코드블럭 하나로 감싼다. 프롬프트 본문에 마크다운 제목·코드블럭이 들어가므로 바깥 펜스는 백틱 4개(````)를 쓴다.

프롬프트는 API 저장소만 열어둔 세션이 **이 저장소를 보지 않고도** 수행할 수 있도록 자기완결적으로 쓴다. 최소 다음을 포함한다:

- **배경** — 왜 필요한지, 앱의 어느 화면/기능이 요구하는지
- **엔드포인트** — `METHOD /api/...`, 쿼리 파라미터와 기본값
- **응답 스펙** — TypeScript 타입으로. 기존 타입 확장이면 어느 파일의 무엇인지 명시
- **하위 호환** — 기존 웹(v1)이 같은 엔드포인트를 쓰므로 필드 추가는 되지만 제거·타입 변경은 안 된다 (웹을 내린 뒤라면 그 사실을 명시)
- **검증** — curl 예시와 기대 응답

프롬프트를 준 뒤에는 API 쪽 작업이 끝나 배포될 때까지 앱에서 해당 기능을 목업/스텁으로 둔다.

### 지금 API 작업이 필요한 것

- **선수 기록(시즌 TOP5)** — 대응 엔드포인트가 없다. `lib/domain/models/player_stat.dart` 참조
- **선수 명단** — 분석 탭 선수 카드가 쓰는 데이터. 역시 엔드포인트가 없어
  `lib/domain/models/player.dart`의 목업이 이름까지 지어내고 있다
- **순위 상세 필드** — `/api/ranking`은 승·무·패·득실을 이미 준다. 분석 탭의
  순위·기록 표는 그 값을 그대로 쓰면 되므로 API 작업이 필요 없다
- **경기 상태(pre/live/finished) 판정** — 현재 `scoreText` 문자열과 시작 시각만 오고, v1 웹이 클라이언트에서 계산했다. 위젯·라이브 액티비티까지 가려면 서버가 줘야 한다
- **실시간 스코어 + 득점 이벤트 푸시** — 위젯 LIVE 상태의 전제

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
  --dart-define=MH_INITIAL_THEME=light     # 기본은 시안대로 dark

# 화면 전체를 PNG로 떠서 레이아웃 확인 (tool/preview/*.png, gitignore됨)
flutter test --update-goldens tool/design_preview_test.dart
```

`tool/`은 `flutter test`의 기본 대상(`test/`)에 없으므로 CI를 깨지 않는다.
프리뷰 PNG는 테스트 환경이라 **본문이 네모로 렌더된다** — 커스텀 폰트가
로드되지 않아서다. 레이아웃 확인용이고, 타이포 확인은 시뮬레이터로 한다.

API 베이스 URL은 컴파일 타임에 주입한다. 웹 v1은 미지정 시 `window.location.origin`으로 폴백했지만 **앱에는 origin이 없으므로 항상 명시해야 한다.**

```bash
flutter run --dart-define=API_BASE_URL=https://myhandball.kro.kr
```

**Android는 아직 빌드 불가** — `flutter doctor`가 cmdline-tools 누락을 보고한다. Android Studio에서 SDK Command-line Tools 설치 후 `flutter doctor --android-licenses` 필요.

## API 계약

전 엔드포인트가 `/api` 프리픽스를 가진다. 인증 없음. 모든 데이터는 koreahandball.com을 cheerio로 스크래핑해 Redis에 캐시한 결과다(팀 목록 TTL 24h).

| 엔드포인트 | 쿼리 | 응답 |
|---|---|---|
| `GET /api/schedule` | `gender`(`W`/`M`/``), `season`, `type`, `month` | `ScheduleResponse` — `days[].games[]` |
| `GET /api/schedule/ics/my-team` | `gender`, `season`, `type`, `teamName`(필수) | `text/calendar` ICS 본문 |
| `GET /api/ranking` | `gender`(`W`/`M`), `season`, `type` | `RankingResponse` — `items[]` |
| `GET /api/team` | `gender` | `TeamListResponse` — `teams[]` |
| `POST /api/welcome/submissions` | — | 온보딩 선택값을 Postgres에 기록 |

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

### 실시간 스코어는 없다

API에 이벤트 스트림도 푸시도 없다. v2 시안의 LIVE 위젯·라이브 액티비티·경기 상세 라이브 피드는 **백엔드 신규 작업이 선행돼야** 한다. 해당 기능을 건드리게 되면 먼저 API 작업 프롬프트를 사용자에게 준다 (위 "작업 경계" 참조).

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
mh_onboarded  mh_preds  mh_mvp  mh_guide  mh_attended
mh_recent_search  mh_cheer  mh_fav_players
```

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
| 버전 | `1.1.0+3` — 스토어 현재 값. **다음 배포 시 빌드 번호 4 이상** |
| 지원 기기 | iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) |
| 방향 | iPhone 세로+가로, iPad 4방향 (배포본과 동일, Flutter 기본값과도 일치) |
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

### 방향 · iPad 관련 주의

v2 시안은 375x812 세로 화면 하나만 그려져 있다. 배포본이 가로와 iPad를
허용한 건 WebView라 반응형으로 넘어갔기 때문이고, 지금 UI는 세로 고정을
전제로 짜여 있다. 실제 배포 전에 `ios/Runner/Info.plist`의
`UISupportedInterfaceOrientations`를 세로만 남기는 쪽을 검토한다.

## 서버 상태

`myhandball.kro.kr` — 가정 회선 자체 호스팅. 도커로 postgres / redis / api / web(nginx) 4개 컨테이너를 띄우고, **nginx가 443에서 TLS를 종료해 `/api/`를 `api:3000`으로 프록시**한다. API 프로세스 자체는 인증서를 갖지 않는다.

2026-09-23 기준 외부에서 443이 응답하지 않는 상태로 관측됐다(서버 측 작업은 사용자가 별도 진행 중). API 연동 코드를 짤 때는:

- 마지막 응답을 로컬 캐시해 서버 장애 시에도 일정·순위가 보이게 한다
- 흰 화면 대신 명시적 오류 화면을 띄운다 (v2 시안에 `오프라인` / `서버 오류` 상태가 이미 설계돼 있다)
- **인증서 피닝은 하지 않는다.** 갱신 때마다 배포된 구버전 앱이 전부 죽는다

v1의 공지사항은 `AnnouncementBell.tsx`에 **하드코딩**돼 있어 공지 하나 띄우려면 재배포+심사가 필요했다. v2에서는 원격에서 내려받는 구조로 간다.
