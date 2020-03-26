#!/usr/bin/with-contenv bash

# start

set -e

bash /usr/local/sabnzbd-scripts/video-pp.bash "$@" "/usr/local/sma/config/autoProcess.ini"

exit $?
