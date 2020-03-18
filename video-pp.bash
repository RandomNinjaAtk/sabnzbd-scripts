#!/usr/bin/with-contenv bash

set -e

# start

# check for video files
if find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
	sleep 0.1
else
	echo "ERROR: No video files found for processing"
	exit 1
fi


find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" -print0 | while IFS= read -r -d '' video; do
	tracks=$(ffprobe -show_streams -print_format json -loglevel quiet "$video")
	if [ ! -z "${tracks}" ]; then
		allvideo=$(echo "${tracks}" | jq '. | .streams | .[] | select (.codec_type=="video") | .index')
		allaudio=$(echo "${tracks}" | jq '. | .streams | .[] | select (.codec_type=="audio") | .index')
		allsub=$(echo "${tracks}" | jq '. | .streams | .[] | select (.codec_type=="subtitle") | .index')	
		setaudio=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language==\"${VIDEO_LANG}\") | .index")
		undaudio=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language==\"und\") | .index")
		nonundaudio=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language!=\"und\") | .index")
		setsub=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"subtitle\") | select(.tags.language==\"${VIDEO_LANG}\") | .index")
	else
		echo "ERROR: ffprobe failed to read tracks and set values"
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
	elif [ -z "${setsub}" ]; then
		echo "${VIDEO_LANG} audio tracks found, id: ${setsub}"
	else
		echo "ERROR: no ${VIDEO_LANG} audio/subtitle tracks found"
		rm "$video" && echo "INFO: deleted: $video"
	fi	
done

# check for video files
if find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
	sleep 0.1
else
	echo "ERROR: No video files found for processing"
	exit 1
fi

# Manual run of Sickbeard MP4 Automator
python3 /usr/local/sma/manual.py --config "$2" -i "$1" -nt

# check for video files
if find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\)" | read; then
	echo "video processing complete!"
else
	echo "ERROR: No video files"
	exit 1
fi

exit 0
