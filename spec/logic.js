// MyHandball v2.dc.html 의 로직 클래스 원문 (자동 추출). 마크업의 {{ }} 값은 모두 renderVals()에서 나옴.
class Component extends DCLogic {
  state = {
    step: 0, inApp: false, appScreen: 'home', homeGameIdx: 0, attended: {}, guideOpen: false, guideView: 'path', guideLesson: 0, guideStep: 0, guidePick: null, guideChecked: false, guideDone: [], guideGradDate: '', guideJustGrad: false, guideLastCorrect: false, gd: null, gdTab: 'live', gdEvents: [], preds: {}, mvpVotes: {}, searchOpen: false, searchQuery: '', recentSearches: [], errDismissed: false, top5Cat: 'goals', hgDragging: false, favPlayerIds: [], introExpanded: false, historyExpanded: false, cheerDraft: '', cheerByTeam: {}, cheerLiked: [], cheerConfirmId: null,
    interest: null, gender: '', age: '', teamGender: 'M', selectedTeam: null,
    rankGender: 'M', statTab: 'rank', monthOffset: 0, selectedDay: null,
    q1Answer: null, q2Answer: null, cardPlayerId: null,
    teamDetailName: null, teamDetailTab: 'info', theme: 'dark',
    cardEditOpen: false, placedStickers: [], draggingStickerId: null,
    savedStickers: [],
    teamPickerOpen: false, pickerGender: 'M',
    schedView: 'list', calSelDay: null, toast: null, ymPickerOpen: false, ymPickerYear: 2026, trendMode: 'rank', cmpOpen: false, cmpA: null, cmpB: null, cmpPicking: null, icsSaved: false,
    notifOn: true, cardSaveStatus: 'idle',
    loadingHome: false, loadingSchedule: false, loadingStat: false, loadingTeamDetail: false,
    settingsOpen: false, seasonPickerOpen: false, season: '2025-26', policyOpen: false, termsOpen: false,
    cheerMenu: null, reportPost: null, reportReason: null, reportDetail: '', reportBlock: false, blockAsk: null, blocked: [], reportedKeys: [], blockedOpen: false, homeTab: 'home', predDiv: 'all', nickEditing: false, nickDraft: '', attTouched: false, attSheetOpen: false, rankScope: 'all', profile: null, pfOpen: false, pfEdit: false, pfNick: '', pfTeam: null, pfGender: 'M', pfConsent: false, pfPending: null,
  };
  static M_TEAMS = ['인천도시공사', 'SK호크스', '하남시청', '두산', '충남도청', '상무피닉스'];
  static NICK_A = ['속공', '피봇', '윙어', '7미터', '점프슛', '스카이', '수비벽', '역습', '코트', '백패스', '골문', '센터백'];
  static NICK_B = ['장인', '요정', '덕후', '러버', '매니아', '고수', '요원', '대장', '킹', '신', '지기', '천재'];
  static NICK_BANNED = ['운영자', '관리자', 'admin', '핸드볼연맹', '마이핸드볼'];
  // TODO(v3): 랭킹 목업 — 서버 집계(주 1회 갱신)로 교체
  rankUsers = () => {
    if (this._rkUsers) return this._rkUsers;
    const r = this.rng('rank-users'), A = Component.NICK_A, B = Component.NICK_B, T = [...Component.M_TEAMS, ...Component.W_TEAMS], seen = new Set(), out = [];
    while (out.length < 140) {
      const nick = A[Math.floor(r() * A.length)] + B[Math.floor(r() * B.length)] + (r() < 0.55 ? String(Math.floor(r() * 99) + 1) : '');
      if (seen.has(nick)) continue; seen.add(nick);
      const n = 10 + Math.floor(r() * 22), skill = 0.4 + Math.pow(r(), 1.4) * 0.45;
      out.push({ nick, team: T[Math.floor(Math.pow(r(), 1.3) * T.length)], n, h: Math.round(n * skill) });
    }
    return (this._rkUsers = out);
  };
  nickCheck = (raw, own) => {
    const n = (raw || '').trim();
    if (!n) return { ok: false, msg: '' };
    if (n.length < 2) return { ok: false, msg: '2자 이상 입력해 주세요' };
    if (!/^[가-힣a-zA-Z0-9_]+$/.test(n)) return { ok: false, msg: '한글·영문·숫자·_만 쓸 수 있어요 (공백·자음 단독 불가)' };
    if (Component.NICK_BANNED.some(w => n.toLowerCase().includes(w.toLowerCase()))) return { ok: false, msg: '사용할 수 없는 단어가 들어 있어요' };
    if (n !== own && this.rankUsers().some(u => u.nick === n)) return { ok: false, msg: '이미 사용 중인 닉네임이에요' };
    return { ok: true, msg: '사용할 수 있는 닉네임이에요' };
  };
  setHomeTab = (t) => () => { if (this.state.homeTab !== t) this.setState({ homeTab: t }); };
  goPredTab = () => { this.setState({ appScreen: 'home', homeTab: 'pred' }); this.simulateLoad('loadingHome'); };
  onHomeSwipeDown = (e) => { this._sw = e.target.closest && e.target.closest('[data-noswipe],input') ? null : { x: e.clientX, y: e.clientY }; };
  static HOME_TABS = ['home', 'pred', 'att'];
  startNickEdit = () => this.setState(s => ({ nickEditing: true, nickDraft: s.profile ? s.profile.nick : '' }));
  cancelNickEdit = () => this.setState({ nickEditing: false });
  onNickDraft = (e) => this.setState({ nickDraft: e.target.value.slice(0, 10) });
  onNickKey = (e) => { if (e.key === 'Enter') this.saveNick(); if (e.key === 'Escape') this.cancelNickEdit(); };
  saveNick = () => {
    const s = this.state, prev = s.profile, nick = s.nickDraft.trim();
    if (prev && nick === prev.nick) { this.setState({ nickEditing: false }); return; }
    if (!this.nickCheck(nick, prev && prev.nick).ok) return;
    if (this.netFail()) { this.showToast(this.failMsg('닉네임을 바꾸지')); return; }
    const d = new Date();
    const profile = prev ? { ...prev, nick } : { nick, team: s.selectedTeam || 'SK호크스', uid: 'anon-' + Math.random().toString(36).slice(2, 10), since: `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}` };
    try { localStorage.setItem('mh_profile', JSON.stringify(profile)); localStorage.setItem('mh_nick', nick); } catch (e) {}
    this.setState({ profile, nickEditing: false });
    this.showToast('닉네임을 바꿨어요');
  };
  onHomeSwipeUp = (e) => {
    const s = this._sw; this._sw = null; if (!s) return;
    const dx = e.clientX - s.x, dy = e.clientY - s.y;
    if (Math.abs(dx) < 60 || Math.abs(dx) < Math.abs(dy) * 1.5) return;
    const T = Component.HOME_TABS, i = T.indexOf(this.state.homeTab), j = Math.max(0, Math.min(T.length - 1, i + (dx < 0 ? 1 : -1)));
    if (j !== i) this.setState({ homeTab: T[j] });
  };
  // TODO(v3): 배지 조건·획득일은 서버 기준으로 교체
  buildBadges = (attDecided, diff, hits, guideN, c) => {
    const star = 'M30 17 l3.2 6.6 7.2.9-5.3 5 1.4 7.1-6.5-3.6-6.5 3.6 1.4-7.1-5.3-5 7.2-.9z';
    const heart = 'M30 39 C19 32 17 23 23 20.5 C26.5 19 29 21 30 23.5 C31 21 33.5 19 37 20.5 C43 23 41 32 30 39 Z';
    const check = 'M20 28.5 L27 35.5 L40 21.5';
    const defs = [
      { name: '승리 요정', earned: attDecided >= 3 && diff > 0, subOn: `내가 가면 승률 +${diff}%p`, subOff: attDecided < 3 ? `응원 경기 ${attDecided}/3` : '직관 승률이 팀보다 높으면', pct: Math.min(1, attDecided / 3), open: this.goAttTab,
        r1: '#C2185B', r2: '#E5487D', c0: '#D63D72', c1: '#FF7FA6', c2: '#FF9DBB', glyph: heart, gFill: '#fff', gStroke: '#D63D72', gW: 1.2, bg: '#FFE6EE', nameColor: '#8A1C45', subColor: '#B0305E', bar: '#E5487D' },
      { name: '예측 고수', earned: hits >= 10, subOn: `적중 ${hits}회 달성`, subOff: `적중 ${Math.min(hits, 10)}/10`, pct: Math.min(1, hits / 10), open: this.goPredTab,
        r1: '#003C99', r2: '#0050C8', c0: '#0050C8', c1: '#0068FF', c2: '#3D8BFF', glyph: check, gFill: 'none', gStroke: '#fff', gW: 4.5, bg: '#E3EEFF', nameColor: '#00347F', subColor: '#0050C8', bar: '#0068FF' },
      { name: '입문 수료', earned: guideN >= 5, subOn: this.state.guideGradDate ? `${this.state.guideGradDate} 수료` : '가이드 완료', subOff: `레슨 ${guideN}/5`, pct: Math.min(1, guideN / 5), open: this.openGuide,
        r1: '#0050C8', r2: '#0068FF', c0: '#D9A400', c1: '#FFC800', c2: '#FFD43B', glyph: star, gFill: '#fff', gStroke: '#D9A400', gW: 1.2, bg: '#FFF4CC', nameColor: '#6b4500', subColor: '#8a6a00', bar: '#FFC800' },
    ];
    const myBadges = defs.map(d => ({ ...d, locked: !d.earned, sub: d.earned ? d.subOn : d.subOff, pct: Math.round(d.pct * 100) + '%',
      op: d.earned ? 1 : 0.35, filter: d.earned ? 'none' : 'grayscale(1)', bg: d.earned ? d.bg : c.card, nameColor: d.earned ? d.nameColor : c.text }));
    return { myBadges, myBadgeCount: `${myBadges.filter(b => b.earned).length}/3 획득` };
  };
  goAttTab = () => { this.setState({ appScreen: 'home', homeTab: 'att' }); this.simulateLoad('loadingHome'); };
  openAttSheet = () => this.setState({ attSheetOpen: true });
  closeAttSheet = () => this.setState({ attSheetOpen: false });
  toggleAttPool = (x) => () => this.setState(s => {
    const base = (!s.attTouched && Object.keys(s.attended).length === 0) ? { ...(this._effAtt || {}) } : { ...s.attended };
    if (base[x.id]) delete base[x.id]; else base[x.id] = { raw: x.raw, venue: x.venue, cheer: x.cheer !== undefined ? x.cheer : null, savedAt: x.savedAt };
    try { localStorage.setItem('mh_attended', JSON.stringify(base)); } catch (e) {}
    return { attended: base, attTouched: true };
  });
  openProfile = () => this.setState(s => {
    const p = s.profile, team = p ? p.team : (s.selectedTeam || 'SK호크스');
    return { pfOpen: true, pfEdit: !!p, pfNick: p ? p.nick : '', pfTeam: team, pfGender: this.genderOf(team), pfConsent: !!p };
  });
  closeProfile = () => { const pend = this.state.pfPending; this.setState({ pfOpen: false, pfPending: null }); if (pend) this.applyPick(pend.g, pend.k); };
  onPfNick = (e) => this.setState({ pfNick: e.target.value.slice(0, 10) });
  suggestNick = () => {
    const A = Component.NICK_A, B = Component.NICK_B;
    for (let i = 0; i < 20; i++) { const n = A[Math.floor(Math.random() * A.length)] + B[Math.floor(Math.random() * B.length)] + (10 + Math.floor(Math.random() * 89)); if (this.nickCheck(n).ok) { this.setState({ pfNick: n }); return; } }
  };
  pfSetGender = (g) => () => this.setState({ pfGender: g });
  pfPickTeam = (t) => () => this.setState({ pfTeam: t });
  togglePfConsent = () => this.setState(s => ({ pfConsent: !s.pfConsent }));
  saveProfile = () => {
    const s = this.state, prev = s.profile, chk = this.nickCheck(s.pfNick, prev && prev.nick);
    if (!chk.ok || !s.pfConsent || !s.pfTeam) return;
    if (this.netFail()) { this.showToast(this.failMsg('프로필을 저장하지')); return; }
    const d = new Date();
    const profile = { nick: s.pfNick.trim(), team: s.pfTeam, uid: (prev && prev.uid) || ('anon-' + Math.random().toString(36).slice(2, 10)), since: (prev && prev.since) || `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}` };
    try {
      localStorage.setItem('mh_profile', JSON.stringify(profile)); localStorage.setItem('mh_nick', profile.nick);
      const ob = JSON.parse(localStorage.getItem('mh_onboarded') || 'null'); if (ob) localStorage.setItem('mh_onboarded', JSON.stringify({ ...ob, team: profile.team, gender: this.genderOf(profile.team) }));
    } catch (e) {}
    const pend = s.pfPending;
    this.setState({ profile, pfOpen: false, pfPending: null, selectedTeam: profile.team, teamGender: this.genderOf(profile.team), rankGender: this.genderOf(profile.team) });
    if (pend) this.applyPick(pend.g, pend.k);
    this.showToast(prev ? '프로필을 저장했어요' : `${profile.nick}님, 랭킹에 참여했어요`);
  };
  leaveRanking = () => {
    try { localStorage.removeItem('mh_profile'); } catch (e) {}
    this.setState({ profile: null, pfOpen: false });
    this.showToast('랭킹 참여를 중단했어요. 예측 기록은 기기에 남아요');
  };
  applyPick = (g, k) => this.setState(s => {
    const preds = { ...s.preds, [g.id]: { ...(s.preds[g.id] || {}), pick: k, match: `${g.teamA} vs ${g.teamB}`, teamA: g.teamA, teamB: g.teamB, date: g.dateShort || '' } };
    try { localStorage.setItem('mh_preds', JSON.stringify(preds)); } catch (e) {} return { preds };
  });
  pickPredFor = (g, k) => () => {
    if (!this.state.profile) { this.setState({ pfPending: { g, k } }); this.openProfile(); return; }
    this.applyPick(g, k);
  };

  simulateLoad = (key, ms = 500) => {
    this.setState({ [key]: true });
    clearTimeout(this['_t_' + key]);
    this['_t_' + key] = setTimeout(() => this.setState({ [key]: false }), ms);
  };

  stickerImages = [
    'figassets/sticker-goal.png', 'figassets/sticker-ball.png', 'figassets/sticker-goaltext.png', 'figassets/sticker-mascot.png',
    'figassets/sticker-bolt.png', 'figassets/sticker-heart.png', 'figassets/sticker-playhard.png', 'figassets/sticker-arrow.png',
  ];
  photoAreaRef = React.createRef();

  setThemeLight = () => this.setState({ theme: 'light' });
  setThemeDark = () => this.setState({ theme: 'dark' });
  openMyTeamDetail = () => this.setState(s => ({ appScreen: 'stat', teamDetailName: s.selectedTeam || 'SK호크스', teamDetailTab: 'info' }));
  toggleNotif = () => this.setState(s => ({ notifOn: !s.notifOn }));
  openSettings = () => this.setState({ settingsOpen: true });
  closeSettings = () => this.setState({ settingsOpen: false });
  setThemeToggle = () => this.setState(s => ({ theme: s.theme === 'dark' ? 'light' : 'dark' }));
  openSeasonPicker = () => this.setState({ seasonPickerOpen: true });
  closeSeasonPicker = () => this.setState({ seasonPickerOpen: false });
  openPolicy = () => this.setState({ policyOpen: true });
  closePolicy = () => this.setState({ policyOpen: false });
  openTerms = () => this.setState({ termsOpen: true });
  closeTerms = () => this.setState({ termsOpen: false });
  restartOnboarding = () => { try { localStorage.removeItem('mh_onboarded'); } catch (e) {} this.setState(s => ({ inApp: false, step: 0, pfNick: s.profile ? s.profile.nick : '' })); };
  componentDidMount() {
    try { const p = JSON.parse(localStorage.getItem('mh_preds') || '{}'); const m = JSON.parse(localStorage.getItem('mh_mvp') || '{}'); this.setState({ preds: p || {}, mvpVotes: m || {} }); } catch (e) {}
    try { const gd = JSON.parse(localStorage.getItem('mh_guide') || 'null'); if (gd) this.setState({ guideDone: gd.done || [], guideGradDate: gd.gradDate || '' }); } catch (e) {}
    try { const rawAt = localStorage.getItem('mh_attended'); const at = JSON.parse(rawAt || '{}'); if (at && typeof at === 'object') this.setState({ attended: at, attTouched: rawAt !== null }); } catch (e) {}
    try { const md = JSON.parse(localStorage.getItem('mh_moderation') || 'null'); if (md) this.setState({ blocked: md.blocked || [], reportedKeys: md.reportedKeys || [] }); } catch (e) {}
    try { const rs = JSON.parse(localStorage.getItem('mh_recent_search') || '[]'); if (Array.isArray(rs)) this.setState({ recentSearches: rs }); } catch (e) {}
    try { const ch = JSON.parse(localStorage.getItem('mh_cheer') || 'null'); if (ch) this.setState({ cheerByTeam: ch.byTeam || {}, cheerLiked: ch.liked || [] }); } catch (e) {}
    try { const fav = JSON.parse(localStorage.getItem('mh_fav_players') || '[]'); if (Array.isArray(fav)) this.setState({ favPlayerIds: fav }); } catch (e) {}
    try { const pf = JSON.parse(localStorage.getItem('mh_profile') || 'null'); if (pf && pf.nick) this.setState({ profile: pf }); } catch (e) {}
    if ((this.props.rememberOnboarding ?? true) === false) return;
    try {
      const saved = JSON.parse(localStorage.getItem('mh_onboarded') || 'null');
      if (saved) this.setState({ inApp: true, selectedTeam: saved.team || null, teamGender: saved.gender || 'M', rankGender: this.genderOf(saved.team) });
    } catch (e) {}
  }
  componentDidUpdate(prev) {
    if (prev.demoState !== this.props.demoState && this.state.errDismissed) this.setState({ errDismissed: false });
    if (prev.rememberOnboarding !== false && this.props.rememberOnboarding === false) { try { localStorage.removeItem('mh_onboarded'); } catch (e) {} this.setState({ inApp: false, step: 0 }); }
  }
  saveCardImage = () => {
    this.setState({ cardSaveStatus: 'saving' });
    setTimeout(() => this.setState({ cardSaveStatus: 'done' }), 500);
    setTimeout(() => this.setState({ cardSaveStatus: 'idle' }), 2000);
  };
  openTeamPicker = () => this.setState(s => ({ teamPickerOpen: true, pickerGender: s.teamGender || 'M' }));
  closeTeamPicker = () => this.setState({ teamPickerOpen: false });
  pickerGenderM = () => this.setState({ pickerGender: 'M' });
  pickerGenderW = () => this.setState({ pickerGender: 'W' });
  openCardEdit = () => this.setState({ cardEditOpen: true });
  closeCardEdit = () => this.setState({ cardEditOpen: false });
  saveCardEdit = () => this.setState(s => ({
    cardEditOpen: false,
    savedStickers: s.placedStickers.map(st => ({ ...st, yScaled: st.y * (340 / 436) })),
  }));
  onCanvasDragOver = (e) => { e.preventDefault(); };
  onCanvasDrop = (e) => {
    e.preventDefault();
    const image = e.dataTransfer.getData('text/plain');
    if (!image || !this.photoAreaRef.current) return;
    const rect = this.photoAreaRef.current.getBoundingClientRect();
    const x = Math.max(0, Math.min(rect.width - 48, e.clientX - rect.left - 24));
    const y = Math.max(0, Math.min(rect.height - 48, e.clientY - rect.top - 24));
    const id = 'st' + Date.now() + Math.random().toString(36).slice(2, 6);
    this.setState(s => ({ placedStickers: [...s.placedStickers, { id, image, x, y }] }));
  };
  onStickerDown = (id) => (e) => {
    e.preventDefault();
    e.stopPropagation();
    this.setState({ draggingStickerId: id });
    try { e.target.setPointerCapture(e.pointerId); } catch (_) {}
  };
  onStickerMove = (e) => {
    const dragId = this.state.draggingStickerId;
    if (!dragId || !this.photoAreaRef.current) return;
    e.preventDefault();
    const rect = this.photoAreaRef.current.getBoundingClientRect();
    let x = e.clientX - rect.left - 24;
    let y = e.clientY - rect.top - 24;
    x = Math.max(0, Math.min(rect.width - 48, x));
    y = Math.max(0, Math.min(rect.height - 48, y));
    this.setState(s => ({ placedStickers: s.placedStickers.map(st => st.id === dragId ? { ...st, x, y } : st) }));
  };
  onStickerUp = (e) => {
    try { e.target.releasePointerCapture(e.pointerId); } catch (_) {}
    this.setState({ draggingStickerId: null });
  };

