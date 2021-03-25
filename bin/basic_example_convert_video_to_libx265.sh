#!/bin/bash
####
# Basic example to implement conversion of videos to libx265 mkv
#
####
# @since 2021-03-25
# @author stev leibelt <artodeto@bazzline.net>
####

SCRIPT_PATH=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)

PATH_TO_THE_CORE_SCRIPT="${SCRIPT_PATH}/_basic_example_core.sh"

if [[ ! -f "${PATH_TO_THE_CORE_SCRIPT}" ]];
then
    echo ":: Could not load core."
    echo "   File >>${PATH_TO_THE_CORE_SCRIPT}<< not available."
    
    exit 1
fi

. "${PATH_TO_THE_CORE_SCRIPT}"

####
# @param: <string> SOURCE_FILE_PATH
# @param: <string> PATH_TO_THE_PROCESS_LIST
# @param: <string> DESTINATION_FILE_PATH
function create_process_list_entry ()
{
    local SOURCE_FILE_PATH="${1}"
    local PATH_TO_THE_PROCESS_LIST="${2}"
    local DESTINATION_FILE_PATH="${3}"

    echo "ffmpeg -i \"${FILE_PATH}\" -map 0 -acodec copy -scodec copy -vcodec libx265 -nostats -hide_banner -pass 1 \"${DESTINATION_FILE_PATH}\"" >> "${PATH_TO_THE_PROCESS_LIST}"
}

####
# @param: <string> FILE_PATH
####
function create_process_output_file_path ()
{
    local FILE_PATH="${1}"

    #future state
    #${FILE_PATH:0:-4} returns the file path without the dot and the file extension. It is expected that the dot and the
    #   file extension consumes 4 characters, like >>.mp4<<.
    #NEW_FILE_PATH="${FILE_PATH:0:-4}.converted265.mkv"

    #current state, just add >>.converted265.mkv<<
    NEW_FILE_PATH="${FILE_PATH}.converted265.mkv"

    echo "${NEW_FILE_PATH}"
}

####
# @param: <string> WORKING_DIRECTORY
# @param: <string> PATH_TO_THE_FILE_LIST
####
function fill_file_list ()
{
    local WORKING_DIRECTORY="${1}"
    local PATH_TO_THE_FILE_LIST="${2}"

    find "${WORKING_DIRECTORY}" -iname "*.[mM][pP]4" -type f >> "${PATH_TO_THE_FILE_LIST}"
    find "${WORKING_DIRECTORY}" -iname "*.[aA][vV][iI]" -type f >> "${PATH_TO_THE_FILE_LIST}"
    find "${WORKING_DIRECTORY}" -iname "*.[mM][oO][vV]" -type f >> "${PATH_TO_THE_FILE_LIST}"
    find "${WORKING_DIRECTORY}" -iname "*.[fF][lL][vV]" -type f >> "${PATH_TO_THE_FILE_LIST}"
}

start_main ${@}
