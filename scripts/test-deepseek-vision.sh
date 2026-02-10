#!/usr/bin/env bash
# Test DeepSeek API: 1) vision endpoint, 2) chat with image (base64).
# Usage: from project root, run:
#   source .env 2>/dev/null; ./scripts/test-deepseek-vision.sh
# or:
#   export DEEPSEEK_API_KEY=sk-your-key; ./scripts/test-deepseek-vision.sh

set -e
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && source .env && set +a
KEY="${DEEPSEEK_API_KEY:-}"
if [ -z "$KEY" ]; then
  echo "Set DEEPSEEK_API_KEY (e.g. add to .env or: export DEEPSEEK_API_KEY=sk-...)"
  exit 1
fi

# 1x1 PNG in base64
IMG_B64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
PROMPT="Опиши это изображение в одном предложении."

echo "=== 1) Vision endpoint POST /v1/vision ==="
curl -s -w "\nHTTP %{http_code}\n" \
  -X POST "https://api.deepseek.com/v1/vision" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"deepseek-vision\",\"image\":\"$IMG_B64\",\"prompt\":\"$PROMPT\"}"
echo ""

echo "=== 2) Chat completions with type image + base64 (no image_url) ==="
curl -s -w "\nHTTP %{http_code}\n" \
  -X POST "https://api.deepseek.com/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"deepseek-chat\",
    \"messages\": [
      {\"role\": \"user\", \"content\": [
        {\"type\": \"image\", \"source\": {\"type\": \"base64\", \"media_type\": \"image/png\", \"data\": \"$IMG_B64\"}},
        {\"type\": \"text\", \"text\": \"$PROMPT\"}
      ]}
    ],
    \"max_tokens\": 100
  }"
echo ""

echo "=== 3) Text-only (sanity check) ==="
curl -s -w "\nHTTP %{http_code}\n" \
  -X POST "https://api.deepseek.com/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"Say OK"}],"max_tokens":10}'
echo ""
