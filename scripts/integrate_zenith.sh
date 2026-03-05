#!/bin/bash
# Zenith KSU Integráció Script UN1CA/ExtremeROM-hoz
# Létrehozza a fájlokat, permissionöket és config-okat build időben
# Használat: ./integrate_zenith.sh <target_system_dir> (pl. $OUT/system)
# Created based on Zenith repo files (2026.03.05 verzió)

if [ $# -ne 1 ]; then
    echo "Használat: $0 <system_mappa_útvonala>"
    exit 1
fi

SYSTEM_DIR="$1"
BIN_DIR="$SYSTEM_DIR/bin"
INIT_DIR="$SYSTEM_DIR/etc/init"
FS_CONFIG_FILE="$SYSTEM_DIR/../filesystem_config_zenith.txt"  # Merge-elendő az UN1CA fs_config-ba
SE_CONTEXT_FILE="$SYSTEM_DIR/../file_contexts.zenith"  # Merge-elendő a sepolicy-ba

# Mappák létrehozása
mkdir -p "$BIN_DIR"
mkdir -p "$INIT_DIR"

# Fájlok létrehozása pontos tartalommal

# system/bin/apex_check.sh
cat << 'EOF' > "$BIN_DIR/apex_check.sh"
#!/system/bin/sh # APEX Selective Wipe Script # Created by @szucsy92 & @A1X31 FILE="/data/local/tmp/boot_attempts" # Do nothing if counter file is missing \[ ! -f \( FILE \] && exit 0 VAL= \)(cat $FILE) # Trigger selective wipe only after the 2nd consecutive boot failure if \[ $VAL -gt 1 \]; then mount -o remount,rw /data # Cleaning only updated/active APEX modules and caches # This prevents the "Permission Manager not found" error rm -rf /data/apex/active/\* rm -rf /data/apex/backup/\* rm -rf /data/dalvik-cache/\* rm -rf /data/resource-cache/\* echo "Selective wipe performed at attempt $VAL" > /data/local/tmp/last_wipe_log fi
EOF

# system/bin/apex_reset.sh
cat << 'EOF' > "$BIN_DIR/apex_reset.sh"
#!/system/bin/sh # Stability Success Reset # Created by @szucsy92 & @A1X31 FILE="/data/local/tmp/boot_attempts" # Wait 60 seconds to ensure the system services (SystemServer, PM) are stable sleep 60 # If the system reached this point without crashing, reset the failure counter if \[ -f $FILE \]; then echo 0 > $FILE fi
EOF

# system/bin/ksu_init.sh
cat << 'EOF' > "$BIN_DIR/ksu_init.sh"
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
EOF

# system/bin/boot_guardian.sh
cat << 'EOF' > "$BIN_DIR/boot_guardian.sh"
#!/system/bin/sh # Boot Attempt Counter & Guardian Logic # Created by @szucsy92 & @A1X31 FILE="/data/local/tmp/boot_attempts" mount -o remount,rw /data # Initialize the counter file if it doesn't exist \[ ! -f $FILE \] && echo 0 > \( FILE VAL= \)(cat \( FILE) NEW_VAL= \)((VAL + 1)) echo $NEW_VAL > $FILE # Limit reached: Reboot to recovery on the 5th attempt if no success reset occurred if \[ $NEW_VAL -gt 4 \]; then echo 0 > $FILE reboot recovery fi
EOF

# system/bin/zenith
cat << 'EOF' > "$BIN_DIR/zenith"
#!/system/bin/sh
# ZENITH KSU MODULE MANAGER - FINAL SYSTEM VERSION
# Created by @szucsy92 & @A1X31

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

while true; do
    clear
    echo -e "\( {CYAN}======================================== \){NC}"
    echo -e "${CYAN}       ZENITH KSU MODULE MANAGER        ${NC}"
    echo -e "\( {CYAN}======================================== \){NC}"
    echo ""
    echo "1) CLEAR (Choose what you want to delete)"
    echo "2) UPDATE & INJECT"
    echo "q) Quit"
    echo ""
    echo -n "Option: "
    read choice

    case $choice in
        1)
            clear
            echo -e "\( {YELLOW}--- CLEAR SUBMENU --- \){NC}"
            echo "1) System injection (ksu_modules)"
            echo "2) System and data (Full remove)"
            echo "3) APEX (Optimization)"
            echo "b) Back"
            echo ""
            echo -n "Sub-option: "
            read subchoice
            
            case $subchoice in
                1)
                    echo -e "\( {RED}Cleaning system injection... \){NC}"
                    su -c "mount -o remount,rw / && rm -rf /system/usr/share/ksu_modules/adb && mount -o remount,ro /"
                    ;;
                2)
                    echo -e "\( {RED}Starting Full Wipe... \){NC}"
                    su -c "mount -o remount,rw / && rm -rf /data/adb && rm -rf /system/usr/share/ksu_modules/adb && mkdir -p /system/usr/share/ksu_modules && mount -o remount,ro /"
                    ;;
                3)
                    echo -e "\( {CYAN}Optimizing APEX... \){NC}"
                    su -c "mount -o remount,rw / && rm -rf /data/apex/* && mount -o remount,ro /"
                    ;;
                b)
                    continue
                    ;;
            esac
            echo -e "\( {GREEN}Operation finished. \){NC}"
            sleep 2
            ;;
        2)
            echo -e "\( {YELLOW}Starting Sync & Injection... \){NC}"
            su -c "mount -o remount,rw / && rm -rf /system/usr/share/ksu_modules/adb && mkdir -p /system/usr/share/ksu_modules && cp -a /data/adb /system/usr/share/ksu_modules/ && rm -rf /system/usr/share/ksu_modules/adb/ksu && restorecon -Rv /system/usr/share/ksu_modules/adb && mount -o remount,ro /"
            echo -e "\( {GREEN}--- Done! /system/usr/share/ksu_modules/adb refreshed! --- \){NC}"
            sleep 2
            ;;
        q)
            exit 0
            ;;
    esac
