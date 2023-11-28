import QtQml 2.0
import com.qownnotes.noteapi 1.0

/**
 * This script creates a menu item and a button to toggle checkbox state.
 * Unfortunately the line with the checkbox needs to be selected (will maybe change
 * in the future).
 * Hint: assign a shortcut.
 */
QtObject {
    property bool checkboxCharacterUppercase;
    property bool onlyTouchCheckboxes;
    property string multipleLinesMethod;

    property variant settingsVariables: [
        {
            'identifier': 'checkboxCharacterUppercase',
            'name': 'Preferred checkbox-character',
            'description': 'Use - [X] instead of the default - [x] as checkbox-character.',
            'type': 'boolean',
            'default': 'false',
        },
        {
            'identifier': 'onlyTouchCheckboxes',
            'name': 'Only touch checkboxes',
            'description': 'Don\'t touch normal list items or normal lines.',
            'type': 'boolean',
            'default': 'false',
        },
        {
            'identifier': 'multipleLinesMethod',
            'name': 'Toggle multiple lines',
            'description': 'What should happen when toggling a selection of multiple lines?',
            'type': 'selection',
            'default': 'cycleIndividually',
            'items': {
                'cycleIndividually': 'Cycle all lines individually.',
                'synchronizeChecked': 'Set all checkboxes to checked when the selection contains at least one checked checkbox. Otherwise cycle.',
                // 'synchronizeFirst': 'Set all checkboxes to the value of the first checkox in the selection.',
            },
        }
    ]

    /**
     * Initializes the custom action
     */
    function init() {
        // See: http://docs.qownnotes.org/en/develop/scripting/README.html#id16
        script.registerCustomAction(
            'toggleCheckbox', /* identifier */
            'Toggle checkbox(es)', /* menuText */
            'Toggle checkbox(es)', /* buttonText */
            '', /* icon, see: https://specifications.freedesktop.org/icon-naming-spec/icon-naming-spec-latest.html */
            true, /* useInNoteEditContextMenu */
            false, /* hideButtonInToolbar */
            false /* useInNoteListContextMenu */
        );
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != 'toggleCheckbox') {
            return;
        }

        let noteTextEditSelectionStart = script.noteTextEditSelectionStart();
        let noteTextEditSelectionEnd = script.noteTextEditSelectionEnd();

        // Get selected lines.
        var text = script.noteTextEditSelectedText();

        // Nothing selected.
        if (text.trim() === '') {
            script.log('Nothing selected, attempt to select the current line.');
            script.noteTextEditSelectCurrentLine(); // TODO recurse.
            text = script.noteTextEditSelectedText();
            if (text.trim() === '') {
                script.log('Nothing selected, nothing to do.');
                return;
            }
        }

        // TODO: support '* - [ ]', '+ - [ ]' as well?
        var checkboxCharacter = '';
        var UNCHECKED = '- [ ] ';
        var CHECKED = (checkboxCharacterUppercase)
            ? '- [X] '
            : '- [x] ';
        var DISABLED = '- [-] ';

        // Set up synchronizeChecked.
        if (multipleLinesMethod === 'synchronizeChecked') {
            var mixedStatesPresent = false;

            // Contains at least 1 checked and at least 1 unchecked checkbox?
            if (
                text.match(/- \[(x|X)\] /) &&
                text.match(/- \[ \] /)
            ) {
                script.log('Scenario: at least 1 checked and at least 1 unchecked: set all lines to checked');
                mixedStatesPresent = true;
                checkboxCharacter = CHECKED;
            }
        }

        // Loop and convert all lines in selection.
        var lines = text.split('\n');
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].trim() === '') {
                continue;
            }

            // synchronizeChecked in effect.
            // checkboxCharacter is already correctly set.
            if (multipleLinesMethod === 'synchronizeChecked' && mixedStatesPresent) {
                lines[i] = lines[i].replace(/- \[( |x|X)\] /, checkboxCharacter);
            }
            // Default: cycle-all-lines-mode.
            else {
                script.log('Scenario: cycle-all-lines');

                // Toggle unchecked to checked.
                if (lines[i].match(/^- \[ \] /)) {
                    script.log('Convert unchecked to checked');
                    lines[i] = lines[i].replace(/- \[ \] /, CHECKED);
                }
                // Toggle checked to disabled.
                else if (lines[i].match(/^- \[(x|X)\] /)) {
                    script.log('Convert checked to disabled');
                    lines[i] = lines[i].replace(/- \[(x|X)\] /, DISABLED);
                }
                // Toggle disabled to unchecked.
                else if (lines[i].match(/^- \[-\] /)) {
                    script.log('Convert disabled to unchecked');
                    lines[i] = lines[i].replace(/- \[-\] /, UNCHECKED);
                }
                // Convert plain list lines (-, *, +) to unchecked checkboxes lines.
                else if (!onlyTouchCheckboxes && lines[i].match(/^(-|\*|\+) /)) {
                    script.log('Convert plain list to unchecked');
                    lines[i] = lines[i].replace(/^(-|\*|\+) /, UNCHECKED);
                }
                // Add checkboxes when unpresent (empty lines are skipped).
                else if (!onlyTouchCheckboxes) {
                    // TODO block adding UNCHECKED mid sentence, how to detect?
                    script.log('Convert no list to unchecked');
                    lines[i] = UNCHECKED + lines[i];
                }
            }
        }

        // Overwrite current selection with processed-content.
        script.noteTextEditWrite(lines.join('\n'));
        // TODO: select the inserted content (for true 'cycling'):
        //  - [x] single line
        //  - [ ] multiple line: how?

        // Restore selection
        script.noteTextEditSetSelection(noteTextEditSelectionStart, noteTextEditSelectionEnd);
    }
}
