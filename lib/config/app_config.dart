/// 빌드 타임 설정.
///
/// v1 웹은 `VITE_API_BASE_URL`이 없으면 `window.location.origin`으로
/// 떨어졌지만, 앱에는 origin이 없다. 베이스 URL은 반드시 주입해야 한다.
abstract final class AppConfig {
  /// 운영 서버. 배포 빌드가 그냥 이걸 쓴다.
  ///
  /// 예전에는 기본값이 비어 있어서 **dart-define을 빠뜨리면 목업이 배포되는**
  /// 구조였다. 잊기 쉬운 쪽이 망가지는 게 나쁜 기본값이라 뒤집었다 —
  /// 이제 잊으면 실제 서버를 본다.
  ///
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.0.5:3000`
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://myhandball.lab241.com',
  );

  /// 개발용 — 서버를 안 타고 목업으로 띄운다.
  /// 서버가 죽었을 때나 디자인만 볼 때 쓴다.
  /// `--dart-define=MH_USE_MOCK=true`
  static const useMock = bool.fromEnvironment('MH_USE_MOCK');

  /// 개발용 — 온보딩을 건너뛰고 바로 앱 본체로 들어간다.
  /// `--dart-define=MH_SKIP_ONBOARDING=true`
  static const skipOnboarding =
      bool.fromEnvironment('MH_SKIP_ONBOARDING', defaultValue: false);

  /// 개발용 — 시작 테마를 고정한다. `light` / `dark`.
  /// 시안 기본은 다크라 비워두면 다크로 시작한다.
  /// `--dart-define=MH_INITIAL_THEME=light`
  static const initialTheme = String.fromEnvironment('MH_INITIAL_THEME');

  /// 개발용 — 시작 탭을 고른다. `home` / `schedule` / `stat` / `my`.
  /// `--dart-define=MH_INITIAL_TAB=schedule`
  static const initialTab = String.fromEnvironment('MH_INITIAL_TAB');

  /// 개발용 — 시작하자마자 규칙 가이드를 연다. 홈 배너를 거쳐야만 닿는
  /// 화면이라 시뮬레이터에서 확인하기 번거로워서 둔다.
  /// `--dart-define=MH_OPEN_GUIDE=true`
  static const openGuide =
      bool.fromEnvironment('MH_OPEN_GUIDE', defaultValue: false);

  /// 중계 편성표. 시안이 "중계 보기"에 걸어 둔 주소다.
  /// 경기별 네이버 중계 링크가 있으면 그쪽을 먼저 연다.
  static const broadcastUrl =
      'https://www.koreahandball.com/medianews/broadcast.php';

  /// 예매. 시안이 "예매하기"에 걸어 둔 주소다.
  static const ticketUrl = 'https://www.ticketlink.co.kr/sports/handball';

  /// 개인정보 처리방침·이용약관. **웹에서 관리한다.**
  /// 앱에 문구를 넣으면 고칠 때마다 심사를 다시 받아야 한다.
  /// `--dart-define=MH_PRIVACY_URL=...`로 바꿀 수 있다.
  static const privacyUrl = String.fromEnvironment(
    'MH_PRIVACY_URL',
    defaultValue: 'https://myhandball.lab241.com/privacy',
  );
  static const termsUrl = String.fromEnvironment(
    'MH_TERMS_URL',
    defaultValue: 'https://myhandball.lab241.com/terms',
  );

  /// 시안 규칙 가이드의 총 레슨 수 (`{{ guideDoneCount }}/5`).
  static const guideLessonCount = 5;

  /// 설정 화면에 표시할 앱 버전. `pubspec.yaml`의 `version`과 맞춰야 하며
  /// `test/app_version_test.dart`가 어긋나면 잡는다.
  static const appVersion = '1.1.0';
  static const buildNumber = '4';

  /// 홈 상단 "시즌 TOP5"가 보여주는 줄 수.
  static const topPlayerCount = 5;
}
