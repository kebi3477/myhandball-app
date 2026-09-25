#!/bin/bash
# android/key.properties의 업로드 키가 쓸 수 있는 상태인지 확인한다.
#
# 저장소 비밀번호와 키 비밀번호는 **다를 수 있고**, 저장소 쪽만 맞아도
# 빌드는 서명 단계에서 깨진다. 그래서 둘을 따로 본다.
#
# 비밀번호는 출력하지 않는다. 지문은 공개 정보라 찍는다 — Play Console의
# `앱 무결성 > 업로드 키 인증서` 지문과 대조하는 데 쓴다.
set -u

KEYTOOL="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
PROPS="$(dirname "$0")/../android/key.properties"

[ -f "$PROPS" ] || { echo "✗ android/key.properties가 없습니다"; exit 1; }

# **주석이 아니라 값만 본다.** 안내 주석에도 `<...>`가 들어 있어서
# 파일 전체를 grep 하면 다 채워 넣어도 "그대로"라고 잘못 말한다.
get() { grep "^$1=" "$PROPS" | head -1 | cut -d= -f2-; }
STORE_FILE=$(get storeFile); STORE_PW=$(get storePassword)
ALIAS=$(get keyAlias);      KEY_PW=$(get keyPassword)

for v in "$STORE_FILE" "$STORE_PW" "$ALIAS" "$KEY_PW"; do
  [ -n "$v" ] || { echo "✗ key.properties에 빠진 항목이 있습니다"; exit 1; }
  case "$v" in *"<"*) echo "✗ 비밀번호 자리(<...>)가 그대로입니다"; exit 1;; esac
done

[ -f "$STORE_FILE" ] || { echo "✗ 키스토어가 없습니다: $STORE_FILE"; exit 1; }

if ! "$KEYTOOL" -list -keystore "$STORE_FILE" -storepass "$STORE_PW" >/dev/null 2>&1; then
  echo "✗ 저장소 비밀번호(storePassword)가 틀립니다"; exit 1
fi
echo "✓ 저장소 비밀번호 맞음"

# -certreq는 개인키를 실제로 열어야 해서 키 비밀번호를 검증한다. 키스토어를
# 건드리지 않고 표준출력으로만 내보낸다.
if ! "$KEYTOOL" -certreq -alias "$ALIAS" -keystore "$STORE_FILE" \
      -storepass "$STORE_PW" -keypass "$KEY_PW" >/dev/null 2>&1; then
  echo "✗ 키 비밀번호(keyPassword)가 틀리거나 별칭('$ALIAS')이 없습니다"; exit 1
fi
echo "✓ 키 비밀번호 맞음 · 별칭 '$ALIAS'"

echo
echo "--- Play Console의 '업로드 키 인증서' 지문과 대조하세요 ---"
"$KEYTOOL" -list -v -alias "$ALIAS" -keystore "$STORE_FILE" -storepass "$STORE_PW" \
  | grep -E "소유자|Owner|유효기간|유효 기간|Valid|SHA1|SHA-1|SHA256|SHA-256"
