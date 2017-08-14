import QtQml 2.2
import QOwnNotesTypes 1.0

/*
 */

Script {
    property string scriptDirPath
    property string inboxFolder
    property string tagMarker
    property string pyBin

    function getPyCommand() {
        var pyVer = script.startSynchronousProcess('python3', '-V', '').toString()
        if (pyVer.indexOf('Python 3') != '-1') {
            return 'python3'
            }
        var pyVer = script.startSynchronousProcess('python', '-V', '').toString()
        if (pyVer.indexOf('Python 3') != '-1') {
            return 'python'
            }
        var pyVer = script.startSynchronousProcess('py', '-V', '').toString()
        if (pyVer.indexOf('Python 3') != '-1') {
            return 'py'
            }
        return ''
    }

    property variant settingsVariables: [
        {
            'identifier': 'inboxFolder',
            'name': 'Inbox folder name',
            'description': 'Name of inbox folder located in the root of note folder. It is single for all note folders\n' +
                           'An empty inbox folder will be created if no exists.',
            'type': 'string',
            'default': 'Inbox',
        },
        {
            'identifier': 'tagMarker',
            'name': 'Tag word marker',
            'description': 'A symbol or group of symbols which start a "tag" word for txt notes. \n' +
                           'For example a txt note with "@tag" word will go to "tag.md" note',
            'type': 'string',
            'default': '@',
        },
        {
            'identifier': 'pyBin',
            'name': 'Command/path to run Python 3 Interpreter',
            'description': "Put a command or path for Python 3 interpreter here.",
            'type': 'file',
            'default': getPyCommand(),
        }
    ]

    function init() {
        if (pyBin == '') {
            script.informationMessageBox("Can't find Python 3 interpreter.\n" +
                                         'Please set the correct path to its binary in the script settings.',
                                         'Inbox script')
        }
        else {
            script.registerCustomAction('inbox', 'Process inbox folder', 'Inbox', 'mail-receive.svg')
        }
    }

    function customActionInvoked(action) {
        if (action == 'inbox') {
            var pyScriptPath = scriptDirPath + script.dirSeparator() + 'inbox.py'
            var inboxPath = script.currentNoteFolderPath() + script.dirSeparator() + inboxFolder

            script.startDetachedProcess(pyBin, [pyScriptPath, inboxPath, script.currentNoteFolderPath(), tagMarker])
            script.log('Processing inbox...')
        }
    }
}
