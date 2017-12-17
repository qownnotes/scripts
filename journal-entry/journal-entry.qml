import QtQml 2.0
import com.qownnotes.noteapi 1.0

/**
 * This script creates a menu item and a button to create or jump to the current date's journal entry
 */
QtObject {
     property string defaultFolder;
     property string defaultTags;
     property bool singleJournalPerDay;

     property variant settingsVariables: [
        {
            "identifier": "defaultFolder",
            "name": "Default folder",
            "description": "The default folder where the newly created journal note should be placed. Specify the path to the folder relative to the note folder. Make sure that the full path exists. Examples: to place new journal notes in the subfolder 'Journal' enter: \"Journal\"; to place new journal notes in the subfolder 'Journal' in the subfolder 'Personal' enter: \"Personal/Journal\". Leave blank to disable (notes will be created in the currently active folder).",
            "type": "string",
            "default": "",
        },
        {
            "identifier": "defaultTags",
            "name": "Default tags",
            "description": "One or more default tags (separated by commas) to assign to a newly created journal note. Leave blank to disable auto-tagging.",
            "type": "string",
            "default": "journal",
        },
         {
            "identifier": "singleJournalPerDay",
            "name": "Single journal per day",
            "description": "Creates a single journal per day instead of always adding a new journal.",
            "type": "boolean",
            "default": "true",
        },
    ];

    /**
     * Initializes the custom action
     */
    function init() {
		if (singleJournalPerDay)
			script.registerCustomAction("journalEntry", "Create or open a journal entry", "Journal", "document-new");
        else
			script.registerCustomAction("journalEntry", "Create a journal entry", "Journal", "document-new");        
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "journalEntry") {
            return;
        }

        // get the date headline
        var m = new Date();
        var headline = "Journal " + m.getFullYear() + ("0" + (m.getMonth()+1)).slice(-2) + ("0" + m.getDate()).slice(-2);
        
        // when the configuration option "singleJournalPerDay" is selected create journal entries including time
        if (!singleJournalPerDay) {
			headline = headline + "T"+ ("0" + m.getHours()).slice(-2) + ("0" + m.getMinutes()).slice(-2) + ("0" + m.getSeconds()).slice(-2)
		}

        var fileName = headline + ".md";

        // Check if we already have a Journal note for today.

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
            script.createNote(headline + "\n================\n\n");

            // Default tags.
            if (defaultTags && defaultTags !== '') {
                defaultTags
                    // Split on 0..* ws, 1..* commas, 0..* ws.
                    .split(/\s*,+\s*/)
                    .forEach(function(i) {
                        script.log('Tag the new journal note with default tag: ' + i);
                        script.tagCurrentNote(i);
                    });
            }
        }
    }
}
