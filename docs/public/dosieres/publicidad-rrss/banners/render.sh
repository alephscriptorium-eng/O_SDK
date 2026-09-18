#!/usr/bin/env bash
# Regenera los HTML y los PNG (1200 px de ancho) con Edge/Chrome headless. Uso: bash render.sh
set -euo pipefail
cd "$(dirname "$0")"
python make_banners.py
BROWSER="${BROWSER:-/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe}"
mkdir -p png
for n in 01-ficha:1062 02-delta:895 03-tres-puertas:960 04-call4obras:962 05-terminal:905; do
  f="banner-${n%%:*}"; h="${n##*:}"
  "$BROWSER" --headless=new --disable-gpu --hide-scrollbars --user-data-dir="${TMPDIR:-/tmp}/banner-profile" \
    --window-size=1200,"$h" --screenshot="$(pwd -W 2>/dev/null || pwd)/png/$f.png" "file:///$(pwd -W 2>/dev/null || pwd)/$f.html" >/dev/null 2>&1
  echo "png/$f.png"
done
