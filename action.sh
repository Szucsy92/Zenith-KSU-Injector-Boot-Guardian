#!/system/bin/sh

MODDIR=${0%/*}
LOG="/data/local/tmp/zenith_action.log"
BOOT_LOG="/data/local/tmp/zenith_boot.log"
INIT_LOG="/data/local/tmp/ksu_init.log"
EXPORT_DIR_PRIMARY="/sdcard/Zenith_KSU_Logs"
EXPORT_DIR_ALT="/storage/emulated/0/Zenith_KSU_Logs"
SYSTEM_STORE_PRIMARY="/system/usr/share/ksu_modules"
SYSTEM_STORE_ALT="/system/system/usr/share/ksu_modules"
SYSTEM_ADB_PRIMARY="$SYSTEM_STORE_PRIMARY/adb"
SYSTEM_ADB_ALT="$SYSTEM_STORE_ALT/adb"
SYSTEM_STORE="$SYSTEM_STORE_PRIMARY"
SYSTEM_ADB="$SYSTEM_ADB_PRIMARY"
DATA_ADB="/data/adb"
CONFIG_DIR="$MODDIR/config"
CONFIG_FILE="$CONFIG_DIR/zenith.conf"

default_config() {
    cat <<'EOF'
BOOT_GUARDIAN_ENABLED=1
APEX_AUTO_HEAL_ENABLED=1
AUTO_INJECT_ON_BOOT=1
BOOT_FAIL_LIMIT=5
APEX_WIPE_TRIGGER=2
RESET_DELAY_SEC=60
EOF
}

timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

log() {
    line="[$(timestamp)] $1"
    echo "$line"
    echo "$line" >>"$LOG"
}

init_log() {
    mkdir -p /data/local/tmp 2>/dev/null
    touch "$LOG" 2>/dev/null
}

ensure_config() {
    mkdir -p "$CONFIG_DIR" 2>/dev/null
    if [ ! -f "$CONFIG_FILE" ]; then
        default_config >"$CONFIG_FILE"
        chmod 0644 "$CONFIG_FILE" 2>/dev/null || true
    fi
}

load_config() {
    ensure_config
    # shellcheck disable=SC1090
    . "$CONFIG_FILE"
}

is_positive_int() {
    case "$1" in
        ''|*[!0-9]*)
            return 1
            ;;
        *)
            [ "$1" -gt 0 ] 2>/dev/null
            ;;
    esac
}

set_config_value() {
    key="$1"
    value="$2"

    case "$key" in
        BOOT_GUARDIAN_ENABLED|APEX_AUTO_HEAL_ENABLED|AUTO_INJECT_ON_BOOT)
            case "$value" in
                0|1) ;;
                *)
                    log "ERROR: $key must be 0 or 1."
                    return 1
                    ;;
            esac
            ;;
        BOOT_FAIL_LIMIT|APEX_WIPE_TRIGGER|RESET_DELAY_SEC)
            if ! is_positive_int "$value"; then
                log "ERROR: $key must be a positive integer."
                return 1
            fi
            ;;
        *)
            log "ERROR: Unknown config key '$key'."
            return 1
            ;;
    esac

    ensure_config
    tmp_file="${CONFIG_FILE}.tmp"
    awk -F= -v key="$key" -v value="$value" '
        BEGIN { updated = 0 }
        $1 == key {
            print key "=" value
            updated = 1
            next
        }
        { print $0 }
        END {
            if (!updated) {
                print key "=" value
            }
        }
    ' "$CONFIG_FILE" >"$tmp_file" || return 1

    mv "$tmp_file" "$CONFIG_FILE"
}

cmd_config_init() {
    ensure_config
    log "Config initialized at $CONFIG_FILE."
    cmd_config_show
}

cmd_config_show() {
    log "Reading config from $CONFIG_FILE"
    load_config
    echo "BOOT_GUARDIAN_ENABLED=$BOOT_GUARDIAN_ENABLED"
    echo "APEX_AUTO_HEAL_ENABLED=$APEX_AUTO_HEAL_ENABLED"
    echo "AUTO_INJECT_ON_BOOT=$AUTO_INJECT_ON_BOOT"
    echo "BOOT_FAIL_LIMIT=$BOOT_FAIL_LIMIT"
    echo "APEX_WIPE_TRIGGER=$APEX_WIPE_TRIGGER"
    echo "RESET_DELAY_SEC=$RESET_DELAY_SEC"
}

cmd_config_set() {
    key="$1"
    value="$2"
    set_config_value "$key" "$value" || return 1
    log "Config updated: $key=$value"
}

cmd_config_apply() {
    if [ "$#" -lt 1 ]; then
        log "ERROR: config_apply requires KEY=VALUE pairs."
        return 1
    fi

    log "Applying $#: config value(s)."
    for pair in "$@"; do
        key=${pair%%=*}
        value=${pair#*=}
        if [ "$key" = "$pair" ]; then
            log "ERROR: Invalid pair '$pair', expected KEY=VALUE."
            return 1
        fi
        set_config_value "$key" "$value" || return 1
    done

    log "Config apply completed."
    cmd_config_show
}

cmd_config_reset() {
    mkdir -p "$CONFIG_DIR" 2>/dev/null
    log "Resetting config to defaults at $CONFIG_FILE"
    default_config >"$CONFIG_FILE" || return 1
    chmod 0644 "$CONFIG_FILE" 2>/dev/null || true
    log "Config reset to defaults."
    cmd_config_show
}

remount_root_rw() {
    mount -o remount,rw / >>"$LOG" 2>&1
}

remount_root_ro() {
    mount -o remount,ro / >>"$LOG" 2>&1
}

cleanup_root_mount() {
    remount_root_ro || true
}

maybe_remount_root_rw() {
    if remount_root_rw; then
        return 0
    fi
    log "WARN: Failed to remount / as read-write. Continuing with direct write attempt."
    return 1
}

resolve_system_store() {
    if [ -d "$SYSTEM_STORE_PRIMARY" ]; then
        SYSTEM_STORE="$SYSTEM_STORE_PRIMARY"
    elif [ -d "$SYSTEM_STORE_ALT" ]; then
        SYSTEM_STORE="$SYSTEM_STORE_ALT"
    else
        SYSTEM_STORE="$SYSTEM_STORE_PRIMARY"
    fi
    SYSTEM_ADB="$SYSTEM_STORE/adb"
}

remove_all_system_snapshots() {
    rm -rf "$SYSTEM_ADB_PRIMARY" "$SYSTEM_ADB_ALT" >>"$LOG" 2>&1
}

schedule_reboot() {
    delay_sec="${1:-3}"
    case "$delay_sec" in
        ''|*[!0-9]*)
            delay_sec=3
            ;;
    esac
    [ "$delay_sec" -lt 1 ] 2>/dev/null && delay_sec=3

    log "Reboot scheduled in ${delay_sec}s."
    (
        sleep "$delay_sec"
        sync >/dev/null 2>&1 || true
        reboot >/dev/null 2>&1 || setprop sys.powerctl reboot >/dev/null 2>&1 || true
    ) &
}

prepare_export_dir() {
    if mkdir -p "$EXPORT_DIR_PRIMARY" >/dev/null 2>&1 && [ -d "$EXPORT_DIR_PRIMARY" ]; then
        echo "$EXPORT_DIR_PRIMARY"
        return 0
    fi
    if mkdir -p "$EXPORT_DIR_ALT" >/dev/null 2>&1 && [ -d "$EXPORT_DIR_ALT" ]; then
        echo "$EXPORT_DIR_ALT"
        return 0
    fi
    return 1
}

export_log_file() {
    src="$1"
    name="$2"
    out_dir="$3"
    suffix="$4"
    latest="$out_dir/${name}_latest.log"
    stamped="$out_dir/${name}_${suffix}.log"

    if [ ! -f "$src" ]; then
        echo "Export skip: missing $src"
        return 0
    fi

    cp -f "$src" "$latest" >/dev/null 2>&1 || {
        echo "Export failed: $latest"
        return 1
    }
    cp -f "$src" "$stamped" >/dev/null 2>&1 || true

    echo "Exported: $latest"
    echo "Exported: $stamped"
}

cmd_update_inject() {
    log "Step: validating source data path ($DATA_ADB)"
    if [ ! -d "$DATA_ADB" ]; then
        log "ERROR: $DATA_ADB does not exist."
        return 1
    fi

    log "Running UPDATE & INJECT."
    maybe_remount_root_rw || true

    resolve_system_store
    log "Step: selected system store ($SYSTEM_STORE)"
    log "Step: preparing destination directory"
    mkdir -p "$SYSTEM_STORE" >>"$LOG" 2>&1 || {
        log "ERROR: Failed to create $SYSTEM_STORE."
        cleanup_root_mount
        return 1
    }

    log "Step: removing old snapshots"
    remove_all_system_snapshots
    log "Step: copying $DATA_ADB -> $SYSTEM_STORE"
    cp -af "$DATA_ADB" "$SYSTEM_STORE/" >>"$LOG" 2>&1 || {
        log "ERROR: Failed to copy $DATA_ADB to $SYSTEM_STORE."
        cleanup_root_mount
        return 1
    }

    log "Step: removing nested ksu directory from snapshot"
    rm -rf "$SYSTEM_ADB/ksu" >>"$LOG" 2>&1
    if command -v restorecon >/dev/null 2>&1; then
        log "Step: applying SELinux restorecon on $SYSTEM_ADB"
        restorecon -RF "$SYSTEM_ADB" >>"$LOG" 2>&1
    else
        log "Step: restorecon not available; skipping relabel"
    fi

    cleanup_root_mount
    log "UPDATE & INJECT completed."
}

cmd_clear_system() {
    log "Running CLEAR SYSTEM INJECTION."
    maybe_remount_root_rw || true

    resolve_system_store
    log "Step: selected system store ($SYSTEM_STORE)"
    log "Step: deleting snapshots at $SYSTEM_ADB_PRIMARY and $SYSTEM_ADB_ALT"
    remove_all_system_snapshots

    cleanup_root_mount
    log "System injection removed (both path variants)."
    schedule_reboot 3
}

cmd_full_remove() {
    log "Running FULL REMOVE."
    maybe_remount_root_rw || true

    log "Step: deleting $DATA_ADB"
    rm -rf "$DATA_ADB" >>"$LOG" 2>&1
    log "Step: deleting system snapshots"
    remove_all_system_snapshots
    resolve_system_store
    log "Step: recreating system store ($SYSTEM_STORE)"
    mkdir -p "$SYSTEM_STORE" >>"$LOG" 2>&1 || {
        log "ERROR: Failed to recreate $SYSTEM_STORE."
        cleanup_root_mount
        return 1
    }

    cleanup_root_mount
    log "Full remove completed."
}

cmd_apex_optimize() {
    log "Running APEX OPTIMIZE."
    mount -o remount,rw /data >>"$LOG" 2>&1 || true
    log "Step: clearing /data/apex/active"
    rm -rf /data/apex/active/* >>"$LOG" 2>&1
    log "Step: clearing /data/apex/backup"
    rm -rf /data/apex/backup/* >>"$LOG" 2>&1
    log "Step: clearing /data/dalvik-cache"
    rm -rf /data/dalvik-cache/* >>"$LOG" 2>&1
    log "Step: clearing /data/resource-cache"
    rm -rf /data/resource-cache/* >>"$LOG" 2>&1
    log "APEX optimization completed."
    schedule_reboot 3
}

cmd_status() {
    log "Status:"
    log "Step: checking snapshot and data directories"
    if [ -d "$SYSTEM_ADB_PRIMARY" ] || [ -d "$SYSTEM_ADB_ALT" ]; then
        if [ -d "$SYSTEM_ADB_PRIMARY" ]; then
            log "  system snapshot: present ($SYSTEM_ADB_PRIMARY)"
        fi
        if [ -d "$SYSTEM_ADB_ALT" ]; then
            log "  system snapshot: present ($SYSTEM_ADB_ALT)"
        fi
    else
        log "  system snapshot: missing ($SYSTEM_ADB_PRIMARY and $SYSTEM_ADB_ALT)"
    fi

    if [ -d "$DATA_ADB" ]; then
        log "  data adb: present ($DATA_ADB)"
    else
        log "  data adb: missing ($DATA_ADB)"
    fi
}

cmd_show_log() {
    stamp=$(date "+%Y%m%d_%H%M%S")
    log "Preparing log export bundle (stamp: $stamp)"
    export_dir="$(prepare_export_dir)" || export_dir=""
    if [ -n "$export_dir" ]; then
        log "Export target directory: $export_dir"
        export_log_file "$LOG" "zenith_action" "$export_dir" "$stamp"
        export_log_file "$BOOT_LOG" "zenith_boot" "$export_dir" "$stamp"
        export_log_file "$INIT_LOG" "ksu_init" "$export_dir" "$stamp"
    else
        echo "WARN: Could not create export directory at $EXPORT_DIR_PRIMARY or $EXPORT_DIR_ALT"
    fi

    if [ -f "$LOG" ]; then
        if command -v tail >/dev/null 2>&1; then
            tail -n 160 "$LOG"
        else
            cat "$LOG"
        fi
    else
        echo "No action log file found at $LOG"
    fi
}

usage() {
    cat <<'EOF'
Usage:
  action.sh update_inject
  action.sh clear_system
  action.sh full_remove
  action.sh apex_optimize
  action.sh status
  action.sh show_log
  action.sh config_init
  action.sh config_show
  action.sh config_set KEY VALUE
  action.sh config_apply KEY=VALUE [KEY=VALUE...]
  action.sh config_reset
EOF
}

main() {
    init_log
    action="${1:-help}"
    log "Action request: $action"

    case "$action" in
        update_inject|inject|sync)
            cmd_update_inject
            ;;
        clear_system|clear_injection)
            cmd_clear_system
            ;;
        full_remove|full_wipe)
            cmd_full_remove
            ;;
        apex_optimize|apex)
            cmd_apex_optimize
            ;;
        status)
            cmd_status
            ;;
        show_log|log)
            cmd_show_log
            ;;
        config_init)
            cmd_config_init
            ;;
        config_show|get_config)
            cmd_config_show
            ;;
        config_set)
            if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
                log "ERROR: config_set requires KEY and VALUE."
                return 1
            fi
            cmd_config_set "$2" "$3"
            ;;
        config_apply)
            shift
            cmd_config_apply "$@"
            ;;
        config_reset)
            cmd_config_reset
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            log "ERROR: Unknown action '$1'."
            usage
            return 2
            ;;
    esac
}

main "$@"
