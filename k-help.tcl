namespace eval khelp {
  	# chan needs +khelp
   	setudef flag khelp

  	# binds
   	bind pub - ".help" khelp::cmd_help_handler
   	bind pub - ".h"    khelp::cmd_help_handler

  	variable rootDirectory 		"filesys/khelp"			;# Relative path to the root directory for the help files
	variable errorPrefix 		[format %-5s "\x0304err?!\x0F"] ;# Prefix for error messages
	variable debugPrefix		[format %-5s "\x0307dbg!!\x0F"] ;# Prefix for debug messages
	variable prefix			[format %-5s "\x02halp!\x0F"]	;# Prefix for standard messages
	variable sendCommand		"putquick"			;# Command to use, when sending to IRC
	variable debug			"0"				;# If set, verbosive output will be shown in the channel

	


	# dict to add all help information
	# Format:
	#	 .dictName		.helpTopic	.filename/keyword	.values
	# Note: helpTopic needs to have the name of the filename, but w/o the suffix '.help'
	variable helpInformation
	dict set helpInformation 	epguides	filename	"epguides.help"
	dict set helpInformation	epguides	keywords	"epguides,epguide,ep,epg,tv,series"
	
	dict set helpInformation	imdb		filename	"imdb.help"
	dict set helpInformation	imdb		keywords	"imdb,movies,movie"

	dict set helpInformation	kernel		filename	"kernel.help"
	dict set helpInformation	kernel		keywords	"kernel,latest kernel,linux"

	dict set helpInformation	statusd		filename	"statusd.help"
	dict set helpInformation	statusd		keywords	"statusd,status,seen"

	dict set helpInformation	webby		filename	"webby.help"
	dict set helpInformation	webby		keywords	"webby,website,crawl"

        dict set helpInformation        google          filename        "google.help"
        dict set helpInformation        google          keywords        "google,search,g"

        dict set helpInformation        wikipedia       filename        "wikipedia.help"
        dict set helpInformation        wikipedia       keywords        "wikipedia,wiki,w"

        dict set helpInformation        youtube         filename        "youtube.help"
        dict set helpInformation        youtube         keywords        "youtube,yt,videos"

        dict set helpInformation        gamefaq         filename        "gamefaq.help"
        dict set helpInformation        gamefaq         keywords        "gamefaq,games,gf,game"

        dict set helpInformation        ign             filename        "ign.help"
        dict set helpInformation        ign             keywords        "ign,games,game"

        dict set helpInformation        gnews           filename        "gnews.help"
        dict set helpInformation        gnews           keywords        "gnews,news,google news"

        dict set helpInformation        weather         filename        "weather.help"
        dict set helpInformation        weather         keywords        "weather,wz"

        dict set helpInformation        misc            filename        "misc.help"
        dict set helpInformation        misc            keywords        "misc,various,time,date,op,uptime,deop,substitute,regexp"

        dict set helpInformation        quote           filename        "quote.help"
        dict set helpInformation        quote           keywords        "quote,quotes,q"

        dict set helpInformation        remind          filename        "remind.help"
        dict set helpInformation        remind          keywords        "remind,reminder"

        dict set helpInformation        news            filename        "news.help"
        dict set helpInformation        news            keywords        "news"

        dict set helpInformation        tcl             filename        "tcl.help"
        dict set helpInformation        tcl             keywords        "tcl"

        dict set helpInformation        urbandictionary filename        "urbandictionary.help"
        dict set helpInformation        urbandictionary keywords        "urban,ud,urban dict,urban dictionary, urbandict, urbandictionary"

        dict set helpInformation        tvmaze          filename        "tvmaze.help"
        dict set helpInformation        tvmaze          keywords        "tvmaze,tv,series"

	variable version		"1.0"
	variable author			"|k"

}; # namespace khelp

proc khelp::cmd_help_handler { nick host hand chan arg } {
	# channel needs +khelp
	if { ![channel get $chan khelp] } {
		return;
	}

	khelp::print_help $chan $arg

	return 0;
}; # proc khelp::cmd_help_handler <nick> <host> <hand> <chan> <arg> <!

