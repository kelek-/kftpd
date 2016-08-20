#
# 16/08/2010
# by horgh
# 
# 11/03/2016
# by |k
# 
# v1.1 changes:
# + Added .qhelp command
# + Added prefix variable, so changing all prefixes is now easier
# + Added four new fields to each quote: user, host, channel, date
# + Added new flag +qshowall - if set host and channel of the person added the quote will be shown, 
#   otherwise only username and time
# + Added a variable timeFormat, which determines how your timestamp will look like
#   Default: Tuesday, 30.11.99 00:00:00 (which is the oldest date TCL can represent, so if its 0000-00-00 00:00:00 it will show that ;>)
# * Fixed the delquote function where it wasnt checked if the flac "quote" is set on the channel
#
# MySQL quote script
#
# Setup:
#  The table must be called "quote" and have the following schema:
# CREATE TABLE `quote` (
#  `qid` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
#  `uid` smallint(5) unsigned NOT NULL,
#  `quote` text NOT NULL,
#  `user` varchar(40) NOT NULL,
#  `host` varchar(200) NOT NULL,
#  `channel` varchar(50) NOT NULL,
#  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
#  PRIMARY KEY (`qid`)
# );
#
#

package require mysqltcl

namespace eval sqlquote {
	variable output_cmd putnow

	# MySQL settings
	variable host 127.0.0.1
	variable user eggdrop
	variable pass mypassword
	variable db quote

	# mysql connection handler
	variable conn []

	# search results stored in this dict
	variable results []

	bind pub - ".qlatest"   sqlquote::latest
	bind pub - ".qstats"	sqlquote::stats
	bind pub - ".q"         sqlquote::quote
	bind pub - ".qadd"     	sqlquote::addquote
	bind pub - ".qdel"   	sqlquote::delquote
	bind pub - ".qhelp"     sqlquote::help

	setudef flag quote

	# if channel has the qshowall flag set, then nothing gets hidden 
	# (otherwise host and channel would be hidden)
	setudef flag qshowall
	variable prefix "\002quote!\002"

	variable timeFormat "%A, %d.%m.%y %H:%M:%S"
}

proc sqlquote::connect {} {
	# If connection not initialised or has disconnected
	if {![mysql::state $sqlquote::conn -numeric] || ![mysql::ping $sqlquote::conn]} {
		set sqlquote::conn [mysql::connect -host $sqlquote::host -user $sqlquote::user -password $sqlquote::pass -db $sqlquote::db]
		putlog "Connecting to db..."
	}
}

# fetch a single quote row with given statement
proc sqlquote::fetch_single {stmt} {
	mysql::sel $sqlquote::conn $stmt
	mysql::map $sqlquote::conn {qid quote user host channel date} {
		set q [list qid $qid quote $quote user $user host $host channel $channel date $date]
	}
	return $q
}

proc sqlquote::fetch_search {terms} {
	putlog "Retrieving new quotes for $terms..."
	set terms [mysql::escape $sqlquote::conn $terms]
	set stmt "SELECT qid, quote, user, host, channel, date FROM quote WHERE quote LIKE \"%${terms}%\" LIMIT 20"
	set count [mysql::sel $sqlquote::conn $stmt]
	if {$count <= 0} {
		return []
	}
	mysql::map $sqlquote::conn {qid quote user host channel date} {
		lappend quotes [list qid $qid quote $quote user $user host $host channel $channel date $date]
	}
	return $quotes
}

proc sqlquote::stats {nick host hand chan argv} {
	if {![channel get $chan quote]} { return }
	sqlquote::connect
	set stmt "SELECT COUNT(qid) FROM quote"
	mysql::sel $sqlquote::conn $stmt
	mysql::map $sqlquote::conn {c} {
		set count $c
	}
	$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix There are \002$count\002 quotes in the database."
}

proc sqlquote::latest {nick host hand chan argv} {
	if {![channel get $chan quote]} { return }
	sqlquote::connect
	set stmt "SELECT qid, quote, user, host, channel, date FROM quote ORDER BY qid DESC LIMIT 1"
	sqlquote::output $chan [sqlquote::fetch_single $stmt]
}

proc sqlquote::random {} {
	set stmt "SELECT qid, quote, user, host, channel, date FROM quote ORDER BY RAND() LIMIT 1"
	return [sqlquote::fetch_single $stmt]
}

