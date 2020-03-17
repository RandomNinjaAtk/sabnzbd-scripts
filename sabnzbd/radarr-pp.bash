#!/usr/bin/with-contenv bash

set -e

# start

bash /usr/local/sabnzbd-scripts/video-pp.bash "$1" "/config/scripts/configs/radarr-pp.ini" 2>&1 | tee "/config/scripts/logs/radarr-pp.log" > /proc/1/fd/1 2>/proc/1/fd/2

exit 0 
