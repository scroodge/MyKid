#!/usr/bin/env bash
# Test Managed AI from Mac: call ai-proxy Edge Function with JWT or email+password.
# Usage:
#   source .env 2>/dev/null; ./scripts/test-ai-proxy.sh --jwt "YOUR_ACCESS_TOKEN"
#   source .env 2>/dev/null; ./scripts/test-ai-proxy.sh --email "you@example.com" --password "your-password"
# Requires: SUPABASE_URL, PUBLISHABLE_KEY (or SUPABASE_ANON_KEY) in .env

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."
[ -f .env ] && set -a && source .env 2>/dev/null && set +a

SUPABASE_URL="${SUPABASE_URL:-}"
ANON_KEY="${PUBLISHABLE_KEY:-${SUPABASE_ANON_KEY:-}}"
JWT=""
EMAIL=""
PASSWORD=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --jwt) JWT="$2"; shift 2 ;;
    --email) EMAIL="$2"; shift 2 ;;
    --password) PASSWORD="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ -z "$SUPABASE_URL" ] || [ -z "$ANON_KEY" ]; then
  echo "Set SUPABASE_URL and PUBLISHABLE_KEY (or SUPABASE_ANON_KEY) in .env"
  exit 1
fi

if [ -z "$JWT" ]; then
  if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
    echo "Use: --jwt TOKEN  or  --email EMAIL --password PASSWORD"
    exit 1
  fi
  echo "Signing in..."
  RESP=$(curl -s -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON_KEY" -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
  JWT=$(printf '%s' "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('access_token',''))" 2>/dev/null)
  if [ -z "$JWT" ]; then
    echo "Login failed: $RESP"
    exit 1
  fi
  echo "Got JWT"
fi

URL="${SUPABASE_URL%/}/functions/v1/ai-proxy"
BODY='{"model":"gpt-4o","messages":[{"role":"user","content":"Say OK"}],"max_tokens":10}'

echo "=== POST ai-proxy (text-only) ==="
HTTP=$(curl -s -w "\n%{http_code}" -X POST "$URL" \
  -H "Authorization: Bearer $JWT" -H "apikey: $ANON_KEY" -H "Content-Type: application/json" -d "$BODY")
CODE=$(echo "$HTTP" | tail -n 1)
BODY_ONLY=$(echo "$HTTP" | sed '$d')
echo "HTTP $CODE"
echo "$BODY_ONLY"
echo ""
echo "Logs: Supabase Dashboard -> Edge Functions -> ai-proxy -> Logs"
echo "Contabo: ssh then journalctl -u ai-gateway -f"
