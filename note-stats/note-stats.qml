import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    property string charNoSpaceLeftName
    property int charNoSpaceLeftTarget
    property string charNoSpaceName
    property string charSpaceLeftName
    property int charSpaceLeftTarget
    property string charSpaceName
    property string paragraphsLeftName
    property int paragraphsLeftTarget
    property string paragraphsName
    property string readTimeName
    property int readTimeRate
    property variant settingsVariables: [
        {
            "identifier": "charSpaceName",
            "name": "Characters including spaces counter name",
            "description": "Put a counter name here or leave empty to disable",
            "type": "string",
            "default": "Chars"
        },
        {
            "identifier": "charSpaceLeftName",
            "name": "Characters including spaces left until target counter name",
            "description": "Put a counter name here or leave empty to disable",
            "type": "string",
            "default": ""
        },
        {
            "identifier": "charSpaceLeftTarget",
            "name": "Target number of characters including spaces",
            "description": "Put number of characters including spaces to count down to",
            "type": "integer",
            "default": "0"
        },
        {
            "identifier": "charNoSpaceName",
            "name": "Characters without spaces counter name",
            "description": "Put a counter name here or leave empty to disable",
            "type": "string",
            "default": ""
        },
        {
            "identifier": "charNoSpaceLeftName",
            "name": "Characters without spaces left until target counter name",
            "description": "Put a counter name here or leave empty to disable",
            "type": "string",
            "default": ""
        },
        {
            "identifier": "charNoSpaceLeftTarget",
            "name": "Target number of characters without spaces",
            "description": "Put number of characters without spaces to count down to",
            "type": "integer",
            "default": "0"
        },
        {
            "identifier": "wordsName",
            "name": "Words counter name",
            "description": "Put a counter name here or leave empty to disable",
            "type": "string",
            "default": "Words"
        },
        {
            "identifier": "wordsLeftName",
            "name": "Words left until target counter name",
            "description": "Put a counter name here or leave empty to disable",
            "type": "string",
            "default": ""
        },
        {
            "identifier": "wordsLeftTarget",
            "name": "Target number of words",
            "description": "Put number of words to count down to",
            "type": "integer",
            "default": "0"
        },
        {
            "identifier": "paragraphsName",
            "name": "Paragraphs counter name",
            "description": "Put a counter name here or leave empty to disable",
            "type": "string",
            "default": ""
        },
        {
            "identifier": "paragraphsLeftName",
            "name": "Paragraphs left until target counter name",
            "description": "Put a counter name here or leave empty to disable",
            "type": "string",
            "default": ""
        },
        {
            "identifier": "paragraphsLeftTarget",
            "name": "Target number of paragraphs",
            "description": "Put number of paragraphs to count down to",
            "type": "integer",
            "default": "0"
        },
        {
            "identifier": "readTimeName",
            "name": "Expected time to read a note",
            "description": "Put a counter name here or leave empty to disable",
            "type": "string",
            "default": "Reading time"
        },
        {
            "identifier": "readTimeRate",
            "name": "Reading speed rate in words per minute",
            "description": "Adjust reading time counter from declamation (120-180) to speed reading (>300)",
            "type": "integer",
            "default": "300"
        }
    ]
    property string wordsLeftName
    property int wordsLeftTarget
    property string wordsName

    function init() {
        script.registerLabel("note stats");
    }
    function noteOpenedHook(note) {
        noteStats(note);
    }
    function noteStats(note) {
        var entry = "<td align=center>%1 <b>%2</b></th>\n";
        var entryLeft = "<td align=center>%1 <b>%2 / %3</b></th>\n";

        if (charSpaceName !== "") {
            var charSpace = entry.arg(charSpaceName).arg(note.noteText.length);
        } else {
            var charSpace = "";
        }

        if (charSpaceLeftName !== "") {
            var charSpaceLeft = entryLeft.arg(charSpaceLeftName).arg(charSpaceLeftTarget - note.noteText.length).arg(charSpaceLeftTarget);
        } else {
            var charSpaceLeft = "";
        }

        if (charNoSpaceName !== "") {
            var charNoSpace = entry.arg(charNoSpaceName).arg(note.noteText.match(/[^ ]/gi).length);
        } else {
            var charNoSpace = "";
        }

        if (charNoSpaceLeftName !== "") {
            var charNoSpaceLeft = entryLeft.arg(charNoSpaceLeftName).arg(charNoSpaceLeftTarget - note.noteText.match(/[^ ]/gi).length).arg(charNoSpaceLeftTarget);
        } else {
            var charNoSpaceLeft = "";
        }

        if (wordsName !== "") {
            var words = entry.arg(wordsName).arg(note.noteText.split(/\s+/).length);
        } else {
            var words = "";
        }

        if (wordsLeftName !== "") {
            var wordsLeft = entryLeft.arg(wordsLeftName).arg(wordsLeftTarget - note.noteText.split(/\s+/).length).arg(wordsLeftTarget);
        } else {
            var wordsLeft = "";
        }

        if (paragraphsName !== "") {
            var paragraphs = entry.arg(paragraphsName).arg((note.noteText.match(/^.*?\S/gm) || "").length);
        } else {
            var paragraphs = "";
        }

        if (paragraphsLeftName !== "") {
            var paragraphsLeft = entryLeft.arg(paragraphsLeftName).arg(paragraphsLeftTarget - (note.noteText.match(/^.*?\S/gm) || "").length).arg(paragraphsLeftTarget);
        } else {
            var paragraphsLeft = "";
        }

        if (readTimeName !== "") {
            var readTime = entry.arg(readTimeName).arg(sec2time(Math.round(note.noteText.split(/\s+/).length / readTimeRate * 60)));
        } else {
            var readTime = "";
        }

        script.setLabelText("note stats", "<table align=center width=90%>\n<tr>\n" + charSpace + charSpaceLeft + charNoSpace + charNoSpaceLeft + words + wordsLeft + paragraphs + paragraphsLeft + readTime + "</tr>\n</table>");
    }
    function onNoteStored(note) {
        noteStats(note);
    }
    function sec2time(seconds) {
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds - (hours * 3600)) / 60);
        var seconds = seconds - (hours * 3600) - (minutes * 60);
        var time = "";

        if (hours != 0) {
            time = hours + ":";
        }
        if (minutes != 0 || time !== "") {
            minutes = (minutes < 10 && time !== "") ? "0" + minutes : String(minutes);
            time += minutes + ":";
        }
        if (time === "") {
            time = seconds + "s";
        } else {
            time += (seconds < 10) ? "0" + seconds : String(seconds);
        }
        return time;
    }
}
