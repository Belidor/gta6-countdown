#!/usr/bin/env bash
# Build the GTA VI countdown watch face.
#   ./build.sh             .prg for Forerunner 965  -> bin/GTA6Countdown-fr965.prg
#   ./build.sh fenix7      .prg for another device  -> bin/GTA6Countdown-fenix7.prg
#   ./build.sh export      .iq package for every device in manifest.xml
#   ./build.sh products    refresh the device list in manifest.xml from SDK Manager downloads
#   ./build.sh newkey      make a new signing key, only for a brand-new app (never overwrites)
#
# Signing key: keys/developer_key.der, or the file in GARMIN_KEY, for example
#   GARMIN_KEY=~/.config/garmin/developer_key.der ./build.sh export
# The script never makes a key by itself. Every Connect IQ Store update must be
# signed with the original key, so a missing key stops the build.
set -euo pipefail

NAME=GTA6Countdown

# A relative GARMIN_KEY is relative to the caller's folder, so resolve it before the cd.
if [ -n "${GARMIN_KEY:-}" ]; then
    case "$GARMIN_KEY" in
        /*) KEY="$GARMIN_KEY" ;;
        *)  KEY="$PWD/$GARMIN_KEY" ;;
    esac
    KEY_FROM="from GARMIN_KEY"
else
    KEY=keys/developer_key.der
    KEY_FROM="default path"
fi
cd "$(dirname "$0")"

CIQ="$HOME/Library/Application Support/Garmin/ConnectIQ"
TARGET="${1:-fr965}"

abs() { case "$1" in /*) echo "$1" ;; *) echo "$PWD/$1" ;; esac; }

newkey() {
    local pem="${KEY%.der}.pem"
    local dir
    dir="$(dirname "$KEY")"
    local f
    for f in "$KEY" "$pem"; do
        if [ -e "$f" ]; then
            echo "error: a signing key file already exists: $(abs "$f")" >&2
        fi
    done
    if [ -e "$KEY" ] || [ -e "$pem" ]; then
        echo "./build.sh newkey never overwrites a key. A new key means a new Connect IQ Store app." >&2
        exit 1
    fi
    (
        umask 077
        mkdir -p "$dir"
        tmp="$(mktemp -d "$dir/.newkey.XXXXXX")"
        trap 'rm -rf "$tmp"' EXIT
        openssl genrsa -out "$tmp/key.pem" 4096
        openssl pkcs8 -topk8 -inform PEM -outform DER -in "$tmp/key.pem" -out "$tmp/key.der" -nocrypt
        chmod 600 "$tmp/key.pem" "$tmp/key.der"
        mv "$tmp/key.pem" "$pem"
        mv "$tmp/key.der" "$KEY"
    )
    echo "New signing key: $(abs "$KEY") and $(abs "$pem") (mode 600)."
    echo "Back up both files now to an encrypted place. Every store update needs this key."
}

require_key() {
    if [ -f "$KEY" ] && [ -r "$KEY" ]; then
        return
    fi
    {
        echo "error: signing key not found or not readable: $(abs "$KEY") ($KEY_FROM)"
        echo
        echo "build.sh does not make a new key by itself: every Connect IQ Store update"
        echo "must be signed with the original key. Do one of these:"
        echo "  1. Restore developer_key.der and developer_key.pem from your private backup"
        echo "     to $(dirname "$(abs "$KEY")")/"
        echo "  2. Point GARMIN_KEY to a key outside the repo, for example:"
        echo "       GARMIN_KEY=~/.config/garmin/developer_key.der ./build.sh $TARGET"
        echo "  3. Only for a brand-new app that is not in the store yet: ./build.sh newkey"
    } >&2
    exit 1
}

case "$TARGET" in
    newkey)
        newkey
        exit 0
        ;;
    products)
        python3 -I tools/update_products.py "$CIQ/Devices" manifest.xml
        exit 0
        ;;
esac

require_key
SDK="$(cat "$CIQ/current-sdk.cfg")"
mkdir -p bin

case "$TARGET" in
    export) "$SDK/bin/monkeyc" -f monkey.jungle -e -r -w -y "$KEY" -o "bin/$NAME.iq" ;;
    *)      "$SDK/bin/monkeyc" -f monkey.jungle -d "$TARGET" -r -w -y "$KEY" -o "bin/$NAME-$TARGET.prg" ;;
esac
