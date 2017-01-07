#!/bin/bash

#
# This file only contains error declarations
#

# initialize needed variables
__CURRENT_FILE="${0##*/}"

#---------------------------------------------------#
#       > List of all available error types <       #
#---------------------------------------------------#
# Definition..........:
#   ["typeOfError:errorName"]="numberOfArguments"
#---+
# Description.........:
#   The type of error is the internal name of the error as used in the associative arrays below.
#   The error name is the actual name of a specific error in the corresponding associative array.
#   The number of arguments defines how many arguments the createError function expects to create 
#   a proper error message.
#---+
# Example.............:
#   > typeOfError 
#       __KBASE_GENERIC_ERROR_DESCRIPTIONS -> __KBASE_GENERIC_ERROR
#       So basically _DESCRIPTIONS/ERROR_CODES is getting removed from the name the
#       associative arrays are using.
#   > errorName:
#       __KBASE_GENERIC_ERROR_DESCRIPTIONS contains elements such as "GENERIC_ERROR"
#       and GENERIC_FILE_ACCESS_ERROR; Those are used as errorName.
#   > numberOfArguments:
#       Well .. take a look at the description
# 
#---------------------------------------------------#
#  Error.Descriptions:
#  NOTE: Every error has %function% and %line% defined and thus those are not counting to the number of arguments  
# 
#----+----------------------------+------------------------------------+-------------+--------------------------------------------------------------------------------+
# #  | Error Type                 | Error Name                         | # Arguments | Arguments                                                                      |
#----+----------------------------+------------------------------------+-------------+--------------------------------------------------------------------------------+
# 10 | __KBASE_GENERIC_ERROR      | GENERIC_ERROR                      |      0      |                                       --                                       |
# 11 | __KBASE_GENERIC_ERROR      | GENERIC_FILE_ACCESS_ERROR          |      2      | accessedFile, accessUser                                                       |
# 20 | __KBASE_GENERAL_ERROR      | BINARY_MISSING                     |      1      | missingBinary                                                                  |
# 30 | __KBASE_FUNCTION_ERROR     | MISSING_ARGUMENT                   |      2      | numberOfExpectedArguments, numberOfRecievedArguments                           |
# 31 | __KBASE_FUNCTION_ERROR     | BAD_ARGUMENT                       |      2      | expectedArgument, recievedArgument, argumentName                               |
# 40 | __KBASE_VARIABLE_ERROR     | BAD_TYPE                           |      3      | expectedType, recievedValue, argumentName                                      |
# 41 | __KBASE_VARIABLE_ERROR     | VARIABLE_UNSET                     |      2      | variableName, variableValue                                                    |     
#----+----------------------------+------------------------------------+-------------+--------------------------------------------------------------------------------+
# 
declare -Ar __KBASE_ERROR_LIST=(
  ["__KBASE_GENERIC_ERROR:GENERIC_ERROR"]="0"
  ["__KBASE_GENERIC_ERROR:GENERIC_FILE_ACCESS_ERROR"]="2"
  ["__KBASE_GENERAL_ERROR:BINARY_MISSING"]="1"
  ["__KBASE_FUNCTION_ERROR:MISSING_ARGUMENT"]="2"
  ["__KBASE_FUNCTION_ERROR:BAD_ARGUMENT"]="3"
  ["__KBASE_VARIABLE_ERROR:BAD_TYPE"]="3"
) #; __KBASE_ERROR_LIST


#---------------------------------------------------#
#           > List of all generic errors <          #
#---------------------------------------------------#
declare -Ar __KBASE_GENERIC_ERROR_DESCRIPTIONS=(
  ["GENERIC_ERROR"]="Function '%function%' (@ line '%line%') has thrown a not specified error."
  ["GENERIC_FILE_ACCESS_ERROR"]="Function '%function%' (@ line '%line%') has thrown a generic file access error. This basically means it was tried to access, modify or execute a file, where the executing user ('%accessUser%') does not have access for. The file, which was tried to access is '%accessedFile%'."
  ["BINARY_MISSING"]="Function (@ line '%line%') reported, that a requiered ('%missingBinary%') binary is missing."
) #; __KBASE_GENERIC_ERROR_DESCRIPTIONS

