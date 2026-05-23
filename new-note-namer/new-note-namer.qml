import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script allows to set both the title and headline of a new note.
 Recommended for when "headline == file name" option is enabled.
 Avoids cumbersome renaming and title editing.
 */
QtObject {
    property bool extraDialogForTitle
    property bool extraDialogForFileName
    property string headingStyle
    property string _searchTerm: ""
    property string customHeadingOpen
    property string customHeadingClose
    property variant settingsVariables: [
        {
            'identifier': 'extraDialogForTitle',
            'name': 'Show a dialog to define the note title',
            'description': 'If checked, ask for a custom note title.',
            'type': 'boolean',
            'default': 'false'
        },
        {
            'identifier': 'extraDialogForFileName',
            'name': 'Show a dialog to define the file name',
            'description': 'If checked, ask for a custom file name.',
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
        // Strip QOwnNotes search filter prefixes (e.g. "n:" for name-only search).
        _searchTerm = headline.replace(/^n:/i, "");
        var name;
        if (extraDialogForTitle || _searchTerm === "") {
            // Show dialog: pre-fill with the search term if available, otherwise a placeholder.
            name = newNamer("New note", "New note title", _searchTerm !== "" ? _searchTerm : "Title");
        } else {
            // If already provided (search term or QOwnNotes own dialog), use it directly.
            name = _searchTerm;
        }
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

        // Default file name: search term if available, otherwise derived from the title.
        var defaultName = _searchTerm !== "" ? _searchTerm : extractTitle(note.noteText);

        if (extraDialogForFileName) {
            return newNamer("New note", "New file name", defaultName);
        }

        return defaultName;
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
