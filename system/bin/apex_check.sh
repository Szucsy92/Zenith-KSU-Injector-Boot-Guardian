#!/system/bin/sh
# APEX Selective Wipe Script
# Created by @szucsy92 & @A1X31

FILE="/data/local/tmp/boot_attempts"

# Do nothing if counter file is missing
[ ! -f $FILE ] && exit 0
VAL=$(cat $FILE)

# Trigger selective wipe only after the 2nd consecutive boot failure
if [ $VAL -gt 1 ]; then
    mount -o remount,rw /data
    
    # Cleaning only updated/active APEX modules and caches
    # This prevents the "Permission Manager not found" error
    rm -rf /data/apex/active/*
    rm -rf /data/apex/backup/*
    rm -rf /data/dalvik-cache/*
    rm -rf /data/resource-cache/*
    
    echo "Selective wipe performed at attempt $VAL" > /data/local/tmp/last_wipe_log
fi
