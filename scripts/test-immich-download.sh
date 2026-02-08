#!/usr/bin/env bash
# Проверка запросов скачивания ассета для Immich 2.5.5.
# Данные берутся из .env в корне проекта (IMMICH_URL, IMMICH_API_KEY, ASSET_ID).
# Запуск из корня: bash scripts/test-immich-download.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -f "$ROOT/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  . "$ROOT/.env"
  set +a
fi

BASE="${IMMICH_URL:-$IMMICH_BASE}"
BASE="${BASE:-$IMMICH_SERVER_URL}"
BASE="${BASE:-http://192.168.100.118:2283}"
KEY="${IMMICH_API_KEY:-$IMMICH_KEY}"
AID="${ASSET_ID:-075685cb-d4f0-4090-956c-bd8774ecf28f}"
BASE="${BASE%/}"

if [ -z "$KEY" ]; then
  echo "Error: IMMICH_API_KEY (или IMMICH_KEY) не задан. Добавь в .env или export."
  exit 1
fi

echo "=== Immich 2.5.5 — тест download/view ==="
echo "Base: $BASE  Asset: $AID"
echo ""

try() {
  local name="$1"
  local url="$2"
  echo "--- $name ---"
  echo "GET $url"
  code=$(curl -s -o /tmp/immich_test_body -w '%{http_code}' -H "x-api-key: $KEY" "$url")
  echo "HTTP $code"
  if [ "$code" = "200" ]; then
    size=$(wc -c < /tmp/immich_test_body)
    echo "OK, body: $size bytes"
    file /tmp/immich_test_body 2>/dev/null || true
  else
    echo "Response:"
    head -c 600 /tmp/immich_test_body | cat -v
    echo ""
  fi
  echo ""
}

try "1) /api/assets/ID/original (v2 API)"   "$BASE/api/assets/$AID/original"
try "2) /api/assets/ID/download"           "$BASE/api/assets/$AID/download"
try "3) /api/asset/ID/download"            "$BASE/api/asset/$AID/download"
try "4) /api/asset/ID?size=fullsize"       "$BASE/api/asset/$AID?size=fullsize"

echo "Готово. Если один из запросов вернул 200 — этот путь подходит для приложения."
