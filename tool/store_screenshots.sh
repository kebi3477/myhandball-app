#!/usr/bin/env bash
# 스토어 스크린샷을 시뮬레이터에서 찍는다.
#
#   tool/store_screenshots.sh <시뮬레이터 UDID> <출력 폴더> [API_BASE_URL]
#   tool/store_screenshots.sh 7A3BEC3E-... ../screenshot/ios-phone http://192.168.55.4:8080
#
# integration_test/store_screenshots_test.dart가 화면을 옮기며 `MH_SHOT <이름>`을
# 찍으면, 여기서 그 순간의 시뮬레이터 화면을 PNG로 저장한다. 상태바는 9:41·배터리
# 가득으로 고정한다. 같은 공유기에서는 도메인으로 서버에 못 붙으므로(CLAUDE.md
# "서버 상태") 집 안 입구(http://<미니 PC IP>:8080)를 넘긴다 — 디버그 빌드라 평문이 된다.
set -euo pipefail

udid=${1:?시뮬레이터 UDID}
out=${2:?출력 폴더}
api=${3:-https://myhandball.lab241.com}

mkdir -p "$out"
log=$(mktemp)
trap 'rm -f "$log"' EXIT

xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged \
  --batteryLevel 100 --wifiBars 3 --cellularMode active --cellularBars 4 \
  --dataNetwork wifi

# 온보딩을 다시 거치지 않게 앱 데이터를 지우고 시작한다.
xcrun simctl uninstall "$udid" com.kebi.myhandball-ios 2>/dev/null || true

flutter test integration_test/store_screenshots_test.dart -d "$udid" \
  --dart-define=API_BASE_URL="$api" \
  --dart-define=MH_SKIP_ONBOARDING=true \
  --dart-define=MH_ADS=false >"$log" 2>&1 &
runner=$!

shot=0
while kill -0 "$runner" 2>/dev/null; do
  while read -r name; do
    xcrun simctl io "$udid" screenshot "$out/$name.png" >/dev/null 2>&1
    echo "찍음: $out/$name.png"
    shot=$((shot + 1))
  done < <(grep -o 'MH_SHOT [0-9a-z-]*' "$log" | awk '{print $2}' | tail -n +$((shot + 1)))
  sleep 0.5
done

wait "$runner" || { tail -30 "$log"; exit 1; }
xcrun simctl status_bar "$udid" clear
echo "완료: $shot장 → $out"
