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
elif [ ${VIDEO_MKVCLEANER} = TRUE ]; then 
	touch "$1/sma-conversion-check"
	CONVERTER_OUTPUT_EXTENSION="mkv"

	#convert mp4 to mkv before language processing
	find "$1" -type f -iregex ".*/.*\.\(mp4\)" -print0 | while IFS= read -r -d '' video; do
		echo ""
		echo "=========================="
		echo "INFO: Processing $video"
		if timeout 10s mkvmerge -i "$video" > /dev/null; then
			echo "INFO: MP4 found, remuxing to mkv before processing audio/subtitles"
			mkvmerge -o "$video.merged.mkv" "$video"
			# cleanup temp files and rename
			mv "$video" "$video.original.mkv" && echo "INFO: Renamed source file"
			mv "$video.merged.mkv" "${video/.mp4/.mkv}" && echo "INFO: Renamed temp file"
			rm "$video.original.mkv" && echo "INFO: Deleted source file"
		else
			echo "ERROR: mkvmerge failed"
			rm "$video" && echo "INFO: deleted: $video"
			continue
		fi
		echo "INFO: Processing complete"
		echo "=========================="
		echo ""
	done

	#convert avi to mkv before language processing
	find "$1" -type f -iregex ".*/.*\.\(avi\)" -print0 | while IFS= read -r -d '' video; do
		echo ""
		echo "=========================="
		echo "INFO: Processing $video"
		if timeout 10s mkvmerge -i "$video" > /dev/null; then
			echo "INFO: AVI found, remuxing to mkv before processing audio/subtitles"
			mkvmerge -o "$video.merged.mkv" "$video"
			# cleanup temp files and rename
			mv "$video" "$video.original.mkv" && echo "INFO: Renamed source file"
			mv "$video.merged.mkv" "${video/.avi/.mkv}" && echo "INFO: Renamed temp file"
			rm "$video.original.mkv" && echo "INFO: Deleted source file"
		else
			echo "ERROR: mkvmerge failed"
			rm "$video" && echo "INFO: deleted: $video"
			continue
		fi
		echo "INFO: Processing complete"
		echo "=========================="
		echo ""
	done
fi

