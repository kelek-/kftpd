#!/bin/bash
#    ~     .         / ~
#  *      /       \ /
#     *  /     - --*-- ~
# \  ^  //     *    \  _ ____ _
# \\ | //_____   _\___________/_>
#  \\|//|--==|\____\--=     /\
# -==+==|->> |/-==/\\      /  \
#  //|\\|   _/   /  \\_  \/.  /
# //.| \\   \  _/___/_/_   \_/
# /,;|<//\  _____ -==/_\__  \_/_
#   .^// \\  | /   //\  \_>>_/_\ _
# ,*_/    \. |/   //__\   \\   )\\\
# `.|________/_____________\\_/_\\ \
# ,'|_______/__\_/zNr/dS!_//__\\ _) \
# `   --- -/-  <_\/________/_k!\/_>>
#----------------------------------------------------------------------#
#                      k-link_latest.sh v1.0k                          #
#----------------------------------------------------------------------#
# Description:                                                         #
#---                                                                   #
# Simple script to link your latest releases to a defined folder. You  #
# can of course chose this directory on your on as well as define, how #
# many releases should be linked there.                                #
# Linking starts with the latest dated folder, BUT the releases        #
# theirselfs are processed as they get passed to the function; That    #
# means, that the releases itself are not necessarily processed in     #
# creation order.                                                      #
#---                                                                   #
# Installation:                                                        #  
#---                                                                   #
# Copy this script to /glftpd/bin and do chmod +x on it. Additionally  #
# change the settings to fit your needs and add a crontab for it like: #
#   */5 * * * * /glftpd/bin/k-latest.sh 2>&1 > /dev/null               #
# This cronjob will re-create all symlinks every 5 minutes. The script #
# is not really increasing the load after all, but if you experience   #
# any performance issues .. try getting a new box! (:                  #
#---                                                                   #
#                                                                      #
# Sincerly,                                                            #
#   |k @ 7th August of 2o16                                            #
#----------------------------------------------------------------------#


#
# settings
#
# NOTE: _ALL_ folders _WITHOUT_ trailing slash!
GLFTPD_ROOT_PATH="/glftpd"                           # well, the glftpd root path
DAILY="/site/mp3"                                    # folder(s) containing daily directories; 1 directory per line
LATEST="/site/+latest"                               # folder where the symlinks for the latest releases should be created in
MAX_COUNT=50                                         # the maximum count of symlinks, which should be created


#                                            #
# < - C O D E   B E G I N S   B E L O W  - > #
#                                            #


#-----------------------------
# init
#------
# Description:
#   Initialize the script and check for necessary binaries
#------
# Globals:
#   GLFTPD_ROOT_PATH (r)
#   DAILY            (r)
#   LATEST           (r)
#------
# Arguments:
#   none
#------
# Returns:
#   nothing, but exits if not all necessary binaries are present or necessary files are not writeable
#-----------------------------
function init () {
   if [ ! -d "${GLFTPD_ROOT_PATH}" ] || [ ! -e "${GLFTPD_ROOT_PATH}" ]; then
     echo "ERROR:GLFTPD_ROOT_PATH '${GLFTPD_ROOT_PATH}' is not a valid directory or does not exist."; exit 1
   fi

   if [ ! -d "${GLFTPD_ROOT_PATH}${DAILY}" ] || [ ! -e "${GLFTPD_ROOT_PATH}${DAILY}" ]; then
     echo "ERROR: DAILY '${DAILY}' is not a valid directory or does not exist."; exit 1
   fi

   if [ ! -d "${GLFTPD_ROOT_PATH}${LATEST}" ] || [ ! -e "${GLFTPD_ROOT_PATH}${LATEST}" ]; then
     echo "ERROR: LATEST '${LATEST}' is not a valid directory or does not exist."; exit 1
   fi

   command -v ls 2>&1 > /dev/null || { echo "ERROR: 'ls' is necessary to run this script."; exit 1; }
   command -v basename 2>&1 > /dev/null || { echo "ERROR: 'basename' is necessary to run this script."; exit 1; }
   command -v sed 2>&1 > /dev/null || { echo "ERROR: 'sed' is necessary to run this script."; exit 1; }
   command -v grep 2>&1 > /dev/null || { echo "ERROR: 'grep' is necessary to run this script."; exit 1; }
   command -v find 2>&1 > /dev/null || { echo "ERROR: 'find' is necessary to run this script."; exit 1; }
   command -v cd 2>&1 > /dev/null || { echo "ERROR: 'cd' is necessary to run this script."; exit 1; }
   command -v wc 2>&1 > /dev/null || { echo "ERROR: 'wc' is necessary to run this script."; exit 1; }
} #; function init ( ) 


#-----------------------------
# link_latest
#------
# Description:
#   Link latest releases to a defined symlink directory
#------
# Globals:
#   GLFTPD_ROOT_PATH (r)
#   DAILY            (r)
#   MAXCOUNT         (r)
#   LATEST           (r)
#------
# Arguments:
#   none
#------
# Returns:
#   nothing
#-----------------------------
function link_latest () {
  local releaseCount=0
  for day in $(ls -1t "${GLFTPD_ROOT_PATH}${DAILY}/"); do
    # only proceed when the directory is \d\d\d\d
    if [[ ! "$(basename "${day}")" =~ ^[[:digit:]]{4}$ ]]; then
      continue
    fi

    # break out of the day loop
    if [ ${releaseCount} -eq ${MAX_COUNT} ]; then
      break
    fi
    for release in "${GLFTPD_ROOT_PATH}${DAILY}/${day}/"*; do
      # break out of the release loop
      if [ ${releaseCount} -eq ${MAX_COUNT} ]; then
        break
      fi

      local releaseName=$(basename "${release}")
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
      # add it to the symlink, change to the appropriate directory and link 
      # the release to the current directory
      symlink=${symlink}$(echo ${release} | sed -e 's@'"${GLFTPD_ROOT_PATH}/site/"'@@')
      cd "${GLFTPD_ROOT_PATH}${LATEST}"
      ln -s "${symlink}" .

      ((releaseCount++))
    done
  done
} #; function link_latest


#-----------------------------
# clean_symlinks
#------
# Description:
#   Remove all symlinks from LATEST
#------
# Globals:
#   GLFTPD_ROOT_PATH (r)
#   LATEST           (r)
#------
# Arguments:
#   none
#------
# Returns:
#   nothing
#-----------------------------
function clean_symlinks () {
  find "${GLFTPD_ROOT_PATH}${LATEST}" -type l -exec rm {} \;
} #; function clean_symlinks

init

# first remove all symlinks
clean_symlinks

# create new symlinks until the MAX_COUNT is reached
link_latest
