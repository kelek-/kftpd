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
#                    k-change_fish.sh v1.1k                            #
#----------------------------------------------------------------------#
# Description:                                                         #
#---                                                                   #
# Basically you can change your fishkey with this script fully auto-   #
# automagical via cron and have it announced to your staff and  your   #
# site channel.                                                        #
# Why this script? Because I was in the mood to do so ;>               #
# All paranoid siteops will love it, all users will hate me for that.. # 
# well thats life, deal with it! ;p                                    #
#---                                                                   #
# Installation:                                                        #  
#---                                                                   #
# First of all I made this script for blowcrypt from PERPLEX - if you  #
# use anything else, you'll need to change the sed command, which is   #
# replacing the old fishkey with the new one for the appropriate       #
# channel (found in the function 'replace_key').                       #
#                                                                      #
# Change the settings below to your needs, copy it to /glftpd/bin and  #
# do chmod +x on it and you are all set ..
# .. unless you want your bot to announce to either your staff or your #
# site channel the change of the key. Then keep reading.               #
#                                                                      #
# The following description is made for the excellent ngBot, but I'm   #
# sure, that if you use anything else, you'll find a way to port it    #
# accordingly. (:                                                      #
#                                                                      #
# - Add 'K-FISH' and 'K-FISH_STAFF' to the msgtypes(DEFAULT) section   #
#   in your ngBot.conf file                                            #
# - Add                                                                #
#     set redirect(K-FISH)          "#mySiteChannel"                   #
#     set redirect(K-FISH_STAFF)    "#myStaffChannel"                  #
#   to your ngBot.conf file                                            #
# - Add                                                                #
#     set variables(K-FISH)         "%msg"                             #
#     set variables(K-FISH_STAFF)   "%msg"                             #
#   to your ngBot.vars file                                            #
# - Add                                                                #
#     announce.K-FISH           =   "%msg"                             #
#     announce.K-FISH_STAFF     =   "%msg"                             #
#   to your theme file (it is defined at the very top of ngBot.conf)   #
# - Add a cronjob like                                                 #
#     0 3 1 * * /glftpd/bin/k-change_fish.sh 56 2>&1 > /dev/null       #
#   which will add a cronjob which runs once a month (at the first     #
#   day of the month at 3am ) and will generate a 56 char long key.    #
#---                                                                   #
# Bugs:                                                                #
#---                                                                   #
# Not that I know of any, feel free to msg me - you know where!        #
#                                                                      #
#---                                                                   #
# Planned features:                                                    #
#---                                                                   #
# Actually no more features are planned, but if you have a nice idea,  #
# feel free to let me know .. maybe I have the time and the mood to    #
# add it.                                                              #
#---                                                                   #
# Other scripts:                                                       #
#---                                                                   #
# I have made plenty of other scripts for glftpd/ngBot, but while      #
# using this script, you might want to check out k-fish.sh, which is   #
# made to use with k-change_fish.sh                                    #
#---
# Conclusion:                                                          #
#---                                                                   #
# Feel free to share, edit, delete, burn, eat or whatever you wish to  #
# do with this script. I made it for fun, so I don't care ;>           #
#                                                                      #
# .. yes, it could be written better, but you know what? Suck ma dick! #
#                                                                      #
#                                                                      #
# Sincerly,                                                            #
#  |k @ 6th August of 2o16                                             #
#----------------------------------------------------------------------#     
# Changelog:                                                           #
#---                                                                   #
# v1.0k (8/6/2016) Initial release                                     #
# v1.1k (8/6/2016) Added support for staff channel key change          #
#----------------------------------------------------------------------#
readonly VER="1.1k"

# 
# settings
#
readonly BLOWCRYPT_FILE="/glftpd/sitebot/scripts/blowcrypt.conf"
readonly EGGDROP_BINARY="/glftpd/sitebot/eggdrop"
readonly EGGDROP_USER="eggdrop"                                        # if empty current user is used
readonly CHANNEL="#siteChan"                                           # site channel the fish key should be set for
readonly STAFF_CHANNEL="#staffChan"                                    # staff channel the fish key should be set for. Used to announce the fishkey for the sitechannel as well - if enabled ofc.
readonly FISH_KEY_FILE="/glftpd/ftp-data/misc/fish.key"                # the keyfile the fishkey for the site channel will be stored in. Use k-fish.sh to implement it as site command
readonly FISH_STAFF_KEY_FILE="/glftpd/ftp-data/misc/fish_staff.key"    # the keyfile the fishkey for the staff channel will be stored in
readonly CHANGE_STAFF_KEY=true                                         # when enabled the fishkey for the staff channel will be changed (to a different one ofc) as well
FISH_KEY_LENGTH="56"                                                   # length of the fishkey for the sitechannel - can be passed via cli arguments
FISH_STAFF_KEY_LENGTH="56"                                             # length of the fishkey for the staffchannel - can be passed via cli arguments
FISH_KEY=""                                                            # fish key itself



