# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

마이핸드볼(MyHandball) 앱. 한국 핸드볼 리그(H리그)의 일정·순위·팀 정보를 제공한다.

기존에 **React 웹 + WKWebView 래퍼**로 iOS 스토어에 배포돼 있던 것을(v1.1.0, 빌드 3) **Flutter 네이티브 앱**으로 전환하는 작업이다. 백엔드(NestJS)는 기존 것을 그대로 쓴다.

- v1 웹: `/Users/kebi/projects/_legercy/myhandball/apps/web` (React 18 + Vite + SCSS Modules + Recoil, 화면 7개)
- v1 iOS: `/Users/kebi/projects/_legercy/myhandball-ios` (SwiftUI + WKWebView 껍데기)
- API: `../myhandball-api` (NestJS, **이 저장소에서 직접 수정하지 않는다** — 아래 참조)

이 저장소는 `flutter create` 직후 상태다. 실제 화면 구현은 아직 시작 전.

## 작업 경계: API 변경은 프롬프트로 넘긴다

**이 세션이 메인이다.** Flutter 앱 쪽 작업은 직접 한다.

**API(`../myhandball-api`) 코드는 직접 수정하지 않는다.** 읽는 것은 자유롭게 하되(계약 확인용), 변경이 필요하면 **API 저장소에서 작업할 다른 Claude 세션에 넘길 프롬프트를 작성**한다.

작성 위치: `docs/api-requests/<NNN>-<슬러그>.md` (번호는 3자리 순번)

프롬프트는 API 저장소만 열어둔 세션이 **이 저장소를 보지 않고도** 수행할 수 있도록 자기완결적으로 쓴다. 최소 다음을 포함한다:

```markdown
# <제목>

## 배경
왜 필요한지. 앱의 어느 화면/기능이 이걸 요구하는지.

## 엔드포인트
METHOD /api/... — 쿼리 파라미터와 기본값

## 응답 스펙
TypeScript 타입으로. 기존 타입을 확장하는 경우 어느 파일의 무엇인지 명시.

## 하위 호환
기존 웹(v1)이 같은 엔드포인트를 쓰고 있으므로, 필드 추가는 되지만 제거·타입 변경은 안 된다.
(웹을 완전히 내린 뒤라면 그 사실을 명시)

## 검증
curl 예시와 기대 응답.
```

프롬프트를 쓴 뒤에는 사용자에게 파일 경로를 알리고, API 쪽 작업이 끝나 배포될 때까지 앱에서는 해당 기능을 목업/스텁으로 둔다.

## 명령어

```bash
flutter analyze                          # 정적 분석
flutter test                             # 전체 테스트
flutter test test/widget_test.dart       # 파일 단위
flutter test --plain-name "테스트 이름"    # 단일 테스트
flutter run                              # 개발 실행
flutter build ios --no-codesign --debug  # iOS 빌드 검증 (서명 없이)
```

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

### 실시간 스코어는 없다

API에 이벤트 스트림도 푸시도 없다. v2 시안의 LIVE 위젯·라이브 액티비티·경기 상세 라이브 피드는 **백엔드 신규 작업이 선행돼야** 한다. 해당 기능을 건드리게 되면 먼저 `docs/api-requests/`에 프롬프트를 쓴다.

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

스토어에 이미 올라간 앱을 갱신하는 것이므로 식별자가 고정이다.

| 항목 | 값 |
|---|---|
| iOS 번들 ID | `com.kebi.myhandball-ios` (하이픈 포함 — 기본값에서 수정함) |
| 서명 팀 | `R36UYT2XU8` |
| iOS 최소 버전 | 15.0 (v1은 26.0이었으나 잘못된 설정으로 판단해 낮춤) |
| 스토어 최종 버전 | 1.1.0 (빌드 3) — 새 빌드는 **빌드 번호 4 이상** |
| Android applicationId | **미확인.** 현재 `com.kebi.myhandball`로 들어가 있으나 Play Console 실제 값과 대조 필요. 다르면 기존 설치 사용자를 업데이트로 잡지 못한다 |

Dart 패키지명은 하이픈을 못 쓰므로 `myhandball`이다(디렉터리명 `myhandball-app`과 다름).

## 서버 상태

`myhandball.kro.kr` — 가정 회선 자체 호스팅. 도커로 postgres / redis / api / web(nginx) 4개 컨테이너를 띄우고, **nginx가 443에서 TLS를 종료해 `/api/`를 `api:3000`으로 프록시**한다. API 프로세스 자체는 인증서를 갖지 않는다.

2026-09-23 기준 외부에서 443이 응답하지 않는 상태로 관측됐다(서버 측 작업은 사용자가 별도 진행 중). API 연동 코드를 짤 때는:

- 마지막 응답을 로컬 캐시해 서버 장애 시에도 일정·순위가 보이게 한다
- 흰 화면 대신 명시적 오류 화면을 띄운다 (v2 시안에 `오프라인` / `서버 오류` 상태가 이미 설계돼 있다)
- **인증서 피닝은 하지 않는다.** 갱신 때마다 배포된 구버전 앱이 전부 죽는다

v1의 공지사항은 `AnnouncementBell.tsx`에 **하드코딩**돼 있어 공지 하나 띄우려면 재배포+심사가 필요했다. v2에서는 원격에서 내려받는 구조로 간다.
