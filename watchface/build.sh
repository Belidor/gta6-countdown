#!/usr/bin/env bash
# Build the GTA VI countdown watch face.
#   ./build.sh             .prg for Forerunner 965  -> bin/GTA6Countdown-fr965.prg
#   ./build.sh fenix7      .prg for another device  -> bin/GTA6Countdown-fenix7.prg
#   ./build.sh export      .iq package for every device in manifest.xml
#   ./build.sh products    refresh the device list in manifest.xml from SDK Manager downloads
set -euo pipefail
cd "$(dirname "$0")"

CIQ="$HOME/Library/Application Support/Garmin/ConnectIQ"
SDK="$(cat "$CIQ/current-sdk.cfg")"
KEY=keys/developer_key.der

if [ ! -f "$KEY" ]; then
    mkdir -p keys
    openssl genrsa -out keys/developer_key.pem 4096
    openssl pkcs8 -topk8 -inform PEM -outform DER -in keys/developer_key.pem -out "$KEY" -nocrypt
fi
mkdir -p bin

TARGET="${1:-fr965}"
case "$TARGET" in
    products) python3 -I tools/update_products.py "$CIQ/Devices" manifest.xml ;;
    export)   "$SDK/bin/monkeyc" -f monkey.jungle -e -r -w -y "$KEY" -o bin/GTA6Countdown.iq ;;
    *)        "$SDK/bin/monkeyc" -f monkey.jungle -d "$TARGET" -r -w -y "$KEY" -o "bin/GTA6Countdown-$TARGET.prg" ;;
esac
