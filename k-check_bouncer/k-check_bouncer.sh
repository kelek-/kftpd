#!/bin/bash
#----------------------------------------------------------------------#
#                      k-check_bouncer.sh v0.1k                        #
#----------------------------------------------------------------------#
# Description:                                                         #
#---                                                                   #
# This is a script for sites with many or slow bouncers. Also it is    #
# pretty helpful when a bouncer is down and blocking the sitebots      #
# output since it still stuck with trying to login to the questionable #
# bouncer.                                                             #
# What this script does is pretty simple:                              #
# It checks your bouncers on a regulary basis - crontab ftw - and      #
# prints the results to a file, which your sitebot can read and print  #
# to your sitechannel(s).                                              #
# So what makes that a better solution compared to the standard ngBot  #
# !bnc feature?                                                        #
#  - It does not block your sitebots output while trying to reach slow #
#    or unreachable bouncers.                                          #
#  - You have way more customization options, than with ngBot:         #
#  - It is possible to display the logintime, the pingtime and how     #
#    many hops it actually need to reach the questionable bouncer      #
#  - Well .. its from me, so its good by design ;p                     #
#---                                                                   #
# Installation:                                                        #  
#---                                                                   #
# Since this is the very first revision and I'm too lazy to work       #
# further on it for the moment and just want to push it to github, it  #
# actually is only a simple script which checks the bouncers and       #
# outputs it to stdout.                                                #
#---                                                                   #
# Bugs:                                                                #
#---                                                                   #
# Not that I know of any, feel free to msg me - you know where!        #
#                                                                      #
#---                                                                   #
# Planned features:                                                    #
#---                                                                   #
# - Print the bouncers in order of pingtime, logintime or hops         #
# - Make a complete new function to totally customize the output with  #
#   variables like %%TLD%% etc                                         #
#---                                                                   #
# Conclusion:                                                          #
#---                                                                   #
# Feel free to share, edit, delete, burn, eat or whatever you wish to  #
# do with this script. I made it for fun, so I don't care ;>           #
#                                                                      #
# .. yes, it could be written better, but you know what? Suck ma dick! #
#                                                                      #
#                                                                      #
# Sincerly,                                                            #
#  |k @ 20th August of 2o16                                            #
#----------------------------------------------------------------------#     
# Changelog:                                                           #
#---                                                                   #
# v0.1k (8/20/2016) Initial release                                    #
# v0.2k (8/20/2016) Commented the code properly                        #
# v0.5k (8/20/2016) Function format_output added. Code improvements    #
#                   NOT working in this state - next week more.        #
#----------------------------------------------------------------------#


# import curl codes
# looks a bit strange, but yea .. this is just about right 
# to surpress the error message, when the file is not there and display a custom one
# .. and dear kids, remember: ALWAYS CLEAN YOUR SHIT!
exec 9>&2; exec 2> /dev/null
source k-curl_codes.sh || { echo "ERROR: k-curl_codes.sh could not be loaded!"; exec 2>&9; exec 9>&-; exit 1; }
exec 2>&9; exec 9>&-


readonly BNC_USER="user"                                                # User to login to your site
readonly BNC_PASSWORD="password"                                        # Password of the user
readonly BNC_SSL=true                                                   # Connect to the bouncer via SSL
declare -ir BNC_TIMEOUT=5                                               # Timeout of how long we should wait until we stop the connecting process
readonly FORMAT_DECIMAL=true                                            # Output the IP address formatted as decimal          \   only one of these can be used
readonly FORMAT_HEXADECIMAL=true                                        # Output the IP address formatted as hexadecimal      /   only one of these can be used
readonly PING_HOST=true                                                 # Ping the host additionally to logging in
readonly TRACEROUTE_HOST=false                                          # Traceroute the host and record the hops
declare -ir MAX_HOPS=25                                                 # Maximum hops it should trace - remember, the more hops the longer it takes and the longer the runtime of this script is
readonly GLFTPD_ROOT_PATH="/glftpd"                                     # Well ..
readonly BNC_FILE="/ftp-data/misc/bouncer.list"                         # File the bouncer data is stored in - relative path!
readonly DEBUG=true                                                     # Get verbose output
readonly DATE_FORMAT="%D %H:%M:%S %Z"                                   # Format the output from GNU date (date -h too check whats possible) - remember: garbage in, garbage out!


#
# UNIQUE!! name needed to work properly
# format: ip:port
declare -Ar BOUNCER=(
)