declare -Ar __KBASE_GENERIC_ERROR_CODES=(
  ["GENERIC_ERROR"]="10"
  ["GENERIC_FILE_ACCESS_ERROR"]="11"
  ["BINARY_MISSING"]="12"
) #; __KBASE_GENERIC_ERROR_CODES
#---------------------------------------------------#
#              >  END generic errors <              #
#---------------------------------------------------#


#---------------------------------------------------#
#           > List of all general errors <          #
#---------------------------------------------------#
declare -Ar __KBASE_GENERAL_ERROR_DESCRIPTIONS=(
  ["BINARY_MISSING"]="Function (@ line '%line%') reported, that a requiered ('%missingBinary%') binary is missing."
) #; __KBASE_GENERIC_ERROR_DESCRIPTIONS

declare -Ar __KBASE_GENERAL_ERROR_CODES=(
  ["BINARY_MISSING"]="20"
) #; __KBASE_GENERIC_ERROR_CODES
#---------------------------------------------------#
#              >  END generic errors <              #
#---------------------------------------------------#


#---------------------------------------------------#
#          > List of all function errors <          #
#---------------------------------------------------#
declare -Ar __KBASE_FUNCTION_ERROR_DESCRIPTIONS=(
  ["MISSING_ARGUMENT"]="Function '%function%' (@ line '%line%') was called with %numberOfRecievedArguments%, but expected %numberOfExpectedArguments%."
  ["BAD_ARGUMENT"]="Function '%function%' (@ line '%line%') expected variable '%argumentName% to be a type of '%expectedType%, but recieved '%recievedValue%' as value."
) #; __KBASE_FUNCTION_ERROR_DESCRIPTIONS

declare -Ar __KBASE_FUNCTION_ERROR_CODES=(
  ["MISSING_ARGUMENT"]="30"
  ["BAD_ARGUMENT"]="31"
) #; __KBASE_FUNCTION_ERROR_CODES
#---------------------------------------------------#
#              >  END funtion errors <              #
#---------------------------------------------------#



#---------------------------------------------------#
#          > List of all variable errors <          #
#---------------------------------------------------#
declare -Ar __KBASE_VARIABLE_ERROR_DESCRIPTIONS=(
  ["BAD_TYPE"]="Function '%function%' (@ line '%line%') expected a variable with the type '%expectedType%', but the checked variable '%variableName%' had an invalid value ('%variableValue%') for this type set."
  ["VARIABLE_UNSET"]="Function %function% (@ '%line') found that the variable '%variableName%' is unset. It will be set to '%variableValue%'."
) #; __KBASE_VARIABLE_ERROR_DESCRIPTIONS

declare -Ar __KBASE_VARIABLE_ERROR_CODES=(
  ["BAD_TYPE"]="40"
  ["VARIABLE_UNSET"]="41"
) #; __KBASE_VARIABLE_ERROR_CODES
#---------------------------------------------------#
#              >  END variable errors <             #
#---------------------------------------------------#




