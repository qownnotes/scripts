import QtQml 2.2
import QOwnNotesTypes 1.0

Script {
    function checkPyCommand() {
        if (script.startSynchronousProcess('pythonw', '-V', '').toString().indexOf('Python 3') != '-1') {return 'pythonw'}
        if (script.startSynchronousProcess('python3', '-V', '').toString().indexOf('Python 3') != '-1') {return 'python3'}
        if (script.startSynchronousProcess('python',  '-V', '').toString().indexOf('Python 3') != '-1') {return 'python'}
        return ''
    }

    function setDefaultPyCommand() {
        if (script.getPersistentVariable('MdNT/pyCommand', '') == '') {
            script.setPersistentVariable('MdNT/pyCommand', checkPyCommand())
        }
        return script.getPersistentVariable('MdNT/pyCommand', '')
    }

    property string scriptDirPath
    property string inboxFolder
    property bool   scanFolder
    property string tagMarker
    property string pyCommand
    property string pandocCommand

    property string pandocVersion

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
            'identifier': 'scanFolder',
            'name': 'Scan whole folder rather than only Inbox folder',
            'description': 'If true the script will convert any non-".md" file in folder to note. \n' +
                           '"Sub-folder to single note" and modification times in note titles will still be only for Inbox.',
            'type': 'boolean',
            'default': 'false',
        },
        {
            'identifier': 'tagMarker',
            'name': 'Tag word marker',
            'description': 'A symbol or group of symbols which start a "topic" word for ".txt" notes. \n' +
                           'For example a txt note with "@tag" word will go to "tag.md" note',
            'type': 'string',
            'default': '@',
        },
        {
            'identifier': 'pyCommand',
            'name': 'Command/path to run Python 3 Interpreter',
            'description': "Put a command or path to run Python 3 interpreter.",
            'type': 'file',
            'default': setDefaultPyCommand(),
        },
        {
            'identifier': 'pandocCommand',
            'name': 'Command/path to run Pandoc',
            'description': "Put a command or path to run Pandoc.",
            'type': 'file',
            'default': 'pandoc',
        },
    ]


    function init() {
        pandocVersion = script.getPersistentVariable('MdNT/pandocVersion', '')

        /// Check if set pyCommand can run Python 3
        if (script.getPersistentVariable('MdNT/pyCommand', '') != pyCommand) {

            if (script.startSynchronousProcess(pyCommand, '-V', '').toString().indexOf('Python 3') != '-1') {
                script.setPersistentVariable('MdNT/pyCommand', pyCommand)
            }
            else {
                script.setPersistentVariable('MdNT/pyCommand', '')
            }
        }

        /// Get the version of pandoc
        if (script.getPersistentVariable('MdNT/pandocCommand', '') != pandocCommand) {
            var pandocCheck = script.startSynchronousProcess(pandocCommand, '-v', '').toString().split('\n')[0]
            if (pandocCheck.indexOf('pandoc') != '-1') {
                script.setPersistentVariable('MdNT/pandocCommand', pandocCommand)
                script.setPersistentVariable('MdNT/pandocVersion', pandocCheck.slice(7))
                pandocVersion = pandocCheck.slice(7)
            }
            else {
            script.setPersistentVariable('MdNT/pandocCommand', '')
            }
        }

        /// Issues alerts
        if (script.getPersistentVariable('MdNT/pandocCommand', '') == '') {
            script.informationMessageBox('The command/path for pandoc in the script settings is not valid\n' +
                                         'Converting web pages will be disabled.',
                                         'Script')
            script.setPersistentVariable('MdNT/pandocCommand', pandocCommand)
            script.setPersistentVariable('MdNT/pandocVersion', '')
            pandocVersion = ''
        }

        if (script.getPersistentVariable('MdNT/pyCommand', '') == '') {
            script.informationMessageBox('The command/path for Python 3 interpreter in the script settings is not valid\n' +
                                         'Please set the correct command/path.',
                                         'Script')
        }
        else {
            script.registerCustomAction('inbox', 'Process inbox folder', 'Inbox', 'mail-receive.svg')
        }
    }

    function customActionInvoked(action) {
        if (action == 'inbox') {
            var pyScriptPath = scriptDirPath + script.dirSeparator() + 'inbox.py'
            var inboxPath = script.currentNoteFolderPath() + script.dirSeparator() + inboxFolder

            var args = [pyScriptPath,
                        '--inbox', inboxPath,
                        '--folder', script.currentNoteFolderPath(),
                        '--marker', tagMarker]

            if (scanFolder == true) {
                args.push('--scan-folder')
            }

            if (pandocVersion != '') {
                args.push('--pandoc-bin', pandocCommand,
                          '--pandoc-ver', pandocVersion)
            }

            script.startDetachedProcess(pyCommand, args)
            script.log('Processing inbox...')
        }
    }
}