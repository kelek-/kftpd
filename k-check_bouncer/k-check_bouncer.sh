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
#                      k-check_bouncer.sh v0.1k                        #
#----------------------------------------------------------------------#
# Description:                                                         #
#---                                                                   #
# This is a script for sites with many or slow bouncers. Also it is    #
# pretty helpful when a bouncer is down and blocking the sitebots      #
# output since its still stuck with trying to login to the questionable#
# bouncer.                                                             #
# What this script does is pretty simple:                              #
# It checks your bouncers on a regulary basis - crontab ftw - and      #
# prints the results to a file, which your sitebot can read and print  #
# to your sitechannel(s).                                              #
# So what makes that a better solution compared to the standard ngBot  #
# !bnc feature?                                                        #
#  - It does not block your sitebots output while trying to reach slow #
#    or unreachable bouncers.                                          #
#  - You have way more customization options, than with ngBot          #
#  - It is possible to display the logintime, the pingtime and how     #
#    many hops it actually need to reach the questionable bouncer      #
#  - Sort output for pingTime, loginTime, numberOfHops and timeChecked #
#  - Well .. its from me, so its good by design ;p                     #
#---                                                                   #
# Installation:                                                        #  
#---                                                                   #
# First of all, the installation is pretty simple, unless you want to  #
# sort your bouncers for ping time, login time, the number of hops or  #
# the last time a bouncer was checked.                                 #
#                                                                      #
# > Basic installation:                                                #
# Copy this script over to /glftpd/bin and do a chmod +x on it. Edit   #
# the settings below, to fit your needs and add a cronjob like:        #
# 5 * * * * /glftpd/bin/k-check_bouncer.sh 2>&1 > /dev/null            #
# This cronjob runs every hour - five minutes after the full hour.     #
#                                                                      #
# In addition to that, you can use k-list_bouncer.sh, which is a       #
# script to display the bouncer as site command or k-list_bouncer.tcl  #
# which is meant as replacement for the ngBot !bnc command or as       #
# addition to it. Refer to the installation in these files.            #
#                                                                      #
#                                                                      #
# > ADVANCED installation:                                             #
# This type of installation is only required if you are going to use   #
# the sort features in this script. Namely sort for login and ping     #
# time, as well as sort for number of hops or the time a bouncer was   #
# last checked.                                                        #
#                                                                      #
# Here is the problem:                                                 #
# BASH itself in its current stable version of 4.3.x does not support  #
# the sorting of associative arrays for its values and retain the      #
# order of keys.                                                       #
# However BASH 4.4.x is introducing so called "BASH Built-ins", which  #
# allows the user to load "plugins" written in native C/C++, which     #
# will then be available as command within BASH, once enabled.         #
# Luckily Geir "geirha" Hauge has written a BASH built-in for sorting  #
# associative arrays and retains the keys, which is called "asort".    #
# Thanks at this point geirha!                                         #
# To enable this built-in, you have to checkout the current BASH devel #
# branch and build some parts of it - however, as I know, most of the  #
# users running this script are lazy asses, I included an already      #
# built asort, which was built on a current stable Debian.             #
# I haven't tried to use it on another box as mine, but if you are     #
# lucky enough, its enough to copy it to /usr/lib/ and run ldconfig.   #
#                                                                      #
# So, the commands would be:                                           #
#   cp asort /usr/lib                                                  #
# and                                                                  #
#   ldconfig                                                           #
# Now try running                                                      #
#   enable -f asort asort                                              #
# If that command succeeds, you are lucky and don't need to build it   #
# yourself.                                                            #
# ... if that doesn't work, contiue reading.                           #
#                                                                      #
# > EXPERT installation:                                               #
# If you are still looking forward to sort your bouncers, then we need #
# a couple of things:                                                  #
#   - git                                                              #
#   - bison (BASH devel-headers is using yacc)                         #
#   - build-essential (like gcc, make, etc .. )                        #
#   - some other tools BASH needs to build (I don't know which tools   #
#     you need exactly, but you'll figure that out :>)                 #
#                                                                      #
# Following steps need to be performed:                                #
# 1. Checkout the current BASH source                                  #
#    > git clone git://git.sv.gnu.org/bash.git                         #
# 2. Enter the cloned repo, checkout the devel branch and pull any     #
#    possible updates                                                  #
#    > cd bash && git checkout devel && git pull                       #
# 3. Configure the devel branch and install the devel-headers          #
#    > ./configure                                                     #
#    > make && make install-headers                                    #
#    > make -C examples/loadables install-dev                          #
# 4. Clone the builtins from geirha                                    #
#    > cd .. && git clone https://github.com/geirha/bash-builtins.git  #
# 5. Make all builtins, copy it to /usr/lib and update ldconfig        #
#    > cd bash-builtins && make && cp asort /usr/lib && ldconfig       #
# 6. Try loading asort                                                 #
#    > enable -f asort asort                                           #
#                                                                      #
# If that didn't work out, you did something wrong. Try resolving it   #
# yourself or simply don't sort your bouncers.                         #
# ... or wait until BASH 4.4 gets stable - I bet it is way easier to   #
# install built-ins to that time then.                                 #
#                                                                      # 
#---                                                                   #
# Bugs:                                                                #
#---                                                                   #
# Not that I know of any, feel free to msg me - you know where!        #
#---                                                                   #
# Planned features:                                                    #
#---                                                                   #
#  - Extend TCL and BASH script to support the sorted bouncers         #
#---                                                                   #
# Added features:                                                      #
# - Make a complete new function to totally customize the output with  #
#   variables like %%TLD%% etc (done! - 08/24/2016)                    #
# - Print the bouncers in order of pingtime, logintime or              #
#   hops (done! - 08/26/2016)                                          #
# - Provide a TCL script for your sitebot to output these              #
#   bouncers (done! - 08/25/2016)                                      #
# - Provide a BASH script for your glftpd installation to output these #
#   bouncers aswell (done! - 08/25/2016)                               #
#---                                                                   #
# Conclusion:                                                          #
#---                                                                   #
# Wow .. that was a big task. I thought I'll finish this in less than  #
# one day, but I ended up adding more and more features, so it quickly #
# blew up.                                                             #
# In the end I'm happy I'm done and it looks quite ok to me - code-    #
# and logicalwise, so I hope you'll enjoy it .. or naht :>             #
#                                                                      #
#                                                                      #
# Feel free to share, edit, delete, burn, eat or whatever you wish to  #
# do with this script. I made it for fun, so I don't care ;>           #
#                                                                      #
# .. yes, it could be written better, but you know what? Suck ma dick! #
#                                                                      #
#                                                                      #
# Sincerly,                                                            #
#  |k @ 26th August of 2o16                                            #
#----------------------------------------------------------------------#     
# Changelog:                                                           #
#---                                                                   #
# v0.1k (8/20/2016) Initial release                                    #
# v0.2k (8/20/2016) Commented the code properly                        #
# v0.5k (8/20/2016) Function format_output added. Code improvements    #
#                   NOT working in this state - next week more.        #
# v0.7k (8/24/2016) Improved code. Function format_output updated.     #
#                   More variables are now available.                  #
# v0.8k (8/24/2016) Added brief descriptions and commented             #
#                   questionable code parts.                           #
#                   And as always: Code improvements (:                #
# v1.0k (8/26/2016) Realized sorting of bouncers. Cleaned code (multi- #
#                   line strings ftw). Updated installation part       #
#----------------------------------------------------------------------#


