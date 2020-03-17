#!/usr/bin/with-contenv bash

# check for video files
if find "$1" -type f  -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
	echo "CHECK: Finding video files for processing..."
	echo "SUCCESS: Video files found"
else
	echo "ERROR: No video files found for processing"
	exit 1
fi

# Manual run of Sickbeard MP4 Automator
python3 /usr/local/sma/manual.py -i "$1" -nt

exit 0
