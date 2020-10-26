import QtQml 2.0
import com.qownnotes.noteapi 1.0

/**
 * This script creates new QOwnNotes blog posts
 */
QtObject {
    property string defaultFolder;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "defaultFolder",
            "name": "Default folder",
            "description": "The default folder where the newly created blog post should be placed.",
            "type": "string",
            "default": "",
        },
    ];

    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction("qownnotesBlogPost", "Create a QOwnNotes Blog Post", "QON Blog Post", "document-new");
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "qownnotesBlogPost") {
            return;
        }

        // get the date headline
        var m = new Date();
        var dateString = m.getFullYear() + "-" + ("0" + (m.getMonth()+1)).slice(-2) + "-" + ("0" + m.getDate()).slice(-2)
        var order = m.getFullYear() + ("0" + (m.getMonth()+1)).slice(-2) + ("0" + m.getDate()).slice(-2) + "000000"

        var headline = script.inputDialogGetText(
            "Title", "Please enter blog post title", "New blog post");

        var fileName = dateString + "-" + headline.replace(/\s/g, "-");

        // Check if we already have a blog post for today.

        // When a default folder is set, make sure to search in that folder.
        // This has the highest chance of finding an existing blog post.
        // Right now we can not search the whole database for a note with this
        // name / filename.
        if (defaultFolder !== '') {
            script.jumpToNoteSubFolder(defaultFolder);
        }

        var subFolder = defaultFolder;

        var note = script.fetchNoteByFileName(fileName);

        // check if note was found
        if (note.id > 0) {
            // jump to the note if it was found
            script.log("found blog post: " + headline);
            script.setCurrentNote(note);
        } else {
            // create a new blog post if it wasn't found
            // keep in mind that the note will not be created instantly on the disk
            script.log("creating new blog post: " + headline);

            // Sub folder.
            if (subFolder !== '') {
                var msg = 'Jump to folder \'' + subFolder + '\' before creating a new blog post.';
                script.log('Attempt: ' + msg);
                var jump = script.jumpToNoteSubFolder(subFolder);
                if (jump) {
                    script.log('Success: ' + msg);
                } else {
                    script.log('Failed: ' + msg);
                }
            }

            // Create the new blog post.
            script.createNote("---\ntitle: " + headline + "\ndescription: \ndate: " + dateString + "\norder: " + order + "\n---\n\n# " + headline + "\n\n" +
                "<BlogDate v-bind:fm=\"$frontmatter\" />\n\n\n");
            const currentNote = script.currentNote();

            // rename the note file if needed
            if (currentNote.allowDifferentFileName()) {
                currentNote.renameNoteFile(fileName);
                mainWindow.buildNotesIndexAndLoadNoteDirectoryList(false, true);
            }
        }
    }
}
