#!/usr/bin/env bash
# Render the README banners: .github/readme/src/<name>.html -> .github/readme/<name>.png
#   ./render.sh               all banners
#   ./render.sh hero          one banner
# Needs Google Chrome and ffmpeg. Chrome renders at 2x, ffmpeg scales down to 1x
# so the text stays crisp. A PNG over 1 MB (the GitHub social preview limit)
# gets a 256-colour palette.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
OUT="$(dirname "$SRC")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
MAX_BYTES=1000000

# name width height
BANNERS="hero 1280 640
three-ways 1280 520
install 1280 220
watches 1280 420"

TMP="$(mktemp -d)"
trap 'pkill -f "user-data-dir=$TMP" 2>/dev/null || true; rm -rf "$TMP"' EXIT

render() {
    local name=$1 w=$2 h=$3
    local shot="$TMP/$name@2x.png" png="$OUT/$name.png"

    # Headless Chrome can hang after it writes the file: start it in the background,
    # wait for the file, then stop it.
    "$CHROME" --headless=new --hide-scrollbars --no-first-run \
        --user-data-dir="$TMP/profile-$name" --virtual-time-budget=6000 \
        --force-device-scale-factor=2 --window-size="$w,$h" \
        --screenshot="$shot" "file://$SRC/$name.html" >/dev/null 2>&1 &
    local i
    for i in $(seq 1 120); do
        [ -s "$shot" ] && break
        sleep 0.25
    done
    sleep 0.5
    pkill -f "user-data-dir=$TMP/profile-$name" 2>/dev/null || true
    [ -s "$shot" ] || { echo "Chrome did not render $name" >&2; return 1; }

    ffmpeg -v error -y -i "$shot" -vf "scale=$w:$h:flags=lanczos" -pix_fmt rgb24 "$png"
    if [ "$(stat -f%z "$png")" -gt "$MAX_BYTES" ]; then
        ffmpeg -v error -y -i "$shot" -filter_complex \
            "scale=$w:$h:flags=lanczos,split[a][b];[a]palettegen=max_colors=256:stats_mode=full[p];[b][p]paletteuse=dither=sierra2_4a" \
            "$png"
    fi
    echo "$png  $(stat -f%z "$png") bytes"
}

echo "$BANNERS" | while read -r name w h; do
    if [ $# -eq 0 ] || [[ " $* " == *" $name "* ]]; then
        render "$name" "$w" "$h"
    fi
done
