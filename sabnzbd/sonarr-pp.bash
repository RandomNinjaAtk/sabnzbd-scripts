#!/usr/bin/with-contenv bash

set -e

# start

# Create log
if [ ! -f "/config/scripts/logs/sonarr-pp.log" ]; then
	touch "/config/scripts/logs/sonarr-pp.log"
	chmod 0666 "/config/scripts/logs/sonarr-pp.log"
fi

bash /usr/local/sabnzbd-scripts/video-pp.bash "$1" "/config/scripts/configs/sonarr-pp.ini" | tee -a "/config/scripts/logs/sonarr-pp.log"

exit 0 
