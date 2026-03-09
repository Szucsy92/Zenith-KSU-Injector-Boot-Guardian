#!/system/bin/sh
# APEX Selective Wipe Script
# Created by @szucsy92 & @A1X31

MODULE_DIR=$(cd "$(dirname "$0")/../.." && pwd)
CONFIG_FILE="$MODULE_DIR/config/zenith.conf"
FILE="/data/local/tmp/boot_attempts"
APEX_AUTO_HEAL_ENABLED=1
APEX_WIPE_TRIGGER=2

[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

case "$APEX_WIPE_TRIGGER" in
    ''|*[!0-9]*)
        APEX_WIPE_TRIGGER=2
        ;;
esac
[ "$APEX_WIPE_TRIGGER" -lt 1 ] 2>/dev/null && APEX_WIPE_TRIGGER=2

[ "$APEX_AUTO_HEAL_ENABLED" = "1" ] || exit 0

# Do nothing if counter file is missing
[ ! -f "$FILE" ] && exit 0
VAL=$(cat "$FILE" 2>/dev/null)
[ -z "$VAL" ] && VAL=0

# Trigger selective wipe only after configured consecutive boot failures.
if [ "$VAL" -ge "$APEX_WIPE_TRIGGER" ]; then
    mount -o remount,rw /data >/dev/null 2>&1 || true
    
    # Cleaning only updated/active APEX modules and caches
    # This prevents the "Permission Manager not found" error
    rm -rf /data/apex/active/*
    rm -rf /data/apex/backup/*
    rm -rf /data/dalvik-cache/*
    rm -rf /data/resource-cache/*
    
    echo "Selective wipe performed at attempt $VAL (trigger=$APEX_WIPE_TRIGGER)" >/data/local/tmp/last_wipe_log
fi
