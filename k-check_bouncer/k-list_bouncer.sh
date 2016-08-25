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
#                      k-list_bouncer.sh v1.0k                         #
#----------------------------------------------------------------------#
# Description:                                                         #
#---                                                                   #
# Simple script to output the bouncer list generated from the script   #
# k-check_bouncers.sh.                                                 #
#---                                                                   #
# Installation:                                                        #  
#---                                                                   #
# Copy this script to /glftpd/bin and do chmod +x on it. Additionally  #
# add                                                                  #
#   site_cmd   BNC   EXEC   /bin/k-list_bouncer.sh                     #
#   custom-bnc !8    *                                                 #
# to your glftpd.conf and you are all set.                             #
# You can set a header and a footer file, which gets printed before    #
# and after the bouncers.                                              #
#---                                                                   #
#                                                                      #
# Sincerly,                                                            #
#   |k @ 25th August of 2o16                                           #
#----------------------------------------------------------------------#

#
# settings
#
HEADER_FILE="/ftp-data/misc/bouncer.header"                            # header to print before the bouncer.list - leave empty if not wanted
FOOTER_FILE="/ftp-data/misc/bouncer.footer"                            # footer to print after the bouncer.list - leave empty if not wanted
BOUNCER_FILE="/ftp-data/misc/bouncer.list"                             # relative path to the file, where the bouncers are listed



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
#   none
#------
# Arguments:
#   none
#------
# Returns:
#   nothing, but exits if not all necessary binaries are present or BOUNCER_LIST is not accesible
#-----------------------------
function init () {
  command -v cat 2>&1 > /dev/null || { echo "/bin/cat is missing. Complain at your local siteop to fix this issue."; exit 1; }
  [ -e "${BOUNCER_FILE}" ] || { echo "BOUNCER_FILE '${BOUNCER_FILE}' does not exist. Complain at your local siteop to fix this issue."; exit 1; }
  [ -f "${BOUNCER_FILE}" ] || { echo "BOUNCER_FILE '${BOUNCER_FILE}' is not a valid file. Complain at your local siteop to fix this issue."; exit 1; }
  [ -r "${BOUNCER_FILE}" ] || { echo "BOUNCER_FILE '${BOUNCER_FILE}' is not readable for the current user. Complain at your local siteop to fix this issue."; exit 1; }
} #; function init


#-----------------------------
# build_message
#------
# Description:
#  Build the message and output it to the user
#------
# Globals:
#   BOUNCER_HEADER      (r)
#   BOUNCER_FILE        (r)
#   BOUNCER_FOOTER      (r)
#   USER                (r / from glftpd)
#   GROUP               (r / from glftpd)
#------
# Arguments:
#   none
#------
# Returns:
#  nothing
#-----------------------------
function build_message () {
  if [ -e "${BOUNCER_HEADER}" ] && [ -f "${BOUNCER_HEADER}" ] && [ -r "${BOUNCER_HEADER}" ]; then
    cat "${BOUNCER_HEADER}"
  fi

  echo -e "Hello ${USER}/${GROUP},\nyou have asked for the bouncer list - here you go:\n"
  cat "${BOUNCER_FILE}"

  if [ -e "${BOUNCER_FOOTER}" ] && [ -f "${BOUNCER_FOOTER}" ] && [ -r "${BOUNCER_FOOTER}" ]; then
    cat "${BOUNCER_FOOTER}"
  fi
} #; function build_message ( )

init
build_message
exit 0
