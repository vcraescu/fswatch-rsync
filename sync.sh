#!/bin/env bash

LATENCY="1"
LOCAL_PATH="$(pwd)/"
TARGET="viorel.work"
TARGET_PATH="/home/viorel/Projects/trisoft/bestvalue/website"
TARGET_SSH_USER="viorel"
IGNORE_FILE="$LOCAL_PATH/.rsignore"

# check color support
colors=$(tput colors)
if (($colors >= 8)); then
    red='\033[0;31m'
    green='\033[0;32m'
    yellow='\033[0;33m'
    white='\033[0;37m'
    nocolor='\033[00m'
else
  red=
  green=
  yellow=
  white=
  nocolor=
fi

fswatch_excludes() {
    local exclude=""
    while read line; do
        exclude="$exclude -e \"$line\" "
    done < "$1"

    echo "$exclude"
}

watch() {
    local ignored_files=$(fswatch_excludes $IGNORE_FILE)
    eval "fswatch -1 -r -l $LATENCY $LOCAL_PATH $ignored_files --exclude=\"/\.[^/]*$\""
}

sync() {
    rsync --update -avm --no-perms --no-owner --no-group --force --exclude=".*" --exclude-from "$IGNORE_FILE" $LOCAL_PATH $TARGET_SSH_USER@$TARGET:$TARGET_PATH
}

echo -e   "Local source path:  ${green}$LOCAL_PATH${nocolor}"
echo -e   "Remote target path: ${green}$TARGET_PATH${nocolor}"
echo -e   "To target server:   ${green}$TARGET_SSH_USER@$TARGET${nocolor}"
echo      ""
echo      "Performing initial complete synchronization"
echo -e   "${red}Warning: Target directory will be overwritten with local version if differences occur.${nocolor}"

# Perform initial complete sync
echo -e   "${white}Press any key to continue (or abort with Ctrl-C)... ${nocolor}" && read -n1 -r key
echo -e   "${green}Synchronizing...${nocolor}"

sync
echo -e   "\n${green}Done.${nocolor}\n"

# Watch for changes and sync (exclude hidden files)
echo -e   "${white}Watching for changes. Quit anytime with Ctrl-C.${nocolor}"

trap exit SIGINT SIGTERM SIGHUP EXIT

while watch && sync; do
    echo -e "${green}Done.${nocolor}"
done
