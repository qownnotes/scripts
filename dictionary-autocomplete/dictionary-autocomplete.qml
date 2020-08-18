import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script attempts to autocomplete the current word based on a dictionary file that contains a list of words,
 * separated by a newline character.
 *
 * You can use the Libre Office dictionary files, that can be downloaded in QOwnNotes as source (*.dic).
 * You will get the dictionary path from the Debug settings.
 * 
 * You can also download the dictionaries from https://github.com/qownnotes/dictionaries directly
 */

Script {
    property variant stringList
    property int stringListLength

    property string dictFile
    property string codec
    property int maxResults

    property variant settingsVariables: [
        {
            "identifier": "dictFile",
            "name": "Dictionary file",
            "description": "Please select the dictionary file:",
            "type": "file",
            "default": "",
        },
        {
            "identifier": "codec",
            "name": "Encoding of the dictionary file",
            "description": "Please enter a encoding:",
            "type": "string",
            "default": "iso-8859-1",
        },
        {
            "identifier": "maxResults",
            "name": "Maximum number of results",
            "description": "Please enter a number:",
            "type": "integer",
            "default": 40,
        }
    ]


    function init() {
        if (dictFile == "") {
            return;
        }

        if (script.fileExists(dictFile)) {
            stringList = script.readFromFile(dictFile, codec).split("\n");
            stringListLength = stringList.length;
        } else {
            console.error("Dictionary file " + dictFile + " doesn't exist!");
        }
    }

    function autocompletionHook() {
        const currentWord = script.noteTextEditCurrentWord();

        if (currentWord.length === 0) {
            return [];
        }

        var resultList = [];
        var resultCount = 0;

        for (var i = 0; i < stringListLength; i++) {
            const word = stringList[i];
            if (word.indexOf(currentWord) === 0) {
                // remove everything after a "/", this is a specifica of the dictionary file
                resultList.push(word.split("/")[0]);
                resultCount++;

                if (resultCount > maxResults) {
                    break;
                }
            }
        }

        return resultList;
    }
}
