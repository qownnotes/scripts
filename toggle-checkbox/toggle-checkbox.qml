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
    property bool synchronizeCheckboxesChecked;

    property variant settingsVariables: [
        {
            'identifier': 'checkboxCharacterUppercase',
            'name': 'Preferred checkbox-character',
            'description': 'Use - [X] instead of the default - [x] as checkbox-character.',
            'type': 'boolean',
            'default': 'false',
        },
        {
            'identifier': 'synchronizeCheckboxesChecked',
            'name': 'Synchronize checkboxes by checked',
            'description': 'When a checked checkbox in the selected lines is detected, set all checkboxes to checked, instead of toggling individual lines.',
            'type': 'boolean',
            'default': 'false',
        },
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

        // Get selected lines.
        var text = script.noteTextEditSelectedText();

        // Nothing selected.
        if (text.trim() === '') {
            script.log('Nothing selected');
            return;
        }

        var lines = text.split('\n');

        // TODO: support '* - [ ]', '+ - [ ]' as well?
        var checkboxCharacter = '';
        var UNCHECKED = '- [ ] ';
        var CHECKED = (checkboxCharacterUppercase)
            ? '- [X] '
            : '- [x] ';

        // Set up synchronizeCheckboxesChecked.
        if (synchronizeCheckboxesChecked) {
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
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].trim() === '') {
                continue;
            }

            // synchronizeCheckboxesChecked in effect.
            // checkboxCharacter is already correctly set.
            if (synchronizeCheckboxesChecked && mixedStatesPresent) {
                lines[i] = lines[i].replace(/- \[( |x|X)\] /, checkboxCharacter);
            }
            // Default: invert-all-lines-mode.
            else {
                script.log('Scenario: invert-all-lines');

                // Toggle unchecked to checked.
                if (lines[i].match(/- \[ \] /)) {
                    script.log('Convert unchecked to checked');
                    lines[i] = lines[i].replace(/- \[ \] /, CHECKED);
                }
                // Toggle checked to unchecked.
                else if (lines[i].match(/- \[(x|X)\] /)) {
                    script.log('Convert checked to unchecked');
                    lines[i] = lines[i].replace(/- \[(x|X)\] /, UNCHECKED);
                }
                // Convert plain list lines (-, *, +) to unchecked checkboxes lines.
                else if (lines[i].match(/(-|\*|\+) /)) {
                    script.log('Convert plain list to unchecked');
                    lines[i] = lines[i].replace(/(-|\*|\+) /, UNCHECKED);
                }
                // Add checkboxes when unpresent (empty lines are skipped).
                else {
                    // TODO block adding UNCHECKED mid sentence, how to detect?
                    script.log('Convert no list to unchecked');
                    lines[i] = UNCHECKED + lines[i];
                }
            }
        }

        // Overwrite current selection with processed-content.
        script.noteTextEditWrite(lines.join('\n'));
        // TODO: select the inserted content (for true 'cycling'): how?
    }
}