proc sqlquote::quote_by_id {id} {
	set stmt "SELECT qid, quote, user, host, channel, date FROM quote WHERE qid = ${id}"
	return [sqlquote::fetch_single $stmt]
}

proc sqlquote::quote {nick host hand chan argv} {
	if {![channel get $chan quote]} { return }
	sqlquote::connect
	if {$argv == ""} {
		sqlquote::output $chan [sqlquote::random]
	} elseif {[string is integer $argv]} {
		sqlquote::output $chan [sqlquote::quote_by_id $argv]
	} else {
		sqlquote::output $chan {*}[sqlquote::search $argv]
	}
}

proc sqlquote::search {terms} {
	set terms [regsub -all -- {\*} $terms "%"]
	if {![dict exists $sqlquote::results $terms]} {
		dict set sqlquote::results $terms [sqlquote::fetch_search $terms]
	}

	# Extract one quote from results
	set quotes [dict get $sqlquote::results $terms]
	set quote [lindex $quotes 0]
	set quotes [lreplace $quotes 0 0]

	# Remove key if no quotes after removal of one, else update quotes
	if {![llength $quotes]} {
		dict unset sqlquote::results $terms
	} else {
		dict set sqlquote::results $terms $quotes
	}
	return [list $quote [llength $quotes]]
}

proc sqlquote::addquote {nick host hand chan argv} {
	if {![channel get $chan quote]} { return }
	if {$argv == ""} {
		$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix usage: .qadd <text>"
		return
	}
	sqlquote::connect

	set argv [regsub -all -- {\\n} $argv \n]
	set quote [mysql::escape $sqlquote::conn $argv]
	set stmt "INSERT INTO quote (uid, quote, user, host, channel) VALUES(1, \"${quote}\", \"${nick}\", \"${host}\", \"${chan}\")"
	set count [mysql::exec $sqlquote::conn $stmt]
	$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix ${count} quote added."
}

proc sqlquote::delquote {nick host hand chan argv} {
        if {![channel get $chan quote]} { return }
	if {$argv == "" || ![string is integer $argv]} {
		$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix usage: delquote <#>"
		return
	}
	sqlquote::connect
	set stmt "DELETE FROM quote WHERE qid = ${argv}"
	set count [mysql::exec $sqlquote::conn $stmt]
	$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix #${argv} deleted. ($count quotes affected.)"
}

# quote is dict of form {qid ID quote TEXT user host channel date}
proc sqlquote::output {chan quote {left {}}} {
	if {$quote == ""} {
		$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix no quotes found."
		return
	}

	# grab all information of the quote from the dict
	set qid [dict get $quote qid]
	set text [dict get $quote quote]
	set user [dict get $quote user]
	set host [dict get $quote host]
	set channel [dict get $quote channel]
	set date [dict get $quote date]

	set head "Quote \00314#$qid\003"
	if {$left ne ""} {
		set head "${head} ($left left)"
	}
	$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix $head"
	foreach l [split $text \n] {
		$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix $l"
	}

	# format the time	
	set date [clock format [clock scan $date] -format $sqlquote::timeFormat]

	# show channel and host if +qshowall is set
	if {![channel get $chan qshowall]} {
		$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix added by \00314$user\003 at \00314$date\003"
	} else {
		$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix added by $user/$host in $channel at \00314$date\003"
	}
}

proc sqlquote::help {nick host hand chan argv} {
	if {![channel get $chan quote]} { return }

	$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix help:"
	$sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix .qhelp         \00314->\003 Show this help"
        $sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix .q \[needle\]    \00314->\003 Show random quotes. If needle is present a search is performed."
        $sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix .qadd <quote>  \00314->\003 Add a quote to the database. Use \\n for newline"
        $sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix .qdel <id>     \00314->\003 Delete a quote from the database."
        $sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix .qlatest       \00314->\003 Show the latest added quote."
        $sqlquote::output_cmd "PRIVMSG $chan :$sqlquote::prefix .qstats        \00314->\003 Show simple database stats."
}

sqlquote::connect
putlog "\[Script loaded\] k-mysqlquote.tcl v1.1"
