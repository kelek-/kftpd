#! /bin/bash

#************************************************************#
#             k-mp3linker_language_linker.sh                 #
#                     written by |k                          #
#                        v0.1dev                             #
#                       21.09.2015                           #
#                                                            #
#         Link releasenames with their language              #
#************************************************************#


#------------------------------------------------------------#
#                         Known Bugs                         #
#------------------------------------------------------------#
# - None                                                     #
#------------------------------------------------------------#
#                           Todo                             #
#------------------------------------------------------------#
# - Nothing at the moment                                    #
#------------------------------------------------------------#


#------------------------------------------------------------#
#                       Version History                      #
#------------------------------------------------------------#
# v0.1dev  - Initial version                                 #
#------------------------------------------------------------#

#------------------------------------------------------------#
#                         Includes                           #
#------------------------------------------------------------#
source k-mp3linker_valid_languages.conf 


#------------------------------------------------------------#
#                         CODE BEGIN                         #
#------------------------------------------------------------#

# global var for the detect_language function
DETECTED_LANGUAGE=""

###
# MP3Linker::Language::init ()
#------------------------------------------------------------#
# Description:                                               #
#  Initialize the linker                                     #
# Globals:                                                   #
#   LANGUAGE_PATH                                            #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::Language::init () {
  if [[ ! "${LANGUAGE_PATH}" ]]; then
    MP3Linker::log "ERROR: You can't use the language linker, when LANGUAGE_PATH is not defined."
    exit 1
  fi

  if [[ ! "${IGNORED_LANGUAGES}" ]]; then
    MP3Linker::log "ERROR: You can't use the language linker, when IGNORED_LANGUAGES is not defined."
    exit 1
  fi

  #if [[ ! "${MAP_LANGUAGES}" ]]; then
  #  MP3Linker::log "ERROR: You can't use the language linker, when MAP_LANGUAGES is not defined."
  #  exit 1
  #fi

  if [[ ! "${LANGUAGES}" ]]; then
    MP3Linker::log "ERROR: You can't use the language linker, when IGNORE_LANGUAGES is not defined."
    exit 1
  fi

  MP3Linker::Language::setup
  MP3Linker::Language::link
} # END function MP3Linker::Language::init ()


###
# MP3Linker::Language::setup ()
#------------------------------------------------------------#
# Description:                                               #
#  Setup the linker                                          #
# Globals:                                                   #
#  GLFTPD_ROOT_PATH                                          #
#  LANGUAGE_PATH                                             #
#  LANGUAGES                                                 #
#  MAP_LANGUAGES                                             #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::Language::setup () {
  for lng in "${LANGUAGES[@]}"; do
    if [ ! -e "${GLFTPD_ROOT_PATH}/${LANGUAGE_PATH}/${lng}" ]; then
      MP3Linker::Language::create_directory
    fi
  done
} # END function MP3Linker::Language::setup ()


###
# MP3Linker::Language::create_directory ()
#------------------------------------------------------------#
# Description:                                               #
#  Create a language directory                               #
# Globals:                                                   #
#   GLFTPD_ROOT_PATH                                         #
#   LANGUAGE_PATH                                            #
# Arguments:                                                 #
#   $1 - name of directory to create                         #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::Language::create_directory () {
  if [ ! "${1}" ]; then
    MP3Linker::log "ERROR: MP3Linker::Language::create_directory did not recieve an argument."
    return 1
  fi

  local directory="${1}"
  if [[ ! -e "${GLFTPD_ROOT_PATH}/${LANGUAGE_PATH}/${directory}" ]]; then
    MP3Linker::log "INFO: '${directory}' does not exist for language linking, creating it."
    mkdir "${GLFTPD_ROOT_PATH}/${LANGUAGE_PATH}/${directory}"
  fi
} # END function MP3Linker::Language::create_directory ()

###
# MP3Linker::Language::check_languages ()
#------------------------------------------------------------#
# Description:                                               #
#  Check for invalid languages and remove the corresponding  #
#  directory                                                 #
# Globals:                                                   #
#   GLFTPD_ROOT_PATH                                         #
#   LANGUAGE_PATH                                            #
# Arguments:                                                 #
#   none                                                     #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::Language::check_languages () {
  if [[ ! "${LANGUAGE_PATH}" ]]; then
    MP3Linker::log "ERROR: You can't use the language linker, when LANGUAGE_PATH is not defined."
    exit 1
  fi

  for lng in "${GLFTPD_ROOT_PATH}/${LANGUAGE_PATH}/"*; do
    for invalid in "${INVALID_LANGUAGES[@]}"; do
      if [[ "$(basename ${lng})" == "${invalid}" ]]; then
        MP3Linker::log "INFO: Found an invalid language directory ($(basename ${lng})), unlinking the symlinks and removing the directory."
        cd "${lng}"
        
        for release in "${lng}/"*; do
          MP3Linker::log "INFO: Unlinking $(basename ${release})."
