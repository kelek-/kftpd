#!/bin/bash

#************************************************************#
#                     k-mp3linker_main.sh                    #
#                        written by |k                       #
#                          v0.1.1dev                         #
#                          21.09.15                          #
#                                                            #
#     Link your mp3 files clean into sorted directories      #
#************************************************************#


#------------------------------------------------------------#
#                         Known Bugs                         #
#------------------------------------------------------------#
# - None so far                                              #
#------------------------------------------------------------#
#                           Todo                             #
#------------------------------------------------------------#
# - Tons of stuff                                            #
# + NEXT UP: year linker fixing + add clean for symlinks     #
#------------------------------------------------------------#


#------------------------------------------------------------#
#                       Version History                      #
#------------------------------------------------------------#
#                                                            #
# v0.1.1dev: - Added commandline argument parsing            #
#            - Added log settings and log function           #
#            - Added version informations                    #
#                                                            #
# v0.1dev  :  - Initial version                              #
#------------------------------------------------------------#

#------------------------------------------------------------#
#                         SETTINGS                           #
#------------------------------------------------------------#

#
# path to /site in glftpd
#
readonly GLFTPD_ROOT_PATH="/glftpd"

#
# path to the parent directory of the sorted directories (relative from the glftpd root directory)
#
readonly SORTED_PATH="site/+sorted"


#
# path for the symlinks for every linker
# set to "" if you don't want to use it
#
readonly ALPHA_PATH="${SORTED_PATH}/alpha"
readonly ARTIST_PATH="${SORTED_PATH}/artist"
readonly CAC_PATH="${SORTED_PATH}/chopped.and.screwed"
readonly GENRE_PATH="${SORTED_PATH}/genre"
readonly GROUP_PATH="${SORTED_PATH}/group"
readonly LANGUAGE_PATH="${SORTED_PATH}/language"
readonly MIXTAPE_PATH="${SORTED_PATH}/mixtape"
readonly REMIX_PATH="${SORTED_PATH}/remix"
readonly SINGLE_PATH="${SORTED_PATH}/single"
readonly SOURCE_PATH="${SORTED_PATH}/source"
readonly YEAR_PATH="${SORTED_PATH}/year"

#
# Add all mp3 paths here (one per line)
# You can use ? for 1 char matching and * for wildcard matching 
#
declare -ar MP3_PATHS=(
  ${GLFTPD_ROOT_PATH}/site/mp3/_archive
  ${GLFTPD_ROOT_PATH}/site/mp3/????
)

#
# Regular expression to skip certain directories (like nukes and such)
# Only the directory itself is checked, the path is not included
#
readonly IGNORE_PATTERN="^\[(inc\!|\!(nfo|sfv|inc)|nuked)\]"

#
# path to the mp3info binary (get the source from: http://ibiblio.org/mp3info/)
#
readonly MP3INFO="/glftpd/bin/mp3info"


#
# debug flag to get a more verbose output
#
readonly DEBUG=true

#
# log file
#
readonly LOG_FILE="mp3linker.log"

#
# log behaviour
# stdout: log to stdout; file: log to file; all: log to file and stdout
#
readonly LOG_OUTPUT_LEVEL="all"

#------------------------------------------------------------#
#                       SETTINGS END                         #
#------------------------------------------------------------#
readonly VERSION="0.1dev"
readonly VERSION_DATE="21.09.2015"

#------------------------------------------------------------#
#                         INCLUDES                           #
#------------------------------------------------------------#
source k-mp3linker_alpha_linker.sh
source k-mp3linker_year_linker.sh
source k-mp3linker_language_linker.sh


###
# MP3Linker::log ()
#------------------------------------------------------------#
# Description:                                               #
#   Log messages to stdout or to the logfile                 #
# Globals:                                                   #
#   LOG_FILE                                                 #
#   LOG_OUTPUT_LEVEL                                         #
# Arguments:                                                 #
#   $1: The message to output/log                            #
#   $2: Optional. Change the log behaviour for the current   #
#       message. Valid values: file, stdout, all             #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::log () {
  local message="${1}"
  local logLevel=""

  if [ "${2}" ]; then
    logLevel="${2}"
  else
    loglevel=${LOG_OUTPUT_LEVEL}
  fi

  case "${loglevel}" in
    file)
      echo "${message}" >> "${LOG_FILE}"
    ;;
    stdout)
      echo "${message}"
    ;;
    all)
      echo "[$(date +'%d.%m.%y/%H:%m:%S')] ${message}" >> "${LOG_FILE}"
      echo "${message}"
    ;;
    *)
    ;;
  esac
} # END function MP3Linker::log


