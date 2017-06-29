#!/usr/bin/env bash
######################################################
# Name:             processcue.sh
# Author:           Ludovic Delafontaine
# Création:         29.05.2016
# Description:      Process audio files to split/create audio files from a CUE file.
# Documentation:    https://github.com/ludelafo/processcue.sh
######################################################

######################################################
# In case of problems, stops the script
set -e
set -u

######################################################
# Consts - Change here if needed
######################################################
MOVE_FILES=false
DELETE_UNWANTED_FILES=false # Only keeps FLACs, lyrics and cover.jpg by default

ENCODER="$(flac --version) --compression-level-8"
COVER_FILE="cover.jpg"

SOURCE_FOLDER="/media/2936714f-f614-440f-a803-23228feeb836/Temp/Downloads"
DESTINATION_FOLDER="/media/2936714f-f614-440f-a803-23228feeb836/Temp/Temp"

TEMP_PATH="/dev/shm"
TEMPLATE_CUE="$TEMP_PATH/template.cue"
TEMP_CUE="$TEMP_PATH/metadata.cue"
CLEAN_CUE="$TEMP_PATH/clean-metadata.cue"
LOG_FILE="/tmp/workflac.log"

INFO_TO_KEEP=(
    PERFORMER
    TITLE
    FILE
    TRACK
    FLAGS
    INDEX
)

######################################################
# Functions
######################################################

cleanCue() {

    cueFile="$1"
    templateCueFile="$2"
    output="$3"

    sed -i 's/ FLAC/ WAVE/g' "$cueFile"
    sed -i 's/ APE/ WAVE/g' "$cueFile"
    grep --word-regexp --file "$templateCueFile" "$cueFile" > "$output"

}

splitFlac() {

    cue="$1"
    musicFile="$2"
    outputFolder="$3"

    shnsplit -q -f "$cue" -t "%n - %t" -o "flac flac --silent --compression-level-8 --verify --output-name %f -" -d "$outputFolder/" -O "never" "$musicFile"

}

addEncoder() {

    encoder="$1"
    music="$2"
    metaflac --set-tag="ENCODER=$encoder" "$music"

}

tagFlac() {

    cueFile="$1"
    source="$2"

    cuetag "$cueFile" "$source"/*.flac

}

moveFiles() {

    sourceDirectory="$1"
    destinationDirectory="$2"
    mkdir -p "$destinationDirectory"
    mv "$sourceDirectory" "$destinationDirectory"

}

log() {

    message="$1"
    echo "$message"
    echo "$message" >> "$LOG_FILE"

}

splitFlacRecursivly() {

    sourceFolder="$1"

    for cueFile in $(find "$sourceFolder" -type f -name "*.cue" | sort); do

        musicFile="${cueFile%.*}"
        musicFileFound=true

        if [[ -f "$musicFile.flac" ]]; then
            musicFile="$musicFile.flac"
        elif [[ -f "$musicFile.ape" ]]; then
            musicFile="$musicFile.ape"
        #elif [[ -f "$musicFile.wv" ]]; then
        #    musicFile="$musicFile.wv"
        else
            musicFileFound=false
            #log "The file '$cueFile' has not found any album file !"
        fi

        if $musicFileFound; then

            echo "Processing $musicFile..."

            cueParentFolder="${cueFile%/*}"

            cleanCue "$cueFile" "$TEMPLATE_CUE" "$CLEAN_CUE"
            splitFlac "$CLEAN_CUE" "$musicFile" "$cueParentFolder"

            if [[ "$?" -eq 0 ]]; then
                rm --force "$cueFile"
                rm --force "$musicFile"
                rm --force "$cueParentFolder/00 - pregap.flac"

                tagFlac "$CLEAN_CUE" "$cueParentFolder"
            fi

            for flacFile in $(find "$cueParentFolder" -type f -name "*.flac" | sort); do
                addEncoder "$ENCODER" "$flacFile"
            done

            if $DELETE_UNWANTED_FILES; then
                deleteUnwantedFiles "$cueParentFolder"
            fi

            if $MOVE_FILES; then
                moveFiles "$cueParentFolder" "$DESTINATION_FOLDER"
            fi

        fi

    done
}

joinFlac() {

    folder="$1"

    indexes=($(shntool cue "$folder"/*.flac | grep INDEX))

    files=($(find $folder -type f -name "*.flac" | sort))

    firstTrack=${files[0]}

    artist=$(metaflac --show-tag=ARTIST "$firstTrack")
    artist=${artist#ARTIST=}

    album=$(metaflac --show-tag=ALBUM "$firstTrack")
    album=${album#ALBUM=}

    template="$folder/$artist - $album"

    cueFile="$template.cue"

    shntool join "$folder"/*.flac -o flac -a "$template" -q

    echo "PERFORMER \"$artist\"" > $cueFile
    echo "TITLE \"$album\"" >> $cueFile
    echo "FILE \"$artist - $album.flac\" WAVE" >> $cueFile

    trackNumber=0

    for music in ${files[@]}; do

        title=$(metaflac --show-tag=TITLE "$music")
        title=${title#TITLE=}

        index=$(echo ${indexes[$trackNumber]})

        trackNumber=$((trackNumber+1))

        printf "  TRACK %02d AUDIO\n" "$trackNumber" >> "$cueFile"
        printf "    TITLE \"%s\"\n" "$title" >> "$cueFile"
        printf "    PERFORMER \"%s\"\n" "$artist" >> "$cueFile"
        printf "    $index\n" >> "$cueFile"

        rm $music

    done

}

deleteUnwantedFiles() {

    directory="$1"
    find $directory ! -name "*.flac" ! -name "$COVER_FILE" ! -name "*.srt" -type f -exec rm {} +

}

######################################################
# Script
######################################################
# Enable "Internal Field Separateur" to allow filenames with spaces
IFS=$'\n'

rm --force "$LOG_FILE"

printf "%s\n" "${INFO_TO_KEEP[@]}" > "$TEMPLATE_CUE"

#joinFlac "/home/ludelafo/Music/Temp/Album"
splitFlacRecursivly "$SOURCE_FOLDER"

echo "Everthing is done. Exiting program."