done
EOF

# system/etc/init/apex_fix.rc
cat << 'EOF' > "$INIT_DIR/apex_fix.rc"
# APEX Fix & Boot Guardian Configuration # Created by @szucsy92 & @A1X31 service apex_check /system/bin/apex_check.sh user root group root oneshot disabled seclabel u:r:su:s0 service boot_guardian /system/bin/boot_guardian.sh user root group root oneshot disabled seclabel u:r:su:s0 service success_reset /system/bin/apex_reset.sh user root group root oneshot disabled seclabel u:r:su:s0 on post-fs-data # Start checking and counting at the beginning of the boot process start apex_check start boot_guardian on property:sys.boot_completed=1 # Reset the counter only after the system is fully loaded and stable start success_reset
EOF

# system/etc/init/init.ksu_prep.rc
cat << 'EOF' > "$INIT_DIR/init.ksu_prep.rc"
# KSU Injector Config # Created by @szucsy92 & @A1X31 on post-fs-data # Start the service start ksu_init_sh service ksu_init_sh /system/bin/sh /system/bin/ksu_init.sh user root group root seclabel u:r:su:s0 oneshot disabled
EOF

# Permissionök beállítása (chmod build időben)
chmod 0755 "$BIN_DIR/apex_check.sh"
chmod 0755 "$BIN_DIR/apex_reset.sh"
chmod 0755 "$BIN_DIR/ksu_init.sh"
chmod 0755 "$BIN_DIR/boot_guardian.sh"
chmod 0755 "$BIN_DIR/zenith"
chmod 0644 "$INIT_DIR/apex_fix.rc"
chmod 0644 "$INIT_DIR/init.ksu_prep.rc"

# Filesystem config létrehozása (uid/gid/mode) - merge-elendő az UN1CA fs_config-ba
cat << 'EOF' > "$FS_CONFIG_FILE"
# Zenith KSU Filesystem Config
system/bin/apex_check.sh 0 2000 0755
system/bin/apex_reset.sh 0 2000 0755
system/bin/ksu_init.sh 0 2000 0755
system/bin/boot_guardian.sh 0 2000 0755
system/bin/zenith 0 2000 0755
system/etc/init/apex_fix.rc 0 0 0644
system/etc/init/init.ksu_prep.rc 0 0 0644
EOF

# SELinux context-ek létrehozása - merge-elendő a sepolicy file_contexts-ba
cat << 'EOF' > "$SE_CONTEXT_FILE"
/system/bin/apex_check\.sh u:object_r:system_file:s0
/system/bin/apex_reset\.sh u:object_r:system_file:s0
/system/bin/ksu_init\.sh u:object_r:su_exec:s0
/system/bin/boot_guardian\.sh u:object_r:system_file:s0
/system/bin/zenith u:object_r:system_file:s0
/system/etc/init/apex_fix\.rc u:object_r:system_file:s0
/system/etc/init/init\.ksu_prep\.rc u:object_r:system_file:s0
EOF

echo "Zenith integráció kész! Fájlok létrehozva: $SYSTEM_DIR"
echo "Merge-eld a $FS_CONFIG_FILE-t az fs_config-ba és a $SE_CONTEXT_FILE-t a file_contexts-ba a build script-ben."
