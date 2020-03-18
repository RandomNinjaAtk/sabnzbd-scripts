#!/usr/bin/with-contenv bash

set -e

# start

find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" -print0 | while IFS= read -r -d '' video; do
	tracks=$(mkvmerge -J "$video")
	if [ ! -z "${tracks}" ]; then
		allvideo=$(echo "${tracks}" | jq ".tracks[] | select(.type==\"video\") | .id")
		allaudio=$(echo "${tracks}" | jq ".tracks[] | select(.type==\"audio\") | .id")
		allsub=$(echo "${tracks}" | jq ".tracks[] | select(.type==\"subtitles\") | .id")		
		setaudio=$(echo "${tracks}" | jq ".tracks[] | select((.type==\"audio\") and select(.properties.language==\"${VIDEO_LANG}\")) | .id")
		undaudio=$(echo "${tracks}" | jq '.tracks[] | select((.type=="audio") and select(.properties.language=="und")) | .id')
		nonundaudio=$(echo "${tracks}" | jq '.tracks[] | select((.type=="audio") and select(.properties.language!="und")) | .id')
		nonperfaudio=$(echo "${tracks}" | jq ".tracks[] | select((.type==\"audio\") and select(.properties.language!=\"${VIDEO_LANG}\")) | .id")
		perfsub=$(echo "${tracks}" | jq ".tracks[] | select((.type==\"subtitles\") and select(.properties.language==\"${VIDEO_LANG}\")) | .id")
		nonperfsub=$(echo "${tracks}" | jq ".tracks[] | select((.type==\"subtitles\") and select(.properties.language!=\"${VIDEO_LANG}\")) | .id")
	else
		echo "ERROR: mkvmerge failed to read tracks and set values"
		rm "$video" && echo "INFO: deleted: $video"
	fi
	
	if [ ! -z "${allvideo}" ]; then
		echo "video tracks found"
	else
		echo "ERROR: no video tracks found"
		rm "$video" && echo "INFO: deleted: $video"
	fi
	
	if [ ! -z "${allaudio}" ]; then
		echo "audio tracks found"
	else
		echo "ERROR: no audio tracks found"
		rm "$video" && echo "INFO: deleted: $video"
	fi
	
	if [ ! -z "${allsub}" ]; then
		echo "subtitles tracks found"
	fi
	
	if [ ! -z "${setaudio}" ]; then
		echo "${VIDEO_LANG} audio tracks found, id: ${setaudio}"
	elif [ ! -z "${undaudio}" ]; then
		echo "und audio tracks found, id: ${undaudio}"
	elif [ -z "${perfsub}" ]; then
		echo "${VIDEO_LANG} audio tracks found, id: ${perfsub}"
	else
		echo "ERROR: no ${VIDEO_LANG} audio/subtitle tracks found"
		rm "$video" && echo "INFO: deleted: $video"
	fi	
done
sleep 5

# check for video files
if find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
	echo "CHECK: Finding video files for processing..."
	echo "SUCCESS: Video files found"
else
	echo "ERROR: No video files found for processing"
	exit 1
fi

# Manual run of Sickbeard MP4 Automator
python3 /usr/local/sma/manual.py --config "$2" -i "$1" -nt

# check for video files
if find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\)" | read; then
	echo "video-pp processing complete!"
else
	echo "ERROR: No video files"
	exit 1
fi

exit 0
