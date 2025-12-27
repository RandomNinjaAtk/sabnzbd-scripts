# sabnzbd-scripts

This project is my own personal documenation for various scripts I've written to improve and further automate the usage of the SABnzbd. Support is not guaranteed, scripts are provided as-is...

## Requirements:

SABnzbd docker container by [Linuxserver.io](https://docs.linuxserver.io/images/docker-sabnzbd/)

## Setup:

1. Add volume to your container: `/custom-cont-init.d` <br>
  Docker Run Example: <br>
  `-v /path/to/preferred/local/directory:/custom-cont-init.d`
1. Download the [script_init.bash](https://github.com/RandomNinjaAtk/sabnzbd-scripts/blob/master/scripts_init.bash) ([Download Link](https://github.com/RandomNinjaAtk/sabnzbd-scripts/raw/refs/heads/master/scripts_init.bash) and place it into the following folder: `/custom-cont-init.d`)
1. Start your container and wait for the application to load
1. Customize the configuration by modifying the following file `/config/scripts/settings.conf`
1. Add the `/config/scripts` folder to the "Scripts Folder" folder setting in SABnzbd
1. Add `video.bash` script to the either the`radarr` or `sonarr` category. If the category does not exist, create the `radarr` or `sonarr` category and use `radarr` or `sonarr` for the folder path.

## Scripts:

### video.bash
This script is used to post process files in SABnzbd before Arr apps pickup the files. What it does:
- Remux all files to MKV
- Validate files have the required audio/subtitle track language
- Strip unwanted audio/subtitle tracks
- Keep the Original Audio Track, only when a subtitle tracks is available in the required language and the downloads original language does not match the required language. It will also keep any other audio tracks that match the required language.
- Mark downloads as failed in SABnzbd, when they don't meet language requirements


## Logging
Logs are generated for each script execution. However, log files are rotated after every 5 executions to only keep the latest 5 log files. Logs can be found in the following folder: `/config/logs`
