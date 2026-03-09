# Zenith KSU Injector Boot Guardian
KernelSU module with one-click install support, bootloop guardian, APEX self-healing, and an in-app WebUI.

Special thanks to @A1X31 for help and support.

## What changed

- Packaged as a real KernelSU module ZIP (`Zenith_KSU.zip`) for direct install in KernelSU Manager.
- Added a WebUI (`webroot/index.html`) so you can run actions from the KSU app instead of Termux.
- Added WebUI config controls (feature toggles + thresholds + reset delay).
- Added shared module action endpoint (`action.sh`) used by both WebUI and CLI.
- Added module boot hooks (`post-fs-data.sh`, `boot-completed.sh`) for automatic startup behavior.
- Added installer auto-configuration so defaults are enabled immediately at install.

## Core features

### Bootloop Guardian

- Boot attempt counter stored in `/data/local/tmp/boot_attempts`
- Recovery reboot on repeated failed boots (5+ failed attempts)
- Counter reset after successful boot

### APEX Self-Healing

- Selective wipe after repeated failures:
  - `/data/apex/active/*`
  - `/data/apex/backup/*`
  - `/data/dalvik-cache/*`
  - `/data/resource-cache/*`

### Injector Sync

- Restore modules from `/system/usr/share/ksu_modules/adb` to `/data/adb` during boot
- Force module activation (`update`, remove `disable`/`skip_mount`)

## One-click install (KernelSU app)

1. Open KernelSU Manager.
2. Go to Modules.
3. Install from storage and select `Zenith_KSU.zip`.
4. Module auto-config runs during install (default config + initial snapshot sync).
5. Reboot.

## WebUI usage

Open the module in KernelSU Manager and tap the WebUI shortcut.

Available buttons:

- `Update & Inject`
- `Refresh Status`
- `Optimize APEX`
- `Clear System Injection`
- `Full Remove (System + Data)`
- `Show Last Log`
- `Reload/Save/Reset` configuration values

Config keys exposed in WebUI:

- `BOOT_GUARDIAN_ENABLED` (`0`/`1`)
- `APEX_AUTO_HEAL_ENABLED` (`0`/`1`)
- `AUTO_INJECT_ON_BOOT` (`0`/`1`)
- `BOOT_FAIL_LIMIT` (integer, default `5`)
- `APEX_WIPE_TRIGGER` (integer, default `2`)
- `RESET_DELAY_SEC` (integer, default `60`)

## Optional Termux/CLI usage

- Run `zenith` (if `/system/bin/zenith` is available on your setup), or
- Run module actions directly:
  - `su -c "sh /data/adb/modules/zenith_ksu_boot_guardian/action.sh update_inject"`
  - `su -c "sh /data/adb/modules/zenith_ksu_boot_guardian/action.sh clear_system"`
  - `su -c "sh /data/adb/modules/zenith_ksu_boot_guardian/action.sh full_remove"`
  - `su -c "sh /data/adb/modules/zenith_ksu_boot_guardian/action.sh apex_optimize"`
  - `su -c "sh /data/adb/modules/zenith_ksu_boot_guardian/action.sh config_show"`
  - `su -c "sh /data/adb/modules/zenith_ksu_boot_guardian/action.sh config_apply BOOT_FAIL_LIMIT=6 RESET_DELAY_SEC=90"`

## Build ZIP

Use:

```bash
./build_module_zip.sh
```

This regenerates `Zenith_KSU.zip` with the current module files.

## Compatibility notes

- Target: Samsung OneUI + KernelSU on writable/ext4-based system setups
- This module performs root-level operations and can trigger recovery reboots by design
- Improper use can cause boot issues, so keep a recovery path available
