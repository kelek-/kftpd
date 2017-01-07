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
#                          k-base.sh v0.01-dev                         #
#----------------------------------------------------------------------#
# Description:                                                         #
#---                                                                   #
# k-base is a collection of useful functions, which are helpful when   #
# it comes to writing a bigger BASH script. I've used plenty of those  #
# over the years and now decided to put them into one collection - a   #
# framework if you like. As this is the first version I'm publishing,  #
# these functions have just passed a quick engineer test while I wrote #
# them - maybe unit tests will follow some day, but I'm not sure yet.  #
# As I'll work continously on this framework, some things might break  #
# or won't work as expected. If this is the case I'll mention that     #
# at the end of this comment section.                                  #
#------+                                                               #
# Bugs:                                                                #
#---                                                                   #
# Not that I know of any, feel free to msg me - you know where!        #
#------+                                                               #
# Planned features:                                                    #
#---                                                                   #
# This and that                                                        #
#------+                                                               #
# Usage:                                                               #
#---                                                                   #
# Well, if you don't know that ..                                      #
#------+                                                               #
# Conclusion:                                                          #
#---                                                                   #
# Feel free to share, edit, delete, burn, eat or whatever you wish to  #
# do with this script. I made it for fun, so I don't care ;>           #
#                                                                      #
# .. yes, it could be written better, but you know what? Suck ma dick! #
#                                                                      #
#                                                                      #
# Sincerly,                                                            #
#  |k @ 7th January of 2o17                                            #
#----------------------------------------------------------------------#     
# Changelog:                                                           #
#---                                                                   #
# v0.01-dev (1/7/2016) Initial release                                 #
#----------------------------------------------------------------------#

# TODO: check sourcing and issue an error if it fails
source k-base_settings.sh
source k-base_errors.sh


#----------------------------------------#
# < internal variables - do NOT modify > #
#----------------------------------------#

#
# settings variables as internal ones, to allow modifications, when there are wrong settings made
#
declare -i __DEBUG=""                            # 
declare __REPLACED_STRING=""                     # Variable stores the replaced string from kbase::replace_string
declare -ar __REQUIERED_BINARIES=(
  "sed"
  "printf"
)


function kbase::init () {
  # BASH version v4.x is needed at least
  # Note: This (lame) check works only until BASH version 9.x, after that a new check needs to be implemented
  [[ "${BASH_VERSION}" =~ ^[4-9]\. ]] || {
    echo "ERROR: You are running '${BASH_VERSION}', but this script needs at least BASH v4.x";
    exit 1;
  };

  for binary in "${__REQUIERED_BINARIES[@]}"; do
    command -v "${binary}" &> /dev/null || {
      echo "ERROR: Requiered binary '${binary}' is not available. Install it to use this script.";
      exit 1;
    };
  done

  return 0;
} #; function kbase::init

function kbase::validate_settings () {
  [ -n "${__DEBUG}" ] || {
    kbase::create_error
  };
} #; function kbase::validate_settings

#---------------------------------------#
#    < type validation functions >      #
#---------------------------------------#
# Note: As these functions are pretty simple,
#       they aren't described extensive.

#----------------
# kbase::typeof_int <variable>
#----
# Description:
#------
#   Check if a variable contains an integer value
#----
# Returns:
#------
#   0: Variable is an integer
#   1: Variable is not an integer
#   2: Missing argument
#--------------------
function kbase::typeof_int () {
  declare integer="${1}"
  [ -n "${integer}" ] || {
    return 2;
  };

  [[ "${integer}" =~ ^[[:digit:]]+$ ]] || {
    return 1;
  };

  return 0;
} #; kbase::typeof_int <variable>


#----------------
# kbase::typeof_boolean <variable>
#----
# Description:
#------
#   Check if a variable contains a boolean value
#----
# Returns:
#------
#   0: Variable is a boolean
#   1: Variable is not a boolean
#   2: No argument given
#--------------------
function kbase::typeof_boolean () {
  declare boolean="${1}"
  [ -n "${boolean}" ] || {
    return 2;
  };

  [[ "${boolean}" =~ ^[0|1]$ ]] || {
    return 1;
  };

  return 0;
} #; kbase::typeof_boolean <variable>


