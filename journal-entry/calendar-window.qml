import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.4

Dialog {
    id: win

    height: 380
    standardButtons: StandardButton.NoButton
    title: qsTr("Double click to jump to journal entry")
    visible: true
    width: 380

    Calendar {
        anchors.fill: parent
        weekNumbersVisible: true

        onDoubleClicked: {
            journalEntry.createOrJumpToJournalEntry(selectedDate, "journalEntryDate");
        }
    }
}