# import curl codes
# looks a bit strange, but yea .. this is just about right 
# to surpress the error message, when the file is not there and display a custom one
# .. and dear kids, remember: ALWAYS CLEAN YOUR SHIT!
exec 9>&2; exec 2> /dev/null
source k-curl_codes.sh || { echo "ERROR: k-curl_codes.sh could not be loaded!"; exec 2>&9; exec 9>&-; exit 1; }
exec 2>&9; exec 9>&-

#                                            #
# <- S E T T I N G S  B E G I N  H E R E  -> #
#                                            #

#
# bouncer settings
#
readonly BNC_USER="user"                                                  # User to login to your site
readonly BNC_PASSWORD="password"                                          # Password of the user
readonly BNC_SSL=true                                                     # Connect to the bouncer via SSL
declare -ir BNC_TIMEOUT=5                                                 # Timeout of how long we should wait until we stop the connecting process

#
# additional checks
#
readonly PING_HOST=false                                                  # Ping the host additionally to logging in
readonly TRACEROUTE_HOST=false                                            # Traceroute the host and record the hops
declare -ir MAX_HOPS=25                                                   # Maximum hops it should trace - remember, the more hops the longer it takes and the longer the runtime of this script is

#
# file settings
#
readonly GLFTPD_ROOT_PATH="/glftpd"                                       # Well ..
readonly BNC_FILE="/ftp-data/misc/bouncer.list"                           # File the bouncer data is stored in - relative path!
readonly BNC_FILE_PING_TIMES="/ftp-data/misc/bouncer_ping_times.list"     # File the bouncer data is stored in, when sorting for ping times - relative path!
readonly BNC_FILE_LOGIN_TIMES="/ftp-data/misc/bouncer_login_times.list"   # File the bouncer data is stored in, when sorting for login times - relative path!
readonly BNC_FILE_HOPS="/ftp-data/misc/bouncer_hops.list"                 # File the bouncer data is stored in, when sorting for number of hops - relative path!
readonly BNC_FILE_LAST_CHECKED="/ftp-data/misc/bouncer_last_checked.list" # File the bouncer data is stored in, when sorting for last checked times - relative path!
readonly DEBUG=false                                                      # Get verbose output

#
# Format/output/sort settings
#
readonly DATE_FORMAT="%D %H:%M:%S %Z"                                     # Format the output from GNU date (date -h too check whats possible) - remember: garbage in, garbage out!
readonly PREFIX_ZERO=true                                                 # Prefix a zero for the bouncer count while the bouncers are less than 10
readonly SORT_ASCENDING=true                                              # Sort output ascending (only relevant for $SORT_OUTPUT_FOR_BOUNCER_PING_TIME, $SORT_OUTPUT_FOR_BOUNCER_LOGIN_TIME,
                                                                          # $SORT_OUTPUT_FOR_BOUNCER_NUMBER_OF_HOPS and $SORT_OUTPUT_FOR_BOUNCER_LAST_CHECKED_TIMES)
                                                                          # NOTE: I didn't split it in seperate boolean values for each sort type, since I can't imagine that somebody will
                                                                          #       sort it descending and ascending mixed .. even descending makes (almost) no sense imho.
#
# additional sorts
#
readonly SORT_OUTPUT_FOR_BOUNCER_PING_TIME=true                           # Sort the output for bouncer ping time
readonly SORT_OUTPUT_FOR_BOUNCER_LOGIN_TIME=false                         # Sort the output for bouncer login time
readonly SORT_OUTPUT_FOR_BOUNCER_NUMBER_OF_HOPS=false                     # Sort the output for number of hops
readonly SORT_OUTPUT_FOR_BOUNCER_LAST_CHECKED_TIMES=false                 # Sort the output for the time the bouncer was last checked


# 
# Array, which holds your bouncers
# NOTE: A _unique_ name is needed to work properly! (name = key)
# Format:
#   ["uniqeName"]="ip:port"
# Example: 
#   ["Netherlands"]="127.0.0.1:8888"
# 
declare -Ar BOUNCER=(
)

#
# These are the settings for each bouncer, you defined above
# NOTE: You _need_ to use the same uniqueName for the settings as in $BOUNCER
#
# Following fields can be used in this array:
#
# > Field             <> Description                                                   <> Type    <
# -------------------------------------------------------------------------------------------------
# > TIMEOUT_SEC       <> Timeout for curl, when connecting to a bouncer                <> Integer <
# > BNC_USER          <> Username to log into your glftpd instance through the bouncer <> String  <
# > BNC_PASSWORD      <> Password for the user                                         <> String  <
# > BNC_SSL           <> Determines, wheter the connection is done via SSL or not      <> Boolean <
# > BNC_TLD           <> Top level domain, where your bouncer is located               <> String  <
# > BNC_COUNTRY       <> Country, where your bouncer is located                        <> String  <
# > BNC_NICKNAME      <> Nickname for your bouncer                                     <> String  <
# > BNC_CITY          <> City, where your bouncer is located                           <> String  <
# > BNC_ISP           <> ISP of the bouncer                                            <> String  <
# > BNC_DESCRIPTION   <> A description of your bouncer                                 <> String  <
#
# All values need to be in double quotes ("") and seperated from each other with a percent sign ('%' - withouth quotes).
# Since the whole line itself is a string, the quotes are needed to be escaped (with '\', but without quotes).
# 
# The format needs to be _exactly_ like this, else it will print out pure garbage. The order is _important_!
# Format:
#   ["uniqueName"]="TIMEOUT_SEC%BNC_USER%BNC_PASSWORD%BNC_SSL%BNC_TLD%BNC_COUNTRY%BNC_NICKNAME%BNC_CITY%BNC_ISP%BNC_DESCRIPTION"
# Example:
#   ["Sweden1"]="10%\"${BNC_USER}\"%\"${BNC_PASSWORD}\"%\"${BNC_SSL}\"%\"se\"%\"Sweden\"%\"Daan\"%\"Stockholm Lan\"%\"Sweden Telecom\"%\"Description comes here\""
#     ^unique Name ^         ^          ^                   ^SSL         ^TLD   ^                    ^city           ^                  ^Description
#                  ^timeout  ^          ^                                       ^country                             ^ISP
#                            ^user      ^
#                                       ^password
#
# If you decide to not to use one of these fields, set it in empty quotes (" "), as the order needs to stay correctly!
# HINT: Usually it doesn't happen, that you have different users,passwords and SSL settings for your bouncers, so you usually just can
#       use $BNC_USER, $BNC_PASWORD and $BNC_SSL. Please set the variables like \"${BNC_PASSWORD}\" < this .. trust me, its better. It really is.
#       For the timeout however, it often helps to set it for each bouncer different. If you get unexpected timeouts, try setting this value higher.
#       Of course you still can use $BNC_TIMEOUT as a general timeout value and increase only those, which randomly time out.
declare -Ar BOUNCER_SETTINGS=(
)

