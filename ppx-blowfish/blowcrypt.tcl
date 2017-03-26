# blowcrypt.tcl v3.6.1 by poci/PPX - updated by |k
# thanx to neoxed for supporting me so much and merge out bugs i didn't see
#       to MIC_vBa for submitting the ': bug' :>
#		to fish.sekure.us for great DH1080_tcl.so and impressions
#		everyone else... YOU ROCK!
#
# TODO:
# - cbc support
# - no more use of eggdrops encryption module
#
# changelog:
# 3.6 to 3.6.1 / 25.03.2017 19:44:49
# - added encrpytion for eggdrops fastest put cmd: putnow
#
# 3.5 to 3.6 / 23.12.2006 09:53:04
# - typo (exlusive-binds) fixed!!
# - fixed bug on nicks with special chars
# - fixed bug with " ... messages
# - more eggdrop-like behaviour ( even messages w/o : are valid for 1 word )
# - fixed nicktracker
#
# 3.1 to 3.5 / 06.06.2006 23:32:43
# - 1.6.18rc1 behaviour (exclusive-binds)
# - external configuration file
# - internal code now put into bc-namespace
# - mode-splitup: normal or paranoid (read blowcrypt.conf)
#
# 3.0 to 3.1 / 05.01.2006 16:34:57
# - added a message length check (message with no content wont be sent just like the real behaviour of eggdrop)
# - removed array unset again so exchanged keys wont get deleted on rehash
#
# following changes were sent in by neoxed
# - corrected several spelling mistakes
# - binds are compared case-insensitively
# - the lastbind variable is now updated to the appropriate command name
# - bind callbacks are now properly expanded before evaluation
#
# 2.5 to 3.0 / 24.07.2005 12:10:43
# - added a command (ismsgencrypted) that returns 1 if the bind was toggled by a encrypted message and 0 if not (useful for script developers only)
# - channelnames dont have to be lower case any more (thats one thing many users got stuck with)
# - fixed: loading scripts/DH1080_tcl.dll even if blowso was set to something else
# - other minor changes
# - pubm/msgm support
#
# 2.3 to 2.5 / 10.06.2005 18:43:14
# - now the keyexchange part gets disabled if DH1080_tcl.so does not exist. so the script works just without keyexchange :]
# - option to change the location of DH1080_tcl.so
# - i also compiled a windows version of DH1080_tcl. get it on http://poci.u5-inside.de! (means 100% windrop compatible) =)
#
# 2.2 to 2.3 / 30.12.2004 12:52:24
# - i took both 2.2's (sorry for the misleading versioning) and put the advantages of each in 1 script = 2.3 :)
#
# 2.1 to 2.2 / 15.12.2004 17:27:09
# - no "space-stripping" anymore ;>
# - test command
#
# look forward for another version with pubm support ;>
#
#  !! BLOWFISH MODULE NEED TO BE LOADED AS ENCRYPTION MODULE !!
#

# initializing stuff
namespace eval bc {
	variable keys
	variable userkeys
	variable mode
	variable keyexmod
	variable tmpkey
	variable paradata
	variable paratimer
	variable version 36
}

if {[catch {source [file dirname [info script]]/blowcrypt.conf} error]} {
	putlog "\002bc\002:error: $error"
	return
}
catch {rename putquick putquick2;rename putserv putserv2;rename puthelp puthelp2; rename putnow putnow2;}

# wrapper & api
proc ::puthelp {text {option ""}} {
	::bc::put puthelp $text $option
}

proc ::putserv {text {option ""}} {
	::bc::put putserv $text $option
}

proc ::putnow {text {option ""}} {
	::bc::put putnow $text $option
}

proc ::putquick {text {option ""}} {
	::bc::put putquick $text $option
}

proc ::ismsgencrypted {} {
	if {[info exists ::bc::isencryptedmessage]} {return 1}
	return 0
}

