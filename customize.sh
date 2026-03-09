ui_print "- Applying Zenith module permissions"

set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/boot-completed.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/customize.sh" 0 0 0755

set_perm_recursive "$MODPATH/system/bin" 0 0 0755 0755
set_perm_recursive "$MODPATH/system/etc/init" 0 0 0755 0644
set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644

ui_print "- Writing default config"
mkdir -p "$MODPATH/config"
cat >"$MODPATH/config/zenith.conf" <<'EOF'
BOOT_GUARDIAN_ENABLED=1
APEX_AUTO_HEAL_ENABLED=1
AUTO_INJECT_ON_BOOT=1
BOOT_FAIL_LIMIT=5
APEX_WIPE_TRIGGER=2
RESET_DELAY_SEC=60
EOF
set_perm_recursive "$MODPATH/config" 0 0 0755 0644
set_perm "$MODPATH/config/zenith.conf" 0 0 0644

if [ -x "$MODPATH/action.sh" ]; then
    ui_print "- Auto-configuring module state"
    sh "$MODPATH/action.sh" config_init >/dev/null 2>&1 || true
    if sh "$MODPATH/action.sh" update_inject >/dev/null 2>&1; then
        ui_print "- Auto-config done: injector snapshot synced"
    else
        ui_print "- Auto-config warning: snapshot sync failed, use WebUI Update & Inject"
    fi
fi
