import QtQml 2.0
import com.qownnotes.noteapi 1.0

import QtQuick.Window 2.2
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtQuick 2.0

/**
 * Based on (@pbek, @sanderboom, @wiktor2200)'s meeting-note script.
 * This script creates a menu item and a button to create or jump to the current date's or datetime's categorized note
 * It creates a small window to select the category e. g. 'work' and creates the corresponding note (in its separate subfolder) with a date.
 */
QtObject {
    property string categoryList
    property string defaultFolder
    property string defaultTags
    property var dialog
    property bool hasCategoryAsTag
    property bool hasCategoryPrefix
    property bool hasOwnCategoryFolder
    property bool hasTimeInNoteName
    property string noteBodyTemplate

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "categoryList",
            "name": "File and headline prefix",
            "description": "Please enter the note categories comma separated e. g. 'sales,logistics,support'",
            "type": "string",
            "default": "sales,logistics,support,colleagues,clients,honeymoon"
        },
        {
            "identifier": "defaultFolder",
            "name": "Default folder",
            "description": "The default folder where the newly created note should be placed. Specify the path to the folder relative to the note folder. Make sure that the full path exists. \nExamples: to place new notes in the subfolder 'Work' enter: \"Work\"; to place new notes in the subfolder 'Clients' in the subfolder 'Work' enter: \"Work/Clients\". Leave blank to disable (notes will be created in the currently active folder).",
            "type": "string",
            "default": ""
        },
        {
            "identifier": "hasOwnCategoryFolder",
            "name": "Default Category Folder",
            "description": "The category will create its own subfolder.",
            "type": "boolean",
            "default": true
        },
        {
            "identifier": "hasCategoryPrefix",
            "name": "Category Prefix",
            "description": "The note file will carry the category's name as prefix.",
            "type": "boolean",
            "default": true
        },
        {
            "identifier": "hasCategoryAsTag",
            "name": "Category Tag",
            "description": "Add the category's name as tag.",
            "type": "boolean",
            "default": true
        },
        {
            "identifier": "defaultTags",
            "name": "Default tags (TODO)",
            "description": "One or more default tags (separated by commas) to assign to a newly created meeting note. Leave blank to disable auto-tagging.",
            "type": "string",
            "default": "meeting"
        },
        {
            "identifier": "hasTimeInNoteName",
            "name": "Time in note name",
            "description": "Add time (HH:mm) in the category's note name.",
            "type": "boolean",
            "default": false
        },
        {
            "identifier": "noteBodyTemplate",
            "name": "Template",
            "description": "Template for a new meeting entry.",
            "type": "text",
            "default": ""
        },
    ]

    /**
      *
      *
      */
    function createNote(category) {
        // close the window a little faster
        dialog.close();
        dialog.destroy();

        // get the date headline
        var m = new Date();
        var dateString = m.getFullYear() + "-" + ("0" + (m.getMonth() + 1)).slice(-2) + "-" + ("0" + m.getDate()).slice(-2);

        /*  if (isAskForDateString) {
            dateString = script.inputDialogGetText(
                        "Date string", "Please enter the date string", dateString);
        }*/

        var prefix = hasCategoryPrefix ? category : "";
        var headline = prefix + "_" + dateString;

        if (hasTimeInNoteName) {
            headline = headline + "T" + ("0" + m.getHours()).slice(-2) + "." + ("0" + m.getMinutes()).slice(-2);
        }

        var fileName = headline + ".md";

        // Check if we already have a meeting note for today.

        // When a default folder is set, make sure to search in that folder.
        // This has the highest chance of finding an existing meeting note.
        // Right now we can not search the whole database for a note with this
        // name / filename.
        if (defaultFolder !== '') {
            script.jumpToNoteSubFolder(defaultFolder);
        }

        var subFolder = defaultFolder;

        if (hasOwnCategoryFolder) {
            subFolder += (subFolder !== '') ? '/' : '';
            subFolder += category;
            mainWindow.createNewNoteSubFolder(category);
            script.jumpToNoteSubFolder(subFolder);
        }

        var note = script.fetchNoteByFileName(fileName);

        // check if note was found
        if (note.id > 0) {
            // jump to the note if it was found
            script.log("found categorized note: " + headline);
            script.setCurrentNote(note);
        } else {
            // create a new meeting note if it wasn't found
            // keep in mind that the note will not be created instantly on the disk
            script.log("creating new note: " + headline);

            // Sub folder.
            if (subFolder !== '') {
                var msg = 'Jump to folder \'' + subFolder + '\' before creating a new categorized note.';
                script.log('Attempt: ' + msg);
                var jump = script.jumpToNoteSubFolder(subFolder);
                if (jump) {
                    script.log('Success: ' + msg);
                } else {
                    script.log('Failed: ' + msg);
                }
            }

            // Create the new meeting note.
            script.createNote(headline + "\n====================\n\n" + noteBodyTemplate);
            const currentNote = script.currentNote();
            // Default tags.
            if (defaultTags && defaultTags !== '') {
                defaultTags
                // Split on 0..* ws, 1..* commas, 0..* ws.
                .split(/\s*,+\s*/).forEach(function (i) {
                    script.log('Tag the new meeting note with default tag: ' + i);
                    script.tagCurrentNote(i);
                });
            }
            // category tag
            if (hasCategoryAsTag && defaultTags !== '') {
                script.tagCurrentNote(category);
            }

            // adjust file name
            //script.log("Allow different file names: "+currentNote.allowDifferentFileName())
            if (currentNote.allowDifferentFileName()) {
                currentNote.renameNoteFile(headline);
                mainWindow.buildNotesIndexAndLoadNoteDirectoryList(false, true);
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
        if (identifier !== "categorizedNote") {
            return;
        }
        showCategoryBox();
    }
    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction("categorizedNote", "Create or open a categorized note", "Categorized Note", "document-new", true, false, true);
    }
    function showCategoryBox() {
        var component = Qt.createComponent("categorized-notes-window.qml");
        if (component.status === Component.Ready) {
            dialog = component.createObject();
            var categories = categoryList.split(",");
            let categories = categories.map(str => str.trim()); // trim names
            dialog.createButtons(categories);
        } else {
            console.error(component.errorString());
        }
    }
}
