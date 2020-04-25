#!/bin/bash

# start

set -e

if [ ! -f /config/scripts/Deobfuscate.py ]; then
    echo "downloading Deobfuscate.py from: https://github.com/sabnzbd/sabnzbd/blob/develop/scripts/Deobfuscate.py"
    curl -o /config/scripts/Deobfuscate.py https://raw.githubusercontent.com/sabnzbd/sabnzbd/develop/scripts/Deobfuscate.py
    echo "done"

    # Set Permissions
    echo "setting permissions..."
    chmod 777 /config/scripts/Deobfuscate.py
    echo "done"
fi

timeout --foreground 1m python3 /config/scripts/Deobfuscate.py "$@"

bash /usr/local/sabnzbd-scripts/video-pp.bash "$1" "/config/scripts/configs/video-pp-sma.ini"

exit $?