  goPrev = () => this.setState(s => ({ step: Math.max(0, s.step - 1) }));
  goNext = () => this.setState(s => ({ step: Math.min(5, s.step + 1) }));
  selectInterestFlow = () => this.setState({ interest: 'flow' });
  selectInterestCheer = () => this.setState({ interest: 'cheer' });
  selectInterestHighlight = () => this.setState({ interest: 'highlight' });
  selectInterestRank = () => this.setState({ interest: 'rank' });
  selectMale = () => this.setState({ gender: 'M' });
  selectFemale = () => this.setState({ gender: 'W' });
  selectTeamGenderM = () => this.setState({ teamGender: 'M', selectedTeam: null });
  selectTeamGenderW = () => this.setState({ teamGender: 'W', selectedTeam: null });
  goHome = () => { this.setState({ appScreen: 'home' }); this.simulateLoad('loadingHome'); };
  goSchedule = () => { this.setState({ appScreen: 'schedule' }); this.simulateLoad('loadingSchedule'); };
  goStat = () => { this.setState({ appScreen: 'stat' }); this.simulateLoad('loadingStat'); };
  goMy = () => this.setState({ appScreen: 'my' });
  rankSelectM = () => {
    this.setState({ rankGender: 'M', selectedDay: null });
    this.simulateLoad(this.state.appScreen === 'schedule' ? 'loadingSchedule' : this.state.appScreen === 'stat' ? 'loadingStat' : 'loadingHome');
  };
  rankSelectW = () => {
    this.setState({ rankGender: 'W', selectedDay: null });
    this.simulateLoad(this.state.appScreen === 'schedule' ? 'loadingSchedule' : this.state.appScreen === 'stat' ? 'loadingStat' : 'loadingHome');
  };
  monthPrev = () => { this.setState(s => ({ monthOffset: s.monthOffset - 1, selectedDay: null, calSelDay: null })); this.simulateLoad('loadingSchedule'); };
  monthNext = () => { this.setState(s => ({ monthOffset: s.monthOffset + 1, selectedDay: null, calSelDay: null })); this.simulateLoad('loadingSchedule'); };
  openYmPicker = () => this.setState(s => ({ ymPickerOpen: true, ymPickerYear: new Date(2026, 4 + s.monthOffset, 1).getFullYear() }));
  closeYmPicker = () => this.setState({ ymPickerOpen: false });
  ymYearPrev = () => this.setState(s => ({ ymPickerYear: s.ymPickerYear - 1 }));
  ymYearNext = () => this.setState(s => ({ ymPickerYear: s.ymPickerYear + 1 }));
  setYm = (y, m) => { this.setState({ monthOffset: (y - 2026) * 12 + (m - 4), selectedDay: null, calSelDay: null, ymPickerOpen: false }); this.simulateLoad('loadingSchedule'); };
  ymToday = () => this.setYm(2026, 4);
  schedToList = () => this.setState({ schedView: 'list' });
  schedToCal = () => this.setState({ schedView: 'cal', calSelDay: null });
  goMyCal = () => { this.setState({ appScreen: 'schedule', schedView: 'cal', calSelDay: null }); this.simulateLoad('loadingSchedule'); };
  openCompare = (a, b) => this.setState({ cmpOpen: true, cmpA: a || null, cmpB: b || null, cmpPicking: a && b ? null : (a ? 'B' : 'A'), cardPlayerId: null });
  closeCmp = () => this.setState({ cmpOpen: false, cmpPicking: null });
  // TODO(v3): MY팀 달력 일정은 목업 — 연맹 경기 일정 API로 교체 (기준일 2026-05-24)
  myCalGames = (team, opps, off) => {
    const base = new Date(2026, 4 + off, 1), y = base.getFullYear(), m = base.getMonth(), dim = new Date(y, m + 1, 0).getDate();
    const today = new Date(2026, 4, 24, 12, 0), out = [], r = this.rng(team + y + '-' + m);
    for (let d = 1; d <= dim && out.length < 6; d++) {
      const wd = new Date(y, m, d).getDay(), isToday = off === 0 && d === 24;
      if (!(isToday || (wd === 6 && !(off === 0 && d === 23)) || (wd === 3 && (d + m) % 2 === 0))) continue;
      const k = out.length, idx = m * 5 + k + y;
      const time = wd === 3 ? '19:00' : wd === 0 ? '15:00' : (k % 2 ? '16:00' : '14:00');
      const [hh, mi] = time.split(':').map(Number), date = new Date(y, m, d, hh, mi);
      const status = isToday ? 'live' : date < today ? 'final' : 'pre';
      let my = 22 + Math.floor(r() * 10), op = 22 + Math.floor(r() * 10);
      if (isToday) { my = 13; op = 11; }
      out.push({ day: d, wd, opp: opps[idx % opps.length], home: idx % 2 === 0, time, status, my, op, date });
    }
    return out;
  };
  downloadIcs = (games, fname) => {
    if (this.netFail()) { this.showToast(this.failMsg('캘린더에 추가하지')); return; }
    if (!games.length) { this.showToast('추가할 예정 경기가 없어요'); return; }
    const p2 = (n) => String(n).padStart(2, '0');
    const fmt = (d) => `${d.getFullYear()}${p2(d.getMonth() + 1)}${p2(d.getDate())}T${p2(d.getHours())}${p2(d.getMinutes())}00`;
    const L = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//MyHandball//KO', 'CALSCALE:GREGORIAN', 'X-WR-CALNAME:마이핸드볼'];
    games.forEach(g => { const e = new Date(g.start.getTime() + 2 * 3600e3);
      L.push('BEGIN:VEVENT', `UID:${g.uid}@myhandball`, `DTSTART;TZID=Asia/Seoul:${fmt(g.start)}`, `DTEND;TZID=Asia/Seoul:${fmt(e)}`, `SUMMARY:${g.summary}`, `LOCATION:${g.venue}`,
        'BEGIN:VALARM', 'TRIGGER:-PT30M', 'ACTION:DISPLAY', 'DESCRIPTION:경기 30분 전', 'END:VALARM', 'END:VEVENT'); });
    L.push('END:VCALENDAR');
    try { const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([L.join('\r\n')], { type: 'text/calendar;charset=utf-8' })); a.download = fname; document.body.appendChild(a); a.click(); a.remove(); } catch (e) {}
    this.setState({ icsSaved: true }); this.showToast(`캘린더 파일을 저장했어요 (${games.length}경기)`); clearTimeout(this._icsT); this._icsT = setTimeout(() => this.setState({ icsSaved: false }), 2200);
  };
  static W_TEAMS = ['SK슈가글라이더즈', '삼척시청', '부산시설공단', '경남개발공사', '대구광역시청', '서울시청', '광주도시공사', '인천광역시청'];
  genderOf = (name) => (Component.W_TEAMS.includes(name) ? 'W' : 'M');
  toggleFav = (id) => (e) => {
    if (e) e.stopPropagation();
    this.setState(s => {
      const favPlayerIds = s.favPlayerIds.includes(id) ? s.favPlayerIds.filter(x => x !== id) : [id, ...s.favPlayerIds];
      try { localStorage.setItem('mh_fav_players', JSON.stringify(favPlayerIds)); } catch (err) {}
      return { favPlayerIds };
    });
  };
  toggleIntro = () => this.setState(s => ({ introExpanded: !s.introExpanded }));
  toggleHistory = () => this.setState(s => ({ historyExpanded: !s.historyExpanded }));
  onCheerInput = (e) => this.setState({ cheerDraft: e.target.value.slice(0, 200) });
  persistCheer = (s) => { try { localStorage.setItem('mh_cheer', JSON.stringify({ byTeam: s.cheerByTeam, liked: s.cheerLiked })); } catch (e) {} };
  submitCheer = () => {
    if (this.netFail()) { this.showToast(this.failMsg('응원글을 등록하지')); return; }
    const text = this.state.cheerDraft.trim(); const team = this.state.teamDetailName;
    if (!text || !team) return;
    const d = new Date(); const date = `${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}`;
    this.setState(s => {
      const post = { id: 'u' + Date.now(), author: this.nickname(), team: (s.profile && s.profile.team) || s.selectedTeam || team, text, date, likes: 0, mine: true };
      const next = { cheerDraft: '', cheerByTeam: { ...s.cheerByTeam, [team]: [post, ...(s.cheerByTeam[team] || [])] } };
      this.persistCheer({ ...s, ...next }); return next;
    });
  };
  nickname = () => {
    if (this.state.profile) return this.state.profile.nick;
    try { let n = localStorage.getItem('mh_nick'); if (!n) { n = '핸드볼팬' + String(Math.floor(1000 + Math.random() * 9000)); localStorage.setItem('mh_nick', n); } return n; } catch (e) { return '핸드볼팬'; }
  };
  // TODO(v3): 신고 POST /reports {postId, reason, detail} (409 = 이미 신고) · 차단 POST/DELETE /blocks
  static REPORT_REASONS = [['spam', '스팸·광고'], ['abuse', '욕설·비방·혐오 표현'], ['sexual', '음란·선정적인 내용'], ['other', '기타']];
  persistMod = (blocked, reportedKeys) => { try { localStorage.setItem('mh_moderation', JSON.stringify({ blocked, reportedKeys })); } catch (e) {} };
  closeCheerMenu = () => this.setState({ cheerMenu: null });
  menuDelete = () => this.setState(s => ({ cheerMenu: null, cheerConfirmId: s.cheerMenu && s.cheerMenu.id }));
  menuReport = () => this.setState(s => ({ cheerMenu: null, reportPost: s.cheerMenu, reportReason: null, reportDetail: '', reportBlock: false }));
  menuBlock = () => this.setState(s => ({ cheerMenu: null, blockAsk: s.cheerMenu }));
  closeReport = () => this.setState({ reportPost: null });
  onReportDetail = (e) => this.setState({ reportDetail: e.target.value.slice(0, 200) });
  toggleReportBlock = () => this.setState(s => ({ reportBlock: !s.reportBlock }));
  submitReport = () => {
    const s = this.state, p = s.reportPost; if (!p || !s.reportReason) return;
    if (s.reportReason === 'other' && !s.reportDetail.trim()) return;
    if (this.netFail()) { this.showToast(this.failMsg('신고를 접수하지')); return; }
    if (s.reportedKeys.includes(p.key)) { this.setState({ reportPost: null }); this.showToast('이미 신고한 응원글이에요'); return; }
    const reportedKeys = [...s.reportedKeys, p.key];
    const blocked = s.reportBlock && !s.blocked.some(b => b.nick === p.author) ? [...s.blocked, { nick: p.author, team: p.team, since: this.todayStr() }] : s.blocked;
    this.persistMod(blocked, reportedKeys);
    this.setState({ reportPost: null, reportedKeys, blocked });
    this.showToast(s.reportBlock ? '신고하고 이 사용자의 글을 숨겼어요' : '신고가 접수됐어요. 검토 후 조치할게요');
  };
  cancelBlock = () => this.setState({ blockAsk: null });
  confirmBlock = () => {
    const s = this.state, p = s.blockAsk; if (!p) return;
    if (this.netFail()) { this.showToast(this.failMsg('차단하지')); return; }
    const blocked = s.blocked.some(b => b.nick === p.author) ? s.blocked : [...s.blocked, { nick: p.author, team: p.team, since: this.todayStr() }];
    this.persistMod(blocked, s.reportedKeys); this.setState({ blockAsk: null, blocked });
    this.showToast(`${p.author}님의 글을 더 이상 보지 않아요`);
  };
  unblock = (nick) => () => {
    if (this.netFail()) { this.showToast(this.failMsg('차단을 해제하지')); return; }
    const blocked = this.state.blocked.filter(b => b.nick !== nick); this.persistMod(blocked, this.state.reportedKeys); this.setState({ blocked });
    this.showToast(`${nick}님 차단을 해제했어요`);
  };
  openBlocked = () => this.setState({ blockedOpen: true });
  closeBlocked = () => this.setState({ blockedOpen: false });
  todayStr = () => { const d = new Date(); return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}`; };
  deleteCheer = (id) => () => this.setState(s => {
    const team = s.teamDetailName;
    const next = { cheerConfirmId: null, cheerByTeam: { ...s.cheerByTeam, [team]: (s.cheerByTeam[team] || []).filter(p => p.id !== id) } };
    this.persistCheer({ ...s, ...next }); return next;
  });
  toggleCheerLike = (key) => () => this.setState(s => {
    const cheerLiked = s.cheerLiked.includes(key) ? s.cheerLiked.filter(k => k !== key) : [...s.cheerLiked, key];
    this.persistCheer({ ...s, cheerLiked }); return { cheerLiked };
  });
  searchInputRef = React.createRef();
  openSearch = () => { this.setState({ searchOpen: true, searchQuery: '' }, () => setTimeout(() => this.searchInputRef.current && this.searchInputRef.current.focus(), 50)); };
  closeSearch = () => this.setState({ searchOpen: false });
  onSearchInput = (e) => this.setState({ searchQuery: e.target.value });
  clearSearch = () => { this.setState({ searchQuery: '' }); this.searchInputRef.current && this.searchInputRef.current.focus(); };
  saveRecent = (q) => this.setState(s => {
    const recentSearches = [q, ...s.recentSearches.filter(x => x !== q)].slice(0, 8);
    try { localStorage.setItem('mh_recent_search', JSON.stringify(recentSearches)); } catch (e) {}
    return { recentSearches };
  });
  onSearchKey = (e) => { if (e.key === 'Enter' && this.state.searchQuery.trim()) this.saveRecent(this.state.searchQuery.trim()); };
  removeRecent = (q) => () => this.setState(s => { const recentSearches = s.recentSearches.filter(x => x !== q); try { localStorage.setItem('mh_recent_search', JSON.stringify(recentSearches)); } catch (e) {} return { recentSearches }; });
  clearRecent = () => { try { localStorage.removeItem('mh_recent_search'); } catch (e) {} this.setState({ recentSearches: [] }); };
  retryWith = (key) => () => { this.setState({ errDismissed: true }); this.simulateLoad(key); };
  retryTeamDetail = this.retryWith('loadingTeamDetail');
  retryGame = () => this.setState({ errDismissed: true });
  retryMy = () => this.setState({ errDismissed: true });
  netFail = () => { const d = this.props.demoState; return (d === '오프라인' || d === '서버 오류') && !this.state.errDismissed ? d : null; };
  showToast = (msg) => { this.setState({ toast: msg }); clearTimeout(this._toastT); this._toastT = setTimeout(() => this.setState({ toast: null }), 2400); };
  failMsg = (what) => this.netFail() === '오프라인' ? `오프라인 상태라 ${what} 못했어요. 연결을 확인해 주세요.` : `일시적인 오류로 ${what} 못했어요. 잠시 후 다시 시도해 주세요.`;
  retryHome = this.retryWith('loadingHome'); retryStat = this.retryWith('loadingStat'); retrySchedule = this.retryWith('loadingSchedule');
  // ---- 경기 상세 / 문자중계 ----
  rng = (seedStr) => { let h = 2166136261; for (const ch of seedStr) { h ^= ch.charCodeAt(0); h = Math.imul(h, 16777619); } return () => { h ^= h << 13; h ^= h >>> 17; h ^= h << 5; return ((h >>> 0) % 10000) / 10000; }; };
  roster = (team) => {
    const r = (this._rosters || {})[team];
    const generic = [7, 9, 11, 14, 21, 23, 33, 5].map(n => `${team} ${n}번`);
    const known = r ? r.field : [];
    return { field: [...known, ...generic], known: known.length, gk: r && r.gk.length ? r.gk[0] : `${team} 골키퍼` };
  };
  pickScorer = (ros, r) => {
    const w = ros.field.map((_, i) => (i < ros.known ? 2.2 : 1) / (1 + i * 0.12));
    const sum = w.reduce((a, b) => a + b, 0); let x = r * sum;
    for (let i = 0; i < w.length; i++) { x -= w[i]; if (x <= 0) return ros.field[i]; }
    return ros.field[ros.field.length - 1];
  };
  mkEvent = (type, min, side, g, extra) => ({ id: g.id + ':' + type + ':' + min + ':' + (extra && extra.n || 0) + ':' + side, type, min, side, ...extra });
  genEvents = (g, upTo) => {
    const rand = this.rng(g.id + g.scoreA + ':' + g.scoreB);
    const total = g.scoreA + g.scoreB; const evs = [this.mkEvent('start', 0, null, g)];
    const mins = Array.from({ length: total }, () => 1 + Math.floor(rand() * Math.max(1, upTo - 1))).sort((a, b) => a - b);
    let a = 0, b = 0, remA = g.scoreA, remB = g.scoreB;
    mins.forEach((m, i) => {
      const side = remA && (!remB || rand() < remA / (remA + remB)) ? 'A' : 'B';
      if (side === 'A') { a++; remA--; } else { b++; remB--; }
      const team = side === 'A' ? g.teamA : g.teamB; const ros = this.roster(team);
      const who = this.pickScorer(ros, rand());
      const seven = rand() < 0.12;
      evs.push(this.mkEvent('goal', m, side, g, { n: i, who, seven, a, b }));
      if (rand() < 0.14) { const os = side === 'A' ? 'B' : 'A'; evs.push(this.mkEvent('save', m, os, g, { n: i + 500, who: this.roster(os === 'A' ? g.teamA : g.teamB).gk })); }
      if (rand() < 0.07) { const ps = rand() < 0.5 ? 'A' : 'B'; const pr = this.roster(ps === 'A' ? g.teamA : g.teamB); evs.push(this.mkEvent('two', m, ps, g, { n: i + 900, who: pr.field[Math.floor(rand() * pr.field.length)] })); }
    });
    if (upTo >= 30) evs.push(this.mkEvent('half', 30, null, g, { n: 1 }));
    if (g.status === 'final') evs.push(this.mkEvent('end', 60, null, g, { n: 2 }));
    return evs.sort((x, y) => x.min - y.min || (x.type === 'half' ? 1 : 0) - (y.type === 'half' ? 1 : 0));
  };
  openGame = (raw) => {
    if (this.hgJustDragged) return;
    if (this.props.demoState === '비시즌' && raw.status === 'live') raw = { ...raw, status: 'final' };
    const num = (v) => { const n = parseInt(v, 10); return isNaN(n) ? 0 : n; };
    const status = raw.status;
    const g = { ...raw, scoreA: num(raw.scoreA), scoreB: num(raw.scoreB), minute: status === 'live' ? (raw.minute || 42) : status === 'final' ? 60 : 0 };
    const gdEvents = status === 'pre' ? [] : this.genEvents(g, g.minute);
    clearInterval(this.liveTimer);
    this.setState({ gd: g, gdEvents, gdTab: status === 'pre' ? 'predict' : 'live' }, () => { if (status === 'live') this.liveTimer = setInterval(this.liveTick, 2400); });
  };
  liveTick = () => {
    const s = this.state; if (!s.gd || s.gd.status !== 'live') { clearInterval(this.liveTimer); return; }
    const g = { ...s.gd }; g.minute += 1;
    const evs = [...s.gdEvents]; const r = Math.random();
    if (g.minute === 30) evs.push(this.mkEvent('half', 30, null, g, { n: 1 }));
    if (r < 0.55) {
      const side = r < 0.28 ? 'A' : 'B'; if (side === 'A') g.scoreA++; else g.scoreB++;
      const ros = this.roster(side === 'A' ? g.teamA : g.teamB);
      evs.push(this.mkEvent('goal', g.minute, side, g, { n: Date.now(), who: this.pickScorer(ros, Math.random()), seven: Math.random() < 0.12, a: g.scoreA, b: g.scoreB, fresh: true }));
    } else if (r < 0.68) {
      const side = r < 0.61 ? 'A' : 'B'; evs.push(this.mkEvent('save', g.minute, side, g, { n: Date.now(), who: this.roster(side === 'A' ? g.teamA : g.teamB).gk, fresh: true }));
    }
    if (g.minute >= 60) { g.status = 'final'; g.minute = 60; evs.push(this.mkEvent('end', 60, null, g, { n: 2 })); clearInterval(this.liveTimer); }
    this.setState({ gd: g, gdEvents: evs.map(e => e.fresh && e.min < g.minute ? { ...e, fresh: false } : e) });
  };
  toggleAttend = () => { if (this.netFail() && this.state.gd && !this.state.attended[this.state.gd.id]) this.showToast('기기에 저장했어요. 연결되면 자동으로 동기화돼요.'); this._toggleAttend(); };
  _toggleAttend = () => this.setState(s => {
    const g = s.gd; if (!g) return null;
    const attended = (!s.attTouched && Object.keys(s.attended).length === 0) ? { ...(this._effAtt || {}) } : { ...s.attended };
    if (attended[g.id]) delete attended[g.id];
    else attended[g.id] = { raw: { id: g.id, teamA: g.teamA, teamB: g.teamB, scoreA: g.scoreA, scoreB: g.scoreB, status: g.status === 'live' ? 'final' : g.status, meta: g.meta, dateShort: g.dateShort, time: g.time }, venue: g.venue || '경기장', cheer: [g.teamA, g.teamB].includes(s.selectedTeam || 'SK호크스') ? (s.selectedTeam || 'SK호크스') : null, savedAt: Date.now() };
    try { localStorage.setItem('mh_attended', JSON.stringify(attended)); } catch (e) {}
    return { attended, attTouched: true };
  });
  closeGame = () => { clearInterval(this.liveTimer); this.setState({ gd: null }); };
  pickPred = (id, pick) => () => this.setState(s => {
    const preds = { ...s.preds, [id]: { ...(s.preds[id] || {}), pick, match: `${s.gd.teamA} vs ${s.gd.teamB}`, teamA: s.gd.teamA, teamB: s.gd.teamB, date: s.gd.dateShort || '' } };
    try { localStorage.setItem('mh_preds', JSON.stringify(preds)); } catch (e) {} return { preds };
  });
  voteMvp = (id, key) => () => this.setState(s => {
    if (s.mvpVotes[id]) return null;
    const mvpVotes = { ...s.mvpVotes, [id]: key }; try { localStorage.setItem('mh_mvp', JSON.stringify(mvpVotes)); } catch (e) {} return { mvpVotes };
  });
  componentWillUnmount() { clearInterval(this.liveTimer); }
  // ---- 입문 가이드 ----
  LESSONS = [
    { id: 'l1', title: '핸드볼 기본', steps: [
      { scene: 'intro', title: '7명 vs 7명', body: '한 팀 7명(필드 6명 + 골키퍼 1명)이 공을 손으로 패스하고 던져서 상대 골대에 넣는 스포츠예요.' },
      { scene: 'time', title: '경기 시간은 60분', body: '전반 30분, 후반 30분이고 사이에 10분을 쉬어요. 공수 전환이 쉴 새 없이 이어져서 정말 빨라요!' },
      { scene: 'win', title: '골을 더 많이 넣으면 승리', body: '공이 골라인을 완전히 넘으면 1점! 한 경기에 두 팀 합쳐 50골 넘게 터지는 경우가 많아요.' } ],
      quiz: { q: '한 팀이 코트에서 동시에 뛰는 선수는 몇 명일까요?', opts: ['6명', '7명', '11명'], a: 1, explain: '필드 플레이어 6명 + 골키퍼 1명, 총 7명이에요.' } },
    { id: 'l2', title: '코트와 포지션', steps: [
      { scene: 'court', title: '골 에어리어는 골키퍼만', body: '골대 앞 6m 구역은 골키퍼만 들어갈 수 있어요. 공격수는 선 밖에서 점프해 공중에서 슛을 던져요.' },
      { scene: 'positions', title: '7개의 포지션', body: '양쪽 윙(LW·RW), 백 3명(LB·CB·RB), 수비 사이를 파고드는 피벗(PV), 그리고 골키퍼(GK). 센터백은 공격을 지휘하는 사령관이에요.' } ],
      quiz: { q: '골 에어리어(6m 안)에 들어갈 수 있는 선수는?', opts: ['누구나', '골키퍼만', '공격수만'], a: 1, explain: '골 에어리어는 골키퍼만의 공간! 공격수가 밟고 슛하면 골이 인정되지 않아요.' } },
    { id: 'l3', title: '공을 다루는 법', steps: [
      { scene: 'steps3', title: '최대 3걸음', body: '공을 잡고 최대 3걸음까지 움직일 수 있어요. 더 가고 싶다면 드리블하거나 패스해야 해요.' },
      { scene: 'sec3', title: '최대 3초', body: '공을 들고 있을 수 있는 시간은 3초! 빠르게 패스하거나 슛해야 해요.' } ],
      quiz: { q: '공을 들고 최대 몇 걸음까지 걸을 수 있을까요?', opts: ['1걸음', '2걸음', '3걸음', '자유롭게'], a: 2, explain: '3걸음까지 OK! 4걸음째부터는 반칙이에요.' } },
    { id: 'l4', title: '7m 드로와 골키퍼', steps: [
      { scene: 'seven', title: '7m 드로 = 핸드볼의 페널티킥', body: '명확한 득점 기회를 반칙으로 막으면, 7m 라인에서 골키퍼와 1대1로 슛할 기회가 주어져요.' },
      { scene: 'gk', title: '골키퍼는 마지막 방패', body: '골키퍼는 골 에어리어 안에서 발까지 온몸을 써서 막을 수 있어요. 선방률 30%를 넘기면 수준급!' } ],
      quiz: { q: '7m 드로는 언제 주어질까요?', opts: ['공이 코트 밖으로 나가면', '득점 기회를 반칙으로 막으면', '골키퍼가 공을 잡으면'], a: 1, explain: '명확한 득점 기회를 반칙으로 방해했을 때 주어져요.' } },
    { id: 'l5', title: '반칙과 퇴장', steps: [
      { scene: 'cards', title: '경고 → 2분 퇴장 → 실격', body: '가벼운 반칙은 옐로카드 경고, 반복되거나 위험하면 2분 퇴장, 아주 심하면 레드카드로 실격돼요.' },
      { scene: 'twomin', title: '2분 동안 한 명 적게', body: '2분 퇴장을 받으면 그동안 팀은 한 명이 적은 채로 싸워야 해요. 경기 흐름이 확 바뀌는 순간이에요!' } ],
      quiz: { q: '2분 퇴장을 받으면 팀은 어떻게 될까요?', opts: ['인원 그대로 경기', '2분간 한 명 적게', '끝까지 한 명 적게'], a: 1, explain: '2분 동안만 한 명이 적게 뛰고, 시간이 지나면 다시 들어올 수 있어요.' } },
  ];
  saveGuide = (done, gradDate) => { try { localStorage.setItem('mh_guide', JSON.stringify({ done, gradDate })); } catch (e) {} };
  openGuide = () => this.setState({ guideOpen: true, guideView: 'path' });
  closeGuide = () => this.setState({ guideOpen: false });
  startLesson = (i) => () => this.setState({ guideView: 'lesson', guideLesson: i, guideStep: 0, guidePick: null, guideChecked: false });
  exitLesson = () => this.setState({ guideView: 'path' });
  backToPath = () => this.setState({ guideView: 'path' });
  pickQuiz = (i) => () => { if (!this.state.guideChecked) this.setState({ guidePick: i }); };
  mainBtnAction = () => {
    const s = this.state, L = this.LESSONS[s.guideLesson];
    if (s.guideStep < L.steps.length) { this.setState({ guideStep: s.guideStep + 1 }); return; }
    if (s.guidePick === null) return;
    this.setState({ guideChecked: true });
  };
  continueLesson = () => {
    const s = this.state, L = this.LESSONS[s.guideLesson];
    const correct = s.guidePick === L.quiz.a;
    const already = s.guideDone.includes(L.id);
    const done = already ? s.guideDone : [...s.guideDone, L.id];
    const graduated = !already && done.length === this.LESSONS.length;
    const d = new Date(); const gradDate = graduated ? `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}` : s.guideGradDate;
    this.saveGuide(done, gradDate);
    this.setState({ guideView: 'done', guideDone: done, guideGradDate: gradDate, guideJustGrad: graduated, guideLastCorrect: correct, guideStep: L.steps.length + 1 });
  };
  doneNext = () => {
    const next = this.state.guideLesson + 1;
    if (next < this.LESSONS.length) this.startLesson(next)(); else this.setState({ guideView: 'path' });
  };
  goStatPlayers = () => { this.setState({ appScreen: 'stat', statTab: 'player', teamDetailName: null }); this.simulateLoad('loadingStat'); };
  homeGamesRef = React.createRef();
  hgDrag = null;
  onHgDown = (e) => {
    if (e.pointerType !== 'mouse') return;
    const el = this.homeGamesRef.current; if (!el) return;
    this.hgDrag = { x: e.clientX, left: el.scrollLeft, moved: false };
    this.setState({ hgDragging: true });
  };
  onHgMove = (e) => {
    const d = this.hgDrag, el = this.homeGamesRef.current; if (!d || !el) return;
    const dx = e.clientX - d.x; if (Math.abs(dx) > 3) d.moved = true;
    el.scrollLeft = d.left - dx;
  };
  onHgUp = (e) => {
    const d = this.hgDrag, el = this.homeGamesRef.current; if (!d || !el) return;
    this.hgDrag = null; this.hgJustDragged = d.moved; setTimeout(() => { this.hgJustDragged = false; }, 0);
    const card = el.firstElementChild; const step = card ? card.offsetWidth + 12 : el.clientWidth;
    const dx = (e.clientX ?? d.x) - d.x;
    let idx = Math.round(d.left / step) + (dx < -40 ? 1 : dx > 40 ? -1 : 0);
    idx = Math.max(0, Math.min(el.children.length - 1, idx));
    this.setState({ hgDragging: false, homeGameIdx: idx }, () => el.scrollTo({ left: idx * step, behavior: 'smooth' }));
  };
  onHomeGamesScroll = (e) => {
    const el = e.currentTarget; const card = el.firstElementChild;
    if (!card) return;
    const idx = Math.round(el.scrollLeft / (card.offsetWidth + 12));
    if (idx !== this.state.homeGameIdx) this.setState({ homeGameIdx: idx });
  };
  goApp = () => {
    if ((this.props.rememberOnboarding ?? true) !== false) { try { localStorage.setItem('mh_onboarded', JSON.stringify({ team: this.state.selectedTeam, gender: this.state.teamGender })); } catch (e) {} }
    const prev = this.state.profile, d = new Date();
    const profile = { nick: this.state.pfNick.trim(), team: this.state.selectedTeam, uid: (prev && prev.uid) || ('anon-' + Math.random().toString(36).slice(2, 10)), since: (prev && prev.since) || `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}` };
    try { localStorage.setItem('mh_profile', JSON.stringify(profile)); localStorage.setItem('mh_nick', profile.nick); } catch (e) {}
    this.setState({ inApp: true, profile, rankGender: this.genderOf(this.state.selectedTeam) }); this.simulateLoad('loadingHome');
  };
  closeCard = () => this.setState({ cardPlayerId: null });
  closeTeamDetail = () => this.setState({ teamDetailName: null });
  stop = (e) => e && e.stopPropagation && e.stopPropagation();

  primaryAction = () => {
    const { step, interest, gender, age, selectedTeam } = this.state;
    if (step === 0) return this.goNext();
    if (step === 1) { if (interest) this.goNext(); return; }
    if (step === 2) { if (gender && age) this.goNext(); return; }
    if (step === 3) { if (selectedTeam) this.goNext(); return; }
    if (step === 4) { if (this.nickCheck(this.state.pfNick, this.state.profile && this.state.profile.nick).ok) this.goNext(); return; }
    if (step === 5) return this.goApp();
  };

  renderVals() {
    const { step, inApp, appScreen, interest, gender, age, teamGender, selectedTeam, rankGender, statTab, monthOffset, q1Answer, q2Answer, cardPlayerId, teamDetailName, teamDetailTab, theme } = this.state;
    const isDark = theme === 'dark';
    const c = isDark ? {
      bg: '#111111', card: '#222222', border: '#333333', borderSubtle: '#2a2a2a',
      text: '#ffffff', textSub: '#6d6d6d', textFaint: '#5d5d5d', textNeutral: '#808080', textMuted: '#a5a5a5',
      statusText: '#ffffff', statusBorder: 'rgba(255,255,255,0.5)', main: '#0068FF',
      pillInactiveBg: '#494949', pillInactiveText: '#808080', tabInactive: '#AFAFAF', orangeText: '#FF7A45', toggleOff: '#333333',
    } : {
      bg: '#FFFFFF', card: '#F2F2F2', border: '#E5E5E5', borderSubtle: '#E5E5E5',
      text: '#111111', textSub: '#6b6b6b', textFaint: '#858585', textNeutral: '#737373', textMuted: '#737373',
      statusText: '#111111', statusBorder: 'rgba(0,0,0,0.35)', main: '#0068FF',
      pillInactiveBg: '#EFEFEF', pillInactiveText: '#666666', tabInactive: '#8a8a8a', orangeText: '#D9480F', toggleOff: '#CFCFCF',
    };

    const ageOptions = [
      { value: '1', label: '19세 이하' }, { value: '2', label: '20-24세' }, { value: '3', label: '25-29세' },
      { value: '4', label: '30-34세' }, { value: '5', label: '35-39세' }, { value: '6', label: '40세 이상' },
    ];
    const ageList = ageOptions.map(o => {
      const active = o.value === age;
      return {
        label: o.label, select: () => this.setState({ age: o.value }),
        bg: active ? '#0068FF' : 'transparent', color: active ? '#fff' : '#fff',
        borderColor: active ? '#0068FF' : '#333333',
        shadow: active ? '0 6px 14px rgba(0,104,255,0.25)' : 'none',
      };
    });

    const LOGO_ID = { '두산': 'm_149', '상무피닉스': 'm_22', '인천도시공사': 'm_120', '충남도청': 'm_113', '하남시청': 'm_150', 'SK호크스': 'm_132',
      '경남개발공사': 'w_102', '광주도시공사': 'w_110', '대구광역시청': 'w_23', '부산시설공단': 'w_100', '삼척시청': 'w_93', '서울시청': 'w_107', '인천광역시청': 'w_127', 'SK슈가글라이더즈': 'w_123' };
    // 로고: 한국핸드볼연맹(koreahandball.com) 이미지 핫링크 — 디자인 시안용. TODO(v3): 사용 허가 후 자체 에셋으로 교체
    const logo = (name) => LOGO_ID[name] ? `url(https://www.koreahandball.com/static/images/logo/logo_${LOGO_ID[name]}.png)` : 'url(assets/team-logo-default.png)';
    const teamsByGender = {
      M: ['인천도시공사', 'SK호크스', '하남시청', '두산', '충남도청', '상무피닉스'],
      W: ['SK슈가글라이더즈', '삼척시청', '부산시설공단', '경남개발공사', '대구광역시청', '서울시청', '광주도시공사', '인천광역시청'],
    };
    const teamList = teamsByGender[teamGender].map(name => {
      const logoUrl = logo(name);
      const isSelected = name === selectedTeam;
      return {
        name, isSelected, logoUrl, select: () => this.setState({ selectedTeam: name }),
        bg: isSelected ? '#1F3358' : '#222222',
        border: isSelected ? '2px solid #0068FF' : '1px solid #333333',
      };
    });

    const labelFor = (s) => ({ 0: '시작하기', 1: '다음', 2: '다음', 3: '다음', 4: '다음', 5: '입장하기' }[s]);
    const disabled = (step === 1 && !interest) || (step === 2 && !(gender && age)) || (step === 3 && !selectedTeam) || (step === 4 && !this.nickCheck(this.state.pfNick, this.state.profile && this.state.profile.nick).ok);

    // 2025-26 신한 SOL Bank H리그 정규리그 최종 순위. 확인: 인천·SK·하남·충남(남), SK·삼척·부산·경남(여) W/D/L
    // TODO(v3): 두산·상무(남), 대구·서울·광주·인천시청(여) W/D/L 및 전 구단 득실점(인천 733골 제외)은 추정치 — 연맹 공식 기록으로 교체
    const rankRaw = {
      M: [
        ['인천도시공사', 21, 0, 4, 733, 612], ['SK호크스', 15, 2, 8, 632, 598], ['하남시청', 13, 1, 11, 652, 648],
        ['두산', 10, 1, 14, 753, 745], ['충남도청', 9, 2, 14, 628, 671], ['상무피닉스', 4, 0, 21, 560, 660],
      ],
      W: [
        ['SK슈가글라이더즈', 21, 0, 0, 648, 452], ['삼척시청', 15, 1, 5, 603, 531], ['부산시설공단', 11, 3, 7, 561, 540],
        ['경남개발공사', 8, 5, 8, 548, 552], ['대구광역시청', 8, 2, 11, 522, 548], ['서울시청', 7, 2, 12, 530, 562],
        ['광주도시공사', 4, 2, 15, 488, 575], ['인천광역시청', 2, 1, 18, 470, 610],
      ],
    };
    const rankData = {};
    Object.keys(rankRaw).forEach(g => { rankData[g] = rankRaw[g].map(([name, wins, draws, losses, goalsFor, goalsAgainst], i) => ({ rank: i + 1, name, logoUrl: logo(name), wins, draws, losses, points: wins * 2 + draws, goalsFor, goalsAgainst, diff: goalsFor - goalsAgainst, gender: g })); });
    const list = rankData[rankGender];
    const otherRank = list.filter(x => x.rank > 3);
    const fullRank = list.map(r => ({ ...r, open: () => { this.setState({ teamDetailName: r.name, teamDetailTab: 'info' }); this.simulateLoad('loadingTeamDetail'); } }));
    const fullRecord = fullRank;
    let teamDetail = { name: teamDetailName || '', logoUrl: teamDetailName ? logo(teamDetailName) : 'none' };
    // 연고지·감독은 기사 확인분만 기입. TODO(v3): '-' 항목은 연맹 구단 정보로 채우기
    const teamInfoMap = {
      '인천도시공사': { founded: '2006', region: '인천', stadium: '-', coach: '-' },
      'SK호크스': { founded: '-', region: '충북 청주', stadium: 'SK호크스 아레나', coach: '누노 알바레즈' },
      '하남시청': { founded: '-', region: '경기 하남', stadium: '-', coach: '백원철' },
      '두산': { founded: '-', region: '서울', stadium: '-', coach: '-' },
      '충남도청': { founded: '-', region: '충남', stadium: '-', coach: '-' },
      '상무피닉스': { founded: '-', region: '국군체육부대', stadium: '-', coach: '-' },
      'SK슈가글라이더즈': { founded: '-', region: '서울', stadium: '-', coach: '-' },
      '삼척시청': { founded: '-', region: '강원 삼척', stadium: '삼척시민체육관', coach: '-' },
      '부산시설공단': { founded: '-', region: '부산', stadium: '-', coach: '-' },
      '경남개발공사': { founded: '-', region: '경남', stadium: '-', coach: '-' },
      '대구광역시청': { founded: '-', region: '대구', stadium: '-', coach: '-' },
      '서울시청': { founded: '-', region: '서울', stadium: '-', coach: '-' },
      '광주도시공사': { founded: '-', region: '광주', stadium: '-', coach: '-' },
      '인천광역시청': { founded: '-', region: '인천', stadium: '-', coach: '-' },
    };
    // 연맹 구단 소개 페이지 요약 (두산·SK호크스·인천도시공사 확인). TODO(v3): 나머지 구단 소개/연혁 수집
    const clubPages = {
      '두산': {
        founded: '1991.11', coach: '윤경신', slogan: 'Team Doosan · 대한민국 최초 남자 실업팀',
        intro: '1991년 11월 창단한 대한민국 최초의 남자 실업 핸드볼팀입니다. 윤경신 감독 체제에서 끈끈한 팀워크와 강한 정신력을 강점으로 한국 핸드볼을 이끌어 왔습니다.\n\n코리아리그 8년 연속 통합우승에 이어 2024년 핸드볼 H리그 초대 통합 우승팀이 되었고, 25-26 시즌에도 더 높은 목표를 향해 도전합니다.',
        address: '서울 송파구 올림픽로 25 잠실종합운동장 내',
        history: [['2023-24', 'H리그 초대 통합 우승'], ['2022-23', 'SK핸드볼코리아리그 우승'], ['2021-22', 'SK핸드볼코리아리그 우승'], ['2020-21', 'SK핸드볼코리아리그 우승'], ['2019-20', 'SK핸드볼코리아리그 우승'], ['2018-19', 'SK핸드볼코리아리그 우승'], ['2009', '제1회 핸드볼슈퍼리그 코리아 우승'], ['2007.07', '두산 핸드볼선수단으로 명칭 변경'], ['1991.11', '㈜경월 핸드볼팀 창단']],
        detail: { '6M': 232, '윙': 57, '9M': 215, '7M': 61, '속공': 117, '돌파': 61, assist: 348, turnover: 180, steal: 72, block: 65, twoMin: 103 },
      },
      'SK호크스': {
        founded: '2016.02', coach: '누노 알바레즈', stadium: 'SK Hawks Arena (1,800석)', region: '충북 청주', slogan: 'One Team, One Top',
        intro: '2016년 2월 창단해 SK하이닉스 사업장과 핸드볼 명문 학교가 있는 청주시를 연고로 합니다. 전용 경기장, 외국인 감독·선수 영입, 해외 구단 교류로 경기력을 끌어올려 왔습니다.\n\nSK Hawks Arena에서 리그 최초 만원 관중을 기록했고, 팬존·코트사이드존 등 팬 친화적인 관람 환경으로 청주를 핸드볼 팬이 가장 많은 도시로 만들었습니다.',
        address: '서울 송파구 올림픽로 19-2 서울종합운동장',
        history: [['2025-26', 'H리그 정규리그 2위 · 챔피언결정전 준우승'], ['2024-25', 'H리그 정규시즌·챔피언결정전 준우승'], ['2023-24', 'H리그 2위 · 챔피언결정전 준우승'], ['2021-22', 'SK핸드볼코리아리그 2위'], ['2019-20', 'SK핸드볼코리아리그 2위'], ['2018-19', 'SK핸드볼코리아리그 2위'], ['2016-17', 'SK핸드볼코리아리그 2위'], ['2016.02', '창단']],
        detail: { '6M': 177, '윙': 67, '9M': 217, '7M': 64, '속공': 66, '돌파': 36, assist: 296, turnover: 146, steal: 43, block: 77, twoMin: 90 },
      },
      '인천도시공사': {
        founded: '2006', slogan: '25-26 H리그 통합 우승',
        intro: '2006년 창단한 인천 연고 구단입니다. 25-26 시즌 21승 4패로 정규리그 1위에 오른 뒤 챔피언결정전까지 제패하며 창단 20년 만에 첫 통합 우승을 차지했습니다.\n\n이요셉·김진영·김락찬으로 이어지는 백코트 라인과 빠른 속공이 강점입니다.',
        history: [['2025-26', 'H리그 정규리그 1위 · 통합 우승'], ['2006', '창단']],
        detail: { '6M': 227, '윙': 32, '9M': 173, '7M': 89, '속공': 138, '돌파': 55, assist: 379, turnover: 148, steal: 78, block: 89, twoMin: 86 },
      },
    };
    const club = clubPages[teamDetailName] || {};
    const baseInfo = teamInfoMap[teamDetailName] || { founded: '-', region: '-', stadium: '-', coach: '-' };
    const introFull = club.intro || `${teamDetailName || ''} 구단 소개를 준비 중이에요.`;
    const introLong = introFull.length > 110;
    const historyAll = (club.history || []).map(([year, text], i) => ({ year, text, dot: i === 0 ? '#0068FF' : c.border }));
    const teamInfo = {
      introShown: introLong && !this.state.introExpanded ? introFull.slice(0, 110).trim() + '…' : introFull,
      canExpandIntro: introLong, introToggleLabel: this.state.introExpanded ? '접기' : '더보기',
      facts: [
        { label: '창단', value: club.founded || baseInfo.founded },
        { label: '연고지', value: club.region || baseInfo.region },
        { label: '홈 경기장', value: club.stadium || baseInfo.stadium },
        { label: '감독', value: club.coach || baseInfo.coach },
      ],
      hasHistory: historyAll.length > 0,
      historyShown: this.state.historyExpanded ? historyAll : historyAll.slice(0, 5),
      canExpandHistory: historyAll.length > 5, historyToggleLabel: this.state.historyExpanded ? '접기' : `전체 연혁 보기 (${historyAll.length})`,
      hasAddress: !!club.address, address: club.address || '',
    };
    // TODO(v3): 응원글 서버 저장 — 현재는 기본 예시 + 로컬 저장
    const seedPosts = [
      { id: 's1', author: '핸드볼러버', text: '오늘 경기 진짜 손에 땀 나게 봤어요! 끝까지 응원합니다', date: '05.03', likes: 24 },
      { id: 's2', author: '경기장직관러', text: '수비 진짜 탄탄해졌네요. 다음 시즌도 기대할게요!', date: '04.27', likes: 12 },
      { id: 's3', author: 'H리그팬', text: '이번 시즌 고생 많으셨습니다. 26-27 시즌 파이팅!', date: '04.19', likes: 8 },
    ];
    const avatarColors = ['#0068FF', '#FF7A45', '#12B886', '#7950F2', '#E64980'];
    const myPosts = (this.state.cheerByTeam[teamDetailName] || []);
    const likedSet = this.state.cheerLiked;
    const allTeamNames = [...Component.M_TEAMS, ...Component.W_TEAMS];
    const authorTeam = (p, i) => { if (p.team) return p.team; if (p.mine) return (this.state.profile && this.state.profile.team) || selectedTeam || teamDetailName; const r = this.rng('cheer-team-' + teamDetailName + p.id)(); return r < 0.75 ? teamDetailName : allTeamNames[Math.floor(r * 97) % allTeamNames.length]; };
    const blockedNicks = this.state.blocked.map(b => b.nick), repKeys = this.state.reportedKeys;
    const cheerAll = [...myPosts, ...seedPosts];
    const cheerHidden = cheerAll.filter(p => !p.mine && (blockedNicks.includes(p.author) || repKeys.includes(teamDetailName + ':' + p.id))).length;
    const cheerPosts = cheerAll.filter(p => p.mine || !(blockedNicks.includes(p.author) || repKeys.includes(teamDetailName + ':' + p.id))).map((p, i) => {
      const key = teamDetailName + ':' + p.id, liked = likedSet.includes(key);
      const isMine = !!p.mine, confirming = this.state.cheerConfirmId === p.id;
      return { ...p, isMine, confirming, showDelete: isMine && !confirming, borderColor: isMine ? '#0068FF' : 'transparent',
        askDelete: () => this.setState({ cheerConfirmId: p.id }), cancelDelete: () => this.setState({ cheerConfirmId: null }), doDelete: this.deleteCheer(p.id),
        initial: p.author.slice(0, 1), avatarBg: isMine ? '#0068FF' : avatarColors[(i + 1) % avatarColors.length], teamLogo: logo(authorTeam(p, i)), avatarRing: isMine ? '#0068FF' : 'transparent', likes: p.likes + (liked ? 1 : 0),
        heartFill: liked ? '#FF4D6A' : 'none', heartStroke: liked ? '#FF4D6A' : c.textFaint, like: this.toggleCheerLike(key),
        openMenu: () => this.setState({ cheerMenu: { id: p.id, key, author: p.author, text: p.text, team: authorTeam(p, i), mine: isMine } }) };
    });
    const MS = this.state, rpP = MS.reportPost, rr = MS.reportReason;
    const mod = {
      showEmpty: cheerPosts.length === 0, emptyHasLink: cheerHidden > 0,
      emptyTitle: cheerHidden > 0 ? '보이는 응원글이 없어요' : '아직 응원글이 없어요',
      emptyDesc: cheerHidden > 0 ? '차단하거나 신고한 글은 숨겨져 있어요' : '첫 응원을 남겨보세요',
      showHiddenNote: cheerPosts.length > 0 && cheerHidden > 0, hiddenNote: `차단·신고로 숨긴 글 ${cheerHidden}개`,
      menuOpen: !!MS.cheerMenu, menuMine: !!(MS.cheerMenu && MS.cheerMenu.mine), menuOther: !!(MS.cheerMenu && !MS.cheerMenu.mine), menuAuthor: MS.cheerMenu ? MS.cheerMenu.author : '',
      reportOpen: !!rpP, reportAuthor: rpP ? rpP.author : '', reportText: rpP ? rpP.text : '',
      reasons: Component.REPORT_REASONS.map(([k, label]) => ({ label, select: () => this.setState({ reportReason: k }), border: rr === k ? '#0068FF' : c.border, bg: rr === k ? 'rgba(0,104,255,0.08)' : 'transparent', ring: rr === k ? '#0068FF' : c.textFaint, dot: rr === k ? '#0068FF' : 'transparent' })),
      detail: MS.reportDetail, detailCount: MS.reportDetail.length, detailPlaceholder: rr === 'other' ? '어떤 문제인지 적어주세요 (필수, 최대 200자)' : '자세한 내용을 적어주세요 (선택, 최대 200자)',
      blockBg: MS.reportBlock ? '#0068FF' : 'transparent', blockBorder: MS.reportBlock ? '#0068FF' : c.textFaint, blockCheck: MS.reportBlock ? '#fff' : 'transparent',
      submitBg: rr && (rr !== 'other' || MS.reportDetail.trim()) ? '#E5484D' : c.textFaint,
      blockAskOpen: !!MS.blockAsk, blockAskTitle: MS.blockAsk ? `${MS.blockAsk.author}님의 글을 보지 않을까요?` : '',
      blockedOpen: MS.blockedOpen, blockedCountLabel: `${MS.blocked.length}명`, hasBlocked: MS.blocked.length > 0, noBlocked: MS.blocked.length === 0,
      blockedList: MS.blocked.map((b, i) => ({ ...b, logo: logo(b.team), divider: i === 0 ? 'transparent' : c.borderSubtle, unblock: this.unblock(b.nick) })),
    };
    const combinedRecord = [...rankData.M, ...rankData.W];
    const trBase = combinedRecord.find(r => r.name === teamDetailName) || { wins: 0, draws: 0, losses: 0, rank: '-', points: 0, goalsFor: 0, goalsAgainst: 0, diff: 0, gender: 'M' };
    const gp = Math.max(1, trBase.wins + trBase.draws + trBase.losses);
    const det = (clubPages[teamDetailName] || {}).detail;
    const shotKeys = ['6M', '9M', '속공', '7M', '윙', '돌파'];
    const shotMax = det ? Math.max(...shotKeys.map(k => det[k])) : 1;
    const teamRecord = { ...trBase,
      wPct: (trBase.wins / gp * 100) + '%', dPct: (trBase.draws / gp * 100) + '%', lPct: (trBase.losses / gp * 100) + '%',
      totals: [{ label: '득점', value: trBase.goalsFor, color: c.text }, { label: '실점', value: trBase.goalsAgainst, color: c.text }, { label: '경기당 득점', value: (trBase.goalsFor / gp).toFixed(1), color: '#0068FF' }],
      hasDetail: !!det, noDetail: !det,
      shotTypes: det ? shotKeys.map(k => ({ label: k, value: det[k], pct: (det[k] / shotMax * 100) + '%' })) : [],
      extras: det ? [{ label: '도움', value: det.assist }, { label: '스틸', value: det.steal }, { label: '블록샷', value: det.block }, { label: '실책', value: det.turnover }, { label: '2분 퇴장', value: det.twoMin }, { label: '득실차', value: (trBase.diff > 0 ? '+' : '') + trBase.diff }] : [],
    };
    teamDetail = { ...teamDetail, division: trBase.gender === 'W' ? '여자부' : '남자부', isMine: teamDetailName === (selectedTeam || 'SK호크스'),
      slogan: (clubPages[teamDetailName] || {}).slogan || `25-26 정규리그 ${trBase.rank}위`,
      chips: [{ label: '순위', value: trBase.rank + '위', color: '#0068FF' }, { label: '승', value: trBase.wins, color: c.text }, { label: '무', value: trBase.draws, color: c.text }, { label: '패', value: trBase.losses, color: c.text }] };
    const teamDetailTabDefs = [
      { key: 'info', label: '구단소개' }, { key: 'players', label: '선수' },
      { key: 'cheer', label: '응원글' }, { key: 'record', label: '기록' },
    ];
    const teamDetailTabs = teamDetailTabDefs.map(t => ({
      label: t.label, select: () => { this.setState({ teamDetailTab: t.key }); this.simulateLoad('loadingTeamDetail'); },
      color: teamDetailTab === t.key ? c.text : c.textNeutral,
      border: teamDetailTab === t.key ? '#0068FF' : 'transparent',
    }));
    const podiumPos = { 1: { left: '111px', top: '0px' }, 2: { left: '0px', top: '60px' }, 3: { left: '222px', top: '60px' } };
    const podium = [2, 1, 3].map(r => {
      const t = list.find(x => x.rank === r);
      return { ...t, ...podiumPos[r], logoBg: '#fff' };
    });

    const q1Opts = ['1걸음', '2걸음', '3걸음', '자유롭게'];
    const q1Options = q1Opts.map((label, i) => {
      const correct = i === 2;
      const active = q1Answer === i;
      return {
        label, select: () => this.setState({ q1Answer: i }),
        bg: active ? (correct ? '#0068FF' : '#3a1f1f') : c.card,
        color: active ? '#fff' : c.text, border: active ? (correct ? '#0068FF' : '#772929') : c.border,
      };
    });
    const q2Opts = ['네, 가능해요', '아니요, 불가능해요', '심판 판단에 따라 달라요'];
    const q2Options = q2Opts.map((label, i) => {
      const correct = i === 1;
      const active = q2Answer === i;
      return {
        label, select: () => this.setState({ q2Answer: i }),
        bg: active ? (correct ? '#0068FF' : '#3a1f1f') : c.card,
        color: active ? '#fff' : c.text, border: active ? (correct ? '#0068FF' : '#772929') : c.border,
      };
    });

    const baseDate = new Date(2026, 4, 1);
    baseDate.setMonth(baseDate.getMonth() + monthOffset);
    const monthLabel = `${baseDate.getFullYear()}.${String(baseDate.getMonth() + 1).padStart(2, '0')}`;
    const nameFontSize = (name) => name.length > 4 ? '13px' : '16px';
    // TODO(v3): placeholder monthly schedule — replace with real KHF fixture data
    const scheduleDataByMonth = {
      M: {
        '-1': [
          { day: 15, teamA: '인천도시공사', teamB: '충남도청', scoreA: '28', scoreB: '25', chipLabel: '경기종료', chipBg: '#808080' },
          { day: 18, teamA: '두산', teamB: 'SK호크스', scoreA: '31', scoreB: '29', chipLabel: '경기종료', chipBg: '#808080' },
        ],
        '0': [
          { day: 20, teamA: '두산', teamB: 'SK호크스', scoreA: '29', scoreB: '26', chipLabel: '경기종료', chipBg: '#808080' },
          { day: 22, teamA: '하남시청', teamB: '상무피닉스', scoreA: '31', scoreB: '28', chipLabel: '경기종료', chipBg: '#808080' },
          { day: 24, teamA: '두산', teamB: '하남시청', scoreA: '13', scoreB: '08', chipLabel: 'LIVE', chipBg: '#FF0000' },
          { day: 26, teamA: '상무피닉스', teamB: '충남도청', scoreA: '27', scoreB: '30', chipLabel: '19:00', chipBg: '#808080' },
          { day: 26, teamA: '인천도시공사', teamB: 'SK호크스', scoreA: '30', scoreB: '30', chipLabel: '16:30', chipBg: '#808080' },
        ],
        '1': [
          { day: 3, teamA: '하남시청', teamB: '인천도시공사', scoreA: '-', scoreB: '-', chipLabel: '18:00', chipBg: '#808080' },
          { day: 7, teamA: 'SK호크스', teamB: '두산', scoreA: '-', scoreB: '-', chipLabel: '19:30', chipBg: '#808080' },
        ],
      },
      W: {
        '-1': [
          { day: 12, teamA: 'SK슈가글라이더즈', teamB: '서울시청', scoreA: '26', scoreB: '24', chipLabel: '경기종료', chipBg: '#808080' },
        ],
        '0': [
          { day: 20, teamA: '삼척시청', teamB: '부산시설공단', scoreA: '24', scoreB: '22', chipLabel: '경기종료', chipBg: '#808080' },
          { day: 21, teamA: '경남개발공사', teamB: '대구광역시청', scoreA: '27', scoreB: '25', chipLabel: '경기종료', chipBg: '#808080' },
          { day: 24, teamA: 'SK슈가글라이더즈', teamB: '삼척시청', scoreA: '20', scoreB: '18', chipLabel: 'LIVE', chipBg: '#FF0000' },
          { day: 26, teamA: '광주도시공사', teamB: '인천광역시청', scoreA: '-', scoreB: '-', chipLabel: '17:00', chipBg: '#808080' },
          { day: 27, teamA: '부산시설공단', teamB: '서울시청', scoreA: '-', scoreB: '-', chipLabel: '19:00', chipBg: '#808080' },
        ],
        '1': [],
      },
    };
    const scheduleGamesAll = (this.props.demoState === '비시즌') ? [] : (scheduleDataByMonth[rankGender] && scheduleDataByMonth[rankGender][String(monthOffset)]) || [];
    const selectedDay = this.state.selectedDay;
    const weekdayNames = ['일', '월', '화', '수', '목', '금', '토'];
    const availableDays = [...new Set(scheduleGamesAll.map(g => g.day))].sort((a, b) => a - b);
    const dayChips = availableDays.map(d => {
      const wd = weekdayNames[new Date(baseDate.getFullYear(), baseDate.getMonth(), d).getDay()];
      const active = selectedDay === d;
      return {
        label: `${d}(${wd})`, select: () => this.setState({ selectedDay: active ? null : d }),
        bg: active ? '#0068FF' : 'transparent', color: active ? '#fff' : c.textNeutral, border: active ? '#0068FF' : c.border,
      };
    });
    const scheduleGamesRaw = selectedDay ? scheduleGamesAll.filter(g => g.day === selectedDay) : scheduleGamesAll;
    const schedVenue = (t) => { const x = teamInfoMap[t] || {}; return x.stadium && x.stadium !== '-' ? x.stadium : `${x.region && x.region !== '-' ? x.region : t} 홈 경기장`; };
    const scheduleGames = scheduleGamesRaw.map((g, i) => ({ ...g, logoA: logo(g.teamA), logoB: logo(g.teamB),
      dateLabel: `${baseDate.getMonth() + 1}월 ${g.day}일 (${weekdayNames[new Date(baseDate.getFullYear(), baseDate.getMonth(), g.day).getDay()]})`, venue: g.venue || schedVenue(g.teamA),
      open: () => this.openGame({ id: `s-${rankGender}-${monthOffset}-${g.day}-${g.teamA}`, teamA: g.teamA, teamB: g.teamB, scoreA: g.scoreA, scoreB: g.scoreB,
        status: g.chipLabel === 'LIVE' ? 'live' : g.chipLabel === '경기종료' ? 'final' : 'pre', time: g.chipLabel === 'LIVE' || g.chipLabel === '경기종료' ? '' : g.chipLabel,
        dateShort: `${String(baseDate.getMonth() + 1).padStart(2, '0')}.${String(g.day).padStart(2, '0')}`, meta: `${baseDate.getMonth() + 1}월 ${g.day}일`, minute: 44 }), nameSize: nameFontSize(g.teamA), nameSizeB: nameFontSize(g.teamB) }));
    const hasSchedule = scheduleGames.length > 0;
    const noSchedule = !hasSchedule;
    const hasDayChips = dayChips.length > 0;

    const statTabDefs = [
      { key: 'rank', label: '순위' }, { key: 'record', label: '기록' },
      { key: 'team', label: '팀' }, { key: 'player', label: '선수' },
    ];
    const statTabs = statTabDefs.map(t => ({
      label: t.label, select: () => { this.setState({ statTab: t.key }); this.simulateLoad('loadingStat'); },
      color: statTab === t.key ? c.text : c.textNeutral,
      border: statTab === t.key ? '#0068FF' : 'transparent',
    }));

    // 2025-26 시즌 기사 기반 선수 명단 (사진 미사용). goals: 확인된 시즌 득점만, null = 집계 전
    const posName = { CB: '센터백', LB: '레프트백', RB: '라이트백', PV: '피벗', GK: '골키퍼', LW: '레프트윙', RW: '라이트윙', BK: '백' };
    const playerData = [
      { id: 'm1', name: '이요셉', team: '인천도시공사', pos: 'CB', goals: 166 },
      { id: 'm2', name: '김진영', team: '인천도시공사', pos: 'RB', goals: 121 },
      { id: 'm3', name: '김락찬', team: '인천도시공사', pos: 'LB', goals: 102 },
      { id: 'm4', name: '이창우', team: '인천도시공사', pos: 'GK', goals: null },
      { id: 'm5', name: '육태경', team: '충남도청', pos: 'BK', goals: 159 }, // TODO(v3): 4/11 기준 159골 — 최종 기록으로 교체
      { id: 'm6', name: '박광순', team: 'SK호크스', pos: 'RB', goals: null },
      { id: 'm7', name: '이주승', team: 'SK호크스', pos: 'BK', goals: null },
      { id: 'm8', name: '김재순', team: '하남시청', pos: 'BK', goals: null },
      { id: 'm9', name: '박재용', team: '하남시청', pos: 'GK', goals: null },
      { id: 'm10', name: '이현식', team: '하남시청', pos: 'BK', goals: null },
      { id: 'm11', name: '이성민', team: '두산', pos: 'BK', goals: null },
      { id: 'w1', name: '최지혜', team: 'SK슈가글라이더즈', pos: 'BK', goals: 155 },
      { id: 'w2', name: '강은혜', team: 'SK슈가글라이더즈', pos: 'PV', goals: null },
      { id: 'w3', name: '강경민', team: 'SK슈가글라이더즈', pos: 'CB', goals: null },
      { id: 'w4', name: '박조은', team: 'SK슈가글라이더즈', pos: 'GK', goals: null },
      { id: 'w5', name: '이연경', team: '삼척시청', pos: 'BK', goals: null },
      { id: 'w6', name: '류은희', team: '부산시설공단', pos: 'BK', goals: 76 },
      { id: 'w7', name: '김아영', team: '경남개발공사', pos: 'CB', goals: null },
      { id: 'w8', name: '김소라', team: '경남개발공사', pos: 'PV', goals: null },
      { id: 'w9', name: '우빛나', team: '서울시청', pos: 'BK', goals: null },
      { id: 'w10', name: '정진희', team: '서울시청', pos: 'GK', goals: null },
      { id: 'w11', name: '정지인', team: '대구광역시청', pos: 'BK', goals: null },
      { id: 'w12', name: '강샤론', team: '인천광역시청', pos: 'BK', goals: 89 },
    ];
    const favIds = this.state.favPlayerIds;
    // TODO(v3): 등번호(number)는 목업 — 연맹 선수 명단으로 교체. 득점(goals)이 확인된 선수 외 경기수·세이브·슈팅률·최근 경기 기록은 목업 — 연맹 기록실 데이터로 교체
    const seed = (str, n) => { let h = 0; for (const ch of str + n) h = (h * 31 + ch.charCodeAt(0)) >>> 0; return h; };
    const allPlayers = playerData.map(p => {
      const isW = p.id[0] === 'w', isGK = p.pos === 'GK';
      const games = (isW ? 21 : 25) - (seed(p.id, 'g') % 4);
      const goals = p.goals != null ? p.goals : isGK ? 0 : 40 + (seed(p.id, 'goal') % 70);
      const saves = isGK ? 180 + (seed(p.id, 'sv') % 120) : 0;
      const pct = isGK ? 30 + (seed(p.id, 'pct') % 12) : 52 + (seed(p.id, 'pct') % 20);
      const assists = isGK ? seed(p.id, 'a') % 6 : 15 + (seed(p.id, 'a') % 60);
      const isFav = favIds.includes(p.id);
      const opps = rankData[isW ? 'W' : 'M'].map(r => r.name).filter(n => n !== p.team);
      const shortName = (n) => n.replace('광역시청', '').replace('도시공사', '도공').replace('시설공단', '시설').replace('개발공사', '개발').replace('슈가글라이더즈', '').replace('피닉스', '').replace('시청', '').replace('도청', '');
      const recent = [0, 1, 2, 3, 4].map(i => ({ opp: shortName(opps[i % opps.length]), value: isGK ? 8 + (seed(p.id, 'r' + i) % 10) : Math.max(1, Math.round(goals / games) + (seed(p.id, 'r' + i) % 5) - 2) }));
      return {
        ...p, posFull: posName[p.pos] || p.pos, logoUrl: logo(p.team), isFav, statGoals: goals, statSaves: saves, statAssists: assists,
        number: p.number ?? (isGK ? [1, 12, 16][seed(p.id, 'n') % 3] : 2 + (seed(p.id, 'n') % 97)),
        statLine: p.goals != null ? `시즌 ${p.goals}골` : posName[p.pos] || '',
        headline: isGK ? `${saves}세이브` : `${goals}골`,
        summary: isGK
          ? [{ label: '경기', value: games }, { label: '세이브', value: saves }, { label: '방어율', value: pct + '%' }, { label: '경기당', value: (saves / games).toFixed(1) }]
          : [{ label: '경기', value: games }, { label: '득점', value: goals }, { label: '경기당', value: (goals / games).toFixed(1) }, { label: '슛 성공률', value: pct + '%' }],
        recent, recentLabel: isGK ? '경기별 세이브' : '경기별 득점',
        heartFill: isFav ? '#FF4D6A' : 'none', heartStroke: isFav ? '#FF4D6A' : c.textFaint,
        favLabel: isFav ? '관심 선수 해제' : '관심 선수 추가',
        statPct: pct, statGames: games, compare: () => this.openCompare(p.id),
        toggleFav: this.toggleFav(p.id),
        openTeam: () => { this.setState({ cardPlayerId: null, appScreen: 'stat', teamDetailName: p.team, teamDetailTab: 'players' }); this.simulateLoad('loadingTeamDetail'); },
        open: () => this.setState({ cardPlayerId: p.id }),
      };
    });
    allPlayers.forEach(p => { p.summary = p.summary.map((s, i) => ({ ...s, color: i === 1 ? '#0068FF' : c.text })); });
    // TODO(v3): TOP5는 연맹 '시즌 TOP5' 데이터로 교체 (득점 1위 이요셉 166·최지혜 155, 김진영 121 확인. 나머지 목업)
    const top5Key = this.state.top5Cat;
    const top5Field = { goals: 'statGoals', saves: 'statSaves', assists: 'statAssists' }[top5Key];
    const top5 = allPlayers.filter(p => p.id[0] === (rankGender === 'M' ? 'm' : 'w')).filter(p => p[top5Field] > 0)
      .sort((a, b) => b[top5Field] - a[top5Field]).slice(0, 5)
      .map((p, i, arr) => ({ ...p, rank: i + 1, top5Value: p[top5Field], isEst: top5Key !== 'goals' || p.goals == null, rankColor: i === 0 ? '#0068FF' : c.textSub, divider: i === arr.length - 1 ? 'transparent' : c.border }));
    const top5Tabs = [['goals', '득점'], ['saves', '세이브'], ['assists', '도움']].map(([k, label]) => ({
      label, select: () => this.setState({ top5Cat: k }), bg: top5Key === k ? '#0068FF' : c.pillInactiveBg, color: top5Key === k ? '#fff' : c.pillInactiveText }));
    this._rosters = {};
    allPlayers.forEach(p => { const r = this._rosters[p.team] || (this._rosters[p.team] = { field: [], gk: [] }); (p.pos === 'GK' ? r.gk : r.field).push(p.name); });
    const gdRaw = this.state.gd;
    let gdVals = { gdOpen: false, h2h: { games: [] }, gd: {}, gdTabs: [], gdEvents: [], gdStats: [], pr: { options: [] }, mvp: { candidates: [] } };
    if (gdRaw) {
      const g = gdRaw, st = g.status, isLive = st === 'live', isFinal = st === 'final', isPre = st === 'pre';
      const aWin = g.scoreA > g.scoreB, bWin = g.scoreB > g.scoreA;
      const minLabel = (m) => m <= 30 ? `전반 ${m}'` : `후반 ${m - 30}'`;
      const evs = this.state.gdEvents;
      const h1A = evs.filter(e => e.type === 'goal' && e.side === 'A' && e.min <= 30).length, h1B = evs.filter(e => e.type === 'goal' && e.side === 'B' && e.min <= 30).length;
      const gdObj = {
        ...g, isLive, isPre, showScore: !isPre, logoA: logo(g.teamA), logoB: logo(g.teamB),
        chip: isLive ? 'LIVE' : isFinal ? '경기 종료' : '경기 예정', chipBg: isLive ? '#FF3B30' : isFinal ? '#808080' : '#0068FF',
        sub: isLive ? minLabel(g.minute) : isFinal ? (aWin ? `${g.teamA} 승` : bWin ? `${g.teamB} 승` : '무승부') : '킥오프',
        subColor: isLive ? '#FF3B30' : c.textSub, time: g.time || '-',
        colA: isFinal && bWin ? c.textFaint : c.text, colB: isFinal && aWin ? c.textFaint : c.text,
        opA: isFinal && bWin ? '0.55' : '1', opB: isFinal && aWin ? '0.55' : '1',
        h1A, h1B, h2A: g.minute > 30 ? g.scoreA - h1A : '-', h2B: g.minute > 30 ? g.scoreB - h1B : '-',
        canAttend: !isPre, attendLabel: this.state.attended[g.id] ? '직관 완료' : '직관했어요',
        attendBg: this.state.attended[g.id] ? '#0068FF' : 'transparent', attendColor: this.state.attended[g.id] ? '#fff' : c.textSub, attendBorder: this.state.attended[g.id] ? '#0068FF' : c.border,
        openTeamA: () => { this.closeGame(); this.setState({ appScreen: 'stat', teamDetailName: g.teamA, teamDetailTab: 'info' }); },
        openTeamB: () => { this.closeGame(); this.setState({ appScreen: 'stat', teamDetailName: g.teamB, teamDetailTab: 'info' }); },
      };
      const tab = this.state.gdTab;
      const tabDefs = [['live', '문자중계'], ['stats', '기록'], ['predict', '승부 예측'], ['mvp', 'MVP']];
      const gdTabs = tabDefs.map(([k, label]) => ({ label, dot: k === 'live' && isLive, select: () => this.setState({ gdTab: k }), color: tab === k ? c.text : c.textNeutral, border: tab === k ? '#0068FF' : 'transparent' }));
      const evView = [...evs].reverse().map(e => {
        const team = e.side === 'A' ? g.teamA : e.side === 'B' ? g.teamB : null;
        const base = { min: e.type === 'start' ? "0'" : e.type === 'end' ? '종료' : e.type === 'half' ? 'HT' : `${e.min}'`, hasTeam: !!team, logo: team ? logo(team) : 'none', hasScore: false, hasDetail: false, weight: 600, dot: c.border, minColor: c.textSub, bg: c.card };
        if (e.type === 'goal') return { ...base, text: `${e.who} ${e.seven ? '7m 골' : '골'}`, detail: team, hasDetail: true, score: `${e.a} : ${e.b}`, hasScore: true, weight: 800, dot: '#0068FF', minColor: '#0068FF', bg: e.fresh ? 'rgba(0,104,255,0.14)' : c.card };
        if (e.type === 'save') return { ...base, text: `${e.who} 선방`, detail: team, hasDetail: true };
        if (e.type === 'two') return { ...base, text: `${e.who} 2분 퇴장`, detail: team, hasDetail: true, dot: '#F5A524' };
        if (e.type === 'half') return { ...base, text: `전반 종료 ${h1A} : ${h1B}`, weight: 700, bg: 'transparent' };
        if (e.type === 'end') return { ...base, text: `경기 종료 ${g.scoreA} : ${g.scoreB}`, weight: 800, dot: c.text, minColor: c.text, bg: 'transparent' };
        return { ...base, text: '경기 시작', weight: 700, bg: 'transparent' };
      });
      // stats
      const cnt = (type, side, fn) => evs.filter(e => e.type === type && e.side === side && (!fn || fn(e))).length;
      const rnd = this.rng(g.id + 'stats');
      let gdStats, gdStatsTitle, gdStatsNote;
      if (isPre) {
        const rA = combinedRecord.find(r => r.name === g.teamA) || { wins: 0, points: 0, goalsFor: 0, goalsAgainst: 0, rank: '-' };
        const rB = combinedRecord.find(r => r.name === g.teamB) || { wins: 0, points: 0, goalsFor: 0, goalsAgainst: 0, rank: '-' };
        gdStats = [['순위', rA.rank, rB.rank, true], ['승점', rA.points, rB.points], ['승', rA.wins, rB.wins], ['득점', rA.goalsFor, rB.goalsFor], ['실점', rA.goalsAgainst, rB.goalsAgainst, true]].map(x => x);
        gdStatsTitle = '25-26 시즌 비교'; gdStatsNote = '경기가 시작되면 실시간 경기 기록으로 바뀌어요';
      } else {
        const shotsA = g.scoreA + 8 + Math.floor(rnd() * 8), shotsB = g.scoreB + 8 + Math.floor(rnd() * 8);
        gdStats = [
          ['득점', g.scoreA, g.scoreB], ['슛 성공률', Math.round(g.scoreA / shotsA * 100) + '%', Math.round(g.scoreB / shotsB * 100) + '%'],
          ['7m 득점', cnt('goal', 'A', e => e.seven), cnt('goal', 'B', e => e.seven)], ['세이브', cnt('save', 'A') + 4 + Math.floor(rnd() * 4), cnt('save', 'B') + 4 + Math.floor(rnd() * 4)],
          ['속공', 2 + Math.floor(rnd() * 6), 2 + Math.floor(rnd() * 6)], ['실책', 5 + Math.floor(rnd() * 6), 5 + Math.floor(rnd() * 6), true], ['2분 퇴장', cnt('two', 'A'), cnt('two', 'B'), true],
        ];
        gdStatsTitle = isLive ? '실시간 경기 기록' : '경기 기록'; gdStatsNote = 'TODO(v3): 연맹 경기 기록으로 교체 — 현재 목업';
      }
      // TODO(v3): 맞대결 기록은 목업 — 연맹 경기 결과로 교체
      const shortT = (n) => n.replace('광역시청', '').replace('도시공사', '도공').replace('시설공단', '시설').replace('개발공사', '개발').replace('슈가글라이더즈', '').replace('피닉스', '').replace('시청', '').replace('도청', '');
      const hR = this.rng('h2h' + [g.teamA, g.teamB].sort().join('|'));
      const hRA = combinedRecord.find(r => r.name === g.teamA) || { rank: 4 }, hRB = combinedRecord.find(r => r.name === g.teamB) || { rank: 4 };
      const pAwin = Math.min(0.85, Math.max(0.15, 0.5 + (hRB.rank - hRA.rank) * 0.07));
      const hDates = [['25-26', '03.14'], ['25-26', '01.10'], ['25-26', '12.06'], ['24-25', '03.22'], ['24-25', '01.18'], ['24-25', '12.14'], ['23-24', '02.24'], ['23-24', '12.09']];
      let hw = 0, hd = 0, hl = 0, hgA = 0, hgB = 0;
      const hGames = hDates.map(([season, date]) => {
        let x = 22 + Math.floor(hR() * 10), y = 22 + Math.floor(hR() * 10);
        if (hR() < 0.1) y = x; else { const aW = hR() < pAwin; if (aW && x <= y) [x, y] = [y + 1, x]; if (!aW && y <= x) [x, y] = [y, x + 1]; }
        hgA += x; hgB += y; if (x > y) hw++; else if (x < y) hl++; else hd++;
        const res = x > y ? 'A' : x < y ? 'B' : 'D';
        return { season, date, score: `${x} : ${y}`, chip: res === 'D' ? '무승부' : `${shortT(res === 'A' ? g.teamA : g.teamB)} 승`, chipBg: res === 'A' ? '#0068FF' : res === 'B' ? '#FF7A45' : '#8a8a8a' };
      });
      const hn = hDates.length;
      const h2h = { total: hn, aw: hw, dr: hd, bw: hl, pA: hw / hn * 100 + '%', pD: hd / hn * 100 + '%', pB: hl / hn * 100 + '%', avgA: (hgA / hn).toFixed(1), avgB: (hgB / hn).toFixed(1), games: hGames.slice(0, 5), shortA: shortT(g.teamA), shortB: shortT(g.teamB) };
      gdStats = gdStats.map(([label, a, b, lowerBetter]) => {
        const na = parseFloat(a) || 0, nb = parseFloat(b) || 0, sum = na + nb || 1;
        const aBetter = lowerBetter ? na < nb : na > nb, bBetter = lowerBetter ? nb < na : nb > na;
        return { label, a, b, pA: (na / sum * 100) + '%', pB: (nb / sum * 100) + '%', barA: aBetter ? '#0068FF' : c.textFaint, barB: bBetter ? '#FF7A45' : c.textFaint, colA: aBetter ? '#0068FF' : c.text, colB: bBetter ? '#FF7A45' : c.text };
      });
      // prediction
      const my = (this.state.preds[g.id] || {}).pick;
      const pRand = this.rng(g.id + 'pred');
      const base = { A: 120 + Math.floor(pRand() * 300), D: 20 + Math.floor(pRand() * 50), B: 100 + Math.floor(pRand() * 300) };
      if (my) base[my] += 1;
      const tot = base.A + base.D + base.B, pct = (k) => Math.round(base[k] / tot * 100) + '%';
      const closed = !isPre;
      const outcome = isFinal ? (aWin ? 'A' : bWin ? 'B' : 'D') : null;
      const optDefs = [['A', `${g.teamA} 승`, logo(g.teamA)], ['D', '무승부', null], ['B', `${g.teamB} 승`, logo(g.teamB)]];
      const pr = {
        options: optDefs.map(([k, label, lg]) => ({ label, logo: lg || 'none', hasLogo: !!lg, isDraw: !lg, pick: closed ? () => {} : this.pickPred(g.id, k), cursor: closed ? 'default' : 'pointer',
          border: my === k ? '#0068FF' : outcome === k ? c.textSub : 'transparent', bg: my === k ? 'rgba(0,104,255,0.1)' : c.bg })),
        showDist: !!my || closed, pA: pct('A'), pD: pct('D'), pB: pct('B'), total: tot.toLocaleString(),
        stateLabel: isPre ? '예측 진행 중' : isLive ? '예측 마감' : '결과 확정', stateColor: isPre ? '#0068FF' : c.textSub,
        hasResult: isFinal && !!my, resultLabel: my === outcome ? '적중' : '실패', resultChip: my === outcome ? '#0068FF' : '#8a8a8a',
        resultBg: my === outcome ? 'rgba(0,104,255,0.1)' : c.card, resultText: my === outcome ? '예측이 맞았어요! 적중 기록이 MY에 반영됐어요.' : '아쉽게도 빗나갔어요. 다음 경기에서 다시 도전해 보세요.',
      };
      // mvp
      const scorers = {};
      evs.forEach(e => { if (e.type === 'goal') { const k = e.side + ':' + e.who; scorers[k] = scorers[k] || { side: e.side, who: e.who, goals: 0, saves: 0 }; scorers[k].goals++; }
        if (e.type === 'save') { const k = e.side + ':' + e.who; scorers[k] = scorers[k] || { side: e.side, who: e.who, goals: 0, saves: 0 }; scorers[k].saves++; } });
      const cands = Object.entries(scorers).sort((x, y) => (y[1].goals * 1 + y[1].saves * 0.8) - (x[1].goals + x[1].saves * 0.8)).slice(0, 5);
      const myVote = this.state.mvpVotes[g.id];
      const mRand = this.rng(g.id + 'mvp');
      const votes = cands.map(([k, v]) => Math.floor((v.goals * 1 + v.saves * 0.8) * (28 + mRand() * 10)) + (myVote === k ? 1 : 0));
      const vTot = votes.reduce((a, b) => a + b, 0) || 1;
      const mvp = {
        locked: !isFinal, open: isFinal, lockTitle: isLive ? '경기가 진행 중이에요' : '아직 경기 전이에요', total: vTot.toLocaleString(), hint: myVote ? '투표 완료' : '한 명을 골라주세요',
        candidates: cands.map(([k, v], i) => { const team = v.side === 'A' ? g.teamA : g.teamB; const p = Math.round(votes[i] / vTot * 100);
          return { name: v.who, team, logo: logo(team), stat: [v.goals ? v.goals + '골' : '', v.saves ? v.saves + '세이브' : ''].filter(Boolean).join(' · '),
            vote: this.voteMvp(g.id, k), cursor: myVote ? 'default' : 'pointer', border: myVote === k ? '#0068FF' : c.border,
            barW: myVote ? p + '%' : '0%', barBg: myVote === k ? 'rgba(0,104,255,0.18)' : 'rgba(128,128,128,0.12)', right: myVote ? p + '%' : '투표', pctColor: myVote === k || !myVote ? '#0068FF' : c.textSub }; }),
      };
      gdVals = { gdOpen: true, h2h, gd: gdObj, gdTabs, gdEvents: evView, gdStats, gdStatsTitle, gdStatsNote, pr, mvp,
        gdTabLive: tab === 'live', gdTabStats: tab === 'stats', gdTabPredict: tab === 'predict', gdTabMvp: tab === 'mvp' };
    }
    const myT = selectedTeam || 'SK호크스';
    // TODO(v3): 직관 후보 경기 목업 — 실제 MY팀 시즌 결과로 교체
    const attOpps = (this.genderOf(myT) === 'W' ? Component.W_TEAMS : Component.M_TEAMS).filter(n => n !== myT);
    const venueFor = (t) => { const x = teamInfoMap[t] || {}; return x.stadium && x.stadium !== '-' ? x.stadium : `${x.region && x.region !== '-' ? x.region : t} 홈 경기장`; };
    const aR = this.rng('attpool-' + myT);
    const attPool = ['04.19', '04.12', '04.05', '03.29', '03.22', '03.15', '03.08', '03.01', '02.22', '02.15'].map((d, i) => {
      const home = i % 2 === 0, opp = attOpps[i % attOpps.length], teamA = home ? myT : opp, teamB = home ? opp : myT;
      const sa = 22 + Math.floor(aR() * 10), sb = 22 + Math.floor(aR() * 10), id = `att-${myT}-${d}`;
      return { id, raw: { id, teamA, teamB, scoreA: String(sa), scoreB: String(sb), status: 'final', meta: `${parseInt(d, 10)}월 ${parseInt(d.slice(3), 10)}일`, dateShort: d, time: '' }, venue: venueFor(teamA), cheer: myT, savedAt: 20260000 + parseInt(d.replace('.', ''), 10) };
    });
    const effAtt = (!this.state.attTouched && Object.keys(this.state.attended).length === 0) ? Object.fromEntries(attPool.filter((_, i) => [0, 2, 3, 6, 8].includes(i)).map(x => [x.id, x])) : this.state.attended;
    this._effAtt = effAtt;
    const attList = Object.values(effAtt).sort((a, b) => String(b.raw.dateShort || '').localeCompare(String(a.raw.dateShort || '')) || b.savedAt - a.savedAt);
    let aw = 0, ad = 0, al = 0;
    const attItems = attList.map((x, i, arr) => {
      const r = x.raw, sa = parseInt(r.scoreA, 10) || 0, sb = parseInt(r.scoreB, 10) || 0;
      const ch = x.cheer !== undefined ? x.cheer : (r.teamA === myT || r.teamB === myT ? myT : null);
      const mine = ch && r.teamA === ch ? 'A' : ch && r.teamB === ch ? 'B' : null;
      let chip = '관람', chipBg = '#8a8a8a';
      if (mine) { const my = mine === 'A' ? sa : sb, op = mine === 'A' ? sb : sa;
        if (my > op) { chip = '승'; chipBg = '#0068FF'; aw++; } else if (my < op) { chip = '패'; chipBg = '#E5484D'; al++; } else { chip = '무'; chipBg = '#8a8a8a'; ad++; } }
      return { match: `${r.teamA} vs ${r.teamB}`, date: r.dateShort || r.meta || '', venue: x.venue, score: `${sa} : ${sb}`, chip, chipBg,
        divider: i === arr.length - 1 ? 'transparent' : c.border, open: () => this.openGame(r) };
    });
    const att = { count: attList.length, wdl: `${aw}-${ad}-${al}`, rate: (aw + ad + al) ? Math.round(aw / (aw + ad + al) * 100) + '%' : '-',
      items: attItems, hasItems: attItems.length > 0, empty: attItems.length === 0 };
    // MY 예측 기록 (시드 기록 + 실제 참여)
    const seedPreds = [
      { match: 'SK호크스 vs 하남시청', pickLabel: 'SK호크스 승', hit: false, date: '04.19' },
      { match: '인천도시공사 vs SK호크스', pickLabel: '인천도시공사 승', hit: true, date: '04.12' },
      { match: 'SK호크스 vs 두산', pickLabel: 'SK호크스 승', hit: true, date: '04.05' },
      { match: '충남도청 vs SK호크스', pickLabel: 'SK호크스 승', hit: true, date: '03.29' },
      { match: 'SK호크스 vs 상무피닉스', pickLabel: '무승부', hit: false, date: '03.22' },
      { match: '하남시청 vs SK호크스', pickLabel: 'SK호크스 승', hit: true, date: '03.15' },
      { match: 'SK호크스 vs 인천도시공사', pickLabel: '인천도시공사 승', hit: true, date: '03.08' },
      { match: '두산 vs SK호크스', pickLabel: '두산 승', hit: false, date: '03.01' },
      { match: 'SK호크스 vs 충남도청', pickLabel: 'SK호크스 승', hit: true, date: '02.22' },
      { match: '상무피닉스 vs SK호크스', pickLabel: 'SK호크스 승', hit: true, date: '02.15' },
      { match: 'SK호크스 vs 하남시청', pickLabel: 'SK호크스 승', hit: false, date: '02.08' },
      { match: '인천도시공사 vs SK호크스', pickLabel: '인천도시공사 승', hit: true, date: '02.01' },
    ];
    const livePreds = Object.values(this.state.preds).map(p => ({ match: p.match, pickLabel: p.pick === 'A' ? `${p.teamA} 승` : p.pick === 'B' ? `${p.teamB} 승` : '무승부', hit: null, date: p.date || '' }));
    const allPreds = [...livePreds, ...seedPreds];
    const decided = allPreds.filter(p => p.hit !== null), hits = decided.filter(p => p.hit).length;
    const myPred = { count: allPreds.length, hits, rate: decided.length ? Math.round(hits / decided.length * 100) + '%' : '-',
      recent: allPreds.slice(0, 4).map((p, i, arr) => ({ ...p, chip: p.hit === null ? '대기' : p.hit ? '적중' : '실패', chipBg: p.hit === null ? '#7a7a7a' : p.hit ? '#0068FF' : '#E5484D', divider: i === arr.length - 1 ? 'transparent' : c.border })) };
    const gS = this.state, LES = this.LESSONS, gL = LES[gS.guideLesson];
    const doneSet = gS.guideDone, firstOpen = LES.findIndex(l => !doneSet.includes(l.id));
    const offsets = ['0px', '56px', '0px', '-56px', '0px'];
    const guideNodes = LES.map((l, i) => {
      const isDone = doneSet.includes(l.id), isCurrent = i === firstOpen, isLocked = !isDone && !isCurrent;
      return { title: l.title, num: i + 1, offset: offsets[i], isDone, isCurrent, isLocked,
        bg: isDone ? '#0068FF' : isCurrent ? 'rgba(0,104,255,0.12)' : c.bg, numColor: isCurrent ? '#0068FF' : c.textFaint, showNum: !isDone,
        sub: `설명 ${l.steps.length}개 · 퀴즈 1개`, rowBorder: isCurrent ? '#0068FF' : 'transparent', rowOpacity: isLocked ? '0.6' : '1',
        cursor: isLocked ? 'default' : 'pointer', labelColor: isLocked ? c.textFaint : c.text, open: isLocked ? () => {} : this.startLesson(i) };
    });
    const nSteps = gL.steps.length, inStep = gS.guideStep < nSteps;
    const stepObj = inStep ? gL.steps[gS.guideStep] : { title: '', body: '', scene: '' };
    const sc = {}; ['intro', 'time', 'win', 'court', 'positions', 'steps3', 'sec3', 'seven', 'gk', 'cards', 'twomin'].forEach(k => { sc[k] = inStep && stepObj.scene === k; });
    const correct = gS.guidePick === gL.quiz.a;
    const quiz = { q: gL.quiz.q, options: gL.quiz.opts.map((label, i) => {
      const picked = gS.guidePick === i, showRight = gS.guideChecked && i === gL.quiz.a, showWrong = gS.guideChecked && picked && !correct;
      const border = showRight ? '#12B886' : showWrong ? '#E5484D' : picked ? '#0068FF' : c.border;
      return { label, key: String(i + 1), pick: this.pickQuiz(i), border, keyColor: border === c.border ? c.textSub : border,
        bg: showRight ? 'rgba(18,184,134,0.12)' : showWrong ? 'rgba(229,72,77,0.1)' : picked ? 'rgba(0,104,255,0.08)' : c.bg };
    }) };
    const guideVals = {
      guideOpen: gS.guideOpen, guidePath: gS.guideView === 'path', guideInLesson: gS.guideView === 'lesson', guideDoneView: gS.guideView === 'done',
      guideNodes, guideGradDate: gS.guideGradDate || '', guideGradLine: gS.guideGradDate ? `${gS.guideGradDate} 수료 · 레슨 다시 보기 ›` : '수료 완료 · 레슨 다시 보기 ›', guideNotDone: doneSet.length < LES.length, justGraduated: gS.guideJustGrad, guideDoneCount: doneSet.length, guidePct: (doneSet.length / LES.length * 100) + '%', guideAllDone: doneSet.length === LES.length,
      guideHeadline: doneSet.length === 0 ? '핸드볼, 같이 배워볼까요?' : doneSet.length === LES.length ? '핸드볼 마스터 달성!' : '좋아요, 계속 가볼까요?',
      openGuide: this.openGuide, closeGuide: this.closeGuide, exitLesson: this.exitLesson, backToPath: this.backToPath,
      lessonPct: (Math.min(gS.guideStep + (gS.guideChecked ? 1 : 0), nSteps + 1) / (nSteps + 1) * 100) + '%',
      lessonLabel: `LESSON ${gS.guideLesson + 1} · ${gL.title}`, isStepView: inStep, isQuizView: !inStep, step: stepObj, sc, quiz,
      quizShake: gS.guideChecked && !correct ? 'ghShake .45s ease-in-out' : 'none',
      showFeedback: !inStep && gS.guideChecked, showMainBtn: inStep || !gS.guideChecked,
      mainBtnLabel: inStep ? '계속' : '확인', mainBtnAction: this.mainBtnAction,
      mainBtnBg: inStep || gS.guidePick !== null ? '#0068FF' : '#B8C2D1', mainBtnShadow: inStep || gS.guidePick !== null ? '#0050C8' : '#9AA5B6',
      fb: correct ? { bg: '#D7F5EA', color: '#0B7A58', title: '정답이에요!', text: gL.quiz.explain, icon: 'M5 12.5l4.5 4.5L19 7.5', btn: '#12B886', btnShadow: '#0B8F68' }
                  : { bg: '#FDE3E4', color: '#B42318', title: '아쉬워요!', text: `정답: ${gL.quiz.opts[gL.quiz.a]} — ${gL.quiz.explain}`, icon: 'M7 7l10 10M17 7L7 17', btn: '#E5484D', btnShadow: '#B7373B' },
      continueLesson: this.continueLesson,
      doneTitle: gL.title + ' 레슨을 끝냈어요', doneHeadline: gS.guideJustGrad ? '입문 가이드 수료!' : '레슨 완료!', doneQuiz: gS.guideLastCorrect ? '정답' : '오답',
      doneNextLabel: gS.guideLesson + 1 < LES.length ? '다음 레슨' : '가이드 완료', doneNext: this.doneNext,
      doneBtnBg: '#0068FF', doneBtnShadow: '#0050C8',
    };
    const favFirst = (arr) => [...arr].sort((a, b) => (b.isFav - a.isFav) || (favIds.indexOf(a.id) - favIds.indexOf(b.id)));
    const players = favFirst(allPlayers.filter(p => p.id[0] === (rankGender === 'M' ? 'm' : 'w')));
    const teamPlayers = favFirst(allPlayers.filter(p => p.team === teamDetailName));
    const favPlayers = favIds.map(id => allPlayers.find(p => p.id === id)).filter(Boolean).map((p, i, arr) => ({ ...p, divider: i === arr.length - 1 ? 'transparent' : c.border }));
    const cardPlayer = allPlayers.find(p => p.id === cardPlayerId) || allPlayers[0];

    const saveLabelMap = { idle: '이미지 저장하기', saving: '저장 중...', done: '저장완료 ✓' };
    const cardSaveLabel = saveLabelMap[this.state.cardSaveStatus];
    const cardSaveBg = this.state.cardSaveStatus === 'done' ? '#0068FF' : '#777777';

    const season = this.state.season;
    const seasonList = ['2026-27', '2025-26', '2024-25', '2023-24'];
    const seasonOptions = seasonList.map(s => ({
      label: s, select: () => this.setState({ season: s, seasonPickerOpen: false }),
      bg: s === season ? '#0068FF' : 'transparent', color: s === season ? '#fff' : c.text,
    }));
    // TODO(v3): replace with actual 서비스 이용약관 copy
    const policySections = [
      { title: '1. 목적', body: '마이핸드볼은 이용자의 개인정보를 소중히 다루며, 서비스 제공에 필요한 최소한의 정보만 수집합니다.' },
      { title: '2. 수집하는 정보', body: '성별, 연령대\n선호 팀 정보: 팀 성별, 팀 번호, 팀명, 팀 로고 URL\n앱 설정 정보: 마이팀, 시즌, 테마, 프로필 설정 완료 여부\n앱 설정 정보는 기기 내 로컬 스토리지에 저장됩니다.' },
      { title: '3. 수집 방법', body: '회원가입 없이 시작하기 과정에서 이용자가 직접 입력한 정보를 수집하며, 입력된 정보는 서버로 전송됩니다.' },
      { title: '4. 이용 목적', body: '맞춤 일정 및 랭킹 화면 제공\n선호 팀 기반 콘텐츠 제공' },
      { title: '5. 보관 및 파기', body: '수집한 정보는 서비스 제공 목적이 달성되면 지체 없이 파기하며, 이용자가 앱 데이터를 삭제하거나 초기화하면 로컬 스토리지 정보도 함께 삭제됩니다.' },
      { title: '6. 제3자 제공', body: '마이핸드볼은 이용자의 개인정보를 외부에 제공하지 않습니다.' },
      { title: '7. 이용자의 권리', body: '이용자는 언제든지 앱 내 설정에서 마이팀을 초기화하거나 앱 데이터를 삭제하여 개인정보 수집을 중단할 수 있습니다.' },
      { title: '8. 문의처', body: '개인정보 관련 문의는 아래 연락처로 부탁드립니다.\n이메일: kebi3477@naver.com' },
    ];

    const stickerOptions = this.stickerImages.map(image => ({
      image, bg: `url(${image})`, dragStart: (e) => { e.dataTransfer.setData('text/plain', image); e.dataTransfer.effectAllowed = 'copy'; },
    }));
    const stickerRow1 = stickerOptions.slice(0, 4);
    const stickerRow2 = stickerOptions.slice(4, 8);
    const placedStickers = this.state.placedStickers.map(st => ({ ...st, bg: `url(${st.image})`, down: this.onStickerDown(st.id) }));
    const savedStickers = this.state.savedStickers.map(st => ({ ...st, bg: `url(${st.image})` }));

    const myTeamName = selectedTeam || 'SK호크스';
    const myRec = combinedRecord.find(r => r.name === myTeamName) || rankData.M[1];
    const myOpps = rankData[myRec.gender].map(r => r.name).filter(n => n !== myTeamName);
    // TODO(v3): 최근 경기 스코어는 목업 — 실제 경기 결과로 교체
    const recentMock = [['승', '28 : 24', '04.19'], ['패', '25 : 27', '04.12'], ['승', '31 : 27', '04.05'], ['무', '26 : 26', '03.29'], ['승', '30 : 22', '03.22']];
    const recentGames = recentMock.map(([res, score, date], i) => ({ res, score, date, opp: myOpps[(i + 1) % myOpps.length], bg: res === '승' ? '#0068FF' : res === '패' ? '#E5484D' : '#8a8a8a' }));
    const myScorers = allPlayers.filter(p => p.team === myTeamName).sort((a, b) => (b.goals || 0) - (a.goals || 0)).slice(0, 3)
      .map((p, i, arr) => ({ ...p, rank: i + 1, rankColor: i === 0 ? '#0068FF' : c.textSub, divider: i === arr.length - 1 ? 'transparent' : c.border }));
    // TODO(v3): 가까운 경기 목업 — MY 팀 기준 실제 일정으로 교체
    const homeRaw = [
      { opp: myOpps[0], home: true, chip: 'LIVE', chipBg: '#FF0000', scoreA: '13', scoreB: '11', meta: '11.14 개막전' },
      { opp: myOpps[1], home: false, chip: '16:00', chipBg: '#0068FF', scoreA: '-', scoreB: '-', meta: '11.21 (토)' },
      { opp: myOpps[2], home: true, chip: '19:00', chipBg: '#0068FF', scoreA: '-', scoreB: '-', meta: '11.28 (토)' },
      { opp: myOpps[3], home: false, chip: '14:00', chipBg: '#0068FF', scoreA: '-', scoreB: '-', meta: '12.05 (토)' },
    ];
    const homeGames = homeRaw.map((g, i) => {
      const teamA = g.home ? myTeamName : g.opp, teamB = g.home ? g.opp : myTeamName;
      const live = g.chip === 'LIVE';
      const open = () => this.openGame({ id: `h${i}-${teamA}-${teamB}`, teamA, teamB, scoreA: g.scoreA, scoreB: g.scoreB, status: live ? 'live' : 'pre', time: live ? '' : g.chip, meta: g.meta, dateShort: g.meta.slice(0, 5), minute: 41 });
      return { ...g, teamA, teamB, logoA: logo(teamA), logoB: logo(teamB), open, broadcast: i === 0 ? 'KBS · MAXPORTS' : 'MAXPORTS', watchLabel: live ? '중계 보기' : '중계 안내', canBook: !live, scoreColor: g.chip === 'LIVE' ? '#0068FF' : c.textFaint };
    });
    const homeGameDots = homeGames.map((_, i) => ({ w: i === this.state.homeGameIdx ? '18px' : '6px', bg: i === this.state.homeGameIdx ? '#0068FF' : c.border }));
    const demoState = this.props.demoState ?? '정상';
    const errActive = (demoState === '오프라인' || demoState === '서버 오류') && !this.state.errDismissed;
    const isOffseason = demoState === '비시즌';
    // ---- 승부예측 탭 ----
    const profile = this.state.profile, homeTab = this.state.homeTab;
    const rkUsers = this.rankUsers(), meN = decided.length, meH = hits;
    const meRow = profile ? { nick: profile.nick, team: profile.team, n: meN, h: meH, me: true } : null;
    const scopeTeam = profile ? profile.team : myTeamName, scope = this.state.rankScope;
    const sortR = (a, b) => (b.h / b.n - a.h / a.n) || (b.n - a.n);
    const qualified = [...rkUsers, ...(meRow && meN >= 10 ? [meRow] : [])];
    const poolAll = [...qualified].sort(sortR);
    const rkPool = scope === 'all' ? poolAll : poolAll.filter(u => u.team === scopeTeam);
    const mkRow = (u, i) => ({ rank: i + 1, nick: u.nick, team: u.team, logo: logo(u.team), rate: Math.round(u.h / u.n * 100) + '%', rec: `${u.h}/${u.n}`,
      rankColor: i < 3 ? '#0068FF' : c.textSub, bg: u.me ? 'rgba(0,104,255,0.1)' : 'transparent', isMe: !!u.me, nickColor: u.me ? '#0068FF' : c.text });
    const myIdx = rkPool.findIndex(u => u.me), myIdxAll = poolAll.findIndex(u => u.me);
    // TODO(v3): 라운드 대진 목업 — 실제 11.21 라운드 전 경기로 교체
    const myG = homeGames[1], myDivG = this.genderOf(myTeamName);
    const pairUp = (list) => { const out = []; for (let k = 0; k + 1 < list.length; k += 2) out.push([list[k], list[k + 1]]); return out; };
    const roundRaw = [];
    ['M', 'W'].forEach(dv => {
      const teams = dv === 'W' ? Component.W_TEAMS : Component.M_TEAMS;
      if (dv === myDivG && myG) {
        roundRaw.push({ dv, teamA: myG.teamA, teamB: myG.teamB, chip: myG.chip, meta: myG.meta, id: `h1-${myG.teamA}-${myG.teamB}`, open: myG.open, mine: true });
        pairUp(teams.filter(t => t !== myG.teamA && t !== myG.teamB)).forEach(([a, b], k) => roundRaw.push({ dv, teamA: a, teamB: b, chip: ['14:00', '19:00'][k % 2], meta: k % 2 ? '11.22 (일)' : '11.21 (토)' }));
      } else pairUp(teams).forEach(([a, b], k) => roundRaw.push({ dv, teamA: a, teamB: b, chip: ['14:00', '16:00', '19:00'][k % 3], meta: k < 2 ? '11.21 (토)' : '11.22 (일)' }));
    });
    const predDiv = this.state.predDiv || 'all';
    const roundList = roundRaw.map(r => {
      const id = r.id || `r-${r.dv}-${r.teamA}-${r.teamB}`;
      return { ...r, id, open: r.open || (() => this.openGame({ id, teamA: r.teamA, teamB: r.teamB, scoreA: '-', scoreB: '-', status: 'pre', time: r.chip, meta: r.meta, dateShort: r.meta.slice(0, 5), minute: 0 })) };
    }).sort((a, b) => (b.mine ? 1 : 0) - (a.mine ? 1 : 0) || (a.dv === myDivG ? 0 : 1) - (b.dv === myDivG ? 0 : 1));
    const predGames = isOffseason ? [] : roundList.filter(r => predDiv === 'all' || r.dv === predDiv).map((g, i) => {
      const live = g.chip === 'LIVE', id = g.id, my = (this.state.preds[id] || {}).pick;
      const gObj = { id, teamA: g.teamA, teamB: g.teamB, dateShort: g.meta.slice(0, 5) };
      const pRand = this.rng(id + 'pred');
      const base = { A: 120 + Math.floor(pRand() * 300), D: 20 + Math.floor(pRand() * 50), B: 100 + Math.floor(pRand() * 300) };
      if (my) base[my] += 1;
      const tot = base.A + base.D + base.B, pct = (k) => Math.round(base[k] / tot * 100) + '%';
      const opts = [['A', `${g.teamA} 승`, logo(g.teamA)], ['D', '무승부', null], ['B', `${g.teamB} 승`, logo(g.teamB)]];
      return { meta: g.meta, time: live ? '경기 중' : g.chip, open: g.open, closed: live, picked: !!my, divLabel: g.dv === 'W' ? '여자부' : '남자부', isMine: !!g.mine,
        stateLabel: live ? '예측 마감' : my ? '참여 완료' : '예측 가능', chipBg: live ? c.border : my ? 'rgba(0,104,255,0.14)' : '#0068FF', chipColor: live ? c.textSub : my ? '#0068FF' : '#fff',
        options: opts.map(([k, label, lg]) => ({ label, logo: lg || 'none', hasLogo: !!lg, pick: live ? () => {} : this.pickPredFor(gObj, k), cursor: live ? 'default' : 'pointer',
          border: my === k ? '#0068FF' : 'transparent', bg: my === k ? 'rgba(0,104,255,0.1)' : c.bg, color: my === k ? '#0068FF' : (live ? c.textSub : c.text) })),
        showDist: !!my || live, pA: pct('A'), pD: pct('D'), pB: pct('B'), total: tot.toLocaleString() };
    });
    const openCount = predGames.filter(g => !g.closed && !g.picked).length;
    const predDivTabs = [['all', '전체'], ['M', '남자부'], ['W', '여자부']].map(([k, label]) => ({ label, select: () => this.setState({ predDiv: k }), bg: predDiv === k ? '#0068FF' : c.pillInactiveBg, color: predDiv === k ? '#fff' : c.pillInactiveText }));
    const divG = this.genderOf(scopeTeam), divTeams = divG === 'W' ? Component.W_TEAMS : Component.M_TEAMS;
    const fanRaw = divTeams.map(t => { const us = qualified.filter(u => u.team === t); const n = us.reduce((a, u) => a + u.n, 0), h = us.reduce((a, u) => a + u.h, 0); return { t, rate: n ? h / n : 0 }; }).sort((a, b) => b.rate - a.rate);
    const fanMax = Math.max(...fanRaw.map(f => f.rate), 0.01);
    const pv = {
      hasProfile: !!profile, noProfile: !profile, nick: profile ? profile.nick : '', team: profile ? profile.team : '', logo: logo(scopeTeam), since: profile ? profile.since : '',
      rate: meN ? Math.round(meH / meN * 100) + '%' : '-', rec: `${meH}/${meN}`,
      rankAll: myIdxAll >= 0 ? `${myIdxAll + 1}위` : '-', rankSub: myIdxAll >= 0 ? `전체 상위 ${Math.max(1, Math.ceil((myIdxAll + 1) / poolAll.length * 100))}%` : `${10 - meN}경기 더 참여`,
      games: predGames, divTabs: predDivTabs, openLabel: isOffseason ? '' : openCount ? `${openCount}경기 예측 가능` : '모두 참여했어요', openColor: openCount ? '#0068FF' : c.textNeutral,
      seasonLabel: isOffseason ? '25-26 시즌 최종' : '25-26 시즌 · 매주 월 갱신',
      scopeTabs: [['all', '전체'], ['team', `${scopeTeam} 팬`]].map(([k, label]) => ({ label, select: () => this.setState({ rankScope: k }), bg: scope === k ? '#0068FF' : c.pillInactiveBg, color: scope === k ? '#fff' : c.pillInactiveText })),
      rows: rkPool.slice(0, 10).map(mkRow), total: rkPool.length.toLocaleString(),
      showPinned: myIdx >= 10, me: myIdx >= 0 ? mkRow(rkPool[myIdx], myIdx) : { rank: '', nick: '', team: '', logo: 'none', rate: '', rec: '' },
      showMeHint: !profile || meN < 10, meHint: !profile ? '프로필을 만들면 내 순위가 여기에 표시돼요 ›' : `확정 ${meN}경기 · ${10 - meN}경기 더 참여하면 랭킹에 올라요`,
      meHintAction: !profile ? this.openProfile : () => {},
      divLabel: divG === 'W' ? '여자부' : '남자부',
      fandom: fanRaw.map((f, i) => ({ rank: i + 1, name: f.t, logo: logo(f.t), pct: Math.round(f.rate * 100) + '%', w: Math.round(f.rate / fanMax * 100) + '%',
        fill: f.t === scopeTeam ? '#0068FF' : c.textNeutral, nameColor: f.t === scopeTeam ? '#0068FF' : c.text })),
    };
    const WDN = ['일', '월', '화', '수', '목', '금', '토'];
    const tGames = myRec.wins + myRec.draws + myRec.losses, teamRateN = tGames ? Math.round(myRec.wins / tGames * 100) : 0;
    const attDecided = aw + ad + al, attRateN = attDecided ? Math.round(aw / attDecided * 100) : null, diff = attRateN === null ? 0 : attRateN - teamRateN;
    const stampTeams = this.genderOf(myT) === 'W' ? Component.W_TEAMS : Component.M_TEAMS;
    const stamps = stampTeams.map(t => { const times = attList.filter(x => x.raw.teamA === t).length, v = times > 0;
      return { logo: logo(t), venue: venueFor(t), visited: v, times: times + '회', op: v ? '1' : '0.35', filter: v ? 'none' : 'grayscale(1)', ring: v ? '#0068FF' : c.textFaint, borderStyle: v ? 'solid' : 'dashed', color: v ? c.text : c.textSub }; });
    const nextHome = isOffseason ? [] : homeGames.filter(g => g.chip !== 'LIVE').slice(0, 2).map((g, i) => {
      const [mm, dd] = g.meta.slice(0, 5).split('.'); const home = g.teamA === myTeamName;
      return { open: g.open, day: String(parseInt(dd, 10)), month: `${parseInt(mm, 10)}월 ${g.meta.slice(7, 8) || ''}`, dday: i === 0 ? 'D-7' : 'D-14', opp: home ? g.teamB : g.teamA, time: g.chip, venue: venueFor(g.teamA), tag: home ? '홈' : '원정', tagColor: home ? '#0068FF' : c.textSub };
    });
    const av = {
      count: attList.length, cheerLine: `응원 경기 ${aw + ad + al} · 관람 ${attList.length - (aw + ad + al)}`, wdl: `${aw}-${ad}-${al}`, rate: attRateN === null ? '-' : attRateN + '%', teamRate: teamRateN + '%',
      hasBadge: attDecided >= 3, badge: diff > 0 ? '승리 요정' : diff < 0 ? '다음엔 꼭 이겨요' : '팀과 같은 흐름',
      badgeSub: diff > 0 ? `내가 가면 승률 +${diff}%p` : diff < 0 ? `직관 승률 ${diff}%p` : '시즌 승률과 같아요',
      badgeBg: diff > 0 ? '#FFD43B' : 'rgba(255,255,255,0.18)', badgeColor: diff > 0 ? '#5a3d00' : '#fff',
      stamps, stampCount: `${stamps.filter(x => x.visited).length}/${stamps.length} 경기장`,
      ...(() => { const n = new Set(attList.filter(x => !stampTeams.includes(x.raw.teamA)).map(x => x.raw.teamA)).size; return { hasStampExtra: n > 0, stampExtra: `+ 다른 리그 경기장 ${n}곳` }; })(), next: nextHome,
      empty: attList.length === 0, hasItems: attList.length > 0,
      items: attItems.map((it, i, arr) => { const raw = attList[i].raw, dd = raw.dateShort || ''; const dt = dd ? new Date(2026, parseInt(dd, 10) - 1, parseInt(dd.slice(3), 10)) : null;
        return { ...it, date: dd, wd: dt ? WDN[dt.getDay()] + '요일' : '', lineTop: i === 0 ? 'transparent' : c.border, lineBottom: i === arr.length - 1 ? 'transparent' : c.border }; }),
      pickedCount: attPool.filter(x => effAtt[x.id]).length,
      pool: attPool.map(x => { const on = !!effAtt[x.id], dd = x.raw.dateShort, dt = new Date(2026, parseInt(dd, 10) - 1, parseInt(dd.slice(3), 10));
        return { toggle: this.toggleAttPool(x), match: `${x.raw.teamA} vs ${x.raw.teamB}`, score: `${x.raw.scoreA} : ${x.raw.scoreB}`, venue: x.venue, dateLabel: `${x.raw.meta} (${WDN[dt.getDay()]})`,
          bg: on ? 'rgba(0,104,255,0.1)' : c.card, border: on ? '#0068FF' : 'transparent', checkBg: on ? '#0068FF' : 'transparent', checkBorder: on ? '#0068FF' : c.textFaint, checkMark: on ? '#fff' : 'transparent' }; }),
    };
    const homeTabs = [['home', '홈', false], ['pred', '승부예측', false], ['att', '직관', false]].map(([k, label, dot]) => ({ label, dot, select: this.setHomeTab(k), color: homeTab === k ? c.text : c.textNeutral, line: homeTab === k ? c.text : 'transparent' }));
    const S = this.state, pfChk = this.nickCheck(S.pfNick, profile && profile.nick), pfCan = pfChk.ok && S.pfConsent && !!S.pfTeam;
    const pf = {
      open: S.pfOpen, isEdit: S.pfEdit, title: S.pfEdit ? '프로필 편집' : '승부예측 프로필 만들기', nick: S.pfNick, count: S.pfNick.length,
      msg: pfChk.msg, msgColor: pfChk.ok ? '#0068FF' : '#E5484D', inputBorder: !S.pfNick ? 'transparent' : pfChk.ok ? '#0068FF' : '#E5484D',
      genderTabs: [['M', '남자부'], ['W', '여자부']].map(([k, label]) => ({ label, select: this.pfSetGender(k), bg: S.pfGender === k ? '#0068FF' : c.pillInactiveBg, color: S.pfGender === k ? '#fff' : c.pillInactiveText })),
      teams: (S.pfGender === 'W' ? Component.W_TEAMS : Component.M_TEAMS).map(t => ({ name: t, logo: logo(t), select: this.pfPickTeam(t), border: t === S.pfTeam ? '#0068FF' : 'transparent', bg: t === S.pfTeam ? 'rgba(0,104,255,0.1)' : c.card, color: t === S.pfTeam ? '#0068FF' : c.text })),
      consentBg: S.pfConsent ? '#0068FF' : 'transparent', consentBorder: S.pfConsent ? '#0068FF' : c.textFaint, consentCheck: S.pfConsent ? '#fff' : 'transparent',
      saveBg: pfCan ? '#0068FF' : '#9a9a9a', saveCursor: pfCan ? 'pointer' : 'default', saveLabel: S.pfEdit ? '저장' : '랭킹 참여하기',
      laterLabel: S.pfPending ? '나중에 하고 예측만 저장할게요' : '닫기',
    };
    const nkChk = this.nickCheck(S.nickDraft, profile && profile.nick), nkSame = profile && S.nickDraft.trim() === profile.nick, nkCan = nkChk.ok || nkSame;
    const myProf = {
      viewing: !S.nickEditing, editing: S.nickEditing,
      title: profile ? profile.nick : '닉네임을 정해 주세요', titleColor: profile ? c.text : c.textSub,
      sub: profile ? `${profile.team} 팬 · ${myIdxAll >= 0 ? `예측 랭킹 ${myIdxAll + 1}위` : '랭킹 집계 전'}` : `${myTeamName} 팬`, logo: logo(profile ? profile.team : myTeamName),
      draft: S.nickDraft, draftCount: S.nickDraft.length, msg: nkSame ? '' : nkChk.msg, msgColor: nkChk.ok ? '#0068FF' : '#E5484D',
      inputBorder: nkSame || !S.nickDraft ? c.border : nkChk.ok ? '#0068FF' : '#E5484D', saveBg: nkCan ? '#0068FF' : '#9a9a9a', saveCursor: nkCan ? 'pointer' : 'default',
    };
    const errCopy = demoState === '오프라인'
      ? { title: '인터넷에 연결되어 있지 않아요', desc: 'Wi-Fi나 모바일 데이터 연결을 확인한 뒤\n다시 시도해 주세요.', icon: 'M2 8.5a15 15 0 0 1 20 0M5.5 12a10 10 0 0 1 13 0M9 15.5a5 5 0 0 1 6 0M12 19h.01M3 3l18 18' }
      : { title: '정보를 불러오지 못했어요', desc: '일시적인 오류가 발생했어요.\n잠시 후 다시 시도해 주세요.', icon: 'M12 8v5M12 16.5h.01M10.3 3.9L2.4 17.6A2 2 0 0 0 4.1 20.6h15.8a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z' };
    const sq = this.state.searchQuery.trim().toLowerCase();
    const allTeams = [...rankData.M, ...rankData.W];
    const teamResults = sq ? allTeams.filter(t => t.name.toLowerCase().includes(sq)).map(t => ({
      name: t.name, logoUrl: logo(t.name), sub: `${t.gender === 'W' ? '여자부' : '남자부'} · 25-26 ${t.rank}위`,
      open: () => { this.saveRecent(t.name); this.setState({ searchOpen: false, appScreen: 'stat', teamDetailName: t.name, teamDetailTab: 'info' }); this.simulateLoad('loadingTeamDetail'); } })) : [];
    const playerResults = sq ? allPlayers.filter(p => p.name.includes(sq) || p.team.toLowerCase().includes(sq)).map(p => ({ ...p,
      pick: () => { this.saveRecent(p.name); this.setState({ cardPlayerId: p.id }); } })) : [];
    const mkUse = (q) => () => { this.setState({ searchQuery: q }); this.saveRecent(q); };
    const pickerGender = this.state.pickerGender;
    const pickerTitle = pickerGender === 'M' ? '남자부 팀 선택' : '여자부 팀 선택';
    const pickerTeamList = teamsByGender[pickerGender].map(name => ({
      name, logoUrl: logo(name), border: name === selectedTeam ? '#0068FF' : c.border, select: () => { const changed = name !== selectedTeam; this.setState({ selectedTeam: name, teamPickerOpen: false, rankGender: this.genderOf(name), selectedDay: null }); if (changed && attList.length) this.showToast('MY팀이 바뀌어도 이전 직관 기록은 그대로 유지돼요'); },
    }));
    // ---- MY팀 달력 ----
    const WD = ['일', '월', '화', '수', '목', '금', '토'], pad2 = (n) => String(n).padStart(2, '0');
    const venueOf = (t) => { const i = teamInfoMap[t] || {}; return i.stadium && i.stadium !== '-' ? i.stadium : `${i.region && i.region !== '-' ? i.region : t} 홈 경기장`; };
    const calTeam = myTeamName;
    const calFor = (off) => this.props.demoState === '비시즌' ? [] : this.myCalGames(calTeam, myOpps, off);
    const calGames = calFor(monthOffset);
    const toIcs = (x) => ({ uid: `${calTeam}-${x.date.getTime()}`, start: x.date, summary: `[핸드볼] ${x.home ? calTeam : x.opp} vs ${x.home ? x.opp : calTeam}`, venue: venueOf(x.home ? calTeam : x.opp) });
    const cy = baseDate.getFullYear(), cm = baseDate.getMonth(), firstWd = new Date(cy, cm, 1).getDay(), dim = new Date(cy, cm + 1, 0).getDate();
    const calSel = this.state.calSelDay ?? (calGames.find(x => x.status !== 'final') || calGames[calGames.length - 1] || {}).day;
    const blankCell = { label: '', hasGame: false, select: () => {}, bg: 'transparent', border: 'transparent', cursor: 'default', numColor: c.textSub, weight: 500, oppLogo: 'none', ring: 'transparent', tag: '', tagColor: c.textSub };
    const calCells = Array.from({ length: firstWd }, () => blankCell);
    for (let d = 1; d <= dim; d++) {
      const x = calGames.find(q => q.day === d), wd = (firstWd + d - 1) % 7, sel = !!x && d === calSel, isToday = monthOffset === 0 && d === 24;
      const res = x && x.status === 'final' ? (x.my > x.op ? '승' : x.my < x.op ? '패' : '무') : null;
      calCells.push({ label: String(d), hasGame: !!x, oppLogo: x ? logo(x.opp) : 'none', ring: x && x.home ? '#0068FF' : c.textFaint,
        tag: !x ? '' : x.status === 'live' ? 'LIVE' : res || x.time,
        tagColor: !x ? c.textSub : x.status === 'live' ? '#FF3B30' : res === '승' ? '#0068FF' : res === '패' ? '#E5484D' : c.textSub,
        select: x ? () => this.setState({ calSelDay: d }) : () => {}, cursor: x ? 'pointer' : 'default',
        bg: sel ? 'rgba(0,104,255,0.14)' : 'transparent', border: sel ? '#0068FF' : isToday ? c.textFaint : 'transparent',
        numColor: wd === 0 ? '#E5484D' : wd === 6 ? '#4D8BFF' : c.text, weight: isToday ? 800 : 500 });
    }
    while (calCells.length % 7) calCells.push(blankCell);
    const sx = calGames.find(q => q.day === calSel);
    let calSelObj = {};
    if (sx) {
      const tA = sx.home ? calTeam : sx.opp, tB = sx.home ? sx.opp : calTeam, sa = sx.home ? sx.my : sx.op, sb = sx.home ? sx.op : sx.my, showScore = sx.status !== 'pre';
      calSelObj = { dateLabel: `${cm + 1}월 ${sx.day}일 (${WD[sx.wd]}) ${sx.time}`, chip: sx.home ? '홈' : '원정', chipBg: sx.home ? '#0068FF' : '#808080',
        teamA: tA, teamB: tB, logoA: logo(tA), logoB: logo(tB), center: showScore ? `${sa} : ${sb}` : 'VS',
        status: sx.status === 'live' ? 'LIVE' : sx.status === 'final' ? '경기 종료' : `D-${Math.ceil((sx.date - new Date(2026, 4, 24)) / 864e5)}`, statusColor: sx.status === 'live' ? '#FF3B30' : c.textSub,
        venue: venueOf(tA), canAdd: sx.status === 'pre',
        open: () => this.openGame({ id: `cal-${calTeam}-${cy}-${cm}-${sx.day}`, teamA: tA, teamB: tB, scoreA: showScore ? String(sa) : '-', scoreB: showScore ? String(sb) : '-', status: sx.status, time: sx.status === 'pre' ? sx.time : '', dateShort: `${pad2(cm + 1)}.${pad2(sx.day)}`, meta: `${cm + 1}월 ${sx.day}일`, minute: 41 }),
        addCal: () => this.downloadIcs([toIcs(sx)], `${calTeam}_${cm + 1}월${sx.day}일.ics`) };
    }
    const calDone = calGames.filter(x => x.status === 'final');
    const cW = calDone.filter(x => x.my > x.op).length, cL = calDone.filter(x => x.my < x.op).length, cD = calDone.length - cW - cL;
    const upcoming = [0, 1, 2, 3, 4, 5, 6].flatMap(o => calFor(o).filter(x => x.status === 'pre'));
    const cal = { weekdays: WD.map((label, i) => ({ label, color: i === 0 ? '#E5484D' : i === 6 ? '#4D8BFF' : c.textSub })), cells: calCells,
      hasSel: !!sx, sel: calSelObj, noGames: calGames.length === 0,
      summary: calGames.length ? `${cm + 1}월 ${calGames.length}경기${calDone.length ? ` · ${cW}승 ${cD}무 ${cL}패` : ''}` : `${cm + 1}월 경기 없음`,
      upcomingCount: upcoming.length, exportAll: () => this.downloadIcs(upcoming.map(toIcs), `${calTeam}_경기일정.ics`),
      exportLabel: this.state.icsSaved ? '저장됨 ✓' : '추가', exportBg: this.state.icsSaved ? '#12B886' : '#0068FF' };
    // ---- 시즌 추이 (TODO(v3): 경기 순서는 최종 W/D/L을 섞은 추정 — 연맹 라운드별 결과로 교체) ----
    const tTeams = rankData[trBase.gender] || [], seqs = {};
    tTeams.forEach(r => { const a = [...Array(r.wins).fill('W'), ...Array(r.draws).fill('D'), ...Array(r.losses).fill('L')]; const rr = this.rng('trend' + r.name); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rr() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } seqs[r.name] = a; });
    const tSeq = seqs[teamDetailName] || [], N = tSeq.length;
    let trend = { has: false, tabs: [], yLabels: [], xLabels: [], results: [], facts: [] };
    if (N > 1) {
      const cum = {}; tTeams.forEach(r => { let s = 0; cum[r.name] = seqs[r.name].map(x => (s += x === 'W' ? 2 : x === 'D' ? 1 : 0)); });
      const nT = tTeams.length, me = cum[teamDetailName];
      const ranks = tSeq.map((_, i) => 1 + tTeams.filter(o => o.name !== teamDetailName && ((cum[o.name][i] || 0) > me[i] || ((cum[o.name][i] || 0) === me[i] && o.rank < trBase.rank))).length);
      const mode = this.state.trendMode, isRank = mode === 'rank', maxPts = Math.max(1, ...tTeams.map(o => o.points));
      const X = (i) => 6 + i / (N - 1) * 288;
      const gy = (v) => isRank ? 12 + (v - 1) / Math.max(1, nT - 1) * 136 : 148 - v / maxPts * 136;
      const Y = (i) => gy(isRank ? ranks[i] : me[i]);
      const pts = tSeq.map((_, i) => `${X(i).toFixed(1)},${Y(i).toFixed(1)}`);
      const gridVals = isRank ? tTeams.map((_, i) => i + 1) : [0, Math.round(maxPts / 2), maxPts];
      let best = 99, ws = 0, ls = 0, cw = 0, cl = 0;
      tSeq.forEach((x, i) => { best = Math.min(best, ranks[i]); cw = x === 'W' ? cw + 1 : 0; cl = x === 'L' ? cl + 1 : 0; ws = Math.max(ws, cw); ls = Math.max(ls, cl); });
      const rounds = Math.max(1, Math.round(N / Math.max(1, nT - 1)));
      trend = { has: true, points: pts.join(' '), areaPath: `M${X(0)},148 L${pts.join(' L')} L${X(N - 1)},148 Z`,
        gridPath: gridVals.map(v => `M0,${gy(v).toFixed(1)} H300`).join(' '),
        yLabels: gridVals.map(v => ({ label: isRank ? v + '위' : String(v), top: gy(v) + 'px' })),
        xLabels: Array.from({ length: rounds }, (_, i) => ({ label: `${i + 1}라운드` })),
        dotLeft: `calc(28px + (100% - 28px) * ${(X(N - 1) / 300).toFixed(3)})`, dotTop: Y(N - 1) + 'px',
        endLabel: isRank ? `최종 ${ranks[N - 1]}위` : `승점 ${me[N - 1]}`,
        results: tSeq.map(x => ({ bg: x === 'W' ? '#0068FF' : x === 'D' ? '#8a8a8a' : '#E5484D' })),
        facts: [{ label: '최고 순위', value: best + '위' }, { label: '최다 연승', value: ws + '연승' }, { label: '최다 연패', value: ls + '연패' }],
        tabs: [['rank', '순위'], ['points', '승점']].map(([k, label]) => ({ label, select: () => this.setState({ trendMode: k }), bg: mode === k ? '#0068FF' : 'transparent', color: mode === k ? '#fff' : c.textSub })) };
    }
    // ---- 선수 비교 ----
    const pBy = (id) => allPlayers.find(p => p.id === id);
    const cA = pBy(this.state.cmpA), cB = pBy(this.state.cmpB), picking = this.state.cmpPicking;
    const gPre = (cA || cB) ? (cA || cB).id[0] : (rankGender === 'M' ? 'm' : 'w');
    const pool = allPlayers.filter(p => p.id[0] === gPre);
    const mDefs = [['득점', 'statGoals'], ['도움', 'statAssists'], ['세이브', 'statSaves'], ['성공률', 'statPct'], ['출전', 'statGames']];
    const mMax = mDefs.map(([, k]) => Math.max(1, ...pool.map(p => p[k] || 0)));
    const RC = { x: 130, y: 114, r: 78 }, ang = (i) => (-90 + i * 72) * Math.PI / 180;
    const rp = (i, v) => `${(RC.x + RC.r * v * Math.cos(ang(i))).toFixed(1)},${(RC.y + RC.r * v * Math.sin(ang(i))).toFixed(1)}`;
    const poly = (p) => p ? mDefs.map(([, k], i) => rp(i, Math.max(0.06, (p[k] || 0) / mMax[i]))).join(' ') : '';
    const webPath = [0.25, 0.5, 0.75, 1].map(v => 'M' + mDefs.map((_, i) => rp(i, v)).join(' L') + ' Z').join(' ') + ' ' + mDefs.map((_, i) => `M${RC.x},${RC.y} L${rp(i, 1)}`).join(' ');
    const axes = mDefs.map(([label], i) => ({ label, left: (RC.x + (RC.r + 20) * Math.cos(ang(i))).toFixed(0) + 'px', top: (RC.y + (RC.r + 14) * Math.sin(ang(i))).toFixed(0) + 'px' }));
    const cmpSlots = [['A', cA, '#0068FF'], ['B', cB, '#FF7A45']].map(([k, p, col]) => ({ filled: !!p, empty: !p, name: p ? p.name : '', team: p ? p.team : '', logoUrl: p ? p.logoUrl : 'none', number: p ? p.number : '', pos: p ? p.posFull : '', color: col,
      border: picking === k ? col : 'transparent', pick: () => this.setState({ cmpPicking: picking === k ? null : k }) }));
    const other = picking === 'A' ? cB : cA, cur = picking === 'A' ? cA : cB;
    const pickList = picking ? favFirst(pool.filter(p => !other || p.id !== other.id)).map(p => ({ ...p, selBorder: cur && cur.id === p.id ? '#0068FF' : 'transparent',
      choose: () => this.setState({ ['cmp' + picking]: p.id, cmpPicking: null }), line: p.pos === 'GK' ? `${p.statSaves}세이브` : `${p.statGoals}골` })) : [];
    const cmpRows = cA && cB ? [['출전 경기', (p) => p.statGames], ['득점', (p) => p.statGoals], ['경기당 득점', (p) => +(p.statGoals / p.statGames).toFixed(1)], ['도움', (p) => p.statAssists], ['세이브', (p) => p.statSaves], [cA.pos === 'GK' || cB.pos === 'GK' ? '성공률 (슛·방어)' : '슛 성공률', (p) => p.statPct, '%']].map(([label, fn, unit]) => {
      const a = fn(cA), b = fn(cB), sum = (a + b) || 1;
      return { label, a: a + (unit || ''), b: b + (unit || ''), pA: a / sum * 100 + '%', pB: b / sum * 100 + '%', barA: a > b ? '#0068FF' : c.textFaint, barB: b > a ? '#FF7A45' : c.textFaint, colA: a > b ? '#0068FF' : c.text, colB: b > a ? '#FF7A45' : c.text };
    }) : [];
    const cmp = { slots: cmpSlots, picking: !!picking, pickTitle: picking === 'A' ? '첫 번째 선수 선택' : '두 번째 선수 선택', pickList, ready: !!(cA && cB) && !picking,
      polyA: poly(cA), polyB: poly(cB), webPath, axes, rows: cmpRows, nameA: cA ? cA.name : '', nameB: cB ? cB.name : '' };
    const dev = this.props.device, isTab = dev === '태블릿' || dev === '태블릿 (세로)', isPortrait = dev === '태블릿 (세로)', railBg = (k) => appScreen === k ? 'rgba(0,104,255,0.12)' : 'transparent';
    const deviceVals = { frameW: isPortrait ? '820px' : isTab ? '1180px' : '375px', frameH: isPortrait ? '1180px' : isTab ? '820px' : '812px', frameR: isTab ? '36px' : '55px',
      islandDisplay: isTab ? 'none' : 'block', obLeft: isTab ? 'calc(50% - 200px)' : '0px',
      sidePad: isTab ? 'max(32px, calc((100% - 1000px) / 2))' : '0px', ovPad: isTab ? 'max(32px, calc((100% - 720px) / 2))' : '0px',
      secCols: isTab ? 'repeat(2,minmax(0,1fr))' : 'minmax(0,1fr)', spanAll: isTab ? '1 / -1' : 'auto', teamCols: isTab ? 'repeat(auto-fill,159px)' : 'repeat(2,159px)', homeCols: isTab && !isPortrait ? 'repeat(2,minmax(0,1fr))' : 'minmax(0,1fr)', schedCols: isTab && !isPortrait ? 'repeat(2,minmax(0,1fr))' : 'minmax(0,1fr)',
      sheetMax: isTab ? '560px' : '100%', toastBottom: isTab ? '32px' : '104px', isTablet: isTab, isPhone: !isTab, railW: isTab ? '100px' : '0px',
      railHomeBg: railBg('home'), railScheduleBg: railBg('schedule'), railStatBg: railBg('stat'), railMyBg: railBg('my') };
    const schedView = this.state.schedView, contentOk = !this.state.loadingSchedule && !errActive;
    const ymY = this.state.ymPickerYear;
    const ymMonths = Array.from({ length: 12 }, (_, m) => { const cur = ymY === cy && m === cm, isNow = ymY === 2026 && m === 4;
      return { label: `${m + 1}월`, select: () => this.setYm(ymY, m), bg: cur ? '#0068FF' : c.card, color: cur ? '#fff' : c.text, border: isNow && !cur ? '#0068FF' : 'transparent' }; });
    const extraVals = { cal, trend, cmp, ymPickerOpen: this.state.ymPickerOpen, ymYear: ymY, ymMonths, openYmPicker: this.openYmPicker, closeYmPicker: this.closeYmPicker, ymYearPrev: this.ymYearPrev, ymYearNext: this.ymYearNext, ymToday: this.ymToday, cmpOpen: this.state.cmpOpen, closeCmp: this.closeCmp, goMyCal: this.goMyCal,
      openCompareTab: () => this.openCompare(players[0] && players[0].id, players[1] && players[1].id),
      schedToList: this.schedToList, schedToCal: this.schedToCal, schedListView: schedView === 'list',
      showScheduleList: contentOk && schedView === 'list', showScheduleCal: contentOk && schedView === 'cal',
      schedListBg: schedView === 'list' ? '#0068FF' : 'transparent', schedListColor: schedView === 'list' ? '#fff' : c.textNeutral,
      schedCalBg: schedView === 'cal' ? '#0068FF' : 'transparent', schedCalColor: schedView === 'cal' ? '#fff' : c.textNeutral };
    const pickerActiveStyle = { bg: '#0068FF', color: '#fff', border: '#0068FF', shadow: '0 6px 14px rgba(0,104,255,0.25)' };
    const pickerInactiveStyle = { bg: c.bg, color: c.textSub, border: c.border, shadow: 'none' };

    return {
      isOnboarding: !inApp, isApp: inApp, ...extraVals, ...deviceVals,
      isHome: appScreen === 'home', isSchedule: appScreen === 'schedule',
      isStat: appScreen === 'stat', isMy: appScreen === 'my',
      isStatRank: statTab === 'rank' && !this.state.loadingStat && !errActive,
      isStatRecord: statTab === 'record' && !this.state.loadingStat && !errActive,
      isStatTeam: statTab === 'team' && !this.state.loadingStat && !errActive, isStatPlayer: statTab === 'player' && !this.state.loadingStat && !errActive,
      isTeamDetail: !!teamDetailName, isStatMain: !teamDetailName,
      teamDetail, teamDetailTabs, closeTeamDetail: this.closeTeamDetail,
      isTeamDetailInfo: teamDetailTab === 'info' && !this.state.loadingTeamDetail && !errActive, isTeamDetailPlayers: teamDetailTab === 'players' && !this.state.loadingTeamDetail && !errActive,
      isTeamDetailCheer: teamDetailTab === 'cheer' && !this.state.loadingTeamDetail && !errActive, isTeamDetailRecord: teamDetailTab === 'record' && !this.state.loadingTeamDetail && !errActive,
      teamInfo, teamRecord, cheerPosts, cheerTotal: cheerPosts.length, mod,
      closeCheerMenu: this.closeCheerMenu, menuDelete: this.menuDelete, menuReport: this.menuReport, menuBlock: this.menuBlock, closeReport: this.closeReport, onReportDetail: this.onReportDetail, toggleReportBlock: this.toggleReportBlock, submitReport: this.submitReport, cancelBlock: this.cancelBlock, confirmBlock: this.confirmBlock, openBlocked: this.openBlocked, closeBlocked: this.closeBlocked,
      cheerDraft: this.state.cheerDraft, onCheerInput: this.onCheerInput, submitCheer: this.submitCheer, cheerCount: this.state.cheerDraft.length,
      cheerBtnBg: this.state.cheerDraft.trim() ? '#0068FF' : '#9a9a9a', toggleIntro: this.toggleIntro, toggleHistory: this.toggleHistory,
      loadingHome: this.state.loadingHome, showHomeContent: !this.state.loadingHome && !errActive && homeTab === 'home', showPredContent: !this.state.loadingHome && !errActive && homeTab === 'pred', showAttContent: !this.state.loadingHome && !errActive && homeTab === 'att', av, attSheetOpen: this.state.attSheetOpen, openAttSheet: this.openAttSheet, closeAttSheet: this.closeAttSheet, goAttTab: this.goAttTab,
      homeTabs, pv, pf, myProf, ...this.buildBadges(attDecided, diff, hits, doneSet.length, c), startNickEdit: this.startNickEdit, cancelNickEdit: this.cancelNickEdit, onNickDraft: this.onNickDraft, onNickKey: this.onNickKey, saveNick: this.saveNick, openProfile: this.openProfile, closeProfile: this.closeProfile, onPfNick: this.onPfNick, suggestNick: this.suggestNick, togglePfConsent: this.togglePfConsent, saveProfile: this.saveProfile, leaveRanking: this.leaveRanking, goPredTab: this.goPredTab, onHomeSwipeDown: this.onHomeSwipeDown, onHomeSwipeUp: this.onHomeSwipeUp,
      loadingSchedule: this.state.loadingSchedule, showScheduleContent: !this.state.loadingSchedule && !errActive,
      loadingStat: this.state.loadingStat, loadingTeamDetail: this.state.loadingTeamDetail,
      showProgress: step !== 0,
      progressWidth: (20 * step) + '%',
      stepTransform: `translateX(${-100 / 6 * step}%)`,
      ...(() => { const n = this.state.pfNick, ck = this.nickCheck(n, this.state.profile && this.state.profile.nick); return { obNick: n, obNickCount: n.length, obNickMsg: ck.msg, obNickMsgColor: ck.ok ? '#0068FF' : '#E5484D', obNickBorder: !n ? 'transparent' : ck.ok ? '#0068FF' : '#E5484D', obNickPreview: n.trim() || '닉네임', obPreviewColor: n.trim() ? '#0068FF' : '#5d5d5d', obTeamLogo: logo(selectedTeam), obTeamName: selectedTeam || '', obWelcome: `${n.trim() || '팬'}님, 환영합니다!` }; })(),
      interestFlowBorder: interest === 'flow' ? '#0068FF' : 'transparent',
      interestCheerBorder: interest === 'cheer' ? '#0068FF' : 'transparent',
      interestHighlightBorder: interest === 'highlight' ? '#0068FF' : 'transparent',
      interestRankBorder: interest === 'rank' ? '#0068FF' : 'transparent',
      goPrev: this.goPrev,
      selectInterestFlow: this.selectInterestFlow, selectInterestCheer: this.selectInterestCheer,
      selectInterestHighlight: this.selectInterestHighlight, selectInterestRank: this.selectInterestRank,
      ageList, teamList,
      selectTeamGenderM: this.selectTeamGenderM, selectTeamGenderW: this.selectTeamGenderW,
      teamGenderMBg: teamGender === 'M' ? '#0068FF' : 'transparent', teamGenderMColor: teamGender === 'M' ? '#fff' : '#fff',
      teamGenderWBg: teamGender === 'W' ? '#0068FF' : 'transparent', teamGenderWColor: teamGender === 'W' ? '#fff' : '#fff',
      selectMale: this.selectMale, selectFemale: this.selectFemale,
      maleBg: gender === 'M' ? '#0068FF' : 'transparent', maleColor: '#fff',
      femaleBg: gender === 'W' ? '#0068FF' : 'transparent', femaleColor: '#fff',
      primaryAction: this.primaryAction, primaryLabel: labelFor(step),
      primaryBg: disabled ? '#4d4d4d' : '#0068FF', primaryOpacity: disabled ? '0.6' : '1',
      goHome: this.goHome, goSchedule: this.goSchedule, goStat: this.goStat, goMy: this.goMy, goApp: this.goApp,
      homeColor: appScreen === 'home' ? '#0068FF' : c.tabInactive,
      scheduleColor: appScreen === 'schedule' ? '#0068FF' : c.tabInactive,
      statColor: appScreen === 'stat' ? '#0068FF' : c.tabInactive,
      myColor: appScreen === 'my' ? '#0068FF' : c.tabInactive,
      rankSelectM: this.rankSelectM, rankSelectW: this.rankSelectW,
      rankMBg: rankGender === 'M' ? '#0068FF' : c.pillInactiveBg, rankMColor: rankGender === 'M' ? '#fff' : c.pillInactiveText,
      rankWBg: rankGender === 'W' ? '#0068FF' : c.pillInactiveBg, rankWColor: rankGender === 'W' ? '#fff' : c.pillInactiveText,
      podium, otherRank, fullRank, fullRecord,
      c, setThemeLight: this.setThemeLight, setThemeDark: this.setThemeDark,
      themeLightBg: !isDark ? '#0068FF' : 'transparent', themeLightColor: !isDark ? '#fff' : c.textSub,
      themeDarkBg: isDark ? '#0068FF' : 'transparent', themeDarkColor: isDark ? '#fff' : c.textSub,
      q1Options, q1Answered: q1Answer !== null,
      q2Options, q2Answered: q2Answer !== null,
      monthLabel, monthPrev: this.monthPrev, monthNext: this.monthNext, scheduleGames, hasSchedule, noSchedule,
      dayChips, hasDayChips,
      statTabs, players,
      hasError: errActive, isOffline: demoState === '오프라인', errTitle: errCopy.title, errDesc: errCopy.desc, errIconPath: errCopy.icon,
      retryHome: this.retryHome, retryStat: this.retryStat, retrySchedule: this.retrySchedule,
      isOffseason, hasHomeGames: !isOffseason,
      openSearch: this.openSearch, closeSearch: this.closeSearch, searchOpen: this.state.searchOpen, searchQuery: this.state.searchQuery,
      searchInputRef: this.searchInputRef, onSearchInput: this.onSearchInput, onSearchKey: this.onSearchKey, clearSearch: this.clearSearch, clearRecent: this.clearRecent,
      hasSearchQuery: !!sq, searchIdle: !sq,
      recentSearches: this.state.recentSearches.map(q => ({ q, use: mkUse(q), remove: this.removeRecent(q) })), hasRecentSearches: this.state.recentSearches.length > 0,
      suggestedSearches: ['인천도시공사', 'SK슈가글라이더즈', '이요셉', '최지혜', '두산', '삼척시청'].map(q => ({ q, use: mkUse(q) })),
      teamResults, playerResults, teamResultCount: teamResults.length, playerResultCount: playerResults.length,
      hasTeamResults: teamResults.length > 0, hasPlayerResults: playerResults.length > 0,
      hasSearchResults: !!sq && (teamResults.length + playerResults.length) > 0, noSearchResults: !!sq && (teamResults.length + playerResults.length) === 0,
      top5, top5Tabs, top5Short: top5.length < 5,
      top5Note: this.state.top5Cat === 'goals' ? '추정 표시가 없는 기록은 한국핸드볼연맹·언론 보도 기준' : '세이브·도움은 추정치 — 연맹 시즌 기록으로 교체 예정', top5Unit: { goals: '골', saves: '세이브', assists: '도움' }[this.state.top5Cat], top5Division: rankGender === 'W' ? '여자부' : '남자부',
      homeGames, homeGameDots, onHomeGamesScroll: this.onHomeGamesScroll,
      homeGamesRef: this.homeGamesRef, onHgDown: this.onHgDown, onHgMove: this.onHgMove, onHgUp: this.onHgUp,
      hgSnap: this.state.hgDragging ? 'none' : 'x mandatory',
      myTeamName, myTeamLogo: logo(myTeamName), myTeamRank: `25-26 시즌 ${myRec.rank}위`,
      nextGame: { dday: isOffseason ? '비시즌 · 개막 D-53' : 'D-53', date: '11월 14일 (토)', opp: myOpps[0], venue: '26-27 시즌 개막전', time: '14:00' },
      seasonStats: [
        { label: '순위', value: `${myRec.rank}위`, color: '#0068FF' }, { label: '경기', value: myRec.wins + myRec.draws + myRec.losses, color: c.text },
        { label: '승', value: myRec.wins, color: c.text }, { label: '무', value: myRec.draws, color: c.text },
        { label: '패', value: myRec.losses, color: c.text }, { label: '승점', value: myRec.points, color: c.text },
        { label: '득점', value: myRec.goalsFor, color: c.text }, { label: '실점', value: myRec.goalsAgainst, color: c.text },
      ],
      recentGames,
      topScorers: myScorers,
      noTopScorers: myScorers.length === 0,
      showCard: !!cardPlayerId, cardPlayer, closeCard: this.closeCard, stop: this.stop,
      teamPlayers, noTeamPlayers: teamPlayers.length === 0,
      ...gdVals, ...(errActive ? { gdTabLive: false, gdTabStats: false, gdTabPredict: false, gdTabMvp: false } : {}), gdErr: errActive && gdVals.gdOpen, retryGame: this.retryGame, retryMy: this.retryMy, retryTeamDetail: this.retryTeamDetail,
      hasToast: !!this.state.toast, toastMsg: this.state.toast || '', statOffseason: isOffseason && !errActive, closeGame: this.closeGame, myPred, att, toggleAttend: this.toggleAttend, ...guideVals,
      favPlayers, hasFavPlayers: favPlayers.length > 0, noFavPlayers: favPlayers.length === 0, goStatPlayers: this.goStatPlayers,
      openMyTeamDetail: this.openMyTeamDetail,
      notifOn: this.state.notifOn, toggleNotif: this.toggleNotif,
      notifTrackBg: this.state.notifOn ? '#0068FF' : c.toggleOff, notifKnobLeft: this.state.notifOn ? '20px' : '2px',
      saveCardImage: this.saveCardImage, cardSaveLabel, cardSaveBg,
      settingsOpen: this.state.settingsOpen, openSettings: this.openSettings, closeSettings: this.closeSettings,
      setThemeToggle: this.setThemeToggle, themeTrackBg: isDark ? '#0068FF' : c.toggleOff, themeKnobLeft: isDark ? '20px' : '2px',
      seasonPickerOpen: this.state.seasonPickerOpen, openSeasonPicker: this.openSeasonPicker, closeSeasonPicker: this.closeSeasonPicker, season, seasonOptions,
      policyOpen: this.state.policyOpen, openPolicy: this.openPolicy, closePolicy: this.closePolicy, policySections,
      termsOpen: this.state.termsOpen, openTerms: this.openTerms, closeTerms: this.closeTerms,
      restartOnboarding: this.restartOnboarding,
      cardEditOpen: this.state.cardEditOpen, openCardEdit: this.openCardEdit, closeCardEdit: this.closeCardEdit, saveCardEdit: this.saveCardEdit,
      stickerRow1, stickerRow2, placedStickers, savedStickers,
      photoAreaRef: this.photoAreaRef, onStickerMove: this.onStickerMove, onStickerUp: this.onStickerUp,
      onCanvasDragOver: this.onCanvasDragOver, onCanvasDrop: this.onCanvasDrop,
      teamPickerOpen: this.state.teamPickerOpen, openTeamPicker: this.openTeamPicker, closeTeamPicker: this.closeTeamPicker,
      pickerGenderM: this.pickerGenderM, pickerGenderW: this.pickerGenderW, pickerTitle, pickerTeamList,
      pickerMBg: (pickerGender === 'M' ? pickerActiveStyle : pickerInactiveStyle).bg,
      pickerMColor: (pickerGender === 'M' ? pickerActiveStyle : pickerInactiveStyle).color,
      pickerMBorder: (pickerGender === 'M' ? pickerActiveStyle : pickerInactiveStyle).border,
      pickerMShadow: (pickerGender === 'M' ? pickerActiveStyle : pickerInactiveStyle).shadow,
      pickerWBg: (pickerGender === 'W' ? pickerActiveStyle : pickerInactiveStyle).bg,
      pickerWColor: (pickerGender === 'W' ? pickerActiveStyle : pickerInactiveStyle).color,
      pickerWBorder: (pickerGender === 'W' ? pickerActiveStyle : pickerInactiveStyle).border,
      pickerWShadow: (pickerGender === 'W' ? pickerActiveStyle : pickerInactiveStyle).shadow,
    };
  }
}
