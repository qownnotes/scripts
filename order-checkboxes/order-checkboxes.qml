import QtQml 2.0
import com.qownnotes.noteapi 1.0

// TODO:
// - make it work without the need to start with a toplevel element
// - make it work with different types of indentation styles (spaces)
// - make the order configurable
// - add more checkbox tyes

/**
 * This script creates a menu item and a button to order checkboxes.
 * Selected lines containing checkboxes will be ordered as follows:
 * [x] checked -> [-] disabled -> [ ] unchecked.
 * Pro tip: assign a shortcut.
 */
QtObject {
    property bool reverseOrder;
    property bool keepSelection;

    property variant settingsVariables: [
        {
            'identifier': 'reverseOrder',
            'name': 'Reverse order',
            'description': 'Reverse the default order to: [ ] unchecked -> [-] disabled -> [x] checked.',
            'type': 'boolean',
            'default': 'false',
        },
        {
            'identifier': 'keepSelection',
            'name': 'Keep selection',
            'description': 'Keep text selected after ordering.',
            'type': 'boolean',
            'default': 'false',
        },
    ];

    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction(
            'orderCheckboxes', /* identifier */
            'Order checkboxes', /* menuText */
            'Order checkboxes', /* buttonText */
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
        if (identifier === 'orderCheckboxes') {
            orderCheckboxes();
        }
    }

    function orderCheckboxes() {
        // Get selected lines.
        const input = script.noteTextEditSelectedText();

        // Nothing selected.
        if (input.trim() === '') {
            script.log('Nothing selected, nothing to do.');
            return;
        }

        const noteTextEditSelectionStart = script.noteTextEditSelectionStart();
        const noteTextEditSelectionEnd = script.noteTextEditSelectionEnd();

        // Text -> structured.
        let structured = [];
        input
            .split('\n')
            .forEach((row) => {
                if (row.trim() !== '') {
                    addItemToLevel(structured, row);
                }
            });

        // Sort structured.
        let structured_sorted = sortLevel(structured);

        // Structured -> text.
        let text_sorted = '';
        unfold(structured_sorted, '');

        // Overwrite current selection with processed-content.
        script.noteTextEditWrite(text_sorted);

        // Restore selection if requested.
        if (keepSelection) {
            script.noteTextEditSetSelection(noteTextEditSelectionStart, noteTextEditSelectionEnd);
        }

        function addItemToLevel(level, row) {
            if (isTopLevel(row)) {
                level.push({
                    txt: row
                });
            } else {
                // Make sure last level has `.sub = []`.
                if (!last(level).hasOwnProperty('sub')) {
                    last(level).sub = [];
                }

                // Remove the first indentation and recurse.
                row = row.replace('\t', '');
                addItemToLevel(last(level).sub, row);
            }

            function isTopLevel(row) {
                return !(row.startsWith(' ') || row.startsWith('\t'));
            }

            function last(level) {
                return level[level.length - 1];
            }
        }

        function sortLevel(level) {
            // Loop all items in level and if we find a sub, recurse.
            level.forEach((item) => {
                if (item.hasOwnProperty('sub')) {
                    sortLevel(item.sub);
                }
            });

            // Actual sort level.
            level.sort((a, b) => {
                let charA = a.txt.charAt(3);
                let charB = b.txt.charAt(3);
                if ((charA === 'x' && charB === '-') ||
                    (charA === 'x' && charB === ' ') ||
                    (charA === '-' && charB === ' ')
                ) {
                    return reverseOrder ? 1 : -1;
                } else if (
                    (charA === ' ' && charB === 'x') ||
                    (charA === ' ' && charB === '-') ||
                    (charA === '-' && charB === 'x')
                ) {
                    return reverseOrder ? -1 : 1;
                } else {
                    return 0;
                }
            });

            return level;
        }

        function unfold(out, prefix) {
            out.forEach((item) => {
                text_sorted = text_sorted + prefix + item.txt + '\n';
                // In case of a sublevel, add indent and recurse.
                if (item.hasOwnProperty('sub')) {
                    unfold(item.sub, prefix + '\t');
                }
            });
        }
    }
}
