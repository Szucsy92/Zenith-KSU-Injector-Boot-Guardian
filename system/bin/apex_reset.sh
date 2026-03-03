#!/system/bin/sh
# Stability Success Reset
# Created by @szucsy92 & @A1X31

FILE="/data/local/tmp/boot_attempts"

# Wait 60 seconds to ensure the system services (SystemServer, PM) are stable
sleep 60

# If the system reached this point without crashing, reset the failure counter
if [ -f $FILE ]; then
    echo 0 > $FILE
fi