#
# these are the settings for each bouncer, you defined above
# format: TIMEOUT_SEC:BNC_USER:BNC_PASSWORD:BNC_SSL:BNC_TLD:BNC_COUNTRY:BNC_NICKNAME:BNC_LOCATION
#
declare -Ar BOUNCER_SETTINGS=(
)



#
# these settings will determine how your output of the different bouncers will be
#
# available variables:
# variable                    -> description                                                                                < can be used with template
#-------------------------------------------------------------------------------------------------------------------------------------------------------
# %%BNC_NUMBER%%              -> Number of the bouncer - just an incrementing number starting from 0                        < online, offline
# %%BNC_UNIQUE_NAME%%         -> Unique name of the bouncer - the key of $BOUNCER                                           < online, offline
# %%BNC_HOST%%                -> Host of the bouncer from $BOUNCER                                                          < online, offline
# %%BNC_PORT%%                -> Port of the bouncer from $BOUNCER                                                          < online, offline
# %%BNC_HOST_HEXADECIMAL%%    -> Host of the bouncer from $BOUNCER in hexadecimal (calculated)                              < online, offline
# %%BNC_HOST_DECIMAL%%        -> Host of the bouncer from $BOUNCER in decimal (calculated)                                  < online, offline
# %%BNC_USER%%                -> User from $BNC_USER                                                                        < online, offline
# %%BNC_PASSWORD%%            -> Password from $BNC_USER                                                                    < online, offline
# %%BNC_SSL%%                 -> Value from BNC_SSL. 1 = SSL; 0 = NONSSL                                                    < online, offline
# %%BNC_TIMEOUT%%             -> Bouncer timeout time from either $BNC_TIMEOUT or if set individually in $BOUNCER_SETTINGS  < online, offline
# %%BNC_TLD%%                 -> TLD from $BOUNCER_SETTINGS                                                                 < online, offline
# %%BNC_COUNTRY%%             -> Name of the country from $BOUNCER_SETTINGS                                                 < online, offline
# %%BNC_NICKNAME%%            -> Nickname of the bouncer from $BOUNCER_SETTINGS                                             < online, offline
# %%BNC_LOCATION%%            -> Location of the bouncer (city) from $BOUNCER_SETTINGS                                      < online, offline
# %%BNC_PING_TIME%%           -> Pingtime of the bouncer (calculated)                                                       < online
# %%BNC_LOGIN_TIME%%          -> Logintime of the bouncer (calculated)                                                      < online
# %%BNC_HOPS%%                -> Hops to the bouncer (calculated)                                                           < online
# %%BNC_LAST_CHECKED%%        -> Time when the bouncer was checked the last time (calculated)                               < online, offline
# %%CURL_ERROR_CODE%%         -> Error code of curl (if an error while connecting happens)                                  < offline
# %%CURL_ERROR_DESCRIPTION%%  -> Description of the curl error (if an error while connecting happens)                       < offline
#

declare -A BOUNCER_ONLINE_TEMPLATE=(
)

declare -A BOUNCER_OFFLINE_TEMPLATE=(
  
)

#                                            #
# < - C O D E   B E G I N S   B E L O W  - > #
#                                            #


# global variables to hold some values
CURRENT_BNC_STATUS=-1
CURRENT_BNC_LOGIN_TIME=-1
CURRENT_BNC_PING_TIME=-1
CURRENT_BNC_HOPS=-1
CURRENT_BNC_NAME=""
declare -A BOUNCER_COUNT_OF_HOPS
declare -A BOUNCER_PING_TIMES
declare -A BOUNCER_LOGIN_TIMES
declare -A BOUNCER_LAST_CHECKED_TIMES
declare -A BOUNCER_OUTPUT



