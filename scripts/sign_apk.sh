#!/bin/bash
# Sign an unsigned (but zipaligned) APK with the RazNameh release keystore.
# usage: BUILD_TOOLS=<bt> KEYSTORE=<ks> bash sign_apk.sh in.apk out.apk
set -euo pipefail
IN="$1"; OUT="$2"
KS="${KEYSTORE:?need KEYSTORE}"
BT="${BUILD_TOOLS:?need BUILD_TOOLS}"

if [ "$IN" != "$OUT" ]; then
    cp -f "$IN" "$OUT"
fi
"${BT}/zipalign" -f -p 4 "$OUT" "$OUT.aligned"
"${BT}/apksigner" sign \
    --ks "$KS" \
    --ks-key-alias raznameh \
    --ks-pass pass:raznameh2026 \
    --key-pass pass:raznameh2026 \
    --out "$OUT.signed" "$OUT.aligned"
mv -f "$OUT.signed" "$OUT"
rm -f "$OUT.aligned"
"${BT}/apksigner" verify --print-certs "$OUT" | head -4
echo "SIGNED OK: $OUT"
