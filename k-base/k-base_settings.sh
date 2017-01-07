#!/bin/bash

#
# Config file for kbase framework
#

#---------------------------------------#
#              > logging <              #
#---------------------------------------#
declare -ir DEBUG=0                                # Get verbose output (0 = true, 1 = false .. it's BASH)
declare -r LOG_FILE="kbase.log"                    # File every log output gets written
declare -r LOG_LEVEL="DEBUG"                       # This setting defines the verbosity of kbase.
#                                                  # Valid values are:
#                                                  # NONE, ERROR, WARNING, INFORMATION, DEBUG, ALL
#                                                  # Abbrevations are allowed as well:
#                                                  # ERR, WARN, INFO, DBG
#                                                  # Note: If you set the LOG_LEVEL to NONE, you are not getting notified about ANYTHING - not even errors.
declare -r LOG_DATE_FORMAT="%d.%m.%y :: %H:%M:%S"  # Refer to man date for formatting options

