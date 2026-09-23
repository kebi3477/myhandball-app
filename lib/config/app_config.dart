/// 빌드 타임 설정.
///
/// v1 웹은 `VITE_API_BASE_URL`이 없으면 `window.location.origin`으로
/// 떨어졌지만, 앱에는 origin이 없다. 베이스 URL은 반드시 주입해야 한다.
abstract final class AppConfig {
  /// `flutter run --dart-define=API_BASE_URL=https://myhandball.kro.kr`
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// 개발용 — 온보딩을 건너뛰고 바로 앱 본체로 들어간다.
  /// `--dart-define=MH_SKIP_ONBOARDING=true`
  static const skipOnboarding =
      bool.fromEnvironment('MH_SKIP_ONBOARDING', defaultValue: false);

  /// 시안 규칙 가이드의 총 레슨 수 (`{{ guideDoneCount }}/5`).
  static const guideLessonCount = 5;

  /// 홈 상단 "시즌 TOP5"가 보여주는 줄 수.
  static const topPlayerCount = 5;
}
