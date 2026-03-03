#!/system/bin/sh
# Boot Attempt Counter & Guardian Logic
# Created by @szucsy92 & @A1X31

FILE="/data/local/tmp/boot_attempts"
mount -o remount,rw /data

# Initialize the counter file if it doesn't exist
[ ! -f $FILE ] && echo 0 > $FILE

VAL=$(cat $FILE)
NEW_VAL=$((VAL + 1))
echo $NEW_VAL > $FILE

# Limit reached: Reboot to recovery on the 5th attempt if no success reset occurred
if [ $NEW_VAL -gt 4 ]; then
    echo 0 > $FILE
    reboot recovery
fi
