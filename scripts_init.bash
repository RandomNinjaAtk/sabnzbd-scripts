#!/usr/bin/with-contenv bash

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
}

installDependencies

# Create Script Folder
if [ ! -d /config/scripts ]; then
  mkdir -p /config/scripts
fi

if [ ! -f /config/scripts/settings.conf ]; then
	echo "Download Settings config..."
	curl "https://raw.githubusercontent.com/RandomNinjaAtk/sabnzbd-scripts/refs/heads/master/setting.conf" -o /config/scripts/settings.conf
	chmod 777 /config/scripts/extended.conf
	echo "Done"
fi

echo "Downloading Video script: /config/scripts/video.bash"
curl "https://raw.githubusercontent.com/RandomNinjaAtk/sabnzbd-scripts/refs/heads/master/video.bash" -o /config/scripts/video.bash

# Set Permissions
chmod 777 -R /config/scripts

exit
