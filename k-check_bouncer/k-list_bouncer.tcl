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
#                     k-list_bouncer.tlc v1.0k                         #
#----------------------------------------------------------------------#
# Description:                                                         #
#---                                                                   #
# Simple script as addition to k-check_bouncer.sh to output the        #
# bouncers linewiese.                                                  #
#---                                                                   #
# Installation:                                                        #  
#---                                                                   #
# Set settings defined below to fit your needs, copy this script to    #
# your eggdrops scripts directory and add                              #
#   source scripts/k-list_bouncer.tcl                                  #
# to your eggdrop.conf. Make sure, the bot has read access to this     #
# file and to your bouncerFile.                                        #
# Every channel where it needs to be accessible needs the flag 'kbnc'  #
# set. You can do that with                                            #
#   .chanset +kbnc #yourChan                                           #
# via telnet or DCC.                                                   #
# Remember to unbind "!bnc" from ngBot or it won't work or use another #
# bind like "!listbnc" or ".bnc" or ..                                 #
#---                                                                   #
#                                                                      #
# Sincerly,                                                            #
#   |k @ 25th August of 2o16                                           #
#----------------------------------------------------------------------#
namespace eval k::list_bouncer {
  	# all channels need to have +kbnc set to allow !bnc
  	setudef flag kbnc

	# bind
	bind pub -|- "!bnc" ::k::list_bouncer::bnc_handle

	#
	# settings
	#
        variable bouncerFile "/glftpd/ftp-data/misc/bouncer.list"
	variable sendCommand "putnow"
} ;# k::list_bouncer


#                                            #
# < - C O D E   B E G I N S   B E L O W  - > #
#                                            #
proc k::list_bouncer::bnc_handle { nick uhost hand chan arg } {
	# channel needs +kbnc
	if { ! [channel get $chan kbnc] } {
		return 0
	} ;# if

	# open file
	set fileHandle [open $::k::list_bouncer::bouncerFile]
	set fileContents [read $fileHandle]
	close $fileHandle

	# print linewise to channel
	set fileData [split $fileContents "\n" ]
	foreach line $fileData {
		$::k::list_bouncer::sendCommand "PRIVMSG $chan :$line"
	} ;# foreach
} ;# k::bnc_handle

putlog "k-list_bouncer.tcl loaded"
