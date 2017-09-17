import QtQml 2.2
import QOwnNotesTypes 1.0

Script {
    function setDefaultPyCommand() {
        
        if (script.getPersistentVariable('MdNT/pyCommand', '') == '') {
            
            if (script.platformIsWindows()) { 
                var defaultPyCommand = 'pythonw'
            }
            else { 
                var defaultPyCommand = 'python3'
            }
            
            if (script.startSynchronousProcess(defaultPyCommand, '-V', '').toString().indexOf('Python 3') != '-1') {
                script.setPersistentVariable('MdNT/pyCommand', checkPyCommand())
            }
        }
        
        return script.getPersistentVariable('MdNT/pyCommand', '')
    }

    property string scriptDirPath
    property string noteFolder
    property string inboxFolder
    property bool   scanFolder
    property bool   watchFS
    property string tagMarker
    property string pyCommand
    property string pandocCommand
    property string pandocVersion

    property variant settingsVariables: [
        {
            'identifier': 'noteFolder',
            'name': 'Note folder path',
            'description': 'Full absolute path to note folder to process. You can select "notes.sqlite" file or type the path in.\n' +
                           "Leave empty for current note folder. Continuous watch mode won't work if empty.",
            'type': 'file',
            'default': '',
        },
        {
            'identifier': 'inboxFolder',
            'name': 'Inbox folder name',
            'description': 'Name of inbox folder located in the root of note folder. An new inbox folder will be created if no exists.',
            'type': 'string',
            'default': 'Inbox',
        },
        {
            'identifier': 'scanFolder',
            'name': 'Scan whole folder rather than only Inbox folder',
            'description': 'If true the script will convert any non-".md" file in folder to note.\n' +
                           '"Sub-folder to single note" and modification times in note titles features will still work only for Inbox.',
            'type': 'boolean',
            'default': 'false',
        },
        {
            'identifier': 'watchFS',
            'name': 'Continuously watch for new files and process them as they appear',
            'description': 'If true the script will continuously watch inbox/folder (depending on above setting)\n' +
                           'for new files and process them as soon as they appear.\n' +
                           'The script will start working on load, no toolbar button will appear.',
            'type': 'boolean',
            'default': 'false',
        },
        {
            'identifier': 'tagMarker',
            'name': 'Tag word marker',
            'description': 'A symbol or string of symbols which start a "topic" word for ".txt" notes. \n' +
                           'For example, if set to "@", a ".txt" file with "@tag" word will go to "tag.md" note',
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

    function runInbox() {

        var pyScriptPath = scriptDirPath + script.dirSeparator() + 'inbox.py'
        var inboxPath = noteFolder + script.dirSeparator() + inboxFolder

        var args = [pyScriptPath,
                    '--inbox', inboxPath,
                    '--folder', noteFolder,
                    '--marker', tagMarker]

        if (scanFolder == true) {
            args.push('--scan-folder')
        }

        if (watchFS == true) {
            args.push('--watch')
        }

        if (pandocVersion != '') {
            args.push('--pandoc-bin', pandocCommand,
                      '--pandoc-ver', pandocVersion)
        }

        script.startDetachedProcess(pyCommand, args)
        script.log('Processing inbox...')
    }

    function init() {

        if (noteFolder == '') {
            noteFolder = script.currentNoteFolderPath()
            watchFS = false
        }
        else {
            noteFolder = noteFolder.replace(script.dirSeparator() + 'notes.sqlite', '')
        }

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
            }
            else {
                script.setPersistentVariable('MdNT/pandocCommand', '')
            }
        }

        /// Issues alerts
        if (script.getPersistentVariable('MdNT/pandocCommand', '') == '') {
            script.informationMessageBox('The command/path for pandoc in the script settings is not valid.\n' +
                                         'Converting web pages to notes will be disabled.',
                                         'Inbox script')
            script.setPersistentVariable('MdNT/pandocCommand', pandocCommand)
            script.setPersistentVariable('MdNT/pandocVersion', '')
            pandocVersion = ''
        }
        else {
            pandocVersion = script.getPersistentVariable('MdNT/pandocVersion', '')
        }

        if (script.getPersistentVariable('MdNT/pyCommand', '') == '') {
            script.informationMessageBox('The command/path for Python 3 interpreter in the script settings is not valid.\n' +
                                         'Please set the correct command/path.',
                                         'Inbox script')
        }
        else if (watchFS == true) {
            runInbox()
        }
        else {
            script.registerCustomAction('inbox', 'Process inbox folder', 'Inbox', 'mail-receive.svg')
        }
    }

    function customActionInvoked(action) {
        if (action == 'inbox') {
            runInbox()
        }
    }
}
