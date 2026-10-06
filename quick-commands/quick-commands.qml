//						-*- mode: js2 -*-
import QtQml 2.0
import QOwnNotesTypes 1.0
import "command-parser.js" as CommandParser

/**
 * This script creates some easy to access commands that leverage the
 * autocomplete functionalities to add more predefined strings or
 * formatted dates.
 *
 * Original author: @LockeBirdsey
 *
 * Main differences with the original quick-commands script is that
 * date and time values are substituted dynamically and can be part of
 * custom quickies as well.
 * It also uses Qt functions for date/time calculations, see
 * https://www.qownnotes.org/scripting/methods-and-objects.html#formatting-dates-and-times,
 * with added support for w and ww (ISO week numbers).
 *
 */

Script {

    // For settings dialog.
    property variant settingsVariables: [
        {
            identifier: "customCommands",
            name: "Custom Commands",
            description: "Custom quick commands. Each line starts with a command name followed by replacement values separated by spaces. Enclose multi-word values in double quotes. For example: 'myName first \"first last\" last-first'. Date and time values can be substituted with {dd}, {MM} and so on.",
            type: "text",
            default: ""
        }
    ];
    property string customCommands;

    // Common date formats for today and friends.
    readonly property string _DDMM:     "{dd}-{MM}";
    readonly property string _DDMMYYYY: "{dd}-{MM}-{yyyy}";
    readonly property string _FULL:     "{yyyy}-{MM}-{dd}T{HH}:{mm}:{ss}";
    readonly property string _YYYYMMDD: "{yyyy}-{MM}-{dd}";
    readonly property string _VERYFULL: "{dddd} {d} {MMMM} {yyyy} {HH}:{mm}:{ss}";

    // Common date formats for week and friends.
    readonly property string _WEEKWWYYYY: "w{ww}-{yyyy}";
    readonly property string _WWYYYY:     "{ww}-{yyyy}";

    // Command list is static, runtime values are substituted at completion time.
    property var commands: initCommands();

    function autocompletionHook() {

        const word = script.noteTextEditCurrentWord(true);
    
        if (!word.startsWith("\\")) {
            return [];
        }

	const command = word.substr(1);

	// Find the possible candidates.
	let availableCommands = [];

	// script.log("command: " + command);
	const av = commands[command];
	if ( av == null || av.length === 0 ) {
	    // Try Unicode literal \uXXXX.
	    if ( command.match( /^u[0-9a-fA-F]{4}$/ ) ) {
		availableCommands = [ unescapeUnicode(word) ];
	    }
	    else {
		return [];
	    }
        }
	else {
	    // script.log("commands: " + av);

	    // Substitute actual values.
	    const ucfirst = command.match( /^[A-Z]/ ); // should use POSIX
	    for ( let i = 0; i < av.length; i++ ) {
		if ( ucfirst ) {
		    availableCommands.push(capitalizeFirstLetter(substitute(av[i])));
		}
		else {
		    availableCommands.push(substitute(av[i]));
		}		
	    }	
	}	

        // QOwnNotes replaces only word characters during completion, so remove
        // the command prefix separately to keep it out of the result.
        const cursorPosition = script.noteTextEditCursorPosition();
        const commandStart = cursorPosition - word.length;
        script.noteTextEditSetSelection(commandStart, commandStart + 1);
        script.noteTextEditWrite("");
        script.noteTextEditSetCursorPosition(cursorPosition - 1);

        return availableCommands;
    }

    // Initialze the list of commands.
    function initCommands() {
	var commands = {
	    today:     buildList(0),
            tomorrow:  buildList(1),
	    yesterday: buildList(-1),
            week:      [ _WWYYYY, _WEEKWWYYYY ],
            now:       [ _FULL ],
	};

        var customRows = customCommands.split("\n");
        for (let i = 0; i < customRows.length; i++) {
            var customCommand = CommandParser.parseCommandLine(customRows[i]);
            if (customCommand === null) {
                continue;
            }

            commands[customCommand.name] = customCommand.values;
        }

	return commands;
    }

    // Build the list of candidates (for initCommands()).
    function buildList(offset) {

	// If it is not today, add a magic modifier item.
	let mod = "";
	if ( offset < 0 ) {
	    offset = -offset;
	    mod = "{-:" + offset.toString() + "D}";
	}
	else if ( offset > 0 ) {
	    mod = "{+:" + offset.toString() + "D}";
	}

        return [
	    mod + _DDMM,
	    mod + _YYYYMMDD,
	    mod + _DDMMYYYY,
	    mod + _FULL,
	    mod + _VERYFULL
	];
    }

    // Perform the substitutions.
    function substitute(format) {

	// Handle newline and unicode escapes.
	format = unescapeUnicode(format.replace( /\\n/g, "\n"));

	// Break out the {...} elements.
	let m = format.split( /(\{.*?\})/g );
	if ( m.length == 1 ) {
	    return format;	// nothing to substitute
	}
	// script.log("split: " + m + " (" + m.length + " matches)");

	let date = new Date();
	let locale;
	let result = "";

	for( let i = 0; i < m.length; i++ ) {
	    let arg = m[i];
	    // script.log("arg" + i + ": " + arg);

	    // Is it a substitution element?
	    if ( arg.startsWith("{") && arg.endsWith("}") ) {
		let target = arg.slice(1,-1);
		
		// Check for {LC:locale} or {+:offset}.
		if ( target.indexOf(":") > 0 ) {
		    // script.log("opt: " + target);
		    let x = target.split(":");
		    // script.log("x:" + x);

		    if ( x.length == 2 ) { // ctrl:value 
			let ctrl   = x[0];
			let value = x[1];

			if ( ctrl.toLowerCase() == "lc" ) {
			    // Set a locale for substitutions.
			    locale = Qt.locale(value);
			    script.log("locale:" + locale);
			    continue;
			}

			if ( ctrl == "+" || ctrl == "-" ) {
			    // Date offset, millisecs or nnD.
			    let now = new Date().getTime();
			    if ( value.endsWith("D") ) {
				value = parseInt(value) * 24*60*60*1000;
			    }
			    else {
				value = parseInt(value);
			    }
			    date = new Date( now + value );
			    //script.log("date " + date);
			    continue;
			}
		    }
		    console.error("Invalid substitution control: " + m[0]);
		    continue;	// makes sense?
		}
		// Perform the substition.
		if ( target == "w" ) {
		    result += getWeekNumber(date);
		}
		else if ( target == "ww" ) {
		    result += getWeekNumber(date).toString().padStart(2,"0");
		}
		else if ( locale != null ) {
		    result += date.toLocaleString( locale, target );
		}
		else {
		    result += Qt.formatDateTime( date, target );
		}
	    }

	    // Else append to result.
	    else {
		result += arg;
	    }
	}

	return result;
    }

    // Helper: Calculate ISO stnadard week number.
    // Taken from https://github.com/qownnotes/scripts/blob/main/journal-entry/journal-entry.qml
    function getWeekNumber(d) {
        // Copy date so don't modify original
        d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        var yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        var weekNo = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
        return weekNo;
    }

    // Helper: Capitalize first letter of a string.
    function capitalizeFirstLetter(string) {
        return string[0].toUpperCase() + string.slice(1);
    }

    // Helper: Return UTF8 character from a \uXXXX string.
    // Simplified version of https://mojoauth.com/dev-guides/unicode-escaping-in-javascript-in-browser#how-to-convert-between-characters-and-code-points-at-runtime.
    function unescapeUnicode(str) {
	return str.replace( /\\u([0-9a-fA-F]{4})/g,
			    (_, hex) => String.fromCodePoint(parseInt(hex, 16)) );
    }

}
