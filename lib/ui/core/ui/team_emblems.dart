/// 팀 로고 → MyHandball 자체 엠블럼 (`assets/emblems/*.svg`).
///
/// 연맹 공식 로고를 핫링크하지 않으려고 자체 심볼로 바꿨다 (2026-09-28
/// 디자인 핸드오프). 서버는 여전히 연맹 로고 URL
/// (`.../logo_{m|w}_{teamNum}.png`)을 주므로 **그 URL을 키로** 엠블럼을 고른다.
/// 선수·프로필처럼 팀 이름 없이 로고 URL만 들고 다니는 모델이 많아서
/// 이름이 아니라 URL로 매칭한다.
///
/// 로고 소스는 이 파일 하나에서 관리한다. 연맹 사용 허가가 나면 여기서
/// 공식 로고로 되돌린다 (시안 `LOGO_ID`에 해당).
///
/// 모르는 팀은 null을 돌려 `TeamLogo`가 회색 원을 그린다. 시안은
/// `assets/team-logo-default.png`로 떨어지는데 **그 파일이 SK호크스 공식
/// 로고라서** 가져오지 않았다 — 다른 팀에 SK 로고가 붙고, 없애려던 연맹
/// 로고가 다시 들어온다.
abstract final class TeamEmblems {
  /// `{m|w}_{teamNum}` → 엠블럼 파일 키.
  /// 팀 번호는 목업(`MockHandballApiService`)과 같은 연맹 사이트 값이다.
  static const _byLogoId = {
    'm_149': 'ds', // 두산
    'm_22': 'sm', // 상무피닉스
    'm_120': 'in', // 인천도시공사
    'm_113': 'cn', // 충남도청
    'm_150': 'hn', // 하남시청
    'm_132': 'skh', // SK호크스
    'w_102': 'gn', // 경남개발공사
    'w_110': 'gj', // 광주도시공사
    'w_23': 'dg', // 대구광역시청
    'w_100': 'bs', // 부산시설공단
    'w_93': 'sc', // 삼척시청
    'w_107': 'sl', // 서울시청
    'w_127': 'ic', // 인천광역시청
    'w_123': 'sks', // SK슈가글라이더즈
  };

  static final _logoId = RegExp(r'logo_([mw])_(\d+)\.\w+$');

  /// 엠블럼 에셋 경로. 로고 URL이 없거나 모르는 팀이면 null.
  static String? assetFor(String? logoUrl) {
    if (logoUrl == null) return null;
    final m = _logoId.firstMatch(logoUrl);
    final key = m == null ? null : _byLogoId['${m[1]}_${m[2]}'];
    return key == null ? null : 'assets/emblems/$key.svg';
  }

  /// 번들에 들어 있어야 하는 파일 전부 (`test/assets_test.dart`).
  static List<String> get allAssets =>
      [for (final key in _byLogoId.values) 'assets/emblems/$key.svg'];
}