# internal
proc ::bc::put {type text {option ""}} {
	if {![regexp -nocase {^(privmsg) ?.+$} $text "" msgtype]} {
		${type}2 $text
		return
	}
	if {![regexp -nocase {^(\S+) (\S+) :(.+)$} $text "" msgtype msgdest msgtext]} {
		if {![regexp -nocase {^(\S+) (\S+) (\S+)$} $text "" msgtype msgdest msgtext]} {
			putlog "BOGUS MESSAGE!"; return
		}
	}
	set key [::bc::getKey $msgdest]
	if {$option==""} {
		if {$key!=""} {
			${type}2 "PRIVMSG $msgdest :+OK [encrypt $key $msgtext]"
		} else {
			if {$::bc::mode=="paranoid"} {
				if {[string match "#*" $msgdest]} {
					putlog "nonono"
				} else {
					if {![info exists ::bc::paradata([string tolower $msgdest])]} {
						::bc::initKeyExchange $msgdest
						set ::bc::paradata([string tolower $msgdest]) [list [list $type $text]]
						set ::bc::paratimer([string tolower $msgdest]) [utimer 10 "[list unset ::bc::paradata([string tolower $msgdest])];[list ${type}2 "PRIVMSG $msgdest :get a keyex plugin!"]"]
					} else {
						lappend ::bc::paradata([string tolower $msgdest]) [list $type $text]
						killutimer $::bc::paratimer([string tolower $msgdest])
						set ::bc::paratimer([string tolower $msgdest]) [utimer 10 "[list unset ::bc::paradata([string tolower $msgdest])];[list ${type}2 "PRIVMSG $msgdest :get a keyex plugin!"]"]
					}
				}
			} else {
				${type}2 $text
			}
		}
	} else {
		if {$key!=""} {
			${type}2 "PRIVMSG $msgdest :+OK [encrypt $key $msgtext]" $option
		} else {
			if {$::bc::mode=="paranoid"} {
				if {[string match "#*" $msgdest]} {
					putlog "nonono"
				} else {
					if {![info exists ::bc::paradata([string tolower $msgdest])]} {
						::bc::initKeyExchange $msgdest
						set ::bc::paradata([string tolower $msgdest]) [list [list $type $text $option]]
						set ::bc::paratimer([string tolower $msgdest]) [utimer 10 "[list unset ::bc::paradata([string tolower $msgdest])];[list ${type}2 "PRIVMSG $msgdest :get a keyex plugin!"]"]
					} else {
						lappend ::bc::paradata([string tolower $msgdest]) [list $type $text $option]
						killutimer $::bc::paratimer([string tolower $msgdest])
						set ::bc::paratimer([string tolower $msgdest]) [utimer 10 "[list unset ::bc::paradata([string tolower $msgdest])];[list ${type}2 "PRIVMSG $msgdest :get a keyex plugin!"]"]
					}
				}
			} else {
				${type}2 $text $option
			}
		}
	}
}

proc ::bc::getKey {for} {
	if {![string match "#*" $for]} {
		if {[info exists ::bc::userkeys([string tolower $for])]} {
			return $::bc::userkeys([string tolower $for])
		}
	}
	foreach entry $::bc::keys {
		if {[string equal -nocase $for [lindex [split $entry] 0]]} {
			return [lindex $entry 1]
		}
	}
}

proc ::bc::onEncryptedText {nick host hand chan arg} {
	set key [::bc::getKey $chan]
	if {$key==""} {return}
	set tmp [decrypt $key $arg]
	if {[regexp {^(\S+) ?(.*)$} $tmp "" trigger arguments]} {
	foreach item [binds pub] {
		if {[lindex $item 2]=="+OK"} {continue}
		if {[lindex $item 1]!="-|-"} {
			if {![matchattr $hand [lindex $item 1] $chan]} {continue}
		}
		if {[string equal -nocase [lindex $item 2] $trigger]} {
			# The lastbind variable must be updated to reflect the
			# command being triggered, otherwise will always be "+OK".
			set ::lastbind [lindex $item 2]
			set ::bc::isencryptedmessage 1
			# Use "eval" to expand the callback script, for example:
			# bind pub -|- !something [list PubCommand MyEvent]
			# proc PubCommand {event nick host hand chan text} {...}
			eval [lindex $item 4] [list $nick $host $hand $chan $arguments]
			unset ::bc::isencryptedmessage
			if {[info exists ::exclusive-binds] && ${::exclusive-binds}} {
				return
			}
		}
	}
	}
	foreach item [binds pubm] {
		if {[lindex $item 2]=="+OK"} {continue}
		if {[lindex $item 1]!="-|-"} {
			if {![matchattr $hand [lindex $item 1] $chan]} {continue}
		}
		if {[string match -nocase [lindex $item 2] "$chan $tmp"]} {
			set ::lastbind [lindex $item 2]
			set ::bc::isencryptedmessage 1
			eval [lindex $item 4] [list $nick $host $hand $chan $tmp]
			unset ::bc::isencryptedmessage
		}
	}
}

proc ::bc::onEncryptedMsg {nick host hand arg} {
	set key [::bc::getKey $nick]
	if {$key==""} {
		puthelp2 "PRIVMSG $nick :remove your key or exchange a new one with me"
		return
	}
	set tmp [decrypt $key $arg]
	if {[regexp {^(\S+) ?(.*)$} $tmp "" trigger arguments]} {
	foreach item [binds msg] {
		if {[lindex $item 2]=="+OK"} {continue}
		if {[lindex $item 1]!="-|-"} {
			if {![matchattr $hand [lindex $item 1]]} {continue}
		}
		if {![string compare -nocase [lindex $item 2] $trigger]} {
			# The lastbind variable must be updated to reflect the
			# command being triggered, otherwise will always be "+OK".
			set ::lastbind [lindex $item 2]
			set ::bc::isencryptedmessage 1
			# Use "eval" to expand the callback script, for example:
			# bind msg -|- !something [list MsgCommand MyEvent]
			# proc MsgCommand {event nick host hand text} {...}
			eval [lindex $item 4] [list $nick $host $hand $arguments]
			unset ::bc::isencryptedmessage
			if {[info exists ::exclusive-binds] && ${::exclusive-binds}} {
				return
			}
		}
	}
	}
	foreach item [binds msgm] {
		if {[lindex $item 2]=="+OK"} {continue}
		if {[lindex $item 1]!="-|-"} {
			if {![matchattr $hand [lindex $item 1]]} {continue}
		}
		if {[string match -nocase [lindex $item 2] $tmp]} {
			set ::lastbind [lindex $item 2]
			set ::bc::isencryptedmessage 1
			eval [lindex $item 4] [list $nick $host $hand $tmp]
			unset ::bc::isencryptedmessage
		}
	}
}