###
# MP3Linker::validate_settings ()
#------------------------------------------------------------#
# Description:                                               #
#  Validate settings for all neccessarry parts               #
# Globals:                                                   #
#   ALPHA_PATH                                               #
#   ARTIST_PATH                                              #
#   CAC_PATH                                                 #
#   GENRE_PATH                                               #
#   GROUP_PATH                                               #
#   LANGUAGE_PATH                                            #
#   MIXTAPE_PATH                                             #
#   REMIX_PATH                                               #
#   SINGLE_PATH                                              #
#   SOURCE_PATH                                              #
#   YEAR_PATH                                                #
#   MP3_PATHS                                                #
#   GLFTPD_ROOT_PATH                                         #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None, but exits on invalid settings                      #
#------------------------------------------------------------#
function MP3Linker::validate_settings () {
  local success=true

  # check for the mp3info binary
  if [[ ! -f "${MP3INFO}" ]] || [[ ! -x "${MP3INFO}" ]] || [[ -z "${MP3INFO}" ]]; then
    echo "ERROR: The mp3info binary does not exist at the specified path, is not executable for the current user or the variable MP3INFO is not set at all."
    echo "       You can download MP3Info from http://ibiblio.org/mp3info/ and build it on your own."
    exit 1
  fi

  # check the site path
  if [[ ! -d "${GLFTPD_ROOT_PATH}" ]] || [[ ! "${GLFTPD_ROOT_PATH}" ]]; then
    echo "ERROR: 'GLFTPD_ROOT_PATH' is not set or does not exist."
    exit 1
  fi

  # check the mp3 paths
  if [[ "${MP3_PATHS}" ]]; then
    for mp3Path in "${MP3_PATHS[@]}"; do
      if [[ ! -d "${mp3Path}" ]] || [[ ! -r "${mp3Path}" ]]; then
        echo "ERROR: ${mp3Path}, which is defined in MP3_PATHS does not exist or is not readable for the current user."
        exit 1
      fi
    done
  else
    echo "ERROR: 'MP3_PATHS' not defined, although it's a neccessary variable."
    exit 1
  fi

  # check the log file
  if [[ ! -e "${LOG_FILE}" ]] || [[ ! -w "${LOG_FILE}" ]]; then
    echo "ERROR: 'LOGFILE' is set, but it does not exist or is not writable for the current user."
    exit 1
  fi

  # check the log level
  if [[ ! "${LOG_OUTPUT_LEVEL}" =~ ^(file|stdout|all)$ ]]; then
    echo "ERROR: invalid 'LOG_OUTPUT_LEVEL' value set."
    echo "Valid values: file, stdout, all"
    exit 1
  fi

  # check the paths of all linker
  if [[ ! -d "${GLFTPD_ROOT_PATH}/${ALPHA_PATH}" ]] || [[ ! -w "${GLFTPD_ROOT_PATH}/${ALPHA_PATH}" ]] && [[ -n "${GLFTPD_ROOT_PATH}/${ALPHA_PATH}" ]]; then
    echo "ERROR: 'ALPHA_PATH' is set, but the directory does not exist or it is not writeable for the current user."
    success=false
  fi

  if [[ ! -d "${GLFTPD_ROOT_PATH}/${ARTIST_PATH}" ]] || [[ ! -w "${GLFTPD_ROOT_PATH}/${ARTIST_PATH}" ]] && [[ -n "${GLFTPD_ROOT_PATH}/${ARTIST_PATH}" ]]; then
    echo "ERROR: 'ARTIST_PATH' is set, but the directory does not exist or it is not writeable for the current user."
    success=false
  fi

  if [[ ! -d "${GLFTPD_ROOT_PATH}/${CAC_PATH}" ]] || [[ ! -w "${GLFTPD_ROOT_PATH}/${CAC_PATH}" ]] && [[ -n "${GLFTPD_ROOT_PATH}/${CAC_PATH}" ]]; then
    echo "ERROR: 'CAC_PATH' is set, but the directory does not exist or it is not writeable for the current user."
    success=false
  fi

  if [[ ! -d "${GLFTPD_ROOT_PATH}/${GENRE_PATH}" ]] || [[ ! -w "${GLFTPD_ROOT_PATH}/${GENRE_PATH}" ]] && [[ -n "${GLFTPD_ROOT_PATH}/${GENRE_PATH}" ]]; then
    echo "ERROR: 'GENRE_PATH' is set, but the directory does not exist or it is not writeable for the current user."
    success=false
  fi

  if [[ ! -d "${GLFTPD_ROOT_PATH}/${GROUP_PATH}" ]] || [[ ! -w "${GLFTPD_ROOT_PATH}/${GROUP_PATH}" ]] && [[ -n "${GLFTPD_ROOT_PATH}/${GROUP_PATH}" ]]; then
    echo "ERROR: 'GROUP_PATH' is set, but the directory does not exist or it is not writeable for the current user."
    success=false
  fi

  if [[ ! -d "${GLFTPD_ROOT_PATH}/${LANGUAGE_PATH}" ]] || [[ ! -w "${GLFTPD_ROOT_PATH}/${LANGUAGE_PATH}" ]] && [[ -n "${GLFTPD_ROOT_PATH}/${LANGUAGE_PATH}" ]]; then
    echo "ERROR: 'LANGUAGE_PATH' is set, but the directory does not exist or it is not writeable for the current user."
    success=false
  fi

  if [[ ! -d "${GLFTPD_ROOT_PATH}/${MIXTAPE_PATH}" ]] || [[ ! -w "${GLFTPD_ROOT_PATH}/${MIXTAPE_PATH}" ]] && [[ -n "${GLFTPD_ROOT_PATH}/${MIXTAPE_PATH}" ]]; then
    echo "ERROR: 'MIXTAPE_PATH' is set, but the directory does not exist or it is not writeable for the current user."
    success=false
  fi

  if [[ ! -d "${GLFTPD_ROOT_PATH}/${REMIX_PATH}" ]] || [[ ! -w "${GLFTPD_ROOT_PATH}/${REMIX_PATH}" ]] && [[ -n "${GLFTPD_ROOT_PATH}/${REMIX_PATH}" ]]; then
    echo "ERROR: 'REMIX_PATH' is set, but the directory does not exist or it is not writeable for the current user."
    success=false
  fi

  if [[ ! -d "${GLFTPD_ROOT_PATH}/${SINGLE_PATH}" ]] || [[ ! -w "${GLFTPD_ROOT_PATH}/${SINGLE_PATH}" ]] && [[ -n "${GLFTPD_ROOT_PATH}/${SINGLE_PATH}" ]]; then
    echo "ERROR: 'SINGLE_PATH' is set, but the directory does not exist or it is not writeable for the current user."
    success=false
  fi

  if [[ ! -d "${GLFTPD_ROOT_PATH}/${SOURCE_PATH}" ]] || [[ ! -w "${GLFTPD_ROOT_PATH}/${SOURCE_PATH}" ]] && [[ -n "${GLFTPD_ROOT_PATH}/${SOURCE_PATH}" ]]; then
    echo "ERROR: 'SOURCE_PATH' is set, but the directory does not exist or it is not writeable for the current user."
    success=false
  fi

  if [[ ! -d "${GLFTPD_ROOT_PATH}/${YEAR_PATH}" ]] || [[ ! -w "${GLFTPD_ROOT_PATH}/${YEAR_PATH}" ]] && [[ -n "${GLFTPD_ROOT_PATH}/${YEAR_PATH}" ]]; then
    echo "ERROR: 'YEAR_PATH' is set, but the directory does not exist or it is not writeable for the current user."
    success=false
  fi
  

  if ! $success; then
    echo "Note: If you want to disable a linker just set it to \"\"."
  else
    echo "Successfully validated the settings!"
  fi
} # END function MP3Linker::validate_settings