#
# These settings will determine how your output of the different bouncers will be
# NOTE: Some of them doesn't really make sense to output - like %%BNC_PASSWORD%% and %%BNC_USER%% for example - but I included them anyway, since it
#       isn't really much more effort. So in case anybody want to use such things, go for it! :) (I don't recommend it however)
#
# You don't need to use every variable of course - just use those, you want to use. You'll find a reasonable example right below the table! (:
# However, you are required to use both offline and online templates (as some variables are only available in either of those) and define all your
# bouncers there.
# I don't verify those templates, so garbage in, garbage out. ;>
#
# Available variables:
# variable                    -> description                                                                                < can be used with template
#-------------------------------------------------------------------------------------------------------------------------------------------------------
# %%BNC_NUMBER%%              -> Number of the bouncer - just an incrementing number starting from 1                        < online, offline
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
# %%BNC_CITY%%                -> City where the bouncer is located from $BOUNCER_SETTINGS                                   < online, offline
# %%BNC_ISP%%                 -> ISP where the bouncer is located from $BOUNCER_SETTINGS                                    < online, offline
# %%BNC_DESCRIPTION%%         -> Description of the bouncer from $BOUNCER_SETTINGS                                          < online, offline
# %%BNC_PING_TIME%%           -> Pingtime of the bouncer (calculated)                                                       < online
# %%BNC_LOGIN_TIME%%          -> Logintime of the bouncer (calculated)                                                      < online
# %%BNC_HOPS%%                -> Hops to the bouncer (calculated)                                                           < online
# %%BNC_LAST_CHECKED%%        -> Time when the bouncer was checked the last time (calculated)                               < online, offline
# %%CURL_ERROR_CODE%%         -> Error code of curl (if an error while connecting happens)                                  < offline
# %%CURL_ERROR%%              -> Error name of curl (if an error while connecting happens)                                  < offline
# %%CURL_ERROR_DESCRIPTION%%  -> Description of the curl error (if an error while connecting happens)                       < offline
#
# Example:
#   Online:
#     ["Sweden1"]="#%%BNC_NUMBER%% (.%%BNC_TLD%%) UP!: %%BNC_HOST_HEXADECIMAL%%:%%BNC_PORT%% located in %%BNC_COUNTRY%%\%%BNC_CITY%% at %%BNC_ISP%% (Ping: %%BNC_PING_TIME%%ms, Login: %%BNC_LOGIN_TIME%%ms) (last check: %%BNC_LAST_CHECKED%%)"
#   Offline:
#     ["Sweden1"]="#%%BNC_NUMBER%% (.%%BNC_TLD%%) DN!: %%BNC_HOST_HEXADECIMAL%%:%%BNC_PORT%% located in %%BNC_COUNTRY%%\%%BNC_CITY%% at %%BNC_ISP%% (%%CURL_ERROR_DESCRIPTION%%) (last check: %%BNC_LAST_CHECKED%%)"
#

declare -A BOUNCER_ONLINE_TEMPLATE=(
) #; BOUNCER_ONLINE_TEMPLATE

declare -A BOUNCER_OFFLINE_TEMPLATE=(
) #; BOUNCER_OFFLINE_TEMPLATE