proc ::bc::unsetKey {for} {
	foreach index [array names ::bc::userkeys] {
		if {[string equal -nocase $for $index]} {
			unset ::bc::userkeys($index)
			return 1
		}
	}
	return 0
}

proc ::bc::bckeydel {nick host hand arg} {
	unsetKey $nick
	puthelp2 "PRIVMSG $nick :done!"
}

proc ::bc::keyexnick {nick host hand chan newnick} {
	if {[info exists ::bc::userkeys([string tolower $nick])] && [string tolower $nick]!=[string tolower $newnick]} {
		set ::bc::userkeys([string tolower $newnick]) $::bc::userkeys([string tolower $nick])
		unset ::bc::userkeys([string tolower $nick])
	}
}

proc ::bc::initKeyExchange {nick} {
	puts "init"
	set privkey [string repeat x 300]
	set pubkey [string repeat x 300]
	DH1080gen "$privkey" "$pubkey"
	set ::bc::tmpkey($nick) "$privkey"
	putquick2 "NOTICE $nick :DH1080_INIT $pubkey"
}

proc ::bc::onKeyExchangeInit {nick host handle text dest} {
	puts "init"
	if {![string equal -nocase $dest $::botnick]} {return}
	if {![regexp -nocase {dh1080_init (\S+)} $text "" hispubkey]} {return}
	set myprivkey [string repeat x 300]
	set mypubkey [string repeat x 300]
	DH1080gen "$myprivkey" "$mypubkey"
	putquick2 "NOTICE $nick :DH1080_FINISH $mypubkey"
	DH1080comp "$myprivkey" "$hispubkey"
    set ::bc::userkeys([string tolower $nick]) $hispubkey
    # do paranoid mode stuff
    if {[info exists ::bc::paradata([string tolower $nick])]} {
    	foreach entry $::bc::paradata([string tolower $nick]) {
    	[lindex $entry 0] [lindex $entry 1]
    	}
	    killutimer $::bc::paratimer([string tolower $nick])
	    unset ::bc::paratimer([string tolower $nick])
    	unset ::bc::paradata([string tolower $nick])
    }
    # till here
	unset hispubkey
}


proc ::bc::onKeyExchangeFinish {nick host handle text dest} {
	if {![string equal -nocase $dest $::botnick]} {return}
	if {![regexp -nocase {dh1080_finish (\S+)} $text "" hispubkey]} {return}
	DH1080comp "$::bc::tmpkey($nick)" "$hispubkey"
	set ::bc::userkeys([string tolower $nick]) $hispubkey
    # do paranoid mode stuff
    if {[info exists ::bc::paradata([string tolower $nick])]} {
		foreach entry $::bc::paradata([string tolower $nick]) {
    		[lindex $entry 0] [lindex $entry 1]
	    }
	    killutimer $::bc::paratimer([string tolower $nick])
	    unset ::bc::paratimer([string tolower $nick])
	    unset ::bc::paradata([string tolower $nick])
	}
    # till here
	unset ::bc::tmpkey($nick)
	unset hispubkey
}

# binds
bind pub - +OK ::bc::onEncryptedText
if {![catch {load $::bc::keyexmod} error]} {
	bind msg - +OK ::bc::onEncryptedMsg
	bind msg - !bckeydel ::bc::bckeydel
	bind nick - * ::bc::keyexnick
	bind notc - "DH1080_INIT *" ::bc::onKeyExchangeInit
	bind notc - "DH1080_FINISH *" ::bc::onKeyExchangeFinish
} else {
	if {$::bc::keyexmod!=""} {
		putlog "\002bc\002:warning: $error - keyexchange is disabled until we can load it someday :>"
	}
}

proc test { nick host hand chan arg } {
	puthelp "PRIVMSG $nick :$nick-$host-$hand-$chan-$arg"
}

bind pub - !test test
bind msg - !test test

putlog "blowcrypt.tcl v[format %.1f [expr $::bc::version / 10.0]] by poci/PPX - blowcrypting the scene since ~2003!"
