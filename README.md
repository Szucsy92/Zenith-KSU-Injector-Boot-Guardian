# Zenith-KSU-Injector-Boot-Guardian
System-level KSU module integration with bootloop guardian and APEX self-healing for Samsung OneUI (ext4)

Check the shared zip for more information about how to use.


This project allows seamless integration of KernelSU modules directly into the system image while providing automatic bootloop protection and APEX self-healing.

 Features

Bootloop Guardian

- Boot attempt counter stored in "/data"
- Automatic recovery reboot after 5 failed boots
- Selective APEX and Dalvik cleanup after 2 failed boots
- Automatic counter reset after successful boot

APEX Self-Healing

On repeated failed boots:

- Cleans "/data/apex/active"
- Cleans "/data/apex/backup"
- Clears Dalvik cache
- Clears resource cache

Prevents common:

- ART corruption loops
- Permission Manager crashes
- Vendor mismatch runtime crashes

KSU Module Injector

- Restores modules from system partition
- Injects into "/data/adb"
- Automatically fixes permissions
- Removes "disable" and "skip_mount"
- Survives factory reset


Architecture

Zenith operates at init level using:

- "post-fs-data" trigger
- custom ".rc" services
- "su" context execution

This makes it:

- independent from Magisk
- independent from userspace apps
- fully system-integrated


Directory Structure

System source directory:

/system/usr/share/ksu_modules/adb

Target injection directory:

/data/adb


Compatibility

- Samsung OneUI 7 (tested)
- ext4 partitions
- KernelSU-enabled kernels

May work on:

- OneUI 6.x
- Other Samsung ext4 ROMs

Not tested on:

- F2FS system
- AOSP ROMs
- Dynamic partition non-Samsung builds



This is not a Magisk module.



This is a system-level integration tool intended for:

- ROM builders
- KernelSU ROM maintainers

Improper integration may result in bootloops.


Recommended Use Case

- Pre-integrated KSU ROM releases
- Persistent module layer after factory reset
- Bootloop-safe ROM development 
