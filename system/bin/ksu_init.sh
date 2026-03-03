#!/system/bin/sh
# KSU Injector Script
# Created by @szucsy92 & @A1X31
# Log (if something gets wrong)
LOG="/data/local/tmp/ksu_init.log"
exec > $LOG 2>&1

echo "--- Start the script: $(date) ---"

SRC="/system/usr/share/ksu_modules/adb"
DEST="/data/adb"

# Waiting forthepartition(max 30 s)
I=0
while [ ! -d "/data/adb" ] && [ $I -lt 15 ]; do
    echo "Waiting forthe /data/adb folder... ($I)"
    sleep 2
    I=$((I+1))
done

if [ ! -d "/data/adb" ]; then
    echo "ERROR:  /data/adb not existing!"
    exit 1
fi

# Folder creating, if it's not available
mkdir -p "$DEST"
echo "Folder created: $DEST"

# Copying cycles
for mod in "$SRC"/*; do
    if [ -d "$mod" ]; then
        name=$(basename "$mod")
        echo "Copyingmodules: $name"
        
        cp -afP "$mod" "$DEST/"
        chown -R root:root "$DEST/$name"
        
        # KSU activation files
        touch "$DEST/$name/update"
        rm -f "$DEST/$name/disable"
        rm -f "$DEST/$name/skip_mount"
        
        echo "$name Done."
    fi
done

echo "--- Finished thescript ---"