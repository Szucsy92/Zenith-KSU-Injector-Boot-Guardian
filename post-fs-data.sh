#!/system/bin/sh

MODDIR=${0%/*}
LOG="/data/local/tmp/zenith_boot.log"

mkdir -p /data/local/tmp 2>/dev/null

{
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] post-fs-data start"
    "$MODDIR/system/bin/apex_check.sh"
    "$MODDIR/system/bin/boot_guardian.sh"
    "$MODDIR/system/bin/ksu_init.sh"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] post-fs-data done"
} >>"$LOG" 2>&1
