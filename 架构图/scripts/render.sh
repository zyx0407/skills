#!/usr/bin/env bash
# 架构图出图（macOS / Linux）
# 用法：./render.sh <index.html> [out.png] [宽] [高] [倍数]
# 例：  ./render.sh ./index.html
#       ./render.sh ./index.html ./_shots/a.png 1400 700 2
set -euo pipefail

HTML="${1:-}"
OUT="${2:-}"
W="${3:-1400}"
H="${4:-760}"
SCALE="${5:-1}"

if [ -z "$HTML" ]; then
  echo "用法: render.sh <index.html> [out.png] [宽] [高] [倍数]" >&2
  exit 2
fi
HTML="$(cd "$(dirname "$HTML")" && pwd)/$(basename "$HTML")"
if [ -z "$OUT" ]; then
  OUT="$(dirname "$HTML")/_shots/$(basename "$HTML" .html).png"
fi
mkdir -p "$(dirname "$OUT")"

BROWSER=""
for c in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
  "$(command -v google-chrome 2>/dev/null || true)" \
  "$(command -v google-chrome-stable 2>/dev/null || true)" \
  "$(command -v chromium 2>/dev/null || true)" \
  "$(command -v chromium-browser 2>/dev/null || true)" \
  "$(command -v microsoft-edge 2>/dev/null || true)"; do
  if [ -n "$c" ] && [ -x "$c" ]; then BROWSER="$c"; break; fi
done
if [ -z "$BROWSER" ]; then
  echo "没找到 Chrome / Edge / Chromium；请安装或用 Node 版 render.mjs" >&2
  exit 1
fi

UD="$(mktemp -d)"
trap 'rm -rf "$UD"' EXIT
rm -f "$OUT"
"$BROWSER" --headless=new --disable-gpu --hide-scrollbars --no-sandbox \
  --force-device-scale-factor="$SCALE" --user-data-dir="$UD" \
  --virtual-time-budget=3000 --window-size="$W,$H" \
  --screenshot="$OUT" "file://$HTML" >/dev/null 2>&1 || true

if [ -f "$OUT" ]; then
  echo "已出图：$OUT"
else
  echo "出图失败：$OUT" >&2
  exit 1
fi
