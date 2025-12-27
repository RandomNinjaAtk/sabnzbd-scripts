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
1. Add `video.bash` script to the appropriate SABnzb category, if categories do not exist, create a `radarr` or `sonarr` category, and use the same category name for the folder path.

## Scripts:

### video.bash
This script is used to post process files in SABnzbd before Arr apps pickup the files. This script can validate the audio/subtitle tracks, strip unwanted tracks and it will remux the file to MKV format for standardization. Ideally when configured to for a specific language, this script will ensure all downloads are validated to meet a minimum requirement of having the required language in either subtitle or audio track and will only keep other languages when it was the original audio language of the video. Thus fully automating validation of files and performing a cleanup. Files that don't meet the requirements are automitically purged and the donwload is marked as failed to allow the Arr apps to try again.
