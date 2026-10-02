#!/usr/bin/with-contenv bash
version="2.0"

installDependencies () {
  echo "Installing script dependencies...."
  if apk --no-cache list | grep installed | grep mkvtoolnix | read; then
    echo "Dependencies already installed, skipping..."
  else
    apk add  -U --update --no-cache \
      jq \
      xq \
      git \
      opus-tools \
      mkvtoolnix \
      ffmpeg
    echo "done"
  fi

	# Delete SMA Folder
	if [ -d /config/scripts/sma ]; then
	  rm -rf /config/scripts/sma
	fi

	# Create SMA Folder
	if [ ! -d /config/scripts/sma ]; then
	  mkdir -p /config/scripts/sma
	  chmod 777 /config/scripts/sma
	fi
	
	echo "************ setup directory ************"
	mkdir -p /config/scripts/sma
	echo "************ download repo ************"
	git clone https://github.com/mdhiggins/sickbeard_mp4_automator.git /config/scripts/sma
	mkdir -p /config/scripts/sma/config
	echo "************ create logging file ************"
	mkdir -p /config/scripts/sma/config
	touch /config/scripts/sma/config/sma.log
	echo "************ install pip dependencies ************"
	pip install --upgrade pip --no-cache-dir --break-system-packages
	pip install -r /config/scripts/sma/setup/requirements.txt --no-cache-dir --break-system-packages
	chmod 777 -R /config/scripts/sma
}

installDependencies

# Create Script Folder
if [ ! -d /config/scripts ]; then
  mkdir -p /config/scripts
fi

if [ ! -f /config/scripts/settings.conf ]; then
	echo "Download Settings config..."
	curl "https://raw.githubusercontent.com/RandomNinjaAtk/sabnzbd-scripts/refs/heads/master/setting.conf" -o /config/scripts/settings.conf
	echo "Done"
fi

echo "Downloading Video script: /config/scripts/video.bash"
curl "https://raw.githubusercontent.com/RandomNinjaAtk/sabnzbd-scripts/refs/heads/master/video.bash" -o /config/scripts/video.bash


echo "Downloading SMA config: /config/scripts/autoProcess.ini"
curl "https://raw.githubusercontent.com/RandomNinjaAtk/sabnzbd-scripts/refs/heads/master/video.bash" -o /config/scripts/autoProcess.ini

# Set Permissions
chmod 777 -R /config/scripts

exit