# 
# -- 
#    below settings are only necessary if you want to have the change of the fishkey announced in 
#    a) the channel itself, befor restarting the eggdrop
#    b) the staff channel (including the new key)
#    c) both of those variants
# --
#
readonly GLFTPD_LOGFILE="/glftpd/ftp-data/logs/glftpd.log"             # well .. path to the glftpd.log
readonly CHANNEL_ANNOUNCE=true                                         # announce that a new key will be set in the channel, where the key will be used
readonly STAFF_ANNOUNCE=true                                           # announce the fishkey to the staff channel before restarting


# customize the messages the eggdrop will send - you can use \x02 etc (usual format meta characters)
# NOTE: %%fish_key%% is only valid for STAFF_MESSAGE _NOT_ for CHANNEL_MESSAGE ... because of safety etc ..
readonly CHANNEL_MESSAGE="\x02ATTENTION\x02: The fishkey for this channel will now be changed! Use 'site key' to obtain it."
readonly STAFF_MESSAGE="New fish key for ${CHANNEL} is: '%%fish_key%%' (without '')"
readonly STAFF_KEY_MESSAGE="New fish key for ${STAFF_CHANNEL} is: '%%fish_key%%' (without '')"


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
#   BLOWCRYPT_FILE (r)
#------
# Arguments:
#   none
#------
# Returns:
#   nothing, but exits if not all necessary binaries are present or necessary files are not writeable
#-----------------------------
function init () {
  if [ ! -f "${BLOWCRYPT_FILE}" ] || [ ! -w "${BLOWCRYPT_FILE}" ]; then
    echo "ERROR: BLOWCRYPT_FILE '${BLOWCRYPT_FILE}' does not exist or is not writeable for the current user"; exit 1
  fi

  if [ ! -f "${GLFTPD_LOGFILE}" ] || [ ! -w "${GLFTPD_LOGFILE}" ]; then
     echo "ERROR: GLFTPD_LOGFILE '${GLFTPD_LOGFILE}' does not exist or is not writeable for the current user"; exit 1
  fi

  command -v pwgen > /dev/null 2>&1 || { echo >&2 "ERROR: 'pwgen' is necessary to run this script."; exit 1; }
  command -v sed > /dev/null 2>&1 || { echo >&2 "ERROR: 'sed' is necessary to run this script."; exit 1; }
  command -v pgrep > /dev/null 2>&1 || { echo >&2 "ERROR: 'pgrep' is necessary to run this script."; exit 1; }
  command -v kill > /dev/null 2>&1 || { echo >&2 "ERROR: 'kill' is necessary to run this script."; exit 1; }
  command -v sleep > /dev/null 2>&1 || { echo >&2 "ERROR: 'sleep' is necessary to run this script."; exit 1; }
  command -v dirname > /dev/null 2>&1 || { echo >&2 "ERROR: 'dirname' is necessary to run this script."; exit 1; }
  command -v basename > /dev/null 2>&1 || { echo >&2 "ERROR: 'basename' is necessary to run this script."; exit 1; } 

  if ${STAFF_ANNOUNCE} || ${CHANNEL_ANNOUNCE}; then
    command -v date > /dev/null 2>&1 || { echo >&2 "ERROR: 'date' is necessary to run this script."; exit 1; }
  fi

  if [ -n "${FISH_KEY_FILE}" ] && ( [ ! -w "${FISH_KEY_FILE}" ] || [ ! -f "${FISH_KEY_FILE}" ] ); then
    echo "ERROR: FISH_KEY_FILE '${FISH_KEY_FILE}' does not exist or is not writeable for the current user"; exit 1
  fi

  if [ -n "${FISH_STAFF_KEY_FILE}" ] && ( [ ! -w "${FISH_STAFF_KEY_FILE}" ] || [ ! -f "${FISH_STAFF_KEY_FILE}" ] ); then
    echo "ERROR: FISH_STAFF_KEY_FILE '${FISH_STAFF_KEY_FILE}' does not exist or is not writeable for the current user"; exit 1
  fi
} #; function init ( )


