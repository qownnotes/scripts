import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script allows to set both the title and headline of a new note.
 Recommended for when "headline == file name" option is enabled.
 Avoids cumbersome renaming and title editing.
 */
QtObject {
    property bool extraDialogForFileName;
    property bool underlineHeading;
    property variant settingsVariables: [
            {
                'identifier': 'extraDialogForFileName',
                'name': 'Extra dialog for note title',
                'description': 'Show an additional dialog window so user can write a file name different to the note title.',
                'type': 'boolean',
                'default': 'false',
            },
            {
                'identifier': 'underlineHeading',
                'name': 'Underline heading',
                'description': 'Highlight the first line by underlining it with =, if not checked, use a preceding # instead.',
                'type': 'boolean',
                'default': 'false',
            },
        ];

  function init() {
    script.log("New-note-namer active");
  }

  function newNamer(title, message, defaultText) {
    var name = script.inputDialogGetText(
      title, message, defaultText);

    script.log("input name: " + name);

    if (name == "" || name == null){
      name = defaultText;
    }

    return name;
  }

  function handleNewNoteHeadlineHook(note) {

    var newName = newNamer("New note", "New note title", "Title");
    script.log(note.fileCreated)
    script.log(note.fileLastModified)

    if (underlineHeading) {
          return newName + "\n" + "=".repeat(newName.length);
    } else {
          return "# " + newName;
    }
  }

  function handleNoteTextFileNameHook(note) {
          script.log("note name: " + note.name);
          script.log("file name: "+ note.fileName);
          script.log(note.fileCreated)
          script.log(note.fileLastModified)

          var noteLines = note.noteText.split("\n");
          var firstLine = noteLines[0];
          var noteTitle = firstLine.slice(2) // Remove the preceding "# "
          if (underlineHeading){             // Underlined headings use the entire first line
              noteTitle = firstLine;
          }

          script.log("note title: " + noteTitle)

          // right when a note is created, the fileCreated property value is 'Invald Date'
          // this blocks the hook to further change the note file name if the note title is changed
          if (note.fileCreated != "Invalid Date"){
              return ""
          }

          if (extraDialogForFileName) {
              return newNamer("New note", "New file name", "File name")
          } else {
              return noteTitle
          }
      }

}
