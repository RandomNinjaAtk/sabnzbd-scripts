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
	filename="$(basename "$video")"
	echo "Checking for \"${VIDEO_LANG}\" audio/subtitle tracks in: $filename"
	tracks=$(ffprobe -show_streams -print_format json -loglevel quiet "$video")
	if [ ! -z "${tracks}" ]; then
		allvideo=$(echo "${tracks}" | jq '. | .streams | .[] | select (.codec_type=="video") | .index')
		allvideocount=$(echo "${allvideo}" | wc -l)
		allaudio=$(echo "${tracks}" | jq '. | .streams | .[] | select (.codec_type=="audio") | .index')
		allaudiocount=$(echo "${allaudio}" | wc -l)
		allsub=$(echo "${tracks}" | jq '. | .streams | .[] | select (.codec_type=="subtitle") | .index')	
		allsubcount=$(echo "${allsub}" | wc -l)
		setaudio=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language==\"${VIDEO_LANG}\") | .index")
		setaudiocount=$(echo "${setaudio}" | wc -l)
		undaudio=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language==\"und\") | .index")
		undaudiocount=$(echo "${undaudio}" | wc -l)
		nonundaudio=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language!=\"und\") | .index")
		setsub=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"subtitle\") | select(.tags.language==\"${VIDEO_LANG}\") | .index")
		setsubcount=$(echo "${setsub}" | wc -l)
	else
		echo "ERROR: ffprobe failed to read tracks and set values"
		rm "$video" && echo "INFO: deleted: $video"
	fi
			
	if [ -z "${allvideocount}" ]; then
		echo "ERROR: no video tracks found"
		rm "$video" && echo "INFO: deleted: $filename"
	fi

	if [ -z "${allaudiocount}" ]; then
		echo "ERROR: no audio tracks found"
		rm "$video" && echo "INFO: deleted: $filename"
	fi	

	if [ -f "$video"]; then	
		if [ ! -z "${setaudiocount}" ]; then
			echo "${setaudiocount} \"${VIDEO_LANG}\" audio tracks found"
			if [ ! -z "${setsubcount}" ]; then
				echo "${setsubcount} \"${VIDEO_LANG}\" subtitle tracks found"
			fi
		elif [ ! -z "${undaudiocount}" ]; then
			echo "${undaudiocount} \"und\" audio tracks found"
			if [ ! -z "${setsubcount}" ]; then
				echo "${setsubcount} \"${VIDEO_LANG}\" subtitle tracks found"
			fi
		elif [ ! -z "${setsubcount}" ]; then
			echo "${allaudiocount} Audio Tracks Found"
			echo "${setsubcount} \"${VIDEO_LANG}\" subtitle tracks found"
		else
			echo "ERROR: no \"${VIDEO_LANG}\" audio/subtitle tracks found"
			rm "$video" && echo "INFO: deleted: $video"
		fi
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
