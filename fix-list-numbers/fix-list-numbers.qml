import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script fixes numbers in ordered list.
 */
QtObject {

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != 'fixListNumbers') {
            return;
        }

        var text = script.noteTextEditSelectedText();
        var indentGroups = [];
        var numberRegex = /^(\s*)(\d+)\./;

        var mapped = text.split("\n").map(function (line) {
            if (!numberRegex.test(line)) {
                return line;
            }

            var execResults = numberRegex.exec(line);
            var spacing = (execResults ? execResults[1] : '').replace(new RegExp("\t", 'g'), '    ');
            var indentLevel = spacing.length;
            var group = indentGroups.pop() || {
                level: indentLevel,
                number: 1
            };

            if (indentLevel < group.level) {
                group = indentGroups.pop();
            } else if (indentLevel > group.level) {
                // this group is for previous indentation level
                // push it back to the list
                indentGroups.push(group);
                group = {
                    level: indentLevel,
                    number: 1
                };
            }

            var newLine = line.replace(numberRegex, '$1' + group.number + '.');
            indentGroups.push({
                level: indentLevel,
                number: group.number + 1
            });

            return newLine;
        });

        script.noteTextEditWrite(mapped.join("\n"));
    }
    /**
     * Initializes the custom action
     */
    function init() {
        // create a menu entry
        script.registerCustomAction("fixListNumbers", "Fix list numbers", "Dummy", "view-sort-ascending", true, true);
    }
}
