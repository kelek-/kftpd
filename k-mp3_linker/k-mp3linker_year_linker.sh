#! /bin/bash

#************************************************************#
#                 k-mp3linker_year_linker.sh                 #
#                       written by |k                        #
#                          v0.2dev                           #
#                        21.09.2015                          #
#                                                            #
#    Link releasenames with their year of the first song     #
#  or if that fails with the year found in the releasename   #
#************************************************************#


#------------------------------------------------------------#
#                         Known Bugs                         #
#------------------------------------------------------------#
# - Linker is creating a symlink to ./* for whatever reason  #
#   ^21.09.15: I don't really know if it is still doing it?! #
#------------------------------------------------------------#
#                           Todo                             #
#------------------------------------------------------------#
# - Nothing at the moment
#------------------------------------------------------------#


#------------------------------------------------------------#
#                       Version History                      #
#------------------------------------------------------------#
#                                                            #
# v0.2dev: - Added check_symlinks to remove dead symlinks    #
#          - Replaced echo with MP3Linker::log               #
#          - Fixed some aesthetical syntax issues            #
#                                                            #
# v0.1dev  - Initial version                                 #
#------------------------------------------------------------#





#------------------------------------------------------------#
#                         CODE BEGIN                         #
#------------------------------------------------------------#

###
# MP3Linker::Year::init ()
#------------------------------------------------------------#
# Description:                                               #
#  Initialize the linker                                     #
# Globals:                                                   #
#   YEAR_PATH                                                #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None, but exists on invalid settings                     #
#------------------------------------------------------------#
function MP3Linker::Year::init () {
  if [[ ! "${YEAR_PATH}" ]]; then
    MP3Linker::log "ERROR: You can't use the year linker, when YEAR_PATH is not defined."
    exit 1
  fi

  MP3Linker::Year::setup
  MP3Linker::Year::link
} # END function MP3Linker::Year::init ()


###
# MP3Linker::Year::setup ()
#------------------------------------------------------------#
# Description:                                               #
#  Setup the linker                                          #
# Globals:                                                   #
#   none                                                     #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::Year::setup () {
  local currentYear=$(date +'%Y')
  for (( year=1970; year<="${currentYear}"; year++)); do
    MP3Linker::Year::create_directories "${year}"
  done

  MP3Linker::Year::create_directories "0000"
  MP3Linker::Year::link
} # END function MP3Linker::Year::setup ()


###
# MP3Linker::Year::create_directories ()
#------------------------------------------------------------#
# Description:                                               #
#  Create the year directories                               #
#-------------+                                              #
# Globals:                                                   #
#  GLFTPD_ROOT                                               #
#  YEAR_PATH                                                 #
#-------------+                                              #
# Arguments:                                                 #
#  None                                                      #
#-------------+                                              #
# Returns:                                                   #
#  None                                                      #
#------------------------------------------------------------#
function MP3Linker::Year::create_directories () {
  if ${DEBUG}; then
    if [[ ! "${@}" =~ [[:digit:]]{4} ]]; then
      MP3Linker::log "DEBUG: MP3Linker::Year::create_directories called with:"
      MP3Linker::log "${@}"
    fi
  fi

  if [ ! "${1}" ]; then
    MP3Linker::log "ERROR: MP3Linker::Year::create_directories did not recieve an argument"
    return 1
  fi

  local directory="${1}"
  if [[ ! -e "${GLFTPD_ROOT_PATH}/${YEAR_PATH}/${directory}" ]]; then
    MP3Linker::log "INFO: '${directory}' does not exist for year linking, creating it."
    mkdir "${GLFTPD_ROOT_PATH}/${YEAR_PATH}/${directory}"
    chmod 777 "${GLFTPD_ROOT_PATH}/${YEAR_PATH}/${directory}"
  fi
} # END function MP3Linker::Year::create_directories ()