proc khelp::print_help { chan {type "general"} } {
	# for whatever reason it happens, that type is empty, but the default value 'general'
	if { [string match $type ""] } {
		set type "general"
	}
	
	# used to determine whether a performed search ended up sucessfully or not
	set found 0

	# used to collect all help topics, when "general" as type is given
	set helpTopics {}
	dict for {id info} $::khelp::helpInformation {

		dict with info {
			# type general is a special case. with that type given, we iterrate over all
			# available helpfiles and output them
			if { [string equal $type "general" ] } {
				if { $::khelp::debug } {
					$::khelp::sendCommand "PRIVMSG $chan :$::khelp::debugPrefix Appending '[regsub {\.help$} $filename ""]'"
				}
				lappend helpTopics [regsub {\.help$} $filename ""]
				continue
			}

			# split keywords and check if the supplied keyword is matching
			set keywords [split $keywords ","]

			foreach keyword $keywords {
				# keyword found, which matches the type requested or it is requested to print all helpfiles
				if { [string equal $keyword $type] || [string equal $type "all"] } {
					
					set found 1
					# try opening the file
					if { [catch {set fileDescriptor [open "${::khelp::rootDirectory}/${filename}" "r"]} errorMessage] } {
						if { $::khelp::debug && ! [string equal $errorMessage ""]} {
							$::khelp::sendCommand "PRIVMSG $chan :$::khelp::debugPrefix $errorMessage"
						}
						$::khelp::sendCommand "PRIVMSG $chan :$::khelp::errorPrefix Could not open help file for '$type' or it simply does not exist, how sad :<"
						continue
					}
				
					# output file contents
					# configure the fileDescriptor to read the file linewise
					catch {fconfigure $fileDescriptor -buffering line} errorMessage
					if { $::khelp::debug && ! [string equal $errorMessage ""]} {
						$::khelp::sendCommand "PRIVMSG $chan :$::khelp::debugPrefix $errorMessage"
					}

					set lineNumber 0
					set prefix ""
					while { [gets $fileDescriptor line] != -1 } {
						switch $lineNumber {
							0 { set prefix [format %-14s "\x02description\x0F"] }
							1 { set prefix [format %-14s "\x02abbrevations\x0F"] }
							2 { set prefix [format %-14s "\x02switches\x0F"] }
							3 { set prefix [format %-14s "\x02example\x0F"] }
						}
						$::khelp::sendCommand "PRIVMSG $chan :$::khelp::prefix ${prefix}${line}"
						incr lineNumber
					}

					# typically one would break out of the loop right now (as we had a matching type already),
					# but in order to allow both double keywords (such as tv for both epguides and tvmaze) and
					# to show all helpfiles at one, we just close the file and continue the loop :)
					catch {close $fileDescriptor} errorMessage
					if { $::khelp::debug && ! [string equal $errorMessage ""]} {
						$::khelp::sendCommand "PRIVMSG $chan :$::khelp::debugPrefix $errorMessage"
					}
				} ;# if [string equal $keyword $type] ..

			}; # foreach keyword $keywords ..

		}; # dict with info ..


	}; # dict for {id info} ${::khelp::helpInformation} ..

	# nothing found
	if {!$found && ![string equal $type "general"]} {
		$::khelp::sendCommand "PRIVMSG $chan :$::khelp::errorPrefix no. just no."
		return 0
	}

	# general is a special case
	if { [string equal $type "general"] } {
		$::khelp::sendCommand "PRIVMSG $chan :$::khelp::prefix help available for the following topics (use .help <topic>):"
		$::khelp::sendCommand "PRIVMSG $chan :$::khelp::prefix [lsort $helpTopics]"
	}
}; # proc khelp::print_general_help <chan> <!


putlog "k-help.tcl $::khelp::version loaded. Credz to $::khelp::author"
