#!/usr/bin/env bash
# Build release APK with SUPABASE_URL and PUBLISHABLE_KEY from .env.
# Usage: ./build_apk_with_env.sh [flutter build apk args...]
# Output: build/app/outputs/flutter-apk/app-release.apk

set -e
ENV_FILE="${ENV_FILE:-.env}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Copy from README or create with SUPABASE_URL and PUBLISHABLE_KEY."
  exit 1
fi

SUPABASE_URL=""
PUBLISHABLE_KEY=""
while IFS= read -r line; do
  line="${line%%#*}"
  line="${line%"${line##*[! ]}"}"
  [[ -z "$line" ]] && continue
  if [[ "$line" == SUPABASE_URL=* ]]; then
    SUPABASE_URL="${line#SUPABASE_URL=}"
    SUPABASE_URL="${SUPABASE_URL%\"}"
    SUPABASE_URL="${SUPABASE_URL#\"}"
  elif [[ "$line" == PUBLISHABLE_KEY=* ]]; then
    PUBLISHABLE_KEY="${line#PUBLISHABLE_KEY=}"
    PUBLISHABLE_KEY="${PUBLISHABLE_KEY%\"}"
    PUBLISHABLE_KEY="${PUBLISHABLE_KEY#\"}"
  fi
done < "$ENV_FILE"

if [[ -z "$SUPABASE_URL" || -z "$PUBLISHABLE_KEY" ]]; then
  echo "SUPABASE_URL and PUBLISHABLE_KEY must be set in $ENV_FILE"
  exit 1
fi

exec flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=PUBLISHABLE_KEY="$PUBLISHABLE_KEY" \
  "$@"
