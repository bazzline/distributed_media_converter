#!/bin/bash
####
# Basic example to implement conversion of images to webp
#
####
# @since 2021-02-25
# @author stev leibelt <artodeto@bazzline.net>
####

####
# Askes the user if we should remove each file in the process list file.
# Askes the user if the process list file should be removed
####
# @param: <string> PATH_TO_THE_FILE_LIST
####
# @since 2021-02-25
# @author stev leibelt <artodeto@bazzline.net>
####
function cleanup ()
{
    if [[ $# -lt 1 ]];
    then
        echo ":: Invalid amount of arguments provided!"
        echo "   cleanup <string: PATH_TO_THE_FILE_LIST> <string: PATH_TO_THE_PROCESS_LIST>"

        return 1
    fi

    local PATH_TO_THE_FILE_LIST="${1}"
    local PATH_TO_THE_PROCESS_LIST="${2}"

    if [[ ! -f "${PATH_TO_THE_FILE_LIST}" ]];
    then
        echo ":: Invalid path to the file list provieded!"
        echo "   >>${PATH_TO_THE_FILE_LIST}<< is not a file."

        return 2
    fi

    if [[ ! -f "${PATH_TO_THE_PROCESS_LIST}" ]];
    then
        echo ":: Invalid path to the process list provieded!"
        echo "   >>${PATH_TO_THE_PROCESS_LIST}<< is not a file."

        return 2
    fi

    local NUMBER_OF_FILE_LIST_ENTRIES=$(cat "${PATH_TO_THE_FILE_LIST}" | wc -l)
    local NUMBER_OF_PROCESS_LIST_ENTRIES=$(cat "${PATH_TO_THE_PROCESS_LIST}" | wc -l)

    echo ":: The file list >>${PATH_TO_THE_FILE_LIST}<< contains >>${NUMBER_OF_FILE_LIST_ENTRIES}<<."
    echo ":: The process list >>${PATH_TO_THE_PROCESS_LIST}<< contains >>${NUMBER_OF_PROCESS_LIST_ENTRIES}<<."

    read -p ":: Remove each file from the file list? [N/y]" YES_OR_NO

    case ${YES_OR_NO} in
        [Yy]* )
            local REMOVE_ENTRIES_IN_FILE=1
            ;;
        *) local REMOVE_ENTRIES_IN_FILE=0
            ;;
    esac

    read -p ":: Remove the lists? [Y/n]" YES_OR_NO

    case ${YES_OR_NO} in
        [Nn]* )
            local REMOVE_LIST=0
            ;;
        *) local REMOVE_LIST=1
            ;;
    esac

    if [[ ${REMOVE_ENTRIES_IN_FILE} -eq 1 ]];
    then
        echo ":: Removing files from the list."

        while read FILE_PATH;
        do
            if [[ -f "${FILE_PATH}" ]];
            then
                rm "${FILE_PATH}"
            else
                echo "   Skipping invalid file path."
                echo "   >>${FILE_PATH}<<"
            fi
        done < ${PATH_TO_THE_FILE_LIST}
    fi

    if [[ ${REMOVE_LIST} -eq 1 ]];
    then
        echo ":: Removing file list."
        rm "${PATH_TO_THE_FILE_LIST}"
        echo ":: Removing process list."
        rm "${PATH_TO_THE_PROCESS_LIST}"
    fi
}

