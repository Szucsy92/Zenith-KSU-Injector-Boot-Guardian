#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_ZIP="$ROOT_DIR/Zenith_KSU.zip"
TEMP_DIR="$(mktemp -d)"
MODULE_DIR="$TEMP_DIR/module"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

mkdir -p "$MODULE_DIR"

cp -a \
    "$ROOT_DIR/module.prop" \
    "$ROOT_DIR/post-fs-data.sh" \
    "$ROOT_DIR/boot-completed.sh" \
    "$ROOT_DIR/action.sh" \
    "$ROOT_DIR/customize.sh" \
    "$ROOT_DIR/system" \
    "$ROOT_DIR/webroot" \
    "$ROOT_DIR/README.md" \
    "$ROOT_DIR/LICENSE" \
    "$MODULE_DIR/"

if [ -f "$OUTPUT_ZIP" ]; then
    rm -f "$OUTPUT_ZIP"
fi

(
    cd "$MODULE_DIR"
    zip -r9 "$OUTPUT_ZIP" . -x '*.DS_Store' >/dev/null
)

echo "Created: $OUTPUT_ZIP"
