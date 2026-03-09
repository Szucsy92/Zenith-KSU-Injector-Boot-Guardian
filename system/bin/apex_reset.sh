#!/system/bin/sh
# Stability Success Reset
# Created by @szucsy92 & @A1X31

MODULE_DIR=$(cd "$(dirname "$0")/../.." && pwd)
CONFIG_FILE="$MODULE_DIR/config/zenith.conf"
FILE="/data/local/tmp/boot_attempts"
RESET_DELAY_SEC=60

[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"
case "$RESET_DELAY_SEC" in
    ''|*[!0-9]*)
        RESET_DELAY_SEC=60
        ;;
esac
[ "$RESET_DELAY_SEC" -lt 1 ] 2>/dev/null && RESET_DELAY_SEC=60

# Wait 60 seconds to ensure the system services (SystemServer, PM) are stable
sleep "$RESET_DELAY_SEC"

# If the system reached this point without crashing, reset the failure counter
if [ -f "$FILE" ]; then
    echo 0 >"$FILE"
fi