#-----------------------------
# init
#------
# Description:
#   Initialize the script and check for necessary binaries
#------
# Globals:
#   BNC_USER         (r)
#   BNC_PASSWORD     (r)
#   BNC_SSL          (r)
#   BNC_TIMEOUT      (r)
#   PING_HOST        (r)
#   TRACEROUTE_HOST  (r)
#   MAX_HOPS         (r)
#   DEBUG            (r)
#   GLFTPD_ROOT_PATH (r)
#   BNC_FILE         (r)
#------
# Arguments:
#   none
#------
# Returns:
#   nothing, but exits if not all necessary binaries are present, necessary 
#   files are not writeable or invalid values are set
#-----------------------------
function init () {
  if ${DEBUG}; then
    echo "DEBUG: Entered function 'init' with values:"
    echo "DEBUG: '${@}'"
  fi

  # OBSOLETE
  [[ "${FORMAT_DECIMAL}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${FORMAT_DECIMAL}') for 'FORMAT_DECIMAL' set. Only 'true' or 'false (without '') is valid."; exit 1; }
  [[ "${FORMAT_HEXADECIMAL}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${FORMAT_HEXADECIMAL}') for 'FORMAT_HEXADECIMAL' set. Only 'true' or 'false (without '') is valid."; exit 1; }
  ( [ ${FORMAT_DECIMAL} ] && [ ${FORMAT_HEXADECIMAL} ] ) || { echo "ERROR: Both 'FORMAT_DECIMAL' and 'FORMAT_HEXADECIMAL' are set - choose one of both."; exit 1; }


  # validate variables and values
  [ -n "${BNC_USER}" ] || { echo "ERROR: 'BNC_USER' is not set."; exit 1; }
  [ -n "${BNC_PASSWORD}" ] || { echo "ERROR: 'BNC_PASSWORD' is not set."; exit 1; }
  [[ "${BNC_SSL}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${BNC_SSL}') for 'BNC_SSL' set. Only 'true' or 'false' (without '') is valid."; exit 1; }
  [[ "${BNC_TIMEOUT}" =~ ^[[:digit:]]+$ ]] || { echo "ERROR: Invalid value ('${BNC_TIMEOUT}') for 'BNC_TIMEOUT' set. Only digits are valid."; exit 1; }
  [ ${BNC_TIMEOUT} -gt 0 ] || { echo "ERROR: A value of less than 1 makes no sense for timeout!"; exit 1; }
  [[ "${PING_HOST}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${PING_HOST}') for 'PING_HOST' set. Only 'true' or 'false (without '') is valid."; exit 1; }
  [[ "${TRACEROUTE_HOST}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${TRACEROUTE_HOST}') for 'TRACEROUTE_HOST' set. Only 'true' or 'false (without '') is valid."; exit 1; }
  if ${TRACEROUTE_HOST}; then
    [[ "${MAX_HOPS}" =~ ^[[:digit:]]+$ ]] || { echo "ERROR: Invalid value ('${MAX_HOPS}') for 'MAX_HOPS' set. Only digits are valid."; exit 1; }
    ( [ ${MAX_HOPS} -lt 256 ] && [ ${MAX_HOPS} -gt 0 ] ) || { echo "ERROR: Invalid value ('${MAX_HOPS}') for 'MAX_HOPS' set. Maximum allowed is 255 and minimum allowed is 1."; exit 1; }
  fi
  [[ "${DEBUG}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${DEBUG}') for 'DEBUG' set. Only 'true' and' 'false' (without '') is valid."; exit 1; }

  # check for necessary programs
  command -v curl 2>&1 > /dev/null || { echo "ERROR: 'curl' is needed to run this script!"; exit 1; }
  command -v sed 2>&1 > /dev/null ||{ echo "ERROR: 'sed' is needed to run this script!"; exit 1; }
  
  if ${PING_HOST} && ! $(command -v ping 2>&1 > /dev/null);  then
    echo "ERROR: 'PING_HOST' is set, but you don't have 'ping', which is necessary to use this function"; exit 1
  fi

  if ${TRACEROUTE_HOST} && ! $(command -v traceroute 2>&1 > /dev/null); then
    echo "ERROR: 'TRACEROUTE_HOST' is set, but you don't have 'traceroute', which is necessary to use this function!"; exit 1
  fi

  if ${TRACEROUTE_HOST} && ! $(command -v bc 2>&1 > /dev/null); then
    echo "ERROR: 'TRACEROUTE_HOST' is set, but you don't have 'bc', which is necessary to use this function!"; exit 1
  fi

  if ( ${FORMAT_DECIMAL} || ${FORMAT_HEXADECIMAL} ) && ! $(command -v printf 2>&1 > /dev/null); then
    echo "ERROR: Either 'FORMAT_DECIMAL' or 'FORMAT_HEXADECIMAL' is set, but you don't have 'printf', which is necessary to use this function!"; exit 1
  fi


  # files/folders
  if [ ! -e "${GLFTPD_ROOT_PATH}" ] || [ ! -d "${GLFTPD_ROOT_PATH}" ] || [ ! -w "${GLFTPD_ROOT_PATH}" ]; then
    echo "ERROR: 'GLFTPD_ROOT_PATH' is either not a valid directory or it is not accessible for the current user!"; exit 1
  fi

  if [ ! -e "${GLFTPD_ROOT_PATH}${BNC_FILE}" ] || [ ! -f "${GLFTPD_ROOT_PATH}${BNC_FILE}" ] || [ ! -w "${GLFTPD_ROOT_PATH}${BNC_FILE}" ]; then
    echo "ERROR: 'BNC_FILE' '${GLFTPD_ROOT_PATH}${BNC_FILE}' either does not exist, is not a valid file or is not writeable for the current user!"; exit 1
  fi

  
} #; init ( )


#-----------------------------
# get_status <host> <port> <user> <password> <timeout> <useSsl>
#------
# Description:
#   Gets the current status of the given host. This means in
#   particular it determines if the host is down or up. 
#   Additionally it calculates the time it needs to login to the
#   site via this host. Both the hosts status and the login time
#   gets written to $CURRENT_BNC_STATUS and $BNC_LOGIN_TIME.
#   Also the $BNC_LOGIN_TIME gets added to the array $BOUNCER_LOGIN_TIMES
#------
# Globals:
#   DEBUG                  (r)
#   CURRENT_BNC_LOGIN_TIME (w)
#   CURRENT_BNC_STATUS     (w)
#   CURRENT_BNC_NAME       (r)
#   BOUNCER_LOGIN_TIMES    (w)
#------
# Arguments:
#   $1 - $host      : string  -> Host of the bouncer
#   $2 - $port      : integer -> Port of the bouncer
#   $3 - $user      : string  -> User to login with to the bouncer
#   $4 - $password  : string  -> Password for the user
#   $5 - $timeout   : integer -> Time in seconds until the connection gets canceled if no response can be retrieved
#   $6 - $useSsl    : boolean -> Determines if connection is done via SSL or not
#------
# Returns:
#   0: Host is down
#   1: Host is up
#   2: Not enough arguments given
#-----------------------------
function get_status () {
  if ${DEBUG}; then
    echo "DEBUG: Entered function 'get_status' with values:"
    echo "DEBUG: '${@}'"
  fi

  if [ $# -lt 6 ]; then
    echo "ERROR: get_status -> Not enough arguments given"
    return 2
  fi
  
  local host="${1}"
  local port="${2}"
  local user="${3}"
  local password="${4}"
  local timeout="${5}"
  local useSsl=${6}

  if ${useSsl}; then #; ssl
    if ${DEBUG}; then
      echo "DEBUG: Executing \'curl -o /dev/null -s -w "%{time_total}" --disable-epsv --max-time "${timeout}" --ftp-ssl --insecure -u "${user}":"${password}" ftp://"${host}":"${port}" --ftp-port 1\'"
    fi
    CURRENT_BNC_LOGIN_TIME=$(curl -o /dev/null -s -w "%{time_total}" --disable-epsv --max-time "${timeout}" --ftp-ssl --insecure -u "${user}":"${password}" ftp://"${host}":"${port}" --ftp-port 1)
    CURRENT_BNC_STATUS=$?
  else #; nonssl
    if ${DEBUG}; then
      echo "DEBUG: Executing \'curl -o /dev/null -s -w "%{time_total}" --disable-epsv --max-time "${timeout}" --insecure -u "${user}":"${password}" ftp://"${host}":"${port}" --ftp-port 1\'"
    fi
    CURRENT_BNC_LOGIN_TIME=$(curl -o /dev/null -s -w "%{time_total}" --disable-epsv --max-time "${timeout}" --insecure -u "${user}":"${password}" ftp://"${host}":"${port}" --ftp-port 1)
    CURRENT_BNC_STATUS=$?
  fi

  # remove the dot and leading zero (if present)
  CURRENT_BNC_LOGIN_TIME=$(echo ${CURRENT_BNC_LOGIN_TIME//.} | sed 's/^0*//')

  # add it to the array of login times
  BOUNCER_LOGIN_TIMES["${CURRENT_BNC_NAME}"]="${CURRENT_BNC_LOGIN_TIME}" 
 
  return ${BNC_STATUS}
} #; function get_status <host> <port> <user> <password> <timeout> <useSsl>



#-----------------------------
# get_status <host> <timeout> [count]
#------
# Description:
# Ping a host and record the time it takes to reach the host.
# The ping time gets written to $BNC_PING_TIME and added to
# the array $BOUNCER_PING_TIMES.
#------
# Globals:
#   DEBUG                  (r)
#   CURRENT_BNC_PING_TIME  (w)
#   BOUNCER_PING_TIMES     (w)
#------
# Arguments:
#   $1 - $host      : string  -> Host of the bouncer
#   $2 - $timeout   : integer -> Time in seconds until the connection gets canceled if no response can be retrieved
#   $3 - $count     : integer -> How many ICMP packets should be sent. Default: 1.
#------
# Returns:
#  It sets CURRENT_BNC_PING_TIME and adds its value to $BOUNCER_PING_TIMES aswell.
#-----------------------------
function get_ping () {
  if ${DEBUG}; then
    echo "DEBUG: Entered function 'get_ping' with values:"
    echo "DEBUG: '${@}'"
  fi

  if [ $# -lt 2 ]; then
    echo "ERROR: get_ping -> Not enough arguments given"
    return 1
  fi

  local host="${1}"
  local timeout="${2}"

  if [ -n "${3}" ]; then
    local count="${3}"
  else
    local count=1
  fi
  
  # reset ping time first
  CURRENT_BNC_PING_TIME=-1
  CURRENT_BNC_PING_TIME=$([[ $(ping -q -c"${count}" "${host}") =~ \ =\ [^/]*/([0-9]+\.[0-9]).*ms ]] && echo ${BASH_REMATCH[1]})

  # add it to the array of ping times
  BOUNCER_PING_TIMES["${CURRENT_BNC_NAME}"]="${CURRENT_BNC_PING_TIME}"
  
} #; function get_ping <host> <timeout> [count]



#-----------------------------
# get_hops <host>
#------
# Description:
#  Trace the route to the host and count the hops. The maximum hops are set
#  with $MAX_HOPS and added to $BOUNCER_COUNT_OF_HOPS
#------
# Globals:
#   DEBUG                 (r)
#   CURRENT_BNC_HOPS      (w)
#   MAX_HOPS              (r)
#   BOUNCER_COUNT_OF_HOPS (w)
#------
# Arguments:
#   $1 - $host      : string  -> Host of the bouncer
#------
# Returns:
#  It sets CURRENT_BNC_HOPS and adds its value to $BOUNCER_COUNT_OF_HOPS
#-----------------------------
function get_hops () {
  if ${DEBUG}; then
    echo "DEBUG: Entered function 'get_hops' with values:"
    echo "DEBUG: '${@}'"
  fi

  if [ $# -lt 1 ]; then
    echo "ERROR: get_hops -> Not enough arguments given"
    return 1
  fi
  
  local host="${1}"

  # reset it first
  CURRENT_BNC_HOPS=-1
  # first line cant be surpressed from traceroute, so we need to subtract 1 from the total hops
  CURRENT_BNC_HOPS=$(echo "$(traceroute -m${MAX_HOPS} "${host}" | wc -l) - 1" | bc)

  # add it to the array of hops
  BOUNCER_COUNT_OF_HOPS["${CURRENT_BNC_NAMES}"]="${CURRENT_BNC_HOPS}"
} #; functions get_hops <host>


#-----------------------------
# ip2dec <ip>
#------
# Description:
#  Transform an ip address to an decimal value
#  Sloppy implementation ..
#------
# Globals:
#  DEBUG (r)
#------
# Arguments:
#   $1 - $ip      : string  -> IP to transform
#------
# Returns:
#  The transformed ip address
#-----------------------------
function ip2dec () {
  if ${DEBUG}; then
    echo "DEBUG: Entered function 'ip2dec' with values:"
    echo "DEBUG: '${@}'"
  fi

  local a b c d ip=$@
  IFS=. read -r a b c d <<< "$ip"
  printf '%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
  printf "\n"
} #; function ip2dec <ip> 


#-----------------------------
# ip2hex <ip>
#------
# Description:
#  Transform an ip address to an hexadecimal value.
#  Sloppy implementation .. 
#------
# Globals:
#  DEBUG (r)
#------
# Arguments:
#   $1 - $ip      : string  -> IP to transform
#------
# Returns:
#  The transformed ip address
#-----------------------------
function ip2hex () {
  if ${DEBUG}; then
    echo "DEBUG: Entered function 'ip2hex' with values:"
    echo "DEBUG: '${@}'"
  fi

  local a b c d ip=$@
  IFS=. read -r a b c d <<< "$ip"
  printf '%02X' $a $b $c $d
  printf "\n"
} #; function ip2hex <ip>


#-----------------------------
# format_output <format_line> <bncNumber> <bncUniqueName> <bncName> <bncHost> <bncPort> <bncUser> <bncPassword> 
#               <bncSsl> <bncTimeout> <bncTld> <bncCountry> <bncNickname> <bncLocation> <bncPingTime> <bncLoginTime> 
#               <bncHops> <bncStatus> <bncLastChecked> <curlErrorCode> <curlErrorDescription>
#------
# Description:
#  Replace the variables in the given string and set it into $BOUNCER_OUTPUT
#------
# Globals:
#  DEBUG (r)
#------
# Arguments:
#   $1 - $ip      : string  -> IP to transform
#------
# Returns:
#  The transformed ip address
#-----------------------------
function format_output () {
  if ${DEBUG}; then
    echo "DEBUG: Entered function 'format_output' with values:"
    echo "DEBUG: '${@}'"
  fi

#  if [[ $# -lt 21 ]]; then
#    echo "ERROR: Function 'format_output' did not recieve enough arguments!"; exit 1
#  fi

  local formatLine="${1}"
  local bncNumber="${2}"
  local bncUniqueName="${3}"
  local bncName="${4}"
  local bncHost="${5}"
  local bncPort="${6}"
  local bncUser="${7}"
  local bncPassword="${8}"
  local bncSsl="${9}"
  local bncTimeout="${10}"
  local bncTld="${11}"
  local bncCountry="${12}"
  local bncNickname="${13}"
  local bncLocation="${14}"
  local bncPingTime="${15}"
  local bncLoginTime="${16}"
  local bncHops="${17}"
  local bncStatus="${18}"
  local bncLastChecked="${19}"
  local curlErrorCode="${20}"
  local curlErrorDescription="${21}"

  # replace all variables
  formatLine="${formatLine//%%BNC_NUMBER%%/${bncNumber}}"
  formatLine="${formatLine//%%BNC_UNIQUE_NAME%%/${bncUniqueName}}"
  formatLine="${formatLine//%%BNC_HOST%%/${bncHost}}"
  formatLine="${formatLine//%%BNC_PORT%%/${bncPort}}"
  formatLine="${formatLine//%%BNC_USER%%/${bncUser}}"
  formatLine="${formatLine//%%BNC_PASSWORD%%/${bncPassword}}"
  formatLine="${formatLine//%%BNC_SSL%%/${bncSsl}}"
  formatLine="${formatLine//%%BNC_TIMEOUT%%/${bncTimeout}}"
  formatLine="${formatLine//%%BNC_TLD%%/${bncTld}}"
  formatLine="${formatLine//%%BNC_COUNTRY%%/${bncCountry}}"
  formatLine="${formatLine//%%BNC_NICKNAME%%/${bncNickname}}"
  formatLine="${formatLine//%%BNC_LOCATION%%/${bncLocation}}"
  formatLine="${formatLine//%%BNC_STATUS%%/${bncStatus}}"
  formatLine="${formatLine//%%BNC_LAST_CHECKED%%/${bncLastChecked}}"
  
  formatLine="${formatLine//%%BNC_HOST_HEXADECIMAL%%/$(ip2hex ${bncHost})}"
  formatLine="${formatLine//%%BNC_HOST_DECIMAL%%/$(ip2dec ${bncHost})}"

  # can only be set if the bouncer is up
  if [[ ${bncStatus} -eq 1 ]]; then
    formatLine="${formatLine//%%BNC_PING_TIME%%/${bncPingTime}}"
    formatLine="${formatLine//%%BNC_LOGIN_TIME%%/${bncLoginTime}}"
    formatLine="${formatLine//%%BNC_HOPS%%/${bncHops}}"
  else
    formatLine="${formatLine//%%CURL_ERROR_CODE%%/${curlErrorCode}}"
    formatLine="${formatLine//%%CURL_ERROR_DESCRIPTION%%/${curlErrorDescription}}"
  fi
  

  # finally assign the formatted line, so we can output it
  BOUNCER_OUTPUT["${bncUniqueName}"]="${formatLine}"

} #; function format_output <format_line> <bncNumber> <bncUniqueName> <bncName> <bncHost> <bncPort> <bncUser> <bncPassword> 
  #;                        <bncSsl> <bncTimeout> <bncTld> <bncCountry> <bncNickname> <bncLocation> <bncPingTime> <bncLoginTime> 
  #;                        <bncHops> <bncStatus> <bncLastChecked>

#
# BEGIN!
#

#
# first split the settings line and assign it to variables
#
declare -i currentBncNumber=1
for bouncer in "${!BOUNCER[@]}"; do
  # save IFS to restore it later
  oIFS="${IFS}"


  # get the settings for the given bouncer, with adressing it with the name it has in the BOUNCER array
  # and split it on '%', so we should end up with 6 indexes
  settings="${BOUNCER_SETTINGS["${bouncer}"]}"
  set -- "${settings}"
  IFS="%"; declare -a splittedSettings=($*)

  host="${BOUNCER["${bouncer}"]}"
  set -- "${host}"
  IFS=":"; declare -a splittedHost=($*)

  # format is: TIMEOUT_SEC:BNC_USER:BNC_PASSWORD:BNC_SSL:BNC_COUNTRY_CODE:BNC_DISPLAY_NAME
  if [[ ! ${#splittedSettings[@]} -eq 8 ]]; then
    echo "ERROR: Malformed: ${bouncer}"
    continue
  fi
  
  if [[ ! ${#splittedHost[@]} -eq 2 ]]; then
    echo "ERROR: Malformed: ${bouncer}"
    continue
  fi

  # remove "" from the values names and assign it to single variables
  timeout="${splittedSettings[0]}"
  user="${splittedSettings[1]//\"}"
  password="${splittedSettings[2]//\"}"
  useSsl="${splittedSettings[3]//\"}"
  tld="${splittedSettings[4]//\"}"
  name="${splittedSettings[5]//\"}"
  alias="${splittedSettings[6]//\"}"
  description="${splittedSettings[7]//\"}"

  # no removing needed, but assigning :>
  host="${splittedHost[0]}"
  port="${splittedHost[1]}"

  # (re)assign the current name
  CURRENT_BNC_NAME="${name}"


  # reset IFS
  IFS="${oIFS}"

  # prefix a zero
  if [[ ${bnc_number} -lt 10 ]]; then
    bnc_number=$(echo "0${bnc_number}")
  fi

  # get the status of the bouncer
  get_status "${host}" "${port}" "${user}" "${password}" "${timeout}" ${useSsl}


  # create status line
  output=""

  # BNC is up
  if [[ $CURRENT_BNC_STATUS -eq 0 ]]; then
    if ${PING_HOST} && ${TRACEROUTE_HOST}; then #; get ping and hops
      get_ping "${host}" "${timeout}"
      get_hops "${host}"
    elif ${PING_HOST}; then #; get ping only
      get_ping "${host}" "${timeout}"
    elif ${TRACEROUTE_HOST}; then #; get hops only
      get_hops "${host}"
    fi

    format_output "${BOUNCER_ONLINE_OUTPUT["${bouncer}"]}" "${currentBncNumber}" "${bouncer}" "${host}" "${port}" "${user}" "${password}" "${useSsl}" "${timeout}" "${tld}" "${
  else #; BNC is down

    format_output 
    # one could add way more conditions here, but I felt this is the most important one
    # if you want to add more custom error messages here, look the error codes up in k-curl_codes.sh
    case "${BNC_STATUS}" in
      28)
        output="Bouncer #${bnc_number} ${name} (.${tld}) aka \"${alias}\": $(ip2hex ${host}):${port} -> ${description}, DOWN! (timeout)"
      ;;
      *)
        output="Bouncer #${bnc_number} ${name} (.${tld}) aka \"${alias}\": $(ip2hex ${host}):${port} -> ${description}, ERROR ${CURRENT_BNC_STATUS} (${CURL_EXIT_CODES["${BNC_STATUS}"]}): ${CURL_EXIT_CODES_DESCRIPTION["${CURRENT_BNC_STATUS}"]}"
    esac
  fi

  # append current time
  output="$(echo "${output}" \(last checked: $(date +'%D %H:%M:%S %Z')))"


  echo "${output}"
  # remove the leading zero again
  if [[ ${currentBncNumber} =~ ^0 ]]; then
    currentBncNumber=${bnc_number//0}
  fi

  ((currentBncNumber++))
done
