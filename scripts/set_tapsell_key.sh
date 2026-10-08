#!/bin/bash
# Bake the Tapsell Mediation app key into the gradle build template.
# usage: bash scripts/set_tapsell_key.sh "<APP_KEY>"
# The key lands in android/build/build.gradle as the TapsellMediationAppKey
# manifest placeholder, which the Tapsell SDK manifest resolves into
# meta-data ir.tapsell.mediation.APPLICATION_KEY.
set -euo pipefail
KEY="${1:?usage: set_tapsell_key.sh <APP_KEY>}"
GRADLE_FILE="$(dirname "$0")/../android/build/build.gradle"
if [ ! -f "$GRADLE_FILE" ]; then
    echo "ERROR: $GRADLE_FILE not found (install the android build template first)" >&2
    exit 1
fi
if grep -q "PLACEHOLDER_TAPSELL_KEY" "$GRADLE_FILE"; then
    sed -i "s|PLACEHOLDER_TAPSELL_KEY|${KEY}|g" "$GRADLE_FILE"
    echo "Tapsell key set: ${KEY:0:8}..."
else
    if grep -q "TapsellMediationAppKey" "$GRADLE_FILE"; then
        echo "Key already baked: $(grep -o 'TapsellMediationAppKey: \"[^\"]*\"' "$GRADLE_FILE")"
    else
        echo "ERROR: placeholder marker missing from build.gradle" >&2
        exit 1
    fi
fi