#          unlink "${release}"
        done

        MP3Linker::log "INFO: Deleting language folder ${lng}."
#        rmdir "${lng}"
      fi
    done
  done
} # END MP3Linker::Language::check_languages ()

###
# MP3Linker::Lnguage::link ()
#------------------------------------------------------------#
# Description:                                               #
#  Create symbolic links to the language directory           #
# Globals:                                                   #
#   MP3_PATHS                                                #
#   IGNORE_PATTERN                                           #
#   MAP_LANGUAGES                                            #
#   LANGUAGES                                                #
#   INGORE_LANGUAGES                                         #
#   LANGUAGE_PATH                                            #
# Arguments:                                                 #
#   None                                                     #
# Returns:                                                   #
#   None                                                     #
#------------------------------------------------------------#
function MP3Linker::Language::link () {
  for mp3Path in "${MP3_PATHS[@]}"; do
    for release in "${mp3Path}/"*; do
      # skip all not needed directories
      if [[ ${releaseName} =~ ${IGNORE_PATTERN} ]]; then
        MP3Linker::log "INFO: Skipping ${releaseName}"
        continue
      fi

      local releaseName=$(basename "${release}")
      local language=""
      MP3Linker::Language::detect_language "${releaseName}"

echo "DETECTED LANGUAGE: $DETECTED_LANGUAGE"
continue

      # change to the appropriate year folder
      cd "${GLFTPD_ROOT_PATH}/${LANGUAGE_PATH}/${language}"

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
#        ln -s "${symlink}" .
      fi
    done
  done
} # END MP3Linker::Language::link ()


function MP3Linker::Language::detect_language () {
  if [ -z "${1}" ]; then
    MP3Linker::log "ERROR: MP3Linker::Language::detect_language did not recieve an argument."
    return 1
  fi
 
  # reset latest detected language
  DETECTED_LANGUAGE=""

  local releaseName="${1}"
  local extractedLanguage=""
  
  # release contains a 2 char language tag
  if [[ "${releaseName}" =~ -([[:upper:]]{2})- ]]; then # BEGIN IF1

    # copy the matches to another array (BASH_REMATCH gets rewritten everytime a regex matching is performed)
    matches=("${BASH_REMATCH[@]}")

    # go through all matches and check if the match is an ignored language
    # or if it has -*- (-DE-, -FR-, ..), since this is the complete string
    # the regex matched on, not only the extracted group
    for match in "${matches[@]}"; do
      if [[ ! "${match}" =~ "${IGNORED_LANGUAGES}" ]] && [[ ! "${match}" =~ -[[:upper:]]{2}- ]]; then
        extractedLanguage="${match}"
        break
      fi
    done

    # no language is set yet, so it was an ignored language
    # set US instead and return
    if [ -z "${extractedLanguage}" ]; then
      DETECTED_LANGUAGE="US"
      return 0
    fi

    #MP3Linker::log "INFO: Extracted '${extractedLanguage}' from ${releaseName}."


    #MP3Linker::log "INFO: Checking if the language needs to be mapped."
    # check if the language needs to be mapped
    for lng in "${!MAP_LANGUAGES[@]}"; do
      if [[ "${lng}" =~ "${extractedLanguage}" ]]; then
        MP3Linker::log "INFO: Need to re-map ${lng} to ${MAP_LANGUAGES[${lng}]}."
        DETECTED_LANGUAGE="${MAP_LANGUAGES["${lng}"]}"
        
        #match found, we are done
        return 0
      fi
    done

    #MP3Linker::log "INFO: Checking if the language is valid."
    for lng in "${LANGUAGES[@]}"; do
      if [[ "${lng}" =~ "${extractedLanguage}" ]]; then
     #   echo "INFO: Language '${extractedLanguage}' is valid."
        DETECTED_LANGUAGE="${extractedLanguage}"

        # language is valid, we are done
        return 0
      fi
    done

    # couldn't determine the language, so skip the release
    if [ -z "${DETECTED_LANGUAGE}" ]; then
      MP3Linker::log "ERROR: Couldn't determine the language for ${releaseName}!"
      MP3Linker::log "       Maybe the language tag '${extractedLanguage}' is unnknown?"
      return 2
    fi
  else # no language tag found, so we assume its english (US)
    DETECTED_LANGUAGE="US"
  fi

} # END function MP3Linker::Language::detect_language ()

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

MP3Linker::Language::setup