####
# Creates a file list containing all jpg or png files.
####
# [@param: <string> WORKING_DIRECTRY]
# [@param: <string> PATH_TO_THE_FILE_LIST]
####
# @since 2021-02-25
# @author stev leibelt <artodeto@bazzline.net>
####
function create_file_list ()
{
    if [[ $# -gt 0 ]];
    then
        local WORKING_DIRECTORY="${1}"
    else
        local WORKING_DIRECTORY=$(pwd)
    fi

    if [[ $# -gt 1 ]];
    then
        local PATH_TO_THE_FILE_LIST="${2}"
    else
        local PATH_TO_THE_FILE_LIST="${WORKING_DIRECTORY}/files_to_process.txt"
    fi

    if [[ ! -d "${WORKING_DIRECTORY}" ]];
    then
        echo ":: Invalid working directory provided."
        echo "   >>${WORKING_DIRECTORY}<< is not a directory."

        return 1
    fi

    if [[ -f "${PATH_TO_THE_FILE_LIST}" ]];
    then
        echo ":: Removing existing file."
        echo "   >>${PATH_TO_THE_FILE_LIST}<<"

        rm "${PATH_TO_THE_FILE_LIST}"
    fi

    #we simple don't want to deal with files like >>./foo/bar.jpg<<
    #it is way easier if we only have full qualified file paths like /baz/foo/bar.jpg
    if [[ "${WORKING_DIRECTORY}" == "." ]];
    then
        #makes a >>/baz/foo<< out of a >>.<<
        local WORKING_DIRECTORY=$(realpath ${WORKING_DIRECTORY})
    fi

    #echo "find \"${WORKING_DIRECTORY}\" -iname \"*.[jJ][pP][gG]\" -type f > \"${PATH_TO_THE_FILE_LIST}\""
    #
    #check if following is even better
    #@see: https://stackoverflow.com/a/19009672
    #find "${WORKING_DIRECTORY}" -type f -exec file {} \; | grep -o -P '^.+: \w+ image' > "${PATH_TO_THE_FILE_LIST}"
    find "${WORKING_DIRECTORY}" -iname "*.[jJ][pP][gG]" -type f > "${PATH_TO_THE_FILE_LIST}"
    find "${WORKING_DIRECTORY}" -iname "*.[pP][nN][gG]" -type f >> "${PATH_TO_THE_FILE_LIST}"

    local NUMBER_OF_FILE_LIST_ENTRIES=$(cat "${PATH_TO_THE_FILE_LIST}" | wc -l)

    echo ":: Added >>${NUMBER_OF_FILE_LIST_ENTRIES}<< lines to the file >>${PATH_TO_THE_FILE_LIST}<<."
}

####
# Reads the provided path to a list line by line and creates another file with one action per line
####
# @param: <string> PATH_TO_THE_FILE_LIST
# @param: <string> PATH_TO_THE_PROCESS_LIST
####
function create_process_list ()
{
    if [[ $# -lt 2 ]];
    then
        echo ":: Invalid amount of parameters provided"
        echo "   process_list <path to the file list> <path to the process list>"
    fi

    local IMAGE_QUALITY=80
    local NUMBER_OF_PROCESSED_ENTRIES=0
    local NUMBER_OF_CREATED_ENTRIES=0
    local PATH_TO_THE_FILE_LIST="${1}"
    local PATH_TO_THE_PROCESS_LIST="${2}"

    echo ":: Processing list."

    #possible improvement
    #extend existing process file with the command to do (or create new one)
    #run this file list in parallen
    #@see: https://opensource.com/article/18/5/gnu-parallel
    #parallel --jobs 6 < jobs2run
    ####
    #@todo
    #   -> rewrite this function to be "generate_process_list"
    #   -> write new run_process_list <string: path to the process list> <int: number of parallel process: 2>
    #   -> in the main function, add support for providing number of parallel processes

    while read FILE_PATH;
    do
        if [[ -f ${FILE_PATH} ]];
        then
            #${FILE_PATH:0:-4} returns the file path without the dot and the file extension. It is expected that the dot and the
            #   file extension consumes 4 characters, like >>.jpg<<.
            NEW_FILE_PATH="${FILE_PATH:0:-4}.webp"

            if [[ -f ${NEW_FILE_PATH} ]];
            then
                echo "   Skipping file path."
                echo "   >>${NEW_FILE_PATH}<< exists already."
            else
                echo "convert \"${FILE_PATH}\" -verbose -quality ${IMAGE_QUALITY} -comment \"made with linux and love\" \"${FILE_PATH:0:-4}.webp\"" >> "${PATH_TO_THE_PROCESS_LIST}"
                #convert "${FILE_PATH}" -verbose -quality ${IMAGE_QUALITY} -comment "made with linux and love" "${FILE_PATH:0:-4}.webp"

                NUMBER_OF_CREATED_ENTRIES=$((NUMBER_OF_CREATED_ENTRIES+1))
            fi
        else
            echo "   Skipping invalid file path."
            echo "   >>${FILE_PATH}<< is not a valid file."
        fi

        NUMBER_OF_PROCESSED_ENTRIES=$((NUMBER_OF_PROCESSED_ENTRIES+1))
    done < ${PATH_TO_THE_FILE_LIST}

    echo ":: Processed >>${NUMBER_OF_PROCESSED_ENTRIES}<< entries, created >>${NUMBER_OF_CREATED_ENTRIES}<< entries."
}

####
# Runs the commands in the process list
####
# @param: <string> PATH_TO_THE_PROCESS_LIST
# @param: <int> NUMBER_OF_PARALLEL_PROCESS
####
function execute_process_list ()
{
    if [[ ${NUMBER_OF_PARALLEL_PROCESS} -lt 2 ]];
    then
        echo ":: Skippin parallel processing."
        /usr/bin/bash "${PATH_TO_THE_PROCESS_LIST}"
    else
        echo ":: Running >>${NUMBER_OF_PARALLEL_PROCESS}<< proceses in parallel."
        /usr/bin/parallel --jobs ${NUMBER_OF_PARALLEL_PROCESS} < "${PATH_TO_THE_PROCESS_LIST}"
    fi
}

####
# Does all the magic
####
# [@param: <string> WORKING_DIRECTORY=.]
# [@param: <int> NUMBER_OF_PARALLEL_PROCESS=2]
####
function basic_example()
{
    if [[ ! -d /usr/include/webp ]];
    then
        echo ":: Webp is not installed."
        echo "   Could not find directory >>/usr/include/webp<<"
    fi

    if [[ -f /usr/bin/parallel ]];
    then
        local NUMBER_OF_PARALLEL_PROCESS=${2:-2}
    else
        local NUMBER_OF_PARALLEL_PROCESS=1

        echo ":: Parallel is not installed."
        echo "   >>/usr/bin/parallel<< is missing."
        echo "   Parallel processing is disabled."
    fi

    if [[ $# -gt 0 ]];
    then
        local WORKING_DIRECTORY="${1}"
    else
        local WORKING_DIRECTORY=$(pwd)
    fi

    local PATH_TO_THE_FILE_LIST=$(mktemp)
    local PATH_TO_THE_PROCESS_LIST=$(mktemp)

    create_file_list ${WORKING_DIRECTORY} ${PATH_TO_THE_FILE_LIST}
    create_process_list ${PATH_TO_THE_FILE_LIST} ${PATH_TO_THE_PROCESS_LIST}
    execute_process_list ${PATH_TO_THE_PROCESS_LIST} ${NUMBER_OF_PARALLEL_PROCESS}
    cleanup ${PATH_TO_THE_FILE_LIST} ${PATH_TO_THE_PROCESS_LIST}
}

basic_example ${@}
