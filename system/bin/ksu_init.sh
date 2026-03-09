#!/system/bin/sh
# KSU Injector Script
# Created by @szucsy92 & @A1X31

LOG="/data/local/tmp/ksu_init.log"
exec >"$LOG" 2>&1

MODULE_DIR=$(cd "$(dirname "$0")/../.." && pwd)
CONFIG_FILE="$MODULE_DIR/config/zenith.conf"
SRC_PRIMARY="/system/usr/share/ksu_modules/adb"
SRC_ALT="/system/system/usr/share/ksu_modules/adb"
SRC="$SRC_PRIMARY"
DEST="/data/adb"
MAX_TRIES=15
SLEEP_SEC=2
AUTO_INJECT_ON_BOOT=1

[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

echo "--- KSU injector start: $(date '+%Y-%m-%d %H:%M:%S') ---"

if [ "$AUTO_INJECT_ON_BOOT" != "1" ]; then
    echo "Auto inject on boot disabled by config."
    exit 0
fi

if [ -d "$SRC_PRIMARY" ]; then
    SRC="$SRC_PRIMARY"
elif [ -d "$SRC_ALT" ]; then
    SRC="$SRC_ALT"
fi

i=0
while [ ! -d "$DEST" ] && [ "$i" -lt "$MAX_TRIES" ]; do
    echo "Waiting for $DEST... (attempt $((i + 1))/$MAX_TRIES)"
    sleep "$SLEEP_SEC"
    i=$((i + 1))
done

if [ ! -d "$DEST" ]; then
    echo "ERROR: $DEST does not exist."
    exit 1
fi

if [ ! -d "$SRC" ]; then
    echo "No system snapshot found at $SRC_PRIMARY or $SRC_ALT. Skipping restore."
    exit 0
fi

mkdir -p "$DEST"
echo "Destination ready: $DEST"

for mod in "$SRC"/*; do
    [ -d "$mod" ] || continue
    name=$(basename "$mod")
    echo "Injecting module: $name"

    cp -afP "$mod" "$DEST/" || {
        echo "ERROR: failed to copy $name."
        continue
    }

    chown -R root:root "$DEST/$name"

    # Keep copied module active for KernelSU.
    touch "$DEST/$name/update"
    rm -f "$DEST/$name/disable"
    rm -f "$DEST/$name/skip_mount"

    echo "Done: $name"
done

echo "--- KSU injector finished ---"
