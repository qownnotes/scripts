import QtQml 2.2
import QOwnNotesTypes 1.0

/*This script adds a toolbar button and a note list context menu item to merge multiple selected notes.
  Notes are merged to the first selected note or to a new note, depending on settings. Notes are merged in the order they were selected.
  Dependencies: Python 3.3+ Interpreter
*/

Script {
    /// functions to find correct Python 3 interpreter command and set it as default
    function getPyCommand() {
        if (script.startSynchronousProcess('pythonw', '-V', '').toString().indexOf('Python 3') != '-1') {return 'pythonw'}
        if (script.startSynchronousProcess('python3', '-V', '').toString().indexOf('Python 3') != '-1') {return 'python3'}
        if (script.startSynchronousProcess('python',  '-V', '').toString().indexOf('Python 3') != '-1') {return 'python'}
        return ''
    }

    function setDefaultPyCommand() {
        if (script.getPersistentVariable('MdNT/pyCommand', '') == '') {
            script.setPersistentVariable('MdNT/pyCommand', getPyCommand())
        }
        return script.getPersistentVariable('MdNT/pyCommand', '')
    }


    property string scriptDirPath
    property bool mergeToFirst
    property bool deleteMerged
    property string pyCommand

    property variant settingsVariables: [
        {
            'identifier': 'mergeToFirst',
            'name': '',
            'description': 'Merge selected notes to the note, which was selected first\n' +
                           'If disabled, notes will be merged to a new note',
            'type': 'boolean',
            'default': 'False',
        },
        {
            'identifier': 'deleteMerged',
            'name': '',
            'description': 'Delete notes that were merged',
            'type': 'boolean',
            'default': 'False',
        },
        {
            'identifier': 'pyCommand',
            'name': 'Command/path to run Python 3 Interpreter',
            'description': "Put a command or path for Python 3 interpreter here.",
            'type': 'file',
            'default': setDefaultPyCommand(),
        }
    ]

    function init() {
        /// Check if set pyCommand can run Python 3, alert the user on failure, enable custom action on success
        if (script.getPersistentVariable('MdNT/pyCommand', '') != pyCommand) {

            if (script.startSynchronousProcess(pyCommand, '-V', '').toString().indexOf('Python 3') != '-1') {
                script.setPersistentVariable('MdNT/pyCommand', pyCommand)
            }
            else {
                script.setPersistentVariable('MdNT/pyCommand', '')
            }
        }

        if (script.getPersistentVariable('MdNT/pyCommand', '') == '') {
            script.informationMessageBox('The command/path for Python 3 interpreter in the script settings is not valid\n' +
                                         'Please set the correct command/path.',
                                         'Script')
        }
        else {
            script.registerCustomAction('mergeNotes', 'Merge selected notes', 'Merge notes', 'merge.svg', false, false, true)
        }
    }

    function customActionInvoked(action) {
        if (action == 'mergeNotes') {
            var pyScriptPath = scriptDirPath + script.dirSeparator() + 'merge.py'

            script.startDetachedProcess(pyCommand, [pyScriptPath, mergeToFirst, deleteMerged, script.selectedNotesPaths().join('//>')])

            // script.log(pyCommand + " '" + [pyScriptPath, mergeToFirst, deleteMerged, script.selectedNotesPaths().join('//>')].join("' '") + "'")
        }
    }
}
