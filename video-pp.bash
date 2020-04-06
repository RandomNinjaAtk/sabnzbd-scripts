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
		# video tracks
		VideoTrack=$(echo "${tracks}" | jq '. | .streams | .[] | select (.codec_type=="video") | select(.disposition.default==1) | .index')
		VideoTrackCount=$(echo "${VideoTrack}" | wc -l)
		# video preferred language
		VideoTrackLanguage=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"video\") | select(.tags.language==\"${VIDEO_LANG}\") | .index")
		# audio tracks
		AudioTracks=$(echo "${tracks}" | jq '. | .streams | .[] | select (.codec_type=="audio") | .index')
		AudioTracksCount=$(echo "${AudioTracks}" | wc -l)
		# audio preferred language
		AudioTracksLanguage=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language==\"${VIDEO_LANG}\") | .index")
		AudioTracksLanguageCount=$(echo "${AudioTracksLanguage}" | wc -l)
		# audio unkown laguage
		AudioTracksLanguageUND=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language==\"und\") | .index")
		AudioTracksLanguageUNDCount=$(echo "${AudioTracksLanguageUND}" | wc -l)
		AudioTracksLanguageNull=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"audio\") | select(.tags.language==null) | .index")
		AudioTracksLanguageNullCount=$(echo "${AudioTracksLanguageNull}" | wc -l)
		# subtitle tracks
		SubtitleTracks=$(echo "${tracks}" | jq '. | .streams | .[] | select (.codec_type=="subtitle") | .index')	
		SubtitleTracksCount=$(echo "${SubtitleTracks}" | wc -l)
		# subtitle preferred langauge
		SubtitleTracksLanguage=$(echo "${tracks}" | jq ". | .streams | .[] | select(.codec_type==\"subtitle\") | select(.tags.language==\"${VIDEO_LANG}\") | .index")
		SubtitleTracksLanguageCount=$(echo "${SubtitleTracksLanguage}" | wc -l)
	else
		echo "ERROR: ffprobe failed to read tracks and set values"
		rm "$video" && echo "INFO: deleted: $video"
	fi
	
	# Check for video track
	if [ -z "${VideoTrack}" ]; then
		echo "ERROR: no video track found"
		rm "$video" && echo "INFO: deleted: $filename"
	else
		echo "$VideoTrackCount video track found!"
	fi
	
	# Check for audio track
	if [ -z "${AudioTracks}" ]; then
		echo "ERROR: no audio tracks found"
		rm "$video" && echo "INFO: deleted: $filename"
	else
		echo "$AudioTracksCount audio tracks found!"
	fi
	
	# Check for audio track
	if [ ! -z "${SubtitleTracks}" ]; then
		echo "$SubtitleTracksCount subtitle tracks found!"
	fi
	
	echo "Checking for \"${VIDEO_LANG}\" video/audio/subtitle tracks"
	if [ ! -z "$AudioTracksLanguage" ] || [ ! -z "$SubtitleTracksLanguage" ]; then
		if [ ! ${VIDEO_MKVCLEANER} = TRUE ]; then
			echo "ERROR: No \"${VIDEO_LANG}\" audio or subtitle tracks found..."
			rm "$video" && echo "INFO: deleted: $filename"
			continue
		else
			if [ ! -z "$AudioTracksLanguage" ] || [ ! -z "$SubtitleTracksLanguage" ] || [ ! -z "$AudioTracksLanguageUND" ] || [ ! -z "$AudioTracksLanguageNull" ]; then
				sleep 0.1
			else
				echo "ERROR: No \"${VIDEO_LANG}\" or \"Unknown\" audio tracks found..."
				echo "ERROR: No \"${VIDEO_LANG}\" subtitle tracks found..."
				rm "$video" && echo "INFO: deleted: $filename"
				continue
			fi
		fi
	else
		if [ ! ${VIDEO_MKVCLEANER} = TRUE ]; then
			if [ ! -z "$AudioTracksLanguage" ]; then
				echo "$AudioTracksLanguageCount \"${VIDEO_LANG}\" audio track found..."
			fi
			if [ ! -z "$SubtitleTracksLanguage" ]; then
				echo "$SubtitleTracksLanguageCount \"${VIDEO_LANG}\" subtitle track found..."
			fi
		fi
	fi	
		
	if [ ${VIDEO_MKVCLEANER} = TRUE ]; then
		# Correct video language, if needed...
		if [ -z "$VideoTrackLanguage" ]; then	
			if [ ! -z "$AudioTracksLanguage" ] || [ ! -z "$AudioTracksLanguageUND" ] || [ ! -z "$AudioTracksLanguageNull" ]; then
				SetVideoLanguage="true"
				echo "$VideoTrackCount \"unknown\" video language track found, re-tagging as \"${VIDEO_LANG}\""
				MKVvideo=" -d ${VideoTrack} --language ${VideoTrack}:${VIDEO_LANG}"
			else
				echo "$VideoTrackCount \"foreign\" video tracks found!"
				SetVideoLanguage="false"
				MKVvideo=""
			fi
		else
			echo "$VideoTrackCount \"${VIDEO_LANG}\" video tracks found!"
			SetVideoLanguage="false"
			MKVvideo=""
		fi
	
		# Check for unwanted audio tracks and remove/re-label as needed...
		if [ ! -z "$AudioTracksLanguage" ] || [ ! -z "$AudioTracksLanguageUND" ] || [ ! -z "$AudioTracksLanguageNull" ]; then
			if [ "$AudioTracksCount" -ne "$AudioTracksLanguageCount" ]; then
				RemoveAudioTracks="true"
				if [ ! -z "$AudioTracksLanguage" ]; then
					MKVaudio=" -a ${VIDEO_LANG}"
					echo "$AudioTracksLanguageCount \"${VIDEO_LANG}\" audio tracks found!"
					unwanted=$(($AudioTracksCount-$AudioTracksLanguageCount))
					if [ "$unwanted" -ne "$AudioTracksCount" ]; then
						echo "$unwanted unwanted audio tracks to remove..."
					fi
				elif [ ! -z "$AudioTracksLanguageUND" ]; then
					for I in $AudioTracksLanguageUND
					do
						OUT=$OUT" -a $I --language $I:${VIDEO_LANG}"
					done
					MKVaudio="$OUT"
					echo "$AudioTracksLanguageNullCount \"unknown\" audio tracks found, re-tagging as \"${VIDEO_LANG}\""
					unwanted=$(($AudioTracksCount-$AudioTracksLanguageUND))
					if [ "$unwanted" -ne "$AudioTracksCount" ]; then
						echo "$unwanted unwanted audio tracks to remove..."
					fi
				elif [ ! -z "$AudioTracksLanguageNull" ]; then
					for I in $AudioTracksLanguageNull
					do
						OUT=$OUT" -a $I --language $I:${VIDEO_LANG}"
					done
					MKVaudio="$OUT"
					echo "$AudioTracksLanguageNullCount \"unknown\" audio tracks found, re-tagging as \"${VIDEO_LANG}\""
					unwanted=$(($AudioTracksCount-$AudioTracksLanguageNull))
					if [ "$unwanted" -ne "$AudioTracksCount" ]; then
						echo "$unwanted unwanted audio tracks to remove..."
					fi
				fi
			else
				echo "$AudioTracksLanguageCount \"${VIDEO_LANG}\" audio tracks found!"
				RemoveAudioTracks="false"
				MKVaudio=""
			fi
		elif [ -z "$SubtitleTracksLanguage" ]; then
			echo "ERROR: no \"${VIDEO_LANG}\" audio/subtitle tracks found!"
			rm "$video" && echo "INFO: deleted: $filename"
			continue
		else
			echo "$AudioTracksLanguageCount \"foreign\" audio tracks found!"
			RemoveAudioTracks="false"
			MKVaudio=""
		fi
	
		# Check for unwanted subtitle tracks...
		if [ ! -z "$SubtitleTracks" ]; then	
			if [ "$SubtitleTracksCount" -ne "$SubtitleTracksLanguageCount" ]; then
				RemoveSubtitleTracks="true"
				MKVSubtitle=" -s ${VIDEO_LANG}"
				echo "$SubtitleTracksLanguageCount \"${VIDEO_LANG}\" subtitle tracks found!"
				unwanted=$(($SubtitleTracksCount-$SubtitleTracksLanguageCount))
				if [ "$unwanted" -ne "$SubtitleTracksCount" ]; then
					echo "$unwanted unwanted subtitle tracks to remove..."
				fi
			else
				echo "$SubtitleTracksLanguageCount \"${VIDEO_LANG}\" subtitle tracks found!"
				RemoveSubtitleTracks="false"
				MKVSubtitle=""
			fi
		else
			RemoveSubtitleTracks="false"
			MKVSubtitle=""
		fi
	
		if [ "${RemoveAudioTracks}" = false ] && [ "${RemoveSubtitleTracks}" = false ] && [ "${SetVideoLanguage}" = false ]; then
			echo "INFO: Video passed all checks, no processing needed"
			touch "$video"
			if find "$video" -type f -iname "*.${CONVERTER_OUTPUT_EXTENSION}" | read; then
				continue
			else
				MKVvideo=" -d ${allvideo} --language ${allvideo}:${VIDEO_LANG}"
				MKVaudio=" -a ${VIDEO_LANG}"
				MKVSubtitle=" -s ${VIDEO_LANG}"
			fi
		fi
		basefilename="${video%.*}"
		if mkvmerge --no-global-tags --title "" -o "${basefilename}.merged.mkv"${MKVvideo}${MKVaudio}${MKVSubtitle} "$video"; then
			echo "SUCCESS: mkvmerge complete"
			echo "INFO: Options used:${MKVvideo}${MKVaudio}${MKVSubtitle}"
			# cleanup temp files and rename
			mv "$video" "$video.original" && echo "INFO: Renamed source file"
			mv "${basefilename}.merged.mkv" "${basefilename}.mkv" && echo "INFO: Renamed temp file"
			rm "$video.original" && echo "INFO: Deleted source file"
		else
			echo "ERROR: mkvmerge failed"
			rm "$video" && echo "INFO: deleted: $video"
			continue
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

if [ ${VIDEO_SMA} = TRUE ] || [ ${VIDEO_MKVCLEANER} = TRUE ]; then
	find "$1" -type f ! -newer "$1/sma-conversion-check" ! -name "$1/sma-conversion-check" -delete
	# check for video files
	if find "$1" -type f -iname "*.${CONVERTER_OUTPUT_EXTENSION}" | read; then
		echo "Post Processing Complete!"
	else
		echo "ERROR: Post Processing failed, no video files found..."
		exit 1
	fi
	if [ -f "$1/sma-conversion-check" ]; then 
		rm "$1/sma-conversion-check"
	fi
fi

exit $?