#----------------
# kbase::typeof_float <variable>
#----
# Description:
#------
#   Check if a variable contains an float value
#----
# Returns:
#------
#   0: Variable is a float
#   1: Variable is not a float
#   2: No argument given
#--------------------
function kbase::typeof_float () {
  declare float="${1}"
  [ -n "${float}" ] || {
    return 2;
  };

  [[ "${float}" =~ ^[[:digit:]]+\.[[:digit:]]+$ ]] || {
    return 1;
  };

  return 0;
} #; kbase::typeof_float <variable<


#----------------
# kbase::typeof_ipv4 <ip> [ignoreLeadingZeroes] [allowZeroByteAddress]
#----
# Description:
#------
#   Check if a variable is a valid ipv4 address.
#   Note that without any optinal argument, addresses, which 
#   either have a fragment starting with zero (like 192.01.10.10) or
#   are only zeroes at all (0.0.0.0) are considered as invalid.
#   You can allow leading zeroes (192.01.10.10), by passing the 2nd
#   argument as "0" (true).
#   If you need to allow zero byte addresses (0.0.0.0), pass the 3rd
#   argument as "0" (true); In this case however, it is adviced to pass
#   the 2nd argument as "1" (false), unless you want to allow addresses
#   like 0.01.0.0 - which in this case is absolutly valid.
#
#   Example usage:
#   Allow leading zeroes:      kbase::typeof_ipv4 "$ip" "0"     -> 192.01.10.10
#   Allow zero byte addresses: kbase::typeof_ipv4 "$ip" "1" "0" -> 0.0.0.0
#
#   Please note, that technically all IP addresses, which fragment values
#   are more than 0, but less than 256, are perfectly valid. However it is
#   not very common to write the address 192.168.140.1 as 192.168.140.001.
#   You can have validation for either of those cases by using the parameters
#   as described.
#----
# Returns:
#------
#   0: Variable is a valid ipv4 address
#   1: General Formatting error (expected is x.x.x.x)
#   2: Fragment of given address has an invalid type (non-integer)
#   3: Fragment of given address exceeds the min/max values (0-255)
#   4: First four bytes are zero and it was not requested to ignore it
#   5: Fragment of given address starts with a zero
#--------------------
function kbase::typeof_ipv4 () {
  declare ip="${1}"
  [ -n "${ip}" ] || {
    return 2;
  };

  declare -i ignoreLeadingZeroes=1
  if [ -n "${2}" ] && kbase::typeof_boolean "${2}"; then
    ignoreLeadingZeroes=${2}
  fi

  declare -i allowZeroByteAddress=1
  if [ -n "${3}" ] && kbase::typeof_boolean "${3}"; then
    allowZeroByteAddress=${3}
  fi

  # validate general formatting
  if [[ ! "${ip}" =~ ^([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}$ ]]; then
    return 1;
  fi

  declare -i fragmentNumber=0
  IFS='.' read -ra address <<< "${ip}"
  for fragment in "${address[@]}"; do
    # validate type
    if ! kbase::typeof_int "${fragment}" ; then
      return 2;
    fi
   
    # validate max and min value
    if [ ! "${fragment}" -le 255 ] || [ ! "${fragment}" -ge 0 ]; then
      return 3;
    fi

    # check that the first four bytes are not zero, unless zero byte addresses are allowed
    if [ ${fragmentNumber} -eq 0 ] && [ ! ${allowZeroByteAddress} -eq 0 ]; then
      [ ! ${fragment} -eq 0 ] || {
        return 4;
      }
    fi

    # ignoring leading zero not requested
    if [ ! ${ignoreLeadingZeroes} -eq 0 ]; then
      # make sure fragment does not start with 0
      if [[ "${fragment}" =~ ^0 ]] && [[ ! "${fragment}" =~ ^0$ ]]; then
        return 5;
      fi
    fi
    
    (( fragmentNumber++ ))
  done

  return 0;
} #; kbase::typeof_ipv4 <address> [ignoreLeadingZeroes] [allowZeroByteAddress]

#-----------------------------------#
# < END type validation functions > #
#-----------------------------------#


function kbase::create_debug_output () {
  declare function="${1}"
  declare line="${2}"
  declare callStack=("${3}")

  # remove already assigned parameters
  shift 3

  # rest of the parameters are optional
  declare -a parameters=("${@}")

  # print all calls from the call stack
  kbase::log "Callstack:" "0" "${line}"
  declare -i callNumber=0
  while [ "${callNumber}" -lt "${#callStack[@]}" ]; do
    kbase::log "call #${callNumber}: ${callStack[${callNumber}]}" "0" "${line}"
    ((callNumber++))
  done

  # print all arguments
  kbase::log "Parameters:" "0" "${line}"
  declare -i parameterNumber=0
  while [ "${parameterNumber}" -lt "${#parameters[@]}" ]; do
    kbase::log "parameter #${parameterNumber}: ${parameters[${parameterNumber}]}" "0" "${line}"
    ((parameterNumber++))
  done
} #; function kbase::create_debug_output

function kbase::init_logging () {
 echo b
} #; kbase::init_logging



#-----------------------------
# kbase::log <message> <level> <lineNumber> [exitCode]
#------
# Description:
#--------
#   Write log to file and/or stdout.
#------
# Globals:
#--------
#   #  | Name             | Origin   | Access (r = read, w = write)
#------+------------------+----------+--------------------------------------->
#   1  - FUNCNAME          (BASH)    : r
#   2  - LINENO            (BASH)    : r
#   3  - LOG_DATE_FORMAT   (internal): r
#   4  - LOG_FILE          (internal): r
#   5  - LOG_LEVEL         (internal): r
#------
# Arguments:
#----------
#   #  | Variable                   | Type          | Description                                                       
#------+----------------------------+---------------+--------------------------->
#   $1 - <message>                   (string       ): Message to log
#   $2 - <level >                    (integer      ): Level of this message (the higer the number, the more important the message will be threated)
#   $3 - <lineNumber>                (integer      ): Line number, where the call to this function came from
#   $4 - [exitCode]                  (integer      ): Only used, when the loglevel is 99 - which means, print the message and exit with a (custom) exitCode.
#                                                     If this argument is not passed, the exitCode will be 2.
#------
# Returns:
#--------
#   #  | Type    | Description
#------+---------+-------------------------------------------------->
#   0 - (return): Everything went fine
#   1 - (exit  ): Not enough arguments are given
#   2 - (exit  ): Message level is 99 and no custom exitCode is given (NO error!)
#   3 - (exit  ): Level has an invalid (non-integer) value set
#   4 - (exit  ): Custom exitCode is given, but has an invalid (non-integer) value set
#-----------------------------
function kbase::log () {
  [ "${#}" -ge 3 ] || {
    printf "["$(date "+${LOG_DATE_FORMAT}")"] %-11s: ${FUNCNAME[0]}, line ${LINENO}: Not enough arguments recieved. Expected 3, recieved '${#}'\n" "ERROR"
    printf "["$(date "+${LOG_DATE_FORMAT}")"] %-11s: ${FUNCNAME[0]}, line ${LINENO}: ${FUNCNAME[0]} was called from ${FUNCNAME[1]}.\n" "ERROR"
    exit 1;
  };

  declare message="${1}"
  declare -i level="${2}"
  declare -i lineNumber="${3}"

  declare -i exitCode=2
  # custom exitCode given
  [ -z "${4}" ] || {
    exitCode="${4}";
    return 0;
  };

  declare lastFunction="${FUNCNAME[1]}"
  declare timeStamp="$(date "+${LOG_DATE_FORMAT}")"
  declare -i quitAfterMessage=1


  # check values before proceeding with the message handling
  if [[ ! "$(kbase::typeof_int "${level}")" -eq 0 ]]; then
    if [ -n "${LOG_FILE}" ]; then
	printf "[${timeStamp}] %-11s: ${FUNCNAME[0]}, line ${LINENO}: Invalid value set for 'level'. Expected: Integer, Recieved: '${level}'.\n" "ERROR" >> "${LOG_FILE}"
        printf "[${timeStamp}] %-11s: ${FUNCNAME[0]}, line ${LINENO}: ${FUNCNAME[0]} was called from ${FUNCNAME[1]}.\n" "ERROR" >> "${LOG_FILE}"
    fi
    printf "[${timeStamp}] %-11s: ${FUNCNAME[0]}, line ${LINENO}: Invalid value set for 'level'. Expected: Integer, Recieved: '${level}'.\n" "ERROR"
    printf "[${timeStamp}] %-11s: ${FUNCNAME[0]}, line ${LINENO}: ${FUNCNAME[0]} was called from ${FUNCNAME[1]}.\n" "ERROR"
    exit 3;
  fi

  if [[ ! "$(kbase::typeof_int "${errorCode}")" -eq 0 ]]; then
    if [ -n "${LOG_FILE}" ]; then
        printf "[${timeStamp}] %-11s: ${FUNCNAME[0]}, line ${LINENO}: Invalid value set for 'errorCode'. Expected: Integer, Recieved: '${errorCode}'.\n" "ERROR" >> "${LOG_FILE}"
        printf "[${timeStamp}] %-11s: ${FUNCNAME[0]}, line ${LINENO}: ${FUNCNAME[0]} was called from ${FUNCNAME[1]}.\n" "ERROR" >> "${LOG_FILE}"
    fi
    printf "[${timeStamp}] %-11s: ${FUNCNAME[0]}, line ${LINENO}: Invalid value set for 'errorCode'. Expected: Integer, Recieved: '${level}'.\n" "ERROR"
    printf "[${timeStamp}] %-11s: ${FUNCNAME[0]}, line ${LINENO}: ${FUNCNAME[0]} was called from ${FUNCNAME[1]}.\n" "ERROR"
    exit 4;
  fi


  # re-map message level to make it easier to read
  declare messageLevel=""
  if [ "${level}" -le 5 ]; then
    messageLevel="DEBUG"
  elif [ "${level}" -le 10 ] && [ ${level} -gt 5 ]; then
    messageLevel="INFORMATION"
  elif [ "${level}" -le 15 ] && [ ${level} -gt 10 ]; then
    messageLevel="WARNING"
  elif [ "${level}" -ge 20 ] && [ ! ${level} -eq 99 ]; then
    messageLevel="ERROR"
  elif [ "${level}" -eq 99 ]; then
    messageLevel="ERROR"
    quitAfterMessage=0
  fi

  # we print the message to the logfile in any case
  printf "[${timeStamp}] %-11s: %-25s, line %-6s, debug level %-2s: %s\n" "${messageLevel}" "${lastFunction}" "${lineNumber}" "${level}" "${message}" >> "${LOG_FILE}"



  if [ "${LOG_LEVEL}" = "NONE" ] && [ ! "${quitAfterMessage}" -eq 0 ]; then # user does not want to have anything logged to stdout
    return 0;
  elif [ "${LOG_LEVEL}" = "NONE" ] && [ "${quitAfterMessage}" -eq 0 ]; then # however, there we have an error, so we exit with the (custom) error code
    exit ${exitCode};
  fi


  # print the messages based on the loglevel
  if [ "${messageLevel}" = "DEBUG" ] && [[ "${LOG_LEVEL}" =~ ^(DBG|DEBUG|ALL)$ ]]; then
    printf "[${timeStamp}] %-11s: %-25s, line %-6s, debug level %-2s: %s\n" "${messageLevel}" "${lastFunction}" "${lineNumber}" "${level}" "${message}"
  elif [ "${messageLevel}" = "INFORMATION" ] && [[ "${LOG_LEVEL}" =~ ^(INFO|DBG|INFORMATION|DEBUG|ALL)$ ]]; then
    printf "[${timeStamp}] %-11s: %-25s, line %-6s, debug level %-2s: %s\n" "${messageLevel}" "${lastFunction}" "${lineNumber}" "${level}" "${message}"
  elif [ "${messageLevel}" = "WARNING" ] && [[ "${LOG_LEVEL}" =~ ^(WARN|INFO|DBG|WARNING|INFORMATION|DEBUG|ALL)$ ]]; then
    printf "[${timeStamp}] %-11s: %-25s, line %-6s, debug level %-2s: %s\n" "${messageLevel}" "${lastFunction}" "${lineNumber}" "${level}" "${message}"
  elif [ "${messageLevel}" = "ERROR" ] && [[ "${LOG_LEVEL}" =~ ^(ERR|WARN|INFO|DBG|ERROR|WARNING|INFORMATION|DEBUG|ALL)$ ]]; then
    printf "[${timeStamp}] %-11s: %-25s, line %-6s, debug level %-2s: %s\n" "${messageLevel}" "${lastFunction}" "${lineNumber}" "${level}" "${message}"
  fi


  if [ "${quitAfterMessage}" -eq 0 ]; then
    exit ${exitCode};
  fi

  return 0;
} #; function kbase::log ( <message>, <level>, <lineNumber>, [exitCode] )


#-----------------------------
# kbase::replace_string <string> <search> <replace> [replaceAllOccurences]
#------
# Description:
#--------
#   Used to replace a needle in a string. The result of it, will be saved in __REPLACED_STRING.
#------
# Globals:
#--------
#   #  | Name             | Origin   | Access (r = read, w = write)
#------+------------------+----------+--------------------------------------->
#   1  - FUNCNAME          (BASH)    : r
#   2  - LINENO            (BASH)    : r
#   3  - __REPLACED_STRING (internal): w
#------
# Arguments:
#----------
#   #  | Variable                   | Type          | Description                                                       
#------+----------------------------+---------------+--------------------------->
#   $1 - <string>                    (string       ): String to search in
#   $2 - <search>                    (string       ): Search for this string
#   $3 - <replace>                   (string       ): Replace with this string
#   $4 - [replaceAllOccurences]      (boolean      ): Replace all occurences of the search string 
#------
# Returns:
#--------
#   #  | Type    | Description
#------+---------+-------------------------------------------------->
#   0 - (return): Everything went fine
#   1 - (exit  ): Not enough arguments are given
#   2 - (exit  ): Invalid value (non-boolean) recieved for replaceAllOccurences
#-----------------------------
function kbase::replace_string ( ) {
  [ "${#}" -ge 3 ] || {
    printf "${FUNCNAME[0]} (${LINENO}) did not recieve enough arguments.\n>   Expected: 3, Recieved: ${#}\n";
    exit 1;
  };

  declare string="${1}"
  declare search="${2}"
  declare replace="${3}"
  declare -i replaceAllOccurences=1
  
  [ -n "${4}" ] || {
    replaceAllOccurences=0
  };

  [ "$(kbase::typeof_boolean "${replaceAllOccurences}")" ] || {
    printf "[${timeStamp}] %-11s: ${FUNCNAME[0]}, line ${LINENO}: Invalid value set for 'replaceAllOccurences'. Expected: Integer, Recieved: '${replaceAllOccurences}'.\n" "ERROR"
    printf "[${timeStamp}] %-11s: ${FUNCNAME[0]}, line ${LINENO}: ${FUNCNAME[0]} was called from ${FUNCNAME[1]}.\n" "ERROR"
    exit 2;
  };

  # clean the global variable
  __REPLACED_STRING=""

  [ -n "${string}" ] || {
    printf "%s recieved an empty variable 'string' (\$1).\n" "${FUNCNAME[0]}";
    exit 1;
  };

  [ -n "${search}" ] || {
    printf "%s recieved an empty variable 'search' (\$2).\n" "${FUNCNAME[0]}";
    exit 1;
  };

  if [ "${replaceAllOccurences}" -eq 0 ]; then
    __REPLACED_STRING="$(echo "${string}" | sed "s@${search}@${replace}@g")"
  else
    __REPLACED_STRING="$(echo "${string}" | sed "s@${search}@${replace}@")"
  fi

  return 0;
} #; kbase::replace_string $string $search $replace $replaceAllOccurences

kbase::init
