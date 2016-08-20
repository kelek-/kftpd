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
#----------------------------------------------------------------------#


# import curl codes
# looks a bit strange, but yea .. this is just about right 
# to surpress the error message, when the file is not there and display a custom one
# .. and dear kids, remember: ALWAYS CLEAN YOUR SHIT!
exec 9>&2; exec 2> /dev/null
source k-curl_codes.sh || { echo "ERROR: k-curl_codes.sh could not be loaded!"; exec 2>&9; exec 9>&-; exit 1; }
exec 2>&9; exec 9>&-


readonly BNC_USER="user"						# User to login to your site
readonly BNC_PASSWORD="password"	                        	# Password of the user
readonly BNC_SSL=true                                                   # Connect to the bouncer via SSL
declare -ir BNC_TIMEOUT=5                                               # Timeout of how long we should wait until we stop the connecting process
readonly FORMAT_DECIMAL=true                                            # Output the IP address formatted as decimal          \   only one of these can be used
readonly FORMAT_HEXADECIMAL=true                                        # Output the IP address formatted as hexadecimal      /   only one of these can be used
readonly PING_HOST=true                                                 # Ping the host additionally to logging in
readonly TRACEROUTE_HOST=false                                          # Traceroute the host and record the hops
declare -ir MAX_HOPS=25                                                 # Maximum hops it should trace - remember, the more hops the longer it takes and the longer the runtime of this script is
readonly GLFTPD_ROOT_PATH="/glftpd"                                     # Well ..
readonly BNC_FILE="/ftp-data/misc/bouncer.list"                         # File the bouncer data is stored in - relative path!
readonly DEBUG=false                                                    # Get verbose output


#
# UNIQUE!! name needed to work properly
# format: ip:port
declare -Ar BOUNCER=(
  ["Netherlands"]="255.255.255.255:31337"
  ["Hongkong"]="46.46.46.46:31337"
  ["UnitedKingdom"]="213.213.213.213:31337"
)


#
# these are the settings for each bouncer, you defined above
# format: TIMEOUT_SEC:BNC_USER:BNC_PASSWORD:BNC_SSL:BNC_COUNTRY_CODE:BNC_DISPLAY_NAME
#
declare -Ar BOUNCER_SETTINGS=(
  ["Netherlands"]="${BNC_TIMEOUT}%\"${BNC_USER}\"%\"${BNC_PASSWORD}\"%\"${BNC_SSL}\"%\"nl\"%\"Netherlands\"%\"Daan\"%\"Located in Zuid-Holland\\Rotterdam at i3d B.V.\""
  ["Hongkong"]="90%\"${BNC_USER}\"%\"${BNC_PASSWORD}\"%\"${BNC_SSL}\"%\"kr\"%\"Somewhere in asia\"%\"Yun\"%\"Located in Kyonggi-do\\Seongnam at Korea Telecom\""
  ["UnitedKingdom"]="60%\"${BNC_USER}\"%\"${BNC_PASSWORD}\"%\"${BNC_SSL}\"%\"uk\"%\"United Kingdom\"%\"Charles\"%\"Located in England\\London at Hosting Services Inc\""
)

#                                            #
# < - C O D E   B E G I N S   B E L O W  - > #
#                                            #


# global variables to hold some values
BNC_STATUS=-1
BNC_LOGIN_TIME=-1
BNC_PING_TIME=-1
BNC_HOPS=-1


