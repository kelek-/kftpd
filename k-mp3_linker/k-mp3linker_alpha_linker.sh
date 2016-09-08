#! /bin/bash

#************************************************************#
#                k-mp3linker_alpha_linker.sh                 #
#                      written by |k                         #
#                         v0.2dev                            #
#                       21.09.2015                           #
#                                                            #
#         Link releasenames with their first char            #
#                                                            #
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
# MP3Linker::Alpha::init ()
#------------------------------------------------------------#
# Description:                                               #
#  Initialize the linker                                     #
# Globals:                                                   #
#   ALPHA_PATH                                               #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None, but exits on invalid settings                      #
#------------------------------------------------------------#
function MP3Linker::Alpha::init () {
  if [[ ! "${ALPHA_PATH}" ]]; then
    MP3Linker::log "ERROR: You can't use the alpha linker, when ALPHA_PATH is not defined."
    exit 1
  fi

  MP3Linker::Alpha::setup
  MP3Linker::Alpha::link
} # END function MP3Linker::Alpha::init ()


###
# MP3Linker::Alpha::setup ()
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
function MP3Linker::Alpha::setup () {
  for char in 0 1 2 3 4 5 6 7 8 9 0 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \#; do
    MP3Linker::Alpha::create_directories "$char"
  done
} # END function MP3Linker::Alpha::create_directories ()


###
# MP3Linker::Alpha::create_directories ()
#------------------------------------------------------------#
# Description:                                               #
#  Create the alpha directories                              #
# Globals:                                                   #
#   GLFTPD_ROOT_PATH                                         #
#   ALPHA_PATH                                               #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::Alpha::create_directories () {
  if [ ! "$1" ]; then
    MP3Linker::log "ERROR: MP3Linker::Alpha::create_directories did not recieve an argument"
    return 1
  fi
  local directory="$1"
  if [[ ! -e "${GLFTPD_ROOT_PATH}/${ALPHA_PATH}/${directory}" ]]; then
    MP3Linker::log "INFO: '${directory}' does not exist for alpha linking, creating it."
    mkdir "${GLFTPD_ROOT_PATH}/${ALPHA_PATH}/${directory}"
  fi
} # END function MP3Linker::Alpha::create_directories ()


###
# MP3Linker::Alpha::link ()
#------------------------------------------------------------#
# Description:                                               #
#  Create symbolic links to the alpha directory              #
# Globals:                                                   #
#   MP3_PATHS                                                #
#   IGNORE_PATTERN                                           #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::Alpha::link () {
  set -o pipefail
  for mp3Path in "${MP3_PATHS[@]}"; do
    for release in "${mp3Path}/"*; do
      local releaseName=$(basename "${release}")
      
      # skip all not needed directories
      if [[ ${releaseName} =~ ${IGNORE_PATTERN} ]]; then
	MP3Linker::log "INFO: Skipping ${releaseName}"
        continue
      fi
      
      # get the first char of the releasename, convert it to upper 
      # and change the folder to the corresponding alpha directory
      # when the first char is anything other besides [:alnum:] we use # as folder
      char=${releaseName:0:1}
      char=$(echo ${char^^})
      if [[ ! ${char} =~ [[:punct:]] ]]; then
        cd "${GLFTPD_ROOT_PATH}/${ALPHA_PATH}/${char}"
      else
        cd "${GLFTPD_ROOT_PATH}/${ALPHA_PATH}/#"
      fi

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

      if [[ ! -e "./${releaseName}" ]]; then
        if $DEBUG; then
          MP3Linker::log "DEBUG: Linking ${releaseName} to $(pwd)"
        fi
        ln -s "${symlink}" .
      fi

    done
  done
} # END MP3Linker::Alpha::link ()


###
# MP3Linker::Alpha::check_symlinks ()
#------------------------------------------------------------#
# Description:                                               #
#  Check all symlinks and delete broken ones.                #
# Globals:                                                   #
#   ALPHA_PATH                                               #
#   GLFTPD_ROOT_PATH                                         #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::Alpha::check_symlinks () {
  if [[ ! "${ALPHA_PATH}" ]]; then
    MP3Linker::log "ERROR: You can't clean alpha symlinks, when ALPHA_PATH is not defined."
    exit 1
  fi

  local dead=0
  for char in "${GLFTPD_ROOT_PATH}/${ALPHA_PATH}/"*; do

    # special treatment for '#', which would - w/o escaping - take us to /
    if [[ "${char}" =~ '#' ]]; then
      cd "${GLFTPD_ROOT_PATH}/${ALPHA_PATH}/#"
    else
      cd "${char}"
    fi

    for symlink in "${char}/"*; do
      # symlinks is broken, so remove it
      if [ ! -e "${symlink}" ]; then
        MP3Linker::log "Removing dead symlink ${symlink}"
        unlink "${symlink}"
        ((dead++))
      fi
    done
  done

  if [[ "${dead}" > 0 ]]; then
    MP3Linker::log "INFO: Removed ${dead} dead symlinks from the alpha directory."
  else
    MP3Linker::log "INFO: No dead alpha symlinks found!"
  fi
} # END MP3Linker::Alpha::check_symlinks
