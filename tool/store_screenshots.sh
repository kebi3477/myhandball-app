#!/usr/bin/env bash
# 스토어 스크린샷을 시뮬레이터·에뮬레이터에서 찍는다.
#
#   tool/store_screenshots.sh <기기 ID> <출력 폴더> [API_BASE_URL]
#   tool/store_screenshots.sh 7A3BEC3E-... ../screenshot/ios-phone http://192.168.55.4:8080
#   tool/store_screenshots.sh emulator-5554 ../screenshot/android-phone http://192.168.55.4:8080
#
# 기기 ID가 `emulator-`로 시작하면 안드로이드, 아니면 iOS 시뮬레이터 UDID다.
# integration_test/store_screenshots_test.dart가 화면을 옮기며 `MH_SHOT <이름>`을
# 찍으면, 여기서 그 순간의 화면을 PNG로 저장한다. 상태바는 9:41·배터리 가득으로
# 고정한다. 같은 공유기에서는 도메인으로 서버에 못 붙으므로(CLAUDE.md "서버 상태")
# 집 안 입구(http://<미니 PC IP>:8080)를 넘긴다 — 디버그 빌드라 평문이 된다.
set -euo pipefail

device=${1:?기기 ID}
out=${2:?출력 폴더}
api=${3:-https://myhandball.lab241.com}

mkdir -p "$out"
log=$(mktemp)
trap 'rm -f "$log"' EXIT

if [[ $device == emulator-* ]]; then
  adb -s "$device" wait-for-device
  # 데모 모드: 시계·배터리·신호를 고정하고 알림 아이콘을 숨긴다
  adb -s "$device" shell settings put global sysui_demo_allowed 1
  demo() { adb -s "$device" shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null; }
  demo enter
  demo clock -e hhmm 0941
  demo battery -e level 100 -e plugged false
  demo network -e wifi show -e level 4 -e mobile show -e level 4 -e datatype none
  demo notifications -e visible false
  adb -s "$device" uninstall com.myhandball.app >/dev/null 2>&1 || true
  capture() { adb -s "$device" exec-out screencap -p >"$1"; }
  cleanup() { demo exit; }
else
  xcrun simctl boot "$device" 2>/dev/null || true
  xcrun simctl bootstatus "$device" -b >/dev/null
  xcrun simctl status_bar "$device" override --time 9:41 --batteryState charged \
    --batteryLevel 100 --wifiBars 3 --cellularMode active --cellularBars 4 \
    --dataNetwork wifi
  # 온보딩을 다시 거치지 않게 앱 데이터를 지우고 시작한다.
  xcrun simctl uninstall "$device" com.kebi.myhandball-ios 2>/dev/null || true
  capture() { xcrun simctl io "$device" screenshot "$1" >/dev/null 2>&1; }
  cleanup() { xcrun simctl status_bar "$device" clear; }
fi

flutter test integration_test/store_screenshots_test.dart -d "$device" \
  --dart-define=API_BASE_URL="$api" \
  --dart-define=MH_SKIP_ONBOARDING=true \
  --dart-define=MH_ADS=false >"$log" 2>&1 &
runner=$!

shot=0
while kill -0 "$runner" 2>/dev/null; do
  while read -r name; do
    capture "$out/$name.png"
    echo "찍음: $out/$name.png"
    shot=$((shot + 1))
  done < <(grep -o 'MH_SHOT [0-9a-z-]*' "$log" | awk '{print $2}' | tail -n +$((shot + 1)))
  sleep 0.5
done

wait "$runner" || { tail -30 "$log"; cleanup; exit 1; }
cleanup
echo "완료: $shot장 → $out"