function init () {
  # validate variables and values
  [ -n "${BNC_USER}" ] || { echo "ERROR: 'BNC_USER' is not set."; exit 1; }
  [ -n "${BNC_PASSWORD}" ] || { echo "ERROR: 'BNC_PASSWORD' is not set."; exit 1; }
  [[ "${BNC_SSL}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${BNC_SSL}') for 'BNC_SSL' set. Only 'true' or 'false' (without '') is valid."; exit 1; }
  [[ "${BNC_TIMEOUT}" =~ ^[[:digit:]]+$ ]] || { echo "ERROR: Invalid value ('${BNC_TIMEOUT}') for 'BNC_TIMEOUT' set. Only digits are valid."; exit 1; }
  [ ${BNC_TIMEOUT} -gt 0 ] || { echo "ERROR: A value of less than 1 makes no sense for timeout!"; exit 1; }
  [[ "${FORMAT_DECIMAL}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${FORMAT_DECIMAL}') for 'FORMAT_DECIMAL' set. Only 'true' or 'false (without '') is valid."; exit 1; }
  [[ "${FORMAT_HEXADECIMAL}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${FORMAT_HEXADECIMAL}') for 'FORMAT_HEXADECIMAL' set. Only 'true' or 'false (without '') is valid."; exit 1; }
  [[ "${PING_HOST}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${PING_HOST}') for 'PING_HOST' set. Only 'true' or 'false (without '') is valid."; exit 1; }
  [[ "${TRACEROUTE_HOST}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${TRACEROUTE_HOST}') for 'TRACEROUTE_HOST' set. Only 'true' or 'false (without '') is valid."; exit 1; }
  if ${TRACEROUTE_HOST}; then
    [[ "${MAX_HOPS}" =~ ^[[:digit:]]+$ ]] || { echo "ERROR: Invalid value ('${MAX_HOPS}') for 'MAX_HOPS' set. Only digits are valid."; exit 1; }
    ( [ ${MAX_HOPS} -lt 256 ] && [ ${MAX_HOPS} -gt 0 ] ) || { echo "ERROR: Invalid value ('${MAX_HOPS}') for 'MAX_HOPS' set. Maximum allowed is 255 and minimum allowed is 1."; exit 1; }
  fi

  ( [ ${FORMAT_DECIMAL} ] && [ ${FORMAT_HEXADECIMAL} ] ) || { echo "ERROR: Both 'FORMAT_DECIMAL' and 'FORMAT_HEXADECIMAL' are set - choose one of both."; exit 1; }
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


function get_status () {
  if ${DEBUG}; then
    echo "DEBUG: Entered function get_status"
    echo "DEBUG: Values retrieved:"
    echo "DEBUG: ${@}"
  fi

  if [ $# -lt 6 ]; then
    echo "ERROR: get_status -> Not enough arguments given"
    return 1
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
    BNC_LOGIN_TIME=$(curl -o /dev/null -s -w "%{time_total}" --disable-epsv --max-time "${timeout}" --ftp-ssl --insecure -u "${user}":"${password}" ftp://"${host}":"${port}" --ftp-port 1)
    BNC_STATUS=$?
  else #; nonssl
    if ${DEBUG}; then
      echo "DEBUG: Executing \'curl -o /dev/null -s -w "%{time_total}" --disable-epsv --max-time "${timeout}" --insecure -u "${user}":"${password}" ftp://"${host}":"${port}" --ftp-port 1\'"
    fi
    BNC_LOGIN_TIME=$(curl -o /dev/null -s -w "%{time_total}" --disable-epsv --max-time "${timeout}" --insecure -u "${user}":"${password}" ftp://"${host}":"${port}" --ftp-port 1)
    BNC_STATUS=$?
  fi

  # remove the dot and leading zero (if present)
  BNC_LOGIN_TIME=$(echo ${BNC_LOGIN_TIME//.} | sed 's/^0*//')
 
  return ${BNC_STATUS}
} # function check_status <host> <port> <user> <password> <timeout> <useSsl>


function get_ping () {
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
  BNC_PING_TIME=-1
  BNC_PING_TIME=$([[ $(ping -q -c"${count}" "${host}") =~ \ =\ [^/]*/([0-9]+\.[0-9]).*ms ]] && echo ${BASH_REMATCH[1]})
} # function get_ping <host> <timeout> [count]


function get_hops () {
  if [ $# -lt 1 ]; then
    echo "ERROR: get_hops -> Not enough arguments given"
    return 1
  fi
  
  local host="${1}"

  BNC_HOPS=-1
  # first line cant be surpressed from traceroute, so we need to subtract 1 from the total hops
  BNC_HOPS=$(echo "$(traceroute -m${MAX_HOPS} "${host}" | wc -l) - 1" | bc)
} # get_hops <host>


function ip2dec () {
  local a b c d ip=$@
  IFS=. read -r a b c d <<< "$ip"
  printf '%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
  printf "\n"
} #; function ip2dec <ip> 


function ip2hex () {
  local a b c d ip=$@
  IFS=. read -r a b c d <<< "$ip"
  printf '%02X' $a $b $c $d
  printf "\n"
} #; function ip2hex <ip>


#
# first split the settings line and assign it to variables
#
bnc_number=1
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
  if [[ $BNC_STATUS -eq 0 ]]; then
    # format the ipAddress
    formattedIPAddress=""
    if ${FORMAT_DECIMAL}; then
      formattedIPAddress="$(ip2dec ${host}):${port}"
    elif ${FORMAT_HEXADEICMAL}; then
      formattedIPAddress="$(ip2hex ${host}):${port}"
    else
      formattedIPAddress="${host}:${port}"
    fi


    if ${PING_HOST} && ${TRACEROUTE_HOST}; then #; get ping and hops
      get_ping "${host}" "${timeout}"
      get_hops "${host}"
      output="Bouncer #${bnc_number} ${name} (.${tld}) aka \"${alias}\": ${formattedIPAddress} -> ${description}, UP (ping: ${BNC_PING_TIME}ms, login: ${BNC_LOGIN_TIME}ms, hops: ${BNC_HOPS})!"
    elif ${PING_HOST}; then #; get ping only
      get_ping "${host}" "${timeout}"
      output="Bouncer #${bnc_number} ${name} (.${tld}) aka \"${alias}\": ${formattedIPAddress} -> ${description}, UP (ping: ${BNC_PING_TIME}ms, login: ${BNC_LOGIN_TIME}ms)!"
    elif ${TRACEROUTE_HOST}; then #; get hops only
      get_hops "${host}"
      output="Bouncer #${bnc_number} ${name} (.${tld}) aka \"${alias}\": ${formattedIPAddress} -> ${description}, UP (hops: ${BNC_HOPS})!"
    else
      output="Bouncer #${bnc_number} ${name} (.${tld}) aka \"${alias}\": ${formattedIPAddress} -> ${description}, UP!"
    fi
  else #; BNC is down
    # one could add way more conditions here, but I felt this is the most important one
    # if you want to add more custom error messages here, look the error codes up in k-curl_codes.sh
    case "${BNC_STATUS}" in
      28)
        output="Bouncer #${bnc_number} ${name} (.${tld}) aka \"${alias}\": $(ip2hex ${host}):${port} -> ${description}, DOWN! (timeout)"
      ;;
      *)
        output="Bouncer #${bnc_number} ${name} (.${tld}) aka \"${alias}\": $(ip2hex ${host}):${port} -> ${description}, ERROR ${BNC_STATUS} (${CURL_EXIT_CODES["${BNC_STATUS}"]}): ${CURL_EXIT_CODES_DESCRIPTION["${BNC_STATUS}"]}"
    esac
  fi

  # append current time
  output="$(echo "${output}" \(last checked: $(date +'%D %H:%M:%S %Z')))"


  echo "${output}"
  # remove the leading zero again
  if [[ ${bnc_number} =~ ^0 ]]; then
    bnc_number=${bnc_number//0}
  fi

  ((bnc_number++))
done
