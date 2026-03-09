#!/system/bin/sh
# Boot Attempt Counter & Guardian Logic
# Created by @szucsy92 & @A1X31

MODULE_DIR=$(cd "$(dirname "$0")/../.." && pwd)
CONFIG_FILE="$MODULE_DIR/config/zenith.conf"
FILE="/data/local/tmp/boot_attempts"
BOOT_GUARDIAN_ENABLED=1
BOOT_FAIL_LIMIT=5

[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

case "$BOOT_FAIL_LIMIT" in
    ''|*[!0-9]*)
        BOOT_FAIL_LIMIT=5
        ;;
esac
[ "$BOOT_FAIL_LIMIT" -lt 1 ] 2>/dev/null && BOOT_FAIL_LIMIT=5

[ "$BOOT_GUARDIAN_ENABLED" = "1" ] || exit 0

mount -o remount,rw /data >/dev/null 2>&1 || true

# Initialize the counter file if it doesn't exist
[ ! -f "$FILE" ] && echo 0 > "$FILE"

VAL=$(cat "$FILE" 2>/dev/null)
[ -z "$VAL" ] && VAL=0
NEW_VAL=$((VAL + 1))
echo "$NEW_VAL" >"$FILE"

# Limit reached: Reboot to recovery after configured failed attempts.
if [ "$NEW_VAL" -ge "$BOOT_FAIL_LIMIT" ]; then
    echo 0 >"$FILE"
    reboot recovery
fi