#-----------------------------
# replace_key
#------
# Description:
#   Replace the blowfishkey
#------
# Globals:
#   BLOWCRYPT_FILE (r)
#------
# Arguments:
#   $1 - $channel: The channel the key should be set for
#   $2 - $fishKey: The blowfishkey
#------
# Returns:
#   nothing, but exits if not but arguments are given
#-----------------------------
function replace_key () {
  if [ "${#}" -lt 2 ] || [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "ERROR: replace_key -> not enough arguments given."
    exit 1
  fi

  local channel="${1}"
  local fishKey="${2}"
  sed -i "s/{${channel}\s.*}}/{${channel} {${fishKey}}}/" "${BLOWCRYPT_FILE}"
} #; function replace_key <channel> <fishKey>


#-----------------------------
# restart_eggdrop
#------
# Description:
#   Restart the eggdrop
#------
# Globals:
#   EGGDROP_BINARY (r)
#   EGGDROP_USER   (r)
#------
# Arguments:
#   none
#------
# Returns:
#   nothing
#-----------------------------
function restart_eggdrop () {
  kill $(ps ax | pgrep "$(basename ${EGGDROP_BINARY})")
  
  # sleeping for a bit to prevent that the .pid file is still present
  sleep 5

  if [ -z "${EGGDROP_USER}" ]; then
    cd "$(dirname ${EGGDROP_BINARY})"
    "./$(basename "${EGGDROP_BINARY}")"
  else
    su - "${EGGDROP_USER}" -c "cd "$(dirname "${EGGDROP_BINARY}")"; "./$(basename "${EGGDROP_BINARY}")""
  fi
} #; function restart_eggdrop ( )

#-----------------------------
# send_announces
#------
# Description:
#   Send the messages to the channels
#------
# Globals:
#   CHANNEL_ANNOUNCE  (r)
#   CHANNEL_MESSAGE   (r)
#   STAFF_ANNOUNCE    (r)
#   STAFF_MESSAGE     (r)
#   GLFTPD_LOGFILE    (r)
#   CHANGE_STAFF_KEY  (r)
#   STAFF_KEY_MESSAGE (r)
#------
# Arguments:
#   none
#------
# Returns:
#   nothing
#-----------------------------
function send_announces () {
  local timestamp=$(date '+%a %b %e %T %Y')

  # announce to site channel
  if ${CHANNEL_ANNOUNCE} && [ -n "${CHANNEL_MESSAGE}" ]; then
    echo "${timestamp} K-FISH: \"${CHANNEL_MESSAGE}\"" >> "${GLFTPD_LOGFILE}"
  fi

  # announce the sitechannel key to staff channel 
  if ${STAFF_ANNOUNCE} && [ -n "${STAFF_MESSAGE}" ]; then
    local staffMessage="$(echo "${STAFF_MESSAGE}" | sed "s@%%fish_key%%@${FISH_KEY}@")"
    echo "${timestamp} K-FISH_STAFF: \"${staffMessage}\"" >> "${GLFTPD_LOGFILE}"
  fi

  # announce the staffchannel key to the staff channel
  if ${CHANGE_STAFF_KEY} && ${STAFF_ANNOUNCE} && [ -n "${STAFF_KEY_MESSAGE}" ]; then
    local staffMessage="$(echo "${STAFF_KEY_MESSAGE}" | sed "s@%%fish_key%%@${FISH_STAFF_KEY}@")"
    echo "${timestamp} K-FISH_STAFF: \"${staffMessage}\"" >> "${GLFTPD_LOGFILE}"
  fi
} #; function send_announces


init

# get both cli arguments if provided
if [ -n "${1}" ]; then
  FISH_KEY_LENGTH="${1}"
fi
if [ -n "${2}" ]; then
  FISH_STAFF_KEY_LENGTH="${2}"
fi

# generate key for the site channel, replace in blowcrypt.conf
# and write the key into the appropriate file
FISH_KEY="$(pwgen -s ${FISH_KEY_LENGTH} 1)"
replace_key "${CHANNEL}" "${FISH_KEY}"
echo "${FISH_KEY}" > "${FISH_KEY_FILE}"

# it is requested to change the fishkey for the staff channel as well
# let's generate another one :)
if ${CHANGE_STAFF_KEY}; then
  FISH_STAFF_KEY="$(pwgen -s ${FISH_STAFF_KEY_LENGTH} 1)"
  replace_key "${STAFF_CHANNEL}" "${FISH_STAFF_KEY}"
  echo "${FISH_STAFF_KEY}" > "${FISH_STAFF_KEY_FILE}"
fi

# send announces if requested
if ${CHANNEL_ANNOUNCE} || ${STAFF_ANNOUNCE}; then
  send_announces
fi

# sleep before restarting to allow ngBot to send the messages to irc
sleep 5

# restart the eggdrop to apply the changes
restart_eggdrop

exit 0
<<EOF
