/// 팀 로고 → MyHandball 자체 엠블럼 (`assets/emblems/*.svg`).
///
/// 연맹 공식 로고를 핫링크하지 않으려고 자체 심볼로 바꿨다 (2026-09-28
/// 디자인 핸드오프). 서버는 여전히 연맹 로고 URL을 주므로 **그 URL을 키로**
/// 엠블럼을 고른다. 선수·프로필처럼 팀 이름 없이 로고 URL만 들고 다니는
/// 모델이 많아서 이름이 아니라 URL로 매칭한다.
///
/// ### 연맹 로고 URL은 두 종류다
///
/// 서버가 긁는 페이지마다 다른 번호 체계를 쓴다.
///
/// | 경로 | 번호 | 나오는 곳 |
/// |---|---|---|
/// | `logo/logo_{m|w}_{N}.png` | `team_num` (두산 149) | 팀 목록·팀 상세·프로필·선수 |
/// | `logo_api/logo_{m|w}_{N}.png` | `team_seq` (두산 1) | 일정·순위·경기 상세·직관 |
///
/// 둘의 대응은 연맹 사이트 상단 메뉴의 `img[g][g-api]`에 있다 (2026-09-28 확인).
/// **폴더까지 봐야 한다** — 번호만 보면 두 체계가 겹칠 때 다른 팀이 된다.
///
/// 로고 소스는 이 파일 하나에서 관리한다. 연맹 사용 허가가 나면 여기서
/// 공식 로고로 되돌린다 (시안 `LOGO_ID`에 해당).
///
/// 모르는 팀은 null을 돌려 `TeamLogo`가 회색 원을 그린다. 시안은
/// `assets/team-logo-default.png`로 떨어지는데 **그 파일이 SK호크스 공식
/// 로고라서** 가져오지 않았다 — 다른 팀에 SK 로고가 붙고, 없애려던 연맹
/// 로고가 다시 들어온다.
abstract final class TeamEmblems {
  /// `{폴더}/{m|w}_{N}` → 엠블럼 파일 키.
  static const _byLogoId = {
    // 남자부 — team_num / team_seq
    'logo/m_149': 'ds', 'logo_api/m_1': 'ds', // 두산
    'logo/m_22': 'sm', 'logo_api/m_2': 'sm', // 상무피닉스
    'logo/m_113': 'cn', 'logo_api/m_3': 'cn', // 충남도청
    'logo/m_120': 'in', 'logo_api/m_4': 'in', // 인천도시공사
    'logo/m_150': 'hn', 'logo_api/m_5': 'hn', // 하남시청
    'logo/m_132': 'skh', 'logo_api/m_6': 'skh', // SK호크스
    // 여자부
    'logo/w_123': 'sks', 'logo_api/w_7': 'sks', // SK슈가글라이더즈
    'logo/w_102': 'gn', 'logo_api/w_8': 'gn', // 경남개발공사
    'logo/w_110': 'gj', 'logo_api/w_9': 'gj', // 광주도시공사
    'logo/w_23': 'dg', 'logo_api/w_10': 'dg', // 대구광역시청
    'logo/w_100': 'bs', 'logo_api/w_11': 'bs', // 부산시설공단
    'logo/w_93': 'sc', 'logo_api/w_12': 'sc', // 삼척시청
    'logo/w_107': 'sl', 'logo_api/w_13': 'sl', // 서울시청
    'logo/w_127': 'ic', 'logo_api/w_14': 'ic', // 인천광역시청
  };

  static final _logoId = RegExp(r'/(logo|logo_api)/logo_([mw])_(\d+)\.\w+(\?.*)?$');

  /// 엠블럼 에셋 경로. 로고 URL이 없거나 모르는 팀이면 null.
  static String? assetFor(String? logoUrl) {
    if (logoUrl == null) return null;
    final m = _logoId.firstMatch(logoUrl);
    final key = m == null ? null : _byLogoId['${m[1]}/${m[2]}_${m[3]}'];
    return key == null ? null : 'assets/emblems/$key.svg';
  }

  /// 번들에 들어 있어야 하는 파일 전부 (`test/assets_test.dart`).
  static List<String> get allAssets =>
      {for (final key in _byLogoId.values) 'assets/emblems/$key.svg'}.toList();
}
