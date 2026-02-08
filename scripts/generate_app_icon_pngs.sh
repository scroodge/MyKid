#!/usr/bin/env bash
# Regenerate app icon PNGs from SVG sources (app_icon_ios.svg, adaptive_fg.svg, adaptive_bg.svg).
# Requires ImageMagick: brew install imagemagick
# Then run: dart run flutter_launcher_icons

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_DIR="$DIR/assets/brand/app_icon"
cd "$ICON_DIR"

if command -v magick &>/dev/null; then
  CONVERT="magick"
elif command -v convert &>/dev/null; then
  CONVERT="convert"
else
  echo "Need ImageMagick. Install: brew install imagemagick"
  exit 1
fi

"$CONVERT" -background none -resize 1024x1024 app_icon_ios.svg app_icon.png
"$CONVERT" -background none -resize 1024x1024 adaptive_fg.svg adaptive_foreground.png
"$CONVERT" -background none -resize 1024x1024 adaptive_bg.svg adaptive_background.png
echo "Generated app_icon.png, adaptive_foreground.png, adaptive_background.png"
echo "Run: dart run flutter_launcher_icons"
