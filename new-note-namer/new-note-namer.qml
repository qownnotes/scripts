import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script allows to set both the title and headline of a new note.
 Recommended for when "headline == file name" option is enabled.
 Avoids cumbersome renaming and title editing.
 */
QtObject {
    property bool extraDialogForFileName
    property bool underlineHeading
    property bool useSearchTermAsName
    property string searchTermHeadingStyle
    property string customHeadingOpen
    property string customHeadingClose
    property string _pendingSearchTerm: ""
    property variant settingsVariables: [
        {
            'identifier': 'extraDialogForFileName',
            'name': 'Extra dialog for note title',
            'description': 'Show an additional dialog window so user can write a file name different to the note title.',
            'type': 'boolean',
            'default': 'false'
        },
        {
            'identifier': 'underlineHeading',
            'name': 'Setext Markdown underline heading',
            'description': 'Use Setext heading style (Title / =====) for the dialog flow; if unchecked, use ATX (# Title).',
            'type': 'boolean',
            'default': 'false'
        },
        {
            'identifier': 'useSearchTermAsName',
            'name': 'Name note from search term',
            'description': 'Skip the title dialog and use the current search term as the note name.',
            'type': 'boolean',
            'default': 'false'
        },
        {
            'identifier': 'searchTermHeadingStyle',
            'name': 'Search term note – heading style',
            'description': 'Title format when creating a note from the search term.',
            'type': 'selection',
            'default': '0',
            'items': {
                '0': 'ATX Markdown heading (# Title)',
                '1': 'Setext Markdown underline heading (Title / =====)',
                '2': 'Custom heading (opening and closing tags)'
            }
        },
        {
            'identifier': 'customHeadingOpen',
            'name': 'Search term note – custom heading opening tag',
            'description': 'Text inserted before the note name (only used when heading style is "Custom").',
            'type': 'string',
            'default': ''
        },
        {
            'identifier': 'customHeadingClose',
            'name': 'Search term note – custom heading closing tag',
            'description': 'Text inserted after the note name (only used when heading style is "Custom").',
            'type': 'string',
            'default': ''
        },
    ]

    function handleNewNoteHeadlineHook(headline) {
        // 'headline' is a plain string (the search term or default text), not a Note object.
        if (useSearchTermAsName) {
            _pendingSearchTerm = headline;
            return headline; // noteOpenedHook will replace content with the chosen heading style
        }

        var newName = newNamer("New note", "New note title", "Title");
        if (underlineHeading) {
            return newName + "\n" + "=".repeat(newName.length);
        }
        return "# " + newName;
    }
    function buildHeadline(name) {
        if (searchTermHeadingStyle === "2") {
            return customHeadingOpen + name + customHeadingClose;
        }
        if (searchTermHeadingStyle === "1") {
            return name + "\n" + "=".repeat(name.length);
        }
        return "# " + name; // "0" (ATX) or unset
    }
    function handleNoteTextFileNameHook(note) {
        // right when a note is created, the fileCreated property value is 'Invalid Date'
        // this blocks the hook from further changing the note file name if the note title is changed
        if (note.fileCreated != "Invalid Date") {
            return "";
        }

        if (useSearchTermAsName && _pendingSearchTerm !== "") {
            return _pendingSearchTerm; // set by handleNewNoteHeadlineHook
        }

        if (extraDialogForFileName) {
            return newNamer("New note", "New file name", "File name");
        }

        var noteLines = (note.noteText || "").split("\n");
        var firstLine = noteLines[0];
        var noteTitle = firstLine.slice(2); // Remove the preceding "# "
        if (underlineHeading) {
            noteTitle = firstLine;
        }
        return noteTitle;
    }
    function noteOpenedHook(note) {
        if (_pendingSearchTerm === "") {
            return;
        }
        var name = _pendingSearchTerm;
        _pendingSearchTerm = "";
        script.noteTextEditSetSelection(0, (note.noteText || "").length);
        script.noteTextEditWrite(buildHeadline(name));
        mainWindow.focusNoteTextEdit();
    }
    function init() {
        script.log("New-note-namer active");
    }
    function newNamer(title, message, defaultText) {
        var name = script.inputDialogGetText(title, message, defaultText);

        script.log("input name: " + name);

        if (name == "" || name == null) {
            name = defaultText;
        }

        return name;
    }
}
