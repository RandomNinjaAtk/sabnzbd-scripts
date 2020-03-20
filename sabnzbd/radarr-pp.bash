#!/usr/bin/with-contenv bash

set -e

# start

# Create log
if [ ! -f "/config/scripts/logs/radarr-pp.log" ]; then
	touch "/config/scripts/logs/radarr-pp.log"
	chmod 0666 "/config/scripts/logs/radarr-pp.log"
fi


bash /usr/local/sabnzbd-scripts/video-pp.bash "$1" "/config/scripts/configs/radarr-pp.ini" | tee -a "/config/scripts/logs/radarr-pp.log"

exit 0 