filecount=$(find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | wc -l)
echo "Processing ${filecount} video files..."
find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" -print0 | while IFS= read -r -d '' video; do
	echo ""
	echo "===================================================="
	filename="$(basename "$video")"
	echo "Begin processing: $filename"
	echo "Checking for audio/subtitle tracks"
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
		nonsetaudio=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language!=\"${VIDEO_LANG}\") | .index")
		nonsetaudiocount=$(echo "${nonsetaudio}" | wc -l)
		undaudio=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language==\"und\") | .index")
		undaudiocount=$(echo "${undaudio}" | wc -l)
		nonundaudio=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language!=\"und\") | .index")
		nonundaudiocount=$(echo "${nonundaudio}" | wc -l)
		setsub=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"subtitle\") | select(.tags.language==\"${VIDEO_LANG}\") | .index")
		setsubcount=$(echo "${setsub}" | wc -l)
		nonsetsub=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"subtitle\") | select(.tags.language!=\"${VIDEO_LANG}\") | .index")
		nonsetsubcount=$(echo "${nonsetsub}" | wc -l)
	else
		echo "ERROR: ffprobe failed to read tracks and set values"
		rm "$video" && echo "INFO: deleted: $video"
	fi
			
	if [ -z "${allvideo}" ]; then
		echo "ERROR: no video tracks found"
		rm "$video" && echo "INFO: deleted: $filename"
	else
		echo "${allvideocount} video tracks found!"
	fi

	if [ -z "${allaudio}" ]; then
		echo "ERROR: no audio tracks found"
		rm "$video" && echo "INFO: deleted: $filename"
	else
		echo "${allaudiocount} audio tracks found!"
	fi
	
	if [ ! -z "${allsub}" ]; then
		echo "${allsubcount} subtitle tracks found!"
	fi
	
	if [ ! -z "${nonsetaudio}" ]; then
		removeaudio="true"
	else
		removeaudio="false"
	fi
	
	if [ ! -z "${nonsetsub}" ]; then
		removesubs="true"
	else
		removesubs="false"
	fi
	
	if [ -f "$video" ]; then
		echo "Checking for \"${VIDEO_LANG}\" audio/subtitle tracks"
		if [ ! -z "${setaudio}" ]; then
			echo "${setaudiocount} \"${VIDEO_LANG}\" audio tracks found"
			if [ ! -z "${setsub}" ]; then
				echo "${setsubcount} \"${VIDEO_LANG}\" subtitle tracks found"
			fi
		elif [ ! -z "${undaudio}" ]; then
			echo "${undaudiocount} \"und\" audio tracks found"
			if [ ! -z "${setsub}" ]; then
				echo "${setsubcount} \"${VIDEO_LANG}\" subtitle tracks found"
			fi
		elif [ ! -z "${setsub}" ]; then
			echo "${allaudiocount} Audio Tracks Found"
			echo "${setsubcount} \"${VIDEO_LANG}\" subtitle tracks found"
		else
			echo "ERROR: no \"${VIDEO_LANG}\" audio/subtitle tracks found"
			rm "$video" && echo "INFO: deleted: $filename"
			continue
		fi
	fi	
	
	if [ ${VIDEO_MKVCLEANER} = TRUE ]; then 
		if [ "${removeaudio}" = false ] && [ "${removesubs}" = false ]; then
			echo "INFO: Video passed all checks, no processing needed"
			touch "$video"
			continue
		else
			echo "Checking for unwanted audio/subtitles"
			if [ -z "${setaudio}" ] && [ ! -z "${nonsetaudio}" ] && [ ! -z "${nonundaudio}" ]; then
				echo "${nonsetaudiocount} unwanted audio tracks found"
			elif [ ! -z "${undaudio}" ]; then
				echo "${undaudiocount} und audio tracks found to be re-tagged as \"${VIDEO_LANG}\""
			fi
			if [ ! -z "${nonsetsub}" ]; then
				echo "${nonsetsubcount} unwanted subtitle tracks found"
			fi
		fi
		
		if [ "${removeaudio}" = true ]; then
			if [ ! -z "${setaudio}" ]; then
				mkvvideo=" -d ${allvideo} --language ${allvideo}:${VIDEO_LANG}"
				mkvaudio=" -a ${VIDEO_LANG}"
			elif [ ! -z "${undaudio}" ]; then
				for I in $undaudio
				do
					OUT=$OUT" -a $I --language $I:${VIDEO_LANG}"
				done
				mkvvideo=" -d ${allvideo} --language ${allvideo}:${VIDEO_LANG}"
				mkvaudio="$OUT"
			else
				mkvvideo=""
				mkvaudio=""
			fi
		else
			mkvvideo=""
			mkvaudio=""
		fi
		
		if [ "${removesubs}" = true ]; then
			if [ ! -z "${setaudio}" ]; then
				mkvvideo=" -d ${allvideo} --language ${allvideo}:${VIDEO_LANG}"
			fi
			if [ ! -z "${setsub}" ]; then
				mkvsubs=" -s ${VIDEO_LANG}"
			fi
		else
			mkvsubs=""
		fi

		if mkvmerge --no-global-tags --title "" -o "$video.merged.mkv"${mkvvideo}${mkvaudio}${mkvsubs} "$video"; then
			echo "SUCCESS: mkvmerge complete"
			echo "INFO: Options used:${mkvvideo}${mkvaudio}${mkvsubs}"
		else
			echo "ERROR: mkvmerge failed"
			rm "$video" && echo "INFO: deleted: $filename"
			continue
		fi
		# cleanup temp files and rename
		mv "$video" "$video.original.mkv" && echo "INFO: Renamed source file"
		mv "$video.merged.mkv" "$video" && echo "INFO: Renamed temp file"
		rm "$video.original.mkv" && echo "INFO: Deleted source file"
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

if [ ${VIDEO_SMA} = TRUE ] || [ ${VIDEO_MKVCLEANER} = TRUE ]; then
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
