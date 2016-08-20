#"!/bin/bash
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
#                         k-fish.sh v1.0k                              #
#----------------------------------------------------------------------#
# Description:                                                         #
#---                                                                   #
# Simple script to output the current fish key(s) to the user based on #
# the flags the user has.                                              #
# Use this script in conjunction with k-change_fish.sh (:              #
#---                                                                   #
# Installation:                                                        #  
#---                                                                   #
# Copy this script to /glftpd/bin and do chmod +x on it. Additionally  #
# add                                                                  #
#   site_cmd   KEY   EXEC   /bin/k-fish.sh                             #
#   custom-key !8    *                                                 #
# to your glftpd.conf and you are all set.                             #
#---                                                                   #
#                                                                      #
# Sincerly,                                                            #
#   |k @ 6th August of 2o16                                            #
#----------------------------------------------------------------------#


FISH_KEY_FILE="/ftp-data/misc/fish.key"                                # relative path to the file, where the fish key for the site channel is stored
FISH_STAFF_KEY_FILE="/ftp-data/misc/fish_staff.key"                    # relative path to the file, where the fish key for the staff channel is stored
CUSTOM_FLAG="N"                                                        # additional user flag, which is allowed to be in staff channel (1 is always a siteop)

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
#   nothing, but exits if not all necessary binaries are present
#-----------------------------
function init () {
  command -v cat 2>&1 > /dev/null || { echo "/bin/cat is missing. Complain at your local siteop to fix this issue."; exit 1; } 
} #; function init


#-----------------------------
# build_message
#------
# Description:
#  Build the message and output it to the user
#------
# Globals:
#   FISH_KEY_FILE       (r)
#   FISH_KEY_STAFF_FILE (r)
#   USER                (r / from glftpd)
#   GROUP               (r / from glftpd)
#   FLAGS               (r / from glftpd)
#------
# Arguments:
#   none
#------
# Returns:
#  nothing
#-----------------------------
function build_message () {
  local message="Hello ${USER}/${GROUP},\nyou have asked for the blowfish keys - here you go:\n"
  message+="site channel...: $(cat ${FISH_KEY_FILE})\n"
  
  # access to staff channel with flag 1 or custom flag
  if [[ "${FLAGS}" =~ 1 ]] || [[ "${FLAGS}" =~ "${CUSTOM_FLAG}" ]]; then
    message+="staff channel..: $(cat ${FISH_STAFF_KEY_FILE})\n"
  fi
  
  message+="sitebot........: init a DH1080 keyx\n\n\n"
  message+="REMEMBER: Keep this key for _YOURSELF_!!!"
  echo -e "${message}"
} #; function build_message ( )

init
build_message
exit 0
