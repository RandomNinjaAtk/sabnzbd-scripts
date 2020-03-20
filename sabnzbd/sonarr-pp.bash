#!/usr/bin/with-contenv bash

# start

# Create log
if [ ! -f "/config/scripts/logs/sonarr-pp.log" ]; then
	touch "/config/scripts/logs/sonarr-pp.log"
	chmod 0666 "/config/scripts/logs/sonarr-pp.log"
fi

set -o pipefail
bash /usr/local/sabnzbd-scripts/video-pp.bash "$1" "/config/scripts/configs/sonarr-pp.ini" | tee -a "/config/scripts/logs/sonarr-pp.log"

if [ $? = 0 ]; then
	exit 0 
else
	exit $?
fi
