import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script allows to set both the title and headline of a new note.
 Recommended for when "headline == file name" option is enabled.
 Avoids cumbersome renaming and title editing.
 */
QtObject {
    property bool useSearchTermAsName
    property bool extraDialogForFileName
    property string headingStyle
    property string customHeadingOpen
    property string customHeadingClose
    property string _pendingSearchTerm: ""
    property variant settingsVariables: [
        {
            'identifier': 'useSearchTermAsName',
            'name': 'Name note from search term',
            'description': 'Skip the title dialog and use the current search term as the note name.',
            'type': 'boolean',
            'default': 'false'
        },
        {
            'identifier': 'extraDialogForFileName',
            'name': 'Extra dialog for note title',
            'description': 'Show an additional dialog window so user can write a file name different to the note title.',
            'type': 'boolean',
            'default': 'false'
        },
        {
            'identifier': 'headingStyle',
            'name': 'Heading style',
            'description': 'Title format for new notes.',
            'type': 'selection',
            'default': '0',
            'items': {
                '0': 'ATX Markdown heading (# Title)',
                '1': 'Setext Markdown heading (Title / =====)',
                '2': 'Custom heading (opening and closing tags)'
            }
        },
        {
            'identifier': 'customHeadingOpen',
            'name': 'Custom heading – opening tag',
            'description': 'Text inserted before the note name (only used when heading style is "Custom").',
            'type': 'string',
            'default': ''
        },
        {
            'identifier': 'customHeadingClose',
            'name': 'Custom heading – closing tag',
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

        // If QOwnNotes already provided a headline (its own dialog, or a search term),
        // apply the chosen style directly rather than asking again.
        var name = headline !== "" ? headline : newNamer("New note", "New note title", "Title");
        return buildHeadline(name);
    }
    function buildHeadline(name) {
        if (headingStyle === "2") {
            return customHeadingOpen + name + customHeadingClose;
        }
        if (headingStyle === "1") {
            return name + "\n" + "=".repeat(name.length);
        }
        return "# " + name; // "0" (ATX) or unset
    }
    function extractTitle(noteText) {
        var firstLine = (noteText || "").split("\n")[0];
        if (headingStyle === "2") {
            var t = firstLine.slice(customHeadingOpen.length);
            var closeLen = customHeadingClose.length;
            if (closeLen > 0 && t.slice(-closeLen) === customHeadingClose) {
                t = t.slice(0, t.length - closeLen);
            }
            return t;
        }
        if (headingStyle === "1") {
            return firstLine; // setext: first line is the bare title
        }
        return firstLine.slice(2); // ATX: remove "# "
    }
    function handleNoteTextFileNameHook(note) {
        // right when a note is created, the fileCreated property value is 'Invalid Date'
        // this blocks the hook from further changing the note file name if the note title is changed
        if (note.fileCreated != "Invalid Date") {
            return "";
        }

        if (useSearchTermAsName && _pendingSearchTerm !== "") {
            if (extraDialogForFileName) {
                return newNamer("New note", "New file name", _pendingSearchTerm);
            }
            return _pendingSearchTerm;
        }

        if (extraDialogForFileName) {
            return newNamer("New note", "New file name", extractTitle(note.noteText));
        }

        return extractTitle(note.noteText);
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
