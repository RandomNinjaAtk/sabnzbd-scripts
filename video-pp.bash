#!/usr/bin/with-contenv bash

set -e

# start

echo "Sonarr Language setting: ${sonarr-language}"
echo "Radarr Language setting: ${radarr-language}"
sleep 5

# check for video files
if find "$1" -type f  -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
	echo "CHECK: Finding video files for processing..."
	echo "SUCCESS: Video files found"
else
	echo "ERROR: No video files found for processing"
	exit 1
fi

# Manual run of Sickbeard MP4 Automator
python3 /usr/local/sma/manual.py --config "$2" -i "$1" -nt

# check for video files
if find "$1" -type f  -iregex ".*/.*\.\(mkv\|mp4\)" | read; then
	echo "video-pp processing complete!"
else
	echo "ERROR: No video files"
	exit 1
fi

exit 0