#                                            #
# < - S E T T I N G S  E N D  H E R E !  - > #
#                                            #




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
  
  #
  # validate variables and values
  #

  # check for boolean types - only allow 'true' and 'false' - w/o quotes  
  [[ "${PING_HOST}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${PING_HOST}') for 'PING_HOST' set. Only 'true' or 'false (without '') is valid."; exit 1; }
  [[ "${TRACEROUTE_HOST}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${TRACEROUTE_HOST}') for 'TRACEROUTE_HOST' set. Only 'true' or 'false (without '') is valid."; exit 1; }
  [[ "${BNC_SSL}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${BNC_SSL}') for 'BNC_SSL' set. Only 'true' or 'false' (without '') is valid."; exit 1; }
  [[ "${DEBUG}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${DEBUG}') for 'DEBUG' set. Only 'true' and' 'false' (without '') is valid."; exit 1; }
  [[ "${PREFIX_ZERO}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${PREFIX_ZERO}') for 'PREFIX_ZERO'. Only 'true' and 'false' (without '') is valid."; exit 1; }
  [[ "${SORT_OUTPUT_FOR_BOUNCER_PING_TIME}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${SORT_OUTPUT_FOR_BOUNCER_PING_TIME}') for 'SORT_OUTPUT_FOR_BOUNCER_PING_TIME'. "\
										"Only 'true' and 'false' (without '') is valid."; exit 1; }
  [[ "${SORT_OUTPUT_FOR_BOUNCER_LOGIN_TIME}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${SORT_OUTPUT_FOR_BOUNCER_LOGIN_TIME}') for 'SORT_OUTPUT_FOR_BOUNCER_LOGIN_TIME'. "\
										"Only 'true' and 'false' (without '') is valid."; exit 1; }
  [[ "${SORT_OUTPUT_FOR_BOUNCER_PING_TIME}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${SORT_OUTPUT_FOR_BOUNCER_PING_TIME}') for 'SORT_OUTPUT_FOR_BOUNCER_PING_TIME'. "\
										"Only 'true' and 'false' (without '') is valid."; exit 1; }
  [[ "${SORT_OUTPUT_FOR_BOUNCER_NUMBER_OF_HOPS}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${SORT_OUTPUT_FOR_BOUNCER_NUMBER_OF_HOPS}') for 'SORT_OUTPUT_FOR_BOUNCER_NUMBER_OF_HOPS'. "\
										"Only 'true' and 'false' (without '') is valid."; exit 1; }
  [[ "${SORT_OUTPUT_FOR_BOUNCER_LAST_CHECKED_TIMES}" =~ ^(true|false)$ ]] || { echo "ERROR: Invalid value ('${SORT_OUTPUT_FOR_BOUNCER_LAST_CHECKED_TIMES}') for "\
										"'SORT_OUTPUT_FOR_BOUNCER_LAST_CHECKED_TIMES'. Only 'true' and 'false' (without '') is valid."; exit 1; }

  #  check for empty or invalid values
  [ -n "${BNC_USER}" ] || { echo "ERROR: 'BNC_USER' is not set."; exit 1; }
  [ -n "${BNC_PASSWORD}" ] || { echo "ERROR: 'BNC_PASSWORD' is not set."; exit 1; }
  [[ "${BNC_TIMEOUT}" =~ ^[[:digit:]]+$ ]] || { echo "ERROR: Invalid value ('${BNC_TIMEOUT}') for 'BNC_TIMEOUT' set. Only digits are valid."; exit 1; }
  [ ${BNC_TIMEOUT} -gt 0 ] || { echo "ERROR: A value of less than 1 makes no sense for timeout!"; exit 1; }
  if ${TRACEROUTE_HOST}; then
    [[ "${MAX_HOPS}" =~ ^[[:digit:]]+$ ]] || { echo "ERROR: Invalid value ('${MAX_HOPS}') for 'MAX_HOPS' set. Only digits are valid."; exit 1; }
    ( [ ${MAX_HOPS} -lt 256 ] && [ ${MAX_HOPS} -gt 0 ] ) || { echo "ERROR: Invalid value ('${MAX_HOPS}') for 'MAX_HOPS' set. Maximum allowed is 255 and minimum allowed is 1."; exit 1; }
  fi

  # check for necessary binaries
  command -v curl 2>&1 > /dev/null || { echo "ERROR: 'curl' is needed to run this script!"; exit 1; }
  command -v sed 2>&1 > /dev/null ||{ echo "ERROR: 'sed' is needed to run this script!"; exit 1; }
  command -v printf 2>&1 > /dev/null || { echo "ERROR: 'printf' is needed to run this script!"; exit 1; }
  command -v cat 2>&1 > /dev/null || { echo "ERROR: 'cat' is needed to run this script!"; exit 1; }
  [[ "${BASH_VERSION}" =~ ^4\. ]] || { echo "ERROR: BASH version 4.x is needed to run this script!;" exit 1; }

  # check for necessary binaries conditional (e.g. we don't need ping, if we are not going to use PING_HOST)  
  if ${PING_HOST} && ! $(command -v ping 2>&1 > /dev/null);  then
    echo "ERROR: 'PING_HOST' is set, but you don't have 'ping', which is necessary to use this function"; exit 1
  fi

  if ${TRACEROUTE_HOST} && ! $(command -v traceroute 2>&1 > /dev/null); then
    echo "ERROR: 'TRACEROUTE_HOST' is set, but you don't have 'traceroute', which is necessary to use this function!"; exit 1
  fi

  if ${TRACEROUTE_HOST} && ! $(command -v bc 2>&1 > /dev/null); then
    echo "ERROR: 'TRACEROUTE_HOST' is set, but you don't have 'bc', which is necessary to use this function!"; exit 1
  fi



  # check for files and folders
  if [ ! -e "${GLFTPD_ROOT_PATH}" ] || [ ! -d "${GLFTPD_ROOT_PATH}" ] || [ ! -w "${GLFTPD_ROOT_PATH}" ]; then
    echo "ERROR: 'GLFTPD_ROOT_PATH' is either not a valid directory or it is not accessible for the current user!"; exit 1
  fi

  if [ ! -e "${GLFTPD_ROOT_PATH}${BNC_FILE}" ] || [ ! -f "${GLFTPD_ROOT_PATH}${BNC_FILE}" ] || [ ! -w "${GLFTPD_ROOT_PATH}${BNC_FILE}" ]; then
    echo "ERROR: 'BNC_FILE' '${GLFTPD_ROOT_PATH}${BNC_FILE}' either does not exist, is not a valid file or is not writeable for the current user!"; exit 1
  fi


  # check for files and folders conditionally (e.g. we don't  need BNC_FILE_PING_TIMES if SORT_OUTPUT_FOR_BOUNCER_PING_TIME is not true)
  # ping times
  if ${SORT_OUTPUT_FOR_BOUNCER_PING_TIME} && ( [ ! -e "${GLFTPD_ROOT_PATH}${BNC_FILE_PING_TIMES}" ] || \
                                               [ ! -f "${GLFTPD_ROOT_PATH}${BNC_FILE_PING_TIMES}" ] || \
                                               [ ! -w "${GLFTPD_ROOT_PATH}${BNC_FILE_PING_TIMES}" ] ); then
    echo $(cat <<-EOS
	ERROR: 'SORT_OUTPUT_FOR_BOUNCER_PING_TIME' is wanted, but the necessary file BNC_FILE_PING_TIMES '${GLFTPD_ROOT_PATH}${BNC_FILE_PING_TIMES}' either
	does not exist, is not a valid file or is not writeable for the current user!
	EOS
	); exit 1
  fi

  # login times
  if ${SORT_OUTPUT_FOR_BOUNCER_LOGIN_TIME} && ( [ ! -e "${GLFTPD_ROOT_PATH}${BNC_FILE_LOGIN_TIMES}" ] || \
                                               [ ! -f "${GLFTPD_ROOT_PATH}${BNC_FILE_LOGIN_TIMES}" ] || \
                                               [ ! -w "${GLFTPD_ROOT_PATH}${BNC_FILE_LOGIN_TIMES}" ] ); then
    echo $(cat <<-EOS
	ERROR: 'SORT_OUTPUT_FOR_BOUNCER_LOGIN_TIME' is wanted, but the necessary file BNC_FILE_LOGIN_TIMES '${GLFTPD_ROOT_PATH}${BNC_FILE_LOGIN_TIMES}' either
	does not exist, is not a valid file or is not writeable for the current user!
	EOS
        ); exit 1
  fi

  # number of hops file
  if ${SORT_OUTPUT_FOR_BOUNCER_NUMBER_OF_HOPS} && ( [ ! -e "${GLFTPD_ROOT_PATH}${BNC_FILE_HOPS}" ] || \
                                               [ ! -f "${GLFTPD_ROOT_PATH}${BNC_FILE_HOPS}" ] || \
                                               [ ! -w "${GLFTPD_ROOT_PATH}${BNC_FILE_HOPS}" ] ); then
    echo $(cat <<-EOS
	ERROR: 'SORT_OUTPUT_FOR_BOUNCER_NUMBER_OF_HOPS' is wanted, but the necessary file BNC_FILE_HOPS '${GLFTPD_ROOT_PATH}${BNC_FILE_HOPS}' either
	does not exist, is not a valid file or is not writeable for the current user!
	EOS
        ); exit 1
  fi

  # last checked file
  if ${SORT_OUTPUT_FOR_BOUNCER_LAST_CHECKED_TIMES} && ( [ ! -e "${GLFTPD_ROOT_PATH}${BNC_FILE_LAST_CHECKED}" ] || \
                                               [ ! -f "${GLFTPD_ROOT_PATH}${BNC_FILE_LAST_CHECKED}" ] || \
                                               [ ! -w "${GLFTPD_ROOT_PATH}${BNC_FILE_LAST_CHECKED}" ] ); then
    echo $(cat <<-EOS
	ERROR: 'SORT_OUTPUT_FOR_BOUNCER_LAST_CHECKED_TIMES' is wanted, but the necessary file BNC_FILE_LAST_CHECKED '${GLFTPD_ROOT_PATH}${BNC_FILE_LAST_CHECKED}' either
	does not exist, is not a valid file or is not writeable for the current user!
	EOS
        ); exit 1
  fi

  # if sorting is requested, we need the bash built-in "asort" from geirha
  if ${SORT_OUTPUT_FOR_BOUNCER_PING_TIME} || ${SORT_OUTPUT_FOR_BOUNCER_LOGIN_TIME} \
     ${SORT_OUTPUT_FOR_BOUNCER_NUMBER_OF_HOPS} || ${SORT_OUTPUT_FOR_BOUNCER_LAST_CHECKED_TIMES}; then
    
    exec 9>&2; exec 2> /dev/null
    enable -f asort asort || { echo "ERROR: BASH built-in 'asort' is not available, but you requested sorting. Refer to the installation part above!"; exec 2>&9; exec 9>&-; exit 1; }
    #          ^ yes, twice asort, this is not a bug 
    exec 2>&9; exec 9>&-

    command -v asort 2>&1 || { echo "ERROR: BASH built-in 'asort' is not working properly, but you requested sorting. Refer to the installation part above!"; exit 1; }
  fi

  # everything fine
  return 0
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

  # A little note on this - quite confusing looking - set of commands:
  # - We add one more hop as requested - unless its the maximum of 255 already, so we can set the value as ">$MAX_HOPS" (more than)
  # - The first line of traceroute can't be surpressed, so we need to substract 1 to get accurate hops AND the 1 we added before (see above) -> -2
  if [[ ${MAX_HOPS} -lt 255 ]]; then
    CURRENT_BNC_HOPS=$(echo "$(traceroute -m$((${MAX_HOPS} + 1)) "${host}" | wc -l) - 2" | bc)
    # we add a greater than sign, if it actually would be more hops than $MAX_HOPS
    if [[ ${MAX_HOPS} -eq ${CURRENT_BNC_HOPS} ]]; then
      CURRENT_BNC_HOPS="$(echo ">${CURRENT_BNC_HOPS}")"
    fi
  else
    CURRENT_BNC_HOPS=$(echo "$(traceroute -m${MAX_HOPS} "${host}" | wc -l) - 1" | bc)
  fi

  # add it to the array of hops
  BOUNCER_COUNT_OF_HOPS["${CURRENT_BNC_NAME}"]="${CURRENT_BNC_HOPS}"
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
# format_output <formatLine> <bncNumber> <bncUniqueName> <bncName> <bncHost> <bncPort> <bncUser> <bncPassword> 
#               <bncSsl> <bncTimeout> <bncTld> <bncCountry> <bncNickname> <bncCity> <bncIsp> <bncDescription> <bncPingTime> <bncLoginTime> 
#               <bncHops> <bncStatus> <bncLastChecked> <curlErrorCode> <curlError> <curlErrorDescription>
#------
# Description:
#  Replace the variables in the given string and set it into $BOUNCER_OUTPUT
#------
# Globals:
#  DEBUG          (r)
#  BOUNCER_OUTPUT (w)
#------
# Arguments:
#   $1 - $formatLine             : string  -> Line of the template, which contains all the variables, which need to be replaced
#   $2 - $bncNumber              : integer -> Index of the bouncer
#   $3 - $bncUniqueName          : string  -> Unique name of the bouncer
#   $4 - $bncName                : string  -> Name of the bouncer
#   $5 - $bncHost                : string  -> Host of the bouncer
#   $6 - $bncPort                : integer -> Port of the bouncer
#   $7 - $bncUser                : string  -> User to login to glftpd with through the bouncer
#   $8 - $bncPassword            : string  -> Password for the user
#   $9 - $bncSsl                 : boolean -> Connect using SSL
#  $10 - $bncTimeout             : integer -> Timeout, which was set for the bouncer
#  $11 - $bncTld                 : string  -> Top level domain, where the bouncer is located
#  $12 - $bncCountry             : string  -> Full name of the country, where the bouncer is located
#  $13 - $bncNickname            : string  -> Nickname of the bouncer
#  $14 - $bncCity                : string  -> Name of the city, where the bouncer is located
#  $15 - $bncIsp                 : string  -> ISP of the bouncer
#  $16 - $bncDescription         : string  -> Description of the bouncer
#  $17 - $bncPingTime            : float   -> Time it took to ping the bouncer
#  $18 - $bncLoginTime           : integer -> Time it took to login to the glftpd instance via this bouncer
#  $19 - $bncHops                : integer -> Number of hops, from this box to your bouncer
#  $20 - $bncStatus              : integer -> Status of the bouncer (0 = online, everything else = offline)
#  $21 - $bncLastChecked         : string  -> Date when the bouncer was last checked
#  $22 - $curlErrorCode          : integer -> Error code of curl, when it failed to connect to the bouncer
#  $23 - $curlError              : string  -> Error name of curl, when it failed to connect to the bouncer
#  $24 - $curlErrorDescription   : string  -> Description of the error of curl, when it failed to connect to the bouncer
#------
# Returns:
#  Nothing, but adds the format line with replaced values to $BOUNCER_OUTPUT
#-----------------------------
function format_output () {
  if ${DEBUG}; then
    echo "DEBUG: Entered function 'format_output' with values:"
    echo "DEBUG: '${@}'"
  fi

  if [[ $# -lt 24 ]]; then
    echo "ERROR: Function 'format_output' did not recieve enough arguments!"; exit 1
  fi

  # assign all arguments to local variables
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
  local bncCity="${14}"
  local bncIsp="${15}"
  local bncDescription="${16}"
  local bncPingTime="${17}"
  local bncLoginTime="${18}"
  local bncHops="${19}"
  local bncStatus="${20}"
  local bncLastChecked="${21}"
  local curlErrorCode="${22}"
  local curlError="${23}"
  local curlErrorDescription="${24}"

  if ${DEBUG}; then
    echo "DEBUG: function 'format_output' assigned variables with the following values:"
    echo "       FormatLine..............: ${formatLine}"
    echo "       BNC#....................: ${bncNumber}"
    echo "       Unique Name.............: ${bncUniqueName}"
    echo "       Name....................: ${bncName}"
    echo "       Host....................: ${bncHost}"
    echo "       Port....................: ${bncPort}"
    echo "       User....................: ${bncUser}"
    echo "       Password................: ${bncPassword}"
    echo "       SSL used................: ${bncSsl}"
    echo "       Timeout.................: ${bncTimeout}"
    echo "       TLD.....................: ${bncTld}"
    echo "       Country.................: ${bncCountry}"
    echo "       Nickname................: ${bncNickname}"
    echo "       City....................: ${bncCity}"
    echo "       ISP.....................: ${bncIsp}"
    echo "       Description.............: ${bncDescription}"
    echo "       Ping.time...............: ${bncPingTime}"
    echo "       Login.time..............: ${bncLoginTime}"
    echo "       Hops....................: ${bncHops}"
    echo "       BNC.status..............: ${bncStatus}"
    echo "       Last.checked............: ${bncLastChecked}"
    echo "       Curl.error.code.........: ${curlErrorCode}"
    echo "       Curl.error..............: ${curlError}"
    echo "       Curl.error.description..: ${curlErrorDescription}"
    echo ":END DEBUG"
  fi

  # replace all variables

  # bncNumber gets replaced later on, when the output is sorted, if
  # sorting for ping times, login times or hops is requested
  if ! ${SORT_OUTPUT_FOR_BOUNCER_PING_TIME} && ! ${SORT_OUTPUT_FOR_BOUNCER_LOGIN_TIME} && \
     ! ${SORT_OUTPUT_FOR_BOUNCER_NUMBER_OF_HOPS} && ! ${SORT_OUTPUT_FOR_BOUNCER_LAST_CHECKED_TIMES}; then
    formatLine="${formatLine//%%BNC_NUMBER%%/${bncNumber}}"
  fi

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
  formatLine="${formatLine//%%BNC_CITY%%/${bncCity}}"
  formatLine="${formatLine//%%BNC_ISP%%/${bncIsp}}"
  formatLine="${formatLine//%%BNC_DESCRIPTION/${bncDescription}}"
  formatLine="${formatLine//%%BNC_STATUS%%/${bncStatus}}"
  formatLine="${formatLine//%%BNC_LAST_CHECKED%%/${bncLastChecked}}"
  
  formatLine="${formatLine//%%BNC_HOST_HEXADECIMAL%%/$(ip2hex ${bncHost})}"
  formatLine="${formatLine//%%BNC_HOST_DECIMAL%%/$(ip2dec ${bncHost})}"

  # can only be set if the bouncer is up
  if [[ ${bncStatus} -eq 0 ]]; then
    formatLine="${formatLine//%%BNC_PING_TIME%%/${bncPingTime}}"
    formatLine="${formatLine//%%BNC_LOGIN_TIME%%/${bncLoginTime}}"
    formatLine="${formatLine//%%BNC_HOPS%%/${bncHops}}"
  else #; only available, when the bouncer has some sort of error
    formatLine="${formatLine//%%CURL_ERROR%%/${curlError}}"
    formatLine="${formatLine//%%CURL_ERROR_CODE%%/${curlErrorCode}}"
    formatLine="${formatLine//%%CURL_ERROR_DESCRIPTION%%/${curlErrorDescription}}"
  fi
  

  # finally assign the formatted line, so we can output it
  BOUNCER_OUTPUT["${bncUniqueName}"]="${formatLine}"
} #; format_output <format_line> <bncNumber> <bncUniqueName> <bncName> <bncHost> <bncPort> <bncUser> <bncPassword> 
  #;               <bncSsl> <bncTimeout> <bncTld> <bncCountry> <bncNickname> <bncCity> <bncIsp> <bncDescription> <bncPingTime> <bncLoginTime> 
  #;               <bncHops> <bncStatus> <bncLastChecked> <curlErrorCode> <curlError> <curlErrorDescription>

#
# BEGIN!
#

# check everything necessary to run this script
init

#
# first split the settings line and assign it to variables
# NOTE: Not explicitly declared as Integer, since we might need to prefix
#       a zero, while the count is less than 10. Integers itself doesn't 
#       allow prefixing zeroes, so it'll be automagically removed.
#
currentBncNumber=1
for bouncer in "${!BOUNCER[@]}"; do
  # reset global variables
  # yet, it is not really necessary, but I like to write clean code ;>
  CURRENT_BNC_STATUS=-1
  CURRENT_BNC_LOGIN_TIME=-1
  CURRENT_BNC_PING_TIME=-1
  CURRENT_BNC_HOPS=-1
  CURRENT_BNC_NAME=""

  # save IFS to restore it later
  oIFS="${IFS}"


  # get the settings for the given bouncer, with adressing it with the name it has in the BOUNCER array
  # and split it on '%', so we should end up with 10 indexes
  settings="${BOUNCER_SETTINGS["${bouncer}"]}"
  set -- "${settings}"
  IFS="%"; declare -a splittedSettings=($*)

  host="${BOUNCER["${bouncer}"]}"
  set -- "${host}"
  IFS=":"; declare -a splittedHost=($*)

  # format is: TIMEOUT_SEC%BNC_USER%BNC_PASSWORD%BNC_SSL%BNC_TLD%BNC_COUNTRY%BNC_NICKNAME%BNC_CITY%BNC_ISP%BNC_DESCRIPTION
  if [[ ! ${#splittedSettings[@]} -eq 10 ]]; then
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
  country="${splittedSettings[5]//\"}"
  nickname="${splittedSettings[6]//\"}"
  city="${splittedSettings[7]//\"}"
  isp="${splittedSettings[8]//\"}"
  description="${splittedSettings[9]//\"}"

  # no removing needed, but assigning :>
  host="${splittedHost[0]}"
  port="${splittedHost[1]}"

  # (re)assign the current name
  CURRENT_BNC_NAME="${bouncer}"

  # reset IFS again
  IFS="${oIFS}"

  # prefix a zero if requested
  if ${PREFIX_ZERO} && [[ ${currentBncNumber} -lt 10 ]]; then
    currentBncNumber="$(echo "0${currentBncNumber}")"
  fi

  # get the status of the bouncer
  get_status "${host}" "${port}" "${user}" "${password}" "${timeout}" ${useSsl}

  # BNC is up
  if [[ $CURRENT_BNC_STATUS -eq 0 ]]; then
    # get ping and hops
    if ${PING_HOST} && ${TRACEROUTE_HOST}; then
      get_ping "${host}" "${timeout}"
      get_hops "${host}"
    # get ping only
    elif ${PING_HOST}; then
      get_ping "${host}" "${timeout}"
    # get hops only
    elif ${TRACEROUTE_HOST}; then
      get_hops "${host}"
    fi

    # checking the bouncer for login, ping and hops is done, so we record this timestamp
    # saving it into a seperate array, since maybe sorting for it is requested
    BOUNCER_LAST_CHECKED_TIMES["${bouncer}"]="$(date +'%s')"

    format_output "${BOUNCER_ONLINE_TEMPLATE["${bouncer}"]}" "${currentBncNumber}" "${bouncer}" "${nickname}" "${host}" \
                  "${port}" "${user}" "${password}" "${useSsl}" "${timeout}" "${tld}" "${country}" "${nickname}" "${city}" \
                  "${isp}" "${description}" "${CURRENT_BNC_PING_TIME}" "${CURRENT_BNC_LOGIN_TIME}" "${CURRENT_BNC_HOPS}" \
                  "${CURRENT_BNC_STATUS}" "$(date --date "@${BOUNCER_LAST_CHECKED_TIMES["${bouncer}"]}" "+${DATE_FORMAT}")" "0" "0" "0"
  else #; BNC is down
    # checking the bouncer for login, ping and hops is done, so we record this timestamp
    # saving it into a seperate array, since maybe sorting for it is requested
    BOUNCER_LAST_CHECKED_TIMES["${bouncer}"]="$(date +'%s')"

    format_output "${BOUNCER_OFFLINE_TEMPLATE["${bouncer}"]}" "${currentBncNumber}" "${bouncer}" "${nickname}" "${host}" \
                  "${port}" "${user}" "${password}" "${useSsl}" "${timeout}" "${tld}" "${country}" "${nickname}" "${city}" \
                  "${isp}" "${description}" "${CURRENT_BNC_PING_TIME}" "${CURRENT_BNC_LOGIN_TIME}" "${CURRENT_BNC_HOPS}" \
                  "${CURRENT_BNC_STATUS}" "$(date --date "@${BOUNCER_LAST_CHECKED_TIMES["${bouncer}"]}" "+${DATE_FORMAT}")" \
                  "${CURRENT_BNC_STATUS}" "${CURL_EXIT_CODES["${CURRENT_BNC_STATUS}"]}" "${CURL_EXIT_CODES_DESCRIPTION["${CURRENT_BNC_STATUS}"]}"
  fi

  # remove the leading zero again
  if [[ ${currentBncNumber} =~ ^0 ]]; then
    currentBncNumber=${currentBncNumber//0}
  fi

  ((currentBncNumber++))
done

# sorting for ping time
if ${SORT_OUTPUT_FOR_BOUNCER_PING_TIME}; then
  # clear output file first
  cat /dev/null > "${GLFTPD_ROOT_PATH}${BNC_FILE_PING_TIMES}"

  if ${DEBUG}; then
    echo "DEBUG: Sorting the output for the ping times."
  fi

  # sort the output via asort bash built-in - either ascending or descending 
  # and save the keys into $bouncerSortedPingTime
  if ${SORT_ASCENDING}; then
    if ${DEBUG}; then
      echo "DEBUG: Sorting ascending."
    fi
    asort -ni bouncerSortedPingTimes BOUNCER_PING_TIMES
  else #; sort descending
    if ${DEBUG}; then
      echo "DEBUG: Sorting descending."
    fi
    asort -nir bouncerSortedPingTimes BOUNCER_PING_TIMES
  fi

  bncNumber=1
  for pingTime in "${bouncerSortedPingTimes[@]}"; do
    # prefix a zero if requested and bncNumber is less than 10
    if ${PREFIX_ZERO} && [[ ${bncNumber} -lt 10 ]]; then
      bncNumber=$(echo "0${bncNumber}")
    fi
   
    # replace the bouncer number variable %%BNC_NUMBER%%
    # sadly we need a temporary variable to do so .. :(
    bouncerNumberLine="${BOUNCER_OUTPUT["${pingTime}"]}"
    bouncerNumberLine="${bouncerNumberLine//%%BNC_NUMBER%%/${bncNumber}}"
    BOUNCER_OUTPUT["${pingTime}"]="${bouncerNumberLine}"

    if ${DEBUG}; then
      echo "${BOUNCER_OUTPUT["${pingTime}"]}"
    fi

    echo "${BOUNCER_OUTPUT["${pingTime}"]}" >> "${GLFTPD_ROOT_PATH}${BNC_FILE_PING_TIMES}"

    # remove the leading zero again
    if [[ ${bncNumber} =~ ^0 ]]; then
      bncNumber=${bncNumber//0}
    fi

    ((bncNumber++))
  done
fi


# sorting for login time
if ${SORT_OUTPUT_FOR_BOUNCER_LOGIN_TIME}; then
  # clear output file first
  cat /dev/null > "${GLFTPD_ROOT_PATH}${BNC_FILE_LOGIN_TIMES}"

  if ${DEBUG}; then
    echo "DEBUG: Sorting the output for the login time."
  fi

  # sort the output via asort bash built-in - either ascending or descending 
  # and save the keys into $bouncerSortedLoginTimes
  if ${SORT_ASCENDING}; then
    if ${DEBUG}; then
      echo "DEBUG: Sorting ascending."
    fi
    asort -ni bouncerSortedLoginTimes BOUNCER_LOGIN_TIMES
  else #; sort descending
    if ${DEBUG}; then
      echo "DEBUG: Sorting descending."
    fi
    asort -nir bouncerSortedLoginTimes BOUNCER_LOGIN_TIMES
  fi

  bncNumber=1
  for loginTime in "${bouncerSortedLoginTimes[@]}"; do
    # prefix a zero if requested and bncNumber is less than 10
    if ${PREFIX_ZERO} && [[ ${bncNumber} -lt 10 ]]; then
      bncNumber=$(echo "0${bncNumber}")
    fi

    # replace the bouncer number variable %%BNC_NUMBER%%
    # sadly we need a temporary variable to do so .. :(
    bouncerNumberLine="${BOUNCER_OUTPUT["${loginTime}"]}"
    bouncerNumberLine="${bouncerNumberLine//%%BNC_NUMBER%%/${bncNumber}}"
    BOUNCER_OUTPUT["${loginTime}"]="${bouncerNumberLine}"

    if ${DEBUG}; then
      echo "${BOUNCER_OUTPUT["${loginTime}"]}"
    fi

    # save output
    echo "${BOUNCER_OUTPUT["${loginTime}"]}" >> "${GLFTPD_ROOT_PATH}${BNC_FILE_LOGIN_TIMES}"

    # remove the leading zero again
    if [[ ${bncNumber} =~ ^0 ]]; then
      bncNumber=${bncNumber//0}
    fi

    ((bncNumber++))
  done
fi


# sorting for number of hops
if ${SORT_OUTPUT_FOR_BOUNCER_NUMBER_OF_HOPS}; then
  # clear output file first
  cat /dev/null > "${GLFTPD_ROOT_PATH}${BNC_FILE_HOPS}"

  if ${DEBUG}; then
    echo "DEBUG: Sorting the output for the number of hops."
  fi

  # sort the output via asort bash built-in - either ascending or descending 
  # and save the keys into $bouncerSortedHops
  if ${SORT_ASCENDING}; then
    if ${DEBUG}; then
      echo "DEBUG: Sorting ascending."
    fi
    asort -ni bouncerSortedHops BOUNCER_COUNT_OF_HOPS
  else #; sort descending
    if ${DEBUG}; then
      echo "DEBUG: Sorting descending."
    fi
    asort -nir bouncerSortedHops BOUNCER_COUNT_OF_HOPS
  fi

  bncNumber=1
  for hop in "${bouncerSortedHops[@]}"; do
    # prefix a zero if requested and bncNumber is less than 10
    if ${PREFIX_ZERO} && [[ ${bncNumber} -lt 10 ]]; then
      bncNumber=$(echo "0${bncNumber}")
    fi

    # replace the bouncer number variable %%BNC_NUMBER%%
    # sadly we need a temporary variable to do so .. :(
    bouncerNumberLine="${BOUNCER_OUTPUT["${hop}"]}"
    bouncerNumberLine="${bouncerNumberLine//%%BNC_NUMBER%%/${bncNumber}}"
    BOUNCER_OUTPUT["${hop}"]="${bouncerNumberLine}"
    echo "${BOUNCER_OUTPUT["${hop}"]}"

    if ${DEBUG}; then
      echo "DEBUG: ${BOUNCER_OUTPUT["${hop}"]}"
    fi

    # save output
    echo "${BOUNCER_OUTPUT["${hop}"]}" >> "${GLFTPD_ROOT_PATH}${BNC_FILE_HOPS}"

    # remove the leading zero again
    if [[ ${bncNumber} =~ ^0 ]]; then
      bncNumber=${bncNumber//0}
    fi

    ((bncNumber++))
  done
fi


# sorting for last checked times
if ${SORT_OUTPUT_FOR_BOUNCER_LAST_CHECKED_TIMES}; then
  # clear output file first
  cat /dev/null > "${GLFTPD_ROOT_PATH}${BNC_FILE_LAST_CHECKED}"

  if ${DEBUG}; then
    echo "DEBUG: Sorting the output for the last checked times."
  fi

  # sort the output via asort bash built-in - either ascending or descending 
  # and save the keys into $bouncerSortedLastCheckedTimes
  if ${SORT_ASCENDING}; then
    if ${DEBUG}; then
      echo "DEBUG: Sorting ascending."
    fi
    asort -ni bouncerSortedLastCheckedTimes BOUNCER_LAST_CHECKED_TIMES
  else #; sort descending
    if ${DEBUG}; then
      echo "DEBUG: Sorting descending."
    fi
    asort -nir bouncerSortedLastCheckedTimes BOUNCER_LAST_CHECKED_TIMES
  fi

  bncNumber=1
  for checkTime in "${bouncerSortedLastCheckedTimes[@]}"; do
    # prefix a zero if requested and bncNumber is less than 10
    if ${PREFIX_ZERO} && [[ ${bncNumber} -lt 10 ]]; then
      bncNumber=$(echo "0${bncNumber}")
    fi

    # replace the bouncer number variable %%BNC_NUMBER%%
    # sadly we need a temporary variable to do so .. :(
    bouncerNumberLine="${BOUNCER_OUTPUT["${checkTime}"]}"
    bouncerNumberLine="${bouncerNumberLine//%%BNC_NUMBER%%/${bncNumber}}"
    BOUNCER_OUTPUT["${checkTime}"]="${bouncerNumberLine}"

    if ${DEBUG}; then
      echo "DEBUG: ${BOUNCER_OUTPUT["${checkTime}"]}"
    fi

    # save output
    echo "${BOUNCER_OUTPUT["${checkTime}"]}" >> "${GLFTPD_ROOT_PATH}${BNC_FILE_LAST_CHECKED}"

    # remove the leading zero again
    if [[ ${bncNumber} =~ ^0 ]]; then
      bncNumber=${bncNumber//0}
    fi

    ((bncNumber++))
  done
fi

# last but not least the unsorted output :)
# clear file first again
cat /dev/null > "${GLFTPD_ROOT_PATH}${BNC_FILE}"

# %%BNC_NUMBER%% needs replacement when sorting was requested
bncNumber=1
for unsorted in "${!BOUNCER_OUTPUT[@]}"; do
  if ${DEBUG}; then
     echo "${BOUNCER_OUTPUT["${unsorted}"]}"
  fi

  # we sorted before, so we need to replace %%BNC_NUMBER%%
  if ${SORT_OUTPUT_FOR_BOUNCER_PING_TIME} || ${SORT_OUTPUT_FOR_BOUNCER_LOGIN_TIME} \
     ${SORT_OUTPUT_FOR_BOUNCER_NUMBER_OF_HOPS} || ${SORT_OUTPUT_FOR_BOUNCER_LAST_CHECKED_TIMES}; then

    # prefix a zero if requested and bncNumber is less than 10
    if ${PREFIX_ZERO} && [[ ${bncNumber} -lt 10 ]]; then
      bncNumber=$(echo "0${bncNumber}")
    fi
    # replace the bouncer number variable %%BNC_NUMBER%%
    # sadly we need a temporary variable to do so .. :(
    bouncerNumberLine="${BOUNCER_OUTPUT["${unsorted}"]}"
    bouncerNumberLine="${bouncerNumberLine//%%BNC_NUMBER%%/${bncNumber}}"
    BOUNCER_OUTPUT["${unsorted}"]="${bouncerNumberLine}"


    # remove the leading zero again
    if [[ ${bncNumber} =~ ^0 ]]; then
      bncNumber=${bncNumber//0}
    fi

    ((bncNumber++))
  fi

  if ${DEBUG}; then
    echo "DEBUG: ${BOUNCER_OUTPUT["${unsorted}"]}"
  fi

  # save output
  echo "${BOUNCER_OUTPUT["${unsorted}"]}" >> "${GLFTPD_ROOT_PATH}${BNC_FILE}"
done

exit 0
EOF
