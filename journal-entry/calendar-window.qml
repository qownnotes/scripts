import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.4

Dialog {
    id: win
    visible: true
    width: 380
    height: 380
    title: qsTr("Double click to jump to journal entry")
    standardButtons: StandardButton.NoButton

    Calendar {
        anchors.fill: parent
        weekNumbersVisible: true
        onDoubleClicked: {
            journalEntry.createOrJumpToJournalEntry(selectedDate, "journalEntryDate");
        }
    }
}