###
# MP3Linker::Year::link ()
#------------------------------------------------------------#
# Description:                                               #
#  Create symbolic links to the year directory               #
#-------------+                                              #
# Globals:                                                   #
#  MP3_PATHS                                                 #
#  IGNORE_PATTERN                                            #
#  YEAR_PATH                                                 #
#  DEBUG                                                     #
#-------------+                                              #
# Arguments:                                                 #
#  None                                                      #
#-------------+                                              #
# Returns:                                                   #
#  None                                                      #
#------------------------------------------------------------#
function MP3Linker::Year::link () {
  for mp3Path in "${MP3_PATHS[@]}"; do
    for release in "${mp3Path}/"*; do
      # skip all not needed directories
      if [[ ${releaseName} =~ ${IGNORE_PATTERN} ]]; then
        MP3Linker::log "INFO: Skipping ${releaseName}"
        continue
      fi

      local releaseName=$(basename "${release}")

      # try to get the year from the directory, since there is no mp3 file available
      if ( cd ${release}; shopt -s nullglob dotglob; files=(*.mp3); ((! ${#files[@]} )) ); then
        MP3Linker::log "INFO: ${releaseName} does not contain any MP3 files, getting year from the directory."
 
        if [[ ${releaseName} =~ \-([[:digit:]]{2}([[:digit:]]+|([xX_]{1,2}){0,1}))\- ]]; then
          year="${BASH_REMATCH[1]}"
        else
          MP3Linker::log "ERROR: Unable to extract year from ${releaseName}"
          continue
        fi
      else
        # get the year from the first mp3 file
        for mp3 in "${release}/"*.mp3; do
          year=$("${MP3INFO}" "-p %y" "${mp3}" | tr -d ' ')
          break
        done

        # get the year from the directory if getting it from the mp3 files
        # fails (e.g. no ID3v1 tag) or the year seems obviously incorrect, like '0'
        if [[ -z "${year}" ]] || [[ "${year}" =~ "0{1,4}" ]]; then
          MP3Linker::log "ERROR: Unable to extract year for ${releaseName} from mp3 files, trying to get it from the directory."
          if [[ ${releaseName} =~ \-([[:digit:]]{2,3}([[:digit:]]+|([xX_]{1,2}){0,1}))\- ]]; then
            year="${BASH_REMATCH[1]}"
          else
            MP3Linker::log "ERROR: Unable to extract year from ${releaseName}"
            continue
          fi
        fi

      fi

if [ $year == "0" ]; then
  echo $releaseName
fi
      # fix the year if neccessary
      if [[ "${year}" =~ "^0{1,3}$" ]]; then
        MP3Linker::log "INFO: Fixed year of ${releaseName} to 0000."
        year="0000"
      fi

      # we can assume two digit years are always before 2000, since
      # mp3 rules are harder after 2000
      if [[ "${year}" =~ ^[[:digit:]]{2}$ ]]; then
        year="19${year}"
      fi

      # some years are written with _ instead of x, fix that
      if [[ "${year}" =~ _ ]]; then
        year=$(echo "${year}" | sed 's/_/x/g')
      fi

      if [[ "${year}" =~ [[:digit:]]+(x|X)$ ]]; then
        # lower the X's
        year=${year,,}
        MP3Linker::Year::create_directories "${year}"
      fi

      if [[ $year == "" ]]; then echo ${releaseName}; fi

      # change to the appropriate year folder
      cd "${GLFTPD_ROOT_PATH}/${YEAR_PATH}/${year}"

      # remove the releasename, the glftpd root path and the last /
      # from the path to have a relative path from /glftpd to the release
      local relativePath=$(echo "${release}" | sed -e 's@'"${releaseName}"'@@' -e 's@'"${GLFTPD_ROOT_PATH}"'@@' -e 's@\/$@@')

      # count the slashes, so that we know how many levels we have to go up
      backwards=$(grep -o "/" <<< "${relativePath}" | wc -l)

      # add the levels to the symlink
      local symlink=""
      for (( count=1; count<=backwards; count++ )); do
        symlink="${symlink}../"
      done

      # finally remove the glftpd root path and /site from the release,
      # add it to the symlink and link the release to the current directory
      symlink=${symlink}$(echo ${release} | sed -e 's@'"${GLFTPD_ROOT_PATH}/site/"'@@')

      if [[ "$(echo ${release} | sed -e 's@'"${GLFTPD_ROOT_PATH}/site/"'@@')" == "*" ]]; then
        MP3Linker::log "SKIPPING ${release}"
        continue
      fi

      if [[ ${releaseName} =~ [[:space:]] ]]; then
        MP3Linker::log "ERROR: Space in releasename!"
        MP3Linker::log "${releaseName}"
	continue
      fi

      if [[ ! -L "${releaseName}" ]]; then
        if $DEBUG; then
          MP3Linker::log "DEBUG: Linking ${releaseName} to $(pwd)"
        fi
        ln -s "${symlink}" .
      fi
    done
  done
} # END MP3Linker::Year::link ()

###
# MP3Linker::Year::check_symlinks ()
#------------------------------------------------------------#
# Description:                                               #
#  Check all symlinks and delete broken ones.                #
# Globals:                                                   #
#   YEAR_PATH                                                #
#   GLFTPD_ROOT_PATH                                         #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::Year::check_symlinks () {
  if [[ ! "${YEAR_PATH}" ]]; then
    MP3Linker::log "ERROR: You can't clean year symlinks, when YEAR_PATH is not defined."
    exit 1
  fi

  local dead=0
  for year in "${GLFTPD_ROOT_PATH}/${YEAR_PATH}/"*; do
    cd "${year}"

    for symlink in "${year}/"*; do
      # symlinks is broken, so remove it
      if [ ! -e "${symlink}" ]; then
        MP3Linker::log "Removing dead symlink ${symlink}"
        unlink "${symlink}"
        ((dead++))
      fi
    done
  done

  if [[ "${dead}" > 0 ]]; then
    MP3Linker::log "INFO: Removed ${dead} dead symlinks from the year directory."
  else
    MP3Linker::log "INFO: No dead year symlinks found!"
  fi
} 
