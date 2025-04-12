import QtQml 2.0
import com.qownnotes.noteapi 1.0

/**
 * This script creates a menu item and a button to create or jump to the current date's journal entry
 * based on a pre-defined format
 */
QtObject {
    id: journalEntry
    readonly property variant _SHORT_DAYS_EN: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]


    property string defaultFolder
    property string defaultTags
    property var dialog
    property string noteBodyTemplate
    property string noteTitleFormat
    property variant settingsVariables: [
        {
            "identifier": "defaultFolder",
            "name": "Default folder",
            "description": "The default folder where the newly created journal note should be placed. Specify the path to the folder relative to the note folder. Make sure that the full path exists. Examples: to place new journal notes in the subfolder 'Journal' enter: \"Journal\"; to place new journal notes in the subfolder 'Journal' in the subfolder 'Personal' enter: \"Personal/Journal\". Leave blank to disable (notes will be created in the currently active folder).",
            "type": "string",
            "default": ""
        },
        {
            "identifier": "defaultTags",
            "name": "Default tags",
            "description": "One or more default tags (separated by commas) to assign to a newly created journal note. Leave blank to disable auto-tagging.",
            "type": "string",
            "default": "journal"
        },
        {
            "identifier": "noteTitleFormat",
            "name": "Title Format",
            "description": "How the journal title should be formatted, use date format placeholders inside curly braces. YYYY: year, MM: month, DD: day, WW: week, HH: hours, mm: minutes, ss: seconds, ddd: short day of the week e.g. 'Mon'. For example \"Journal {YYYYMMDD}\" will return \"Journal 20240928\". You can have monthly or weekly journals instead of daily by formatting the date to the week or monthly level, or one journal file per entry by including the hour, minutes and seconds.",
            "type": "string",
            "default": "Journal {YYYYMMDD}"
        },
        {
            "identifier": "noteBodyTemplate",
            "name": "Template",
            "description": "Template for a new journal entry.",
            "type": "text",
            "default": ""
        },
    ]

    function createOrJumpToJournalEntry(m, identifier) {
        var headline;
        if (!noteTitleFormat || noteTitleFormat.length == 0) {
            headline = "Journal " + m.getFullYear() + ("0" + (m.getMonth() + 1)).slice(-2) + ("0" + m.getDate()).slice(-2);
        } else {
            headline = noteTitleFormat.replace(/{[^}]*}/g, function (match) {
                return formatDate(m, match.slice(1, -1));
            });
        }

        var fileName = headline + ".md";

        // Check if we already have the requested journal entry.

        // When a default folder is set, make sure to search in that folder.
        // This has the highest chance of finding an existing journal note.
        // Right now we can not search the whole database for a note with this
        // name / filename.
        if (defaultFolder && defaultFolder !== '') {
            script.jumpToNoteSubFolder(defaultFolder);
        }

        var note = script.fetchNoteByFileName(fileName);

        // check if note was found
        if (note.id > 0) {
            // jump to the note if it was found
            script.log("found journal entry: " + headline);
            script.setCurrentNote(note);
        } else {
            // create a new journal entry note if it wasn't found
            // keep in mind that the note will not be created instantly on the disk
            script.log("creating new journal entry: " + headline);

            // Default folder.
            if (defaultFolder && defaultFolder !== '') {
                var msg = 'Jump to default folder \'' + defaultFolder + '\' before creating a new journal note.';
                script.log('Attempt: ' + msg);
                var jump = script.jumpToNoteSubFolder(defaultFolder);
                if (jump) {
                    script.log('Success: ' + msg);
                } else {
                    script.log('Failed: ' + msg);
                }
            }

            // Create the new journal note.
            script.createNote(headline + "\n" + '='.repeat(Math.max(4, headline.length)) + "\n\n" + noteBodyTemplate);

            const currentNote = script.currentNote();

            // rename the note file if needed
            if (currentNote.allowDifferentFileName()) {
                currentNote.renameNoteFile(headline);
                mainWindow.buildNotesIndexAndLoadNoteDirectoryList(false, true);
            }

            // Default tags.
            if (defaultTags && defaultTags !== '') {
                defaultTags
                // Split on 0..* ws, 1..* commas, 0..* ws.
                .split(/\s*,+\s*/).forEach(function (i) {
                    script.log('Tag the new journal note with default tag: ' + i);
                    script.tagCurrentNote(i);
                });
            }
        }
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        // Get the date for the headline.
        var m = new Date();

        switch (identifier) {
        case "journalEntryTomorrow":
            // Set date to tomorrow if action is 'journalEntryTomorrow'.
            m.setDate(m.getDate() + 1);
        case "journalEntry":
            createOrJumpToJournalEntry(m, identifier);
            break;
        case "journalEntryDate":
            showCalendar();
            break;
        }
    }
    function formatDate(date, format) {
        let day = date.getDate();
        let dayOfWeek = _SHORT_DAYS_EN[date.getDay()];
        let month = date.getMonth() + 1; //getMonth() returns 0-11 so we must add 1
        let week = getWeekNumber(date);
        let year = date.getFullYear();
        let hours = date.getHours();
        let minutes = date.getMinutes();
        let seconds = date.getSeconds();

        // If day and month are less than 10, add a leading zero
        day = (day < 10) ? '0' + day : day;
        month = (month < 10) ? '0' + month : month;
        week = (week < 10) ? '0' + week : week;
        hours = (hours < 10) ? '0' + hours : hours;
        minutes = (minutes < 10) ? '0' + minutes : minutes;
        seconds = (seconds < 10) ? '0' + seconds : seconds;

        // Replace format placeholders by actual values
        format = format.replace('WW', week);
        format = format.replace('MM', month);
        format = format.replace('DD', day);
        format = format.replace('ddd', dayOfWeek);
        format = format.replace('YYYY', year);
        format = format.replace('HH', hours);
        format = format.replace('mm', minutes);
        format = format.replace('ss', seconds);

        return format;
    }
    function getWeekNumber(d) {
        // Copy date so don't modify original
        d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        var yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        var weekNo = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
        return weekNo;
    }

    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction("journalEntry", "Create a journal entry", "Journal", "document-new");

        // Create custom action for 'Create or open journal entry for tomorrow'.
        script.registerCustomAction("journalEntryTomorrow", "Create or open a journal entry for tomorrow", "Journal tomorrow", "document-multiple");

        // Create custom action for 'Create or open journal entry for a certain date'.
        script.registerCustomAction("journalEntryDate", "Create or open a journal entry for a certain date", "Journal date", "view-calendar");
    }
    function showCalendar() {
        var component = Qt.createComponent("calendar-window.qml");

        if (component.status === Component.Ready) {
            dialog = component.createObject();
        } else {
            console.error(component.errorString());
        }
    }
}