#-----------------------------
# kbase::print_verbose_information <currentFile> <currentFunction> <currentLine> <callStack>
#------
# Description:
#--------
#   Prints the file, the function, the line and the call stack of
#   the function, which called kbase::print_verbose_information
#------
# Globals:
#--------
#  #  | Name     | Origin  | Access (r = read, w = write)
#-----+----------+---------+--------------------------------------->
#  1  - FUNCNAME  (BASH)   : r
#  2  - LINENO    (BASH)   : r
#------
# Arguments:
#----------
#  #  | Variable         | Type          | Description                                                       
#-----+------------------+---------------+--------------------------->
#  $1 - <currentFile>     (string       ): File of the function, which called kbase::print_verbose_information
#  $2 - <currentFunction> (string       ): Name of the function, which called kbase::print_verbose_information
#  $3 - <currentLine>     (integer      ): Line where the call to the function kbase::print_verbose_information happend
#  $4 - <callStack>       (numeric array): Standard array, which holds the calls of functions from the beginning (main) 
#                                        until the function before kbase::print_verbose_information
#------
# Returns:
#--------
#  #  | Type    | Description
#-----+---------+-------------------------------------------------->
#   0 - (return): Everything went fine
#   1 - (exit  ): Exit code, when not enough arguments are given
#-----------------------------
function kbase::print_verbose_information ( ) {
  [ "${#}" -eq 4 ] || { 
    printf "File......: ${0##*/}\nFunction..: ${FUNCNAME[0]}\nLine#.....:${LINENO}\nCall Stack:${FUNCNAME[*]}\nNot enough arguments. 3 expected, recieved $#\n";
    exit 1; 
  };

  declare currentFile="${1}"
  declare currentFunction="${2}"
  declare currentLine="${3}"
  declare -a callStack=(${4//\ / })

  printf "File........: ${currentFile}\n"
  printf "Function....: ${currentFunction}\n"
  printf "Line........: ${currentLine}\n"
  printf "Call Stack..:\n"

  # The variable $counter actually iterates over the callStack array, but to prettify
  # the output the callNumber counts the inverse way, so the output looks like:
  # call #4: function3
  # call #3: function2
  # call #2: function1
  # call #1: main
  declare -i counter=0
  declare -i callNumber="${#callStack[@]}"
  while [ "${counter}" -lt "${#callStack[@]}" ]; do
    printf "  > call #%02d: %s\n" "${callNumber}" "${callStack["${counter}"]}"
    ((callNumber--))
    ((counter++))
  done
} #; kbase::print_verbose_information <currentFile> <currentFunction> <currentLine> <callStack>


#-----------------------------
# kbase::create_error
#------
# Description:
#--------
#   Used to create an error for a specific event. To see a list of all defined error messages
#   check the definition above at __KBASE_ERROR_LIST.
#------
# Globals:
#--------
#   #  | Name                | Origin  | Access (r = read, w = write)
#------+---------------------+---------+--------------------------------------->
#   1  - FUNCNAME            (BASH)    : r
#   2  - LINENO              (BASH)    : r
#   3  - __KBASE_ERROR_LIST  (internal): r
#   4  - __REPLACED_STRING   (internal): rw
#------
# Arguments:
#----------
#  #  | Variable       | Type          | Description                                                       
#-----+----------------+---------------+--------------------------->
#  $1 - currentFile     (string       ): File of the function, which called kbase::print_verbose_information
#  $2 - currentFunction (string       ): Name of the function, which called kbase::print_verbose_information
#  $3 - currentLine     (integer      ): Line where the call to the function kbase::print_verbose_information happend
#  $4 - callStack       (numeric array): Standard array, which holds the calls of functions from the beginning (main) 
#                                        until the function before kbase::create_error
#  $5 - errorType       (string       ): Type of the error
#  $6 - error           (string       ): Specific error
#  $+ -     --              --         : All arguments after $6 are optional and vary in their number. That depends on
#                                        the type of error requested.
#------
# Returns:
#--------
#  #  | Type    | Description
#-----+---------+-------------------------------------------------->
#   0 - (return): Everything went fine
#   1 - (exit  ): Exit code, when not enough arguments are given
#-----------------------------
function kbase::create_error ( ) {
  [ "${#}" -ge 3 ] || { 
    printf "Function '${FUNCNAME[0]}' (@line '${LINENO}') expected 3 arguments, but recieved only: ${#}\n";
    exit 1; 
  }; 

  declare currentFile="${1}"
  declare currentFunction="${2}"
  declare currentLine="${3}"
  declare callStack="${4}"
  declare errorType="${5}"
  declare error="${6}"
  
  # remove the already assigned values from the arguments
  shift 6

  # check if we have a valid error type
  declare -i validType=1
  for definedError in "${!__KBASE_ERROR_LIST[@]}"; do
    if [[ "${errorType}:${error}" =~ ^${definedError}$ ]]; then
      # type is valid
      validType=0
      break;
    fi
  done

  # type is not valid
  [ "${validType}" -eq 0 ] || { 
    printf "Function '${FUNCNAME[0]}' (@line '${LINENO}') recieved an invalid error type ('${errorType}:${error}').\n";
    exit 1; 
  };

  # check if enough arguments are given for the specific error type
  [ "${__KBASE_ERROR_LIST["${errorType}:${error}"]}" -eq "${#}" ] || {
    kbase::print_verbose_information "${0##*/}" "${FUNCNAME[0]}" "${LINENO}" "${FUNCNAME[*]}";
    printf "Function '${FUNCNAME[0]}' (@line '${LINENO}') did not recieve enough arguments for the error type requested\n"; 
    printf "Type: '${errorType}:${error}', Expected # of arguments '${__KBASE_ERROR_LIST["${errorType}:${error}"]}', Recieved # of arguments: '${#}'\n";
    exit 1;
  };

  # as this is an error some additional info wouldn't hurt
  kbase::print_verbose_information "${currentFile}" "${currentFunction}" "${currentLine}" "${callStack}"


  declare errorMessage=""
  case "${errorType}:${error}" in
    "__KBASE_GENERIC_ERROR:GENERIC_ERROR")
      errorMessage="${__KBASE_GENERIC_ERROR_DESCRIPTIONS["${error}"]}"
    ;;
    "__KBASE_GENERIC_ERROR:GENERIC_FILE_ACCESS_ERROR")
      declare accessedFile="${1}"
      declare accessUser="${2}"
      kbase::replace_string "${__KBASE_GENERIC_ERROR_DESCRIPTIONS["${error}"]}" "%accessedFile%" "${accessedFile}" "1"
      kbase::replace_string "${__REPLACED_STRING}" "%accessUser%" "${accessUser}" "1"
      errorMessage="${__REPLACED_STRING}"
    ;;
    "__KBASE_FUNCTION_ERROR:MISSING_ARGUMENT")
      declare expectedNumberOfArguments="${1}"
      declare recievedNumberOfArguments="${2}"
      kbase::replace_string "${__KBASE_FUNCTION_ERROR_DESCRIPTIONS["${error}"]}" "%expectedNumberOfArguments%" "${expectedNumberOfArguments}" "1"
      kbase::replace_string "${__REPLACED_STRING}" "%recievedNumberOfArguments%" "${recievedNumberOfArguments}" "1"
      errorMessage="${__REPLACED_STRING}"
    ;;
    "__KBASE_FUNCTION_ERROR:BAD_ARGUMENT")
      declare expectedArgument="${1}"
      declare recievedArgument="${2}"
      declare argumentName="${3}"
      kbase::replace_string "${__KBASE_FUNCTION_ERROR["${error}"]}" "%expectedArgument%" "${expectedArgument}" "1"
      kbase::replace_string "${__REPLACED_STRING}" "%recievedArgument%" "${recievedArgument}" "1"
      kbase::replace_string "${__REPLACED_STRING}" "%argumentName%" "${argumentName}" "1"
      errorMessage="${__REPLACED_STRING}"
    ;;
    "__KBASE_VARIABLE_ERROR:BAD_TYPE")
      declare expectedType="${1}"
      declare recievedArgument="${2}"
      declare argumentName="${3}"
      kbase::replace_string "${__KBASE_FUNCTION_ERROR["${error}"]}" "%expectedType%" "${expectedType}" "1"
      kbase::replace_string "${__REPLACED_STRING}" "%recievedValue%" "${recievedArgument}" "1"
      kbase::replace_string "${__REPLACED_STRING}" "%argumentName%" "${argumentName}" "1"
      errorMessage="${__REPLACED_STRING}"
    ;;    
    *)
      printf "'${FUNCNAME[0]}' (@line '${LINENO}') error type '${errorType}:${error}' not supported (yet?).\n"
      exit 2;
    ;;
  esac
   
  # replace the variables every error message has
  kbase::replace_string "${__REPLACED_STRING}" "%line%" "${currentLine}" "1"
  kbase::replace_string "${__REPLACED_STRING}" "%function%" "${currentFunction}" "1"

  # print the final error message
  echo -e "${errorMessage}"
  
  # reset __REPLACED_STRING
  __REPLACED_STRING=""
} #; function kbase::create_error ( )

__REPLACED_STRING=""                        # Variable stores the replaced string from kbase::replace_string
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
#   1 - (exit  ): Exit code, when not enough arguments are given
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
  # TODO: TYPEOF(INT) needed
  [ -z "${4}" ] || {
    replaceAllOccurences=0
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
