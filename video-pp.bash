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

if [ ${VIDEO_SMA} = TRUE ]; then
	touch "$1/sma-conversion-check"
fi

filecount=$(find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | wc -l)
echo "Processing ${filecount} video files..."
find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" -print0 | while IFS= read -r -d '' video; do
	echo ""
	echo "===================================================="
	filename="$(basename "$video")"
	echo "Begin processing: $filename"
	echo "Checking for \"${VIDEO_LANG}\" audio/subtitle tracks"
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

	if [ -f "$video" ]; then	
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
			rm "$video" && echo "INFO: deleted: $filename"
		fi
	fi
	if [ ${VIDEO_SMA} = TRUE ]; then
		if [ -f "$video" ]; then
			echo ""
			echo "Begin processing with Sickbeard MP4 Automator..."
			echo ""
			# Manual run of Sickbeard MP4 Automator
			if python3 /usr/local/sma/manual.py --config "$2" -i "$video" -nt; then
				echo "Processing complete for: ${filename}!"
			else
				echo "ERROR: Sickbeard MP4 Automator Processing Error"
				rm "$video" && echo "INFO: deleted: $filename"
			fi
		fi
	fi
	echo "===================================================="
done

if [ ${VIDEO_SMA} = TRUE ]; then
	find "$1" -type f ! -newer "$1/sma-conversion-check" ! -name "$1/sma-conversion-check" -delete
	# check for video files
	if find "$1" -type f -iname "*.${CONVERTER_OUTPUT_EXTENSION}" | read; then
		echo "Post Processing Complete!"
	else
		echo "ERROR: Conversion failed, no video files found..."
		exit 1
	fi
	if [ -f "$1/sma-conversion-check" ]; then 
		rm "$1/sma-conversion-check"
	fi
fi

exit $?