###
# MP3Linker::main ()
#------------------------------------------------------------#
# Description:                                               #
#   Entry point function for the MP3Linker                   #
# Globals:                                                   #
#                                                            #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::main () {
  MP3Linker::validate_settings
} # END function MP3Linker::main ()


function MP3Linker::display_help () {
  echo "MP3Linker ${VERSION} (${VERSION_DATE}) by |k"
  echo ""
  echo "Available commandline arguments:"
  echo "    --alpha/-n"
  echo "       Run the alpha linker."
  echo "    --artist/-a"
  echo "       Run the artist linker."
  echo "    --language/-lng"
  echo "       Run the language linker."
  echo "    --year/-y"
  echo "       Run the year linker."
} # END function MP3Linker::display_help ()


# no command line arguments given
if [[ $# -eq 0 ]]; then
  MP3Linker::display_help
  exit 0
fi

# parse command line arguments
while [[ $# > 0 ]]; do
  key="${1}"

  case "${key}" in
    -n|--alpha)
      MP3Linker::Alpha::init
      shift
    ;;
    -a|--artist)
      MP3Linker::Artist::init
      shift
    ;;
    -lng|--language)
      MP3Linker::Language::init
      shift
    ;;
    -y|--year)
      MP3Linker::Year::init
      shift
    ;;
    -l|--clean)
     if [[ ! "${2}" ]] || [[ ! "${2,,}" =~ ^(alpha|artist|language|year|all)$ ]]; then
       echo "ERROR: Invalid argument for -l/--clean!"
       echo "       Valid: Alpha, Artist, Language, Year."
       echo "       To clean all symlinks from every linker use 'all'."
       exit 1
     fi

     # IMPORTANT! Always validate the settings beforehand
     MP3Linker::validate_settings
     linker="${2^^}"
     case "${linker}" in
       ALPHA)
         MP3Linker::Alpha::check_symlinks
       ;;
       ARTIST)
         MP3Linker::Artist::check_symlinks
       ;;
       LANGUAGE)
         MP3Linker::Language::check_symlinks
       ;;
       YEAR)
         MP3Linker::Year::check_symlinks
       ;;
       ALL)
        MP3Linker::Alpha::check_symlinks
        MP3Linker::Artist::check_symlinks
        MP3Linker::Language::check_symlinks
        MP3Linker::Year::check_symlinks
       ;;
     esac
    shift
    ;;
    -c|--check)
      MP3Linker::validate_settings
      shift
    ;;
    -h|--help)
      MP3Linker::display_help
      shift
    ;;
    *)
      exit 0
    ;;
  esac
done

exit 0
