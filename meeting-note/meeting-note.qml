import QtQml 2.0
import com.qownnotes.noteapi 1.0

/**
 * This script creates a menu item and a button to create or jump to the current date's meeting note
 */
QtObject {
    property string headlinePrefix;
    property string defaultFolder;
    property string defaultTags;
    property bool timeInNoteName;
    property string noteBodyTemplate;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "headlinePrefix",
            "name": "Headline prefix",
            "description": "Please enter a prefix for your note headline:",
            "type": "string",
            "default": "Teammeeting",
        },
        {
            "identifier": "defaultFolder",
            "name": "Default folder",
            "description": "The default folder where the newly created meeting note should be placed. Specify the path to the folder relative to the note folder. Make sure that the full path exists. Examples: to place new meeting notes in the subfolder 'Meeting' enter: \"Meeting\"; to place new meeting notes in the subfolder 'Meeting' in the subfolder 'Work' enter: \"Work/Meeting\". Leave blank to disable (notes will be created in the currently active folder).",
            "type": "string",
            "default": "",
        },
        {
            "identifier": "defaultTags",
            "name": "Default tags",
            "description": "One or more default tags (separated by commas) to assign to a newly created meeting note. Leave blank to disable auto-tagging.",
            "type": "string",
            "default": "meeting",
        },
        {
            "identifier": "timeInNoteName",
            "name": "Time in note name",
            "description": "Add time (HH:mm) in 'Meeting' note name.",
            "type": "boolean",
            "default": false,
        },
        {
            "identifier": "noteBodyTemplate",
            "name": "Template",
            "description": "Template for a new meeting entry.",
            "type": "text",
            "default": "",
        },
    ];

    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction("meetingNote", "Create or open a meeting note", "Meeting", "document-new");
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "meetingNote") {
            return;
        }

        // get the date headline
        var m = new Date();
        var headline = headlinePrefix + " " + m.getFullYear() + "-" + ("0" + (m.getMonth()+1)).slice(-2) + "-" + ("0" + m.getDate()).slice(-2);

        if (timeInNoteName) {
          headline = headline + "T" + ("0" + m.getHours()).slice(-2) + "." + ("0" + m.getMinutes()).slice(-2);
        }

        var fileName = headline + ".md";

        // Check if we already have a meeting note for today.

        // When a default folder is set, make sure to search in that folder.
        // This has the highest chance of finding an existing meeting note.
        // Right now we can not search the whole database for a note with this
        // name / filename.
        if (defaultFolder && defaultFolder !== '') {
            script.jumpToNoteSubFolder(defaultFolder);
        }

        var note = script.fetchNoteByFileName(fileName);

        // check if note was found
        if (note.id > 0) {
            // jump to the note if it was found
            script.log("found meeting note: " + headline);
            script.setCurrentNote(note);
        } else {
            // create a new meeting note if it wasn't found
            // keep in mind that the note will not be created instantly on the disk
            script.log("creating new meeting note: " + headline);

            // Default folder.
            if (defaultFolder && defaultFolder !== '') {
                var msg = 'Jump to default folder \'' + defaultFolder + '\' before creating a new meeting note.';
                script.log('Attempt: ' + msg);
                var jump = script.jumpToNoteSubFolder(defaultFolder);
                if (jump) {
                    script.log('Success: ' + msg);
                } else {
                    script.log('Failed: ' + msg);
                }
            }

            // Create the new meeting note.
            script.createNote(headline + "\n====================\n\n" + noteBodyTemplate);

            // Default tags.
            if (defaultTags && defaultTags !== '') {
                defaultTags
                    // Split on 0..* ws, 1..* commas, 0..* ws.
                    .split(/\s*,+\s*/)
                    .forEach(function(i) {
                        script.log('Tag the new meeting note with default tag: ' + i);
                        script.tagCurrentNote(i);
                    });
            }
        }
    }
}
